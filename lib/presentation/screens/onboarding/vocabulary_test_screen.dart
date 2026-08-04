import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/text_to_speech_service.dart';
import '../../../data/models/onboarding_vocabulary_test.dart';
import '../../../data/services/onboarding_vocabulary_test_service.dart';

class VocabularyTestScreen extends StatefulWidget {
  const VocabularyTestScreen({
    required this.startingBand,
    this.service,
    super.key,
  });

  final VocabularyStartingBand startingBand;
  final OnboardingVocabularyTestService? service;

  @override
  State<VocabularyTestScreen> createState() => _VocabularyTestScreenState();
}

enum _TestPhase { loading, countdown, question, betweenParts, result, error }

class _VocabularyTestScreenState extends State<VocabularyTestScreen> {
  late final OnboardingVocabularyTestService _service;
  late VocabularyAssessmentNode _currentNode;
  late final BrightLevel _startedLevel;

  _TestPhase _phase = _TestPhase.loading;
  List<VocabularyTestQuestion> _questions = const [];
  int _questionIndex = 0;
  int _partNumber = 1;
  int _correctInPart = 0;
  int _wrongInPart = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;
  int _passedParts = 0;
  int? _selectedChoiceIndex;
  bool _answerRevealed = false;
  int _countdown = 3;
  Timer? _countdownTimer;
  BrightLevel? _resultLevel;
  String? _errorMessage;
  final Set<int> _shownConstructorAlerts = {};

  VocabularyTestQuestion get _question => _questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OnboardingVocabularyTestService();
    _currentNode = VocabularyAssessmentTree.forBand(widget.startingBand);
    _startedLevel = _currentNode.level;
    unawaited(_loadPart(showCountdown: true));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  Future<void> _loadPart({required bool showCountdown}) async {
    setState(() {
      _phase = _TestPhase.loading;
      _errorMessage = null;
    });

    try {
      final questions = await _service.loadQuestions(_currentNode.level);
      if (!mounted) return;
      if (questions.isEmpty) {
        throw StateError('Không tìm thấy câu hỏi cho phần này.');
      }
      setState(() {
        _questions = questions;
        _questionIndex = 0;
        _correctInPart = 0;
        _wrongInPart = 0;
        _selectedChoiceIndex = null;
        _answerRevealed = false;
        _phase = showCountdown ? _TestPhase.countdown : _TestPhase.betweenParts;
      });
      if (showCountdown) _startCountdown();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _phase = _TestPhase.error;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown == 1) {
        timer.cancel();
        _showCurrentQuestion();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _showCurrentQuestion() {
    setState(() {
      _phase = _TestPhase.question;
      _selectedChoiceIndex = null;
      _answerRevealed = false;
    });
    _showConstructorAlertIfNeeded();
  }

  void _showConstructorAlertIfNeeded() {
    if (!_question.isConstructor ||
        !_shownConstructorAlerts.add(_question.definition.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != _TestPhase.question) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.construction_rounded,
            color: Color(0xFF155CFF),
            size: 34,
          ),
          title: const Text('Coming soon'),
          content: const Text(
            'Dạng bài ghép câu đang được hoàn thiện. '
            'Bạn có thể bấm Tiếp theo để tiếp tục bài kiểm tra.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              key: const ValueKey('constructor-coming-soon-close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    });
  }

  void _selectChoice(int index) {
    if (_answerRevealed || _question.isConstructor) return;
    setState(() {
      _selectedChoiceIndex = index;
      _answerRevealed = true;
    });
  }

  void _continueQuestion() {
    if (_question.isConstructor) {
      _recordAnswer(isCorrect: false);
      return;
    }
    final selected = _selectedChoiceIndex;
    if (selected == null) return;
    _recordAnswer(isCorrect: _question.choices[selected].isCorrect);
  }

  void _skipQuestion() => _recordAnswer(isCorrect: false);

  void _recordAnswer({required bool isCorrect}) {
    if (isCorrect) {
      _correctInPart++;
      _totalCorrect++;
    } else {
      _wrongInPart++;
      _totalWrong++;
    }

    final answeredCount = _questionIndex + 1;
    final shouldStopFirstPartEarly =
        _partNumber == 1 && answeredCount == 4 && _wrongInPart == 4;
    final isLastQuestion = _questionIndex == _questions.length - 1;

    if (isLastQuestion || shouldStopFirstPartEarly) {
      unawaited(_finishPart());
      return;
    }

    setState(() {
      _questionIndex++;
      _selectedChoiceIndex = null;
      _answerRevealed = false;
    });
    _showConstructorAlertIfNeeded();
  }

  Future<void> _finishPart() async {
    final passed = _correctInPart > _questions.length / 2;
    if (passed) _passedParts++;
    final nextNode = _currentNode.next(didPass: passed);

    if (nextNode.isResult) {
      _resultLevel = nextNode.level;
      await _saveResult(nextNode.level);
      if (!mounted) return;
      setState(() => _phase = _TestPhase.result);
      return;
    }

    _currentNode = nextNode;
    _partNumber++;
    await _loadPart(showCountdown: false);
  }

  Future<void> _saveResult(BrightLevel finalLevel) async {
    final comparison = finalLevel.index > _startedLevel.index
        ? 'higher'
        : finalLevel.index < _startedLevel.index
        ? 'lower'
        : 'same';
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setBool('isVocabularyTestComplete', true),
        preferences.setString('brightLevel', finalLevel.label),
        preferences.setString('vocabularyTestResult', comparison),
      ]);
    } on Object {
      // The result remains usable in-memory if local persistence is unavailable.
    }
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Thoát bài kiểm tra?'),
        content: const Text('Kết quả của phần đang làm sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tiếp tục làm'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    if (shouldExit != true || !mounted) return;
    context.go('/onboarding/assessment-intro/survey');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuestionProgress =
        _questions.isNotEmpty &&
        (_phase == _TestPhase.question ||
            _phase == _TestPhase.betweenParts ||
            _phase == _TestPhase.countdown);
    final progress = hasQuestionProgress
        ? (_questionIndex + 1) / _questions.length
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061D4C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/bg_choose_language.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TestHeader(
                    level: _resultLevel ?? _currentNode.level,
                    partNumber: _partNumber,
                    progress: progress,
                    showProgress: hasQuestionProgress,
                    onClose: _confirmExit,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBFDFF),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33031A55),
                            blurRadius: 28,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: switch (_phase) {
                        _TestPhase.loading => const _LoadingTestView(),
                        _TestPhase.countdown => _CountdownView(
                          count: _countdown,
                        ),
                        _TestPhase.question => _QuestionView(
                          question: _question,
                          questionNumber: _questionIndex + 1,
                          questionCount: _questions.length,
                          selectedChoiceIndex: _selectedChoiceIndex,
                          answerRevealed: _answerRevealed,
                          onChoiceSelected: _selectChoice,
                          onSpeak: () => TextToSpeechService.instance
                              .speakLatest(_question.writing),
                          onContinue: _continueQuestion,
                          onSkip: _skipQuestion,
                        ),
                        _TestPhase.betweenParts => _BetweenPartsView(
                          partNumber: _partNumber,
                          level: _currentNode.level,
                          onContinue: _showCurrentQuestion,
                        ),
                        _TestPhase.result => _ResultView(
                          resultLevel: _resultLevel!,
                          correct: _totalCorrect,
                          total: _totalCorrect + _totalWrong,
                          passedParts: _passedParts,
                          onContinue: () =>
                              context.go('/onboarding/assessment-intro/survey'),
                        ),
                        _TestPhase.error => _ErrorTestView(
                          message: _errorMessage,
                          onRetry: () =>
                              _loadPart(showCountdown: _partNumber == 1),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestHeader extends StatelessWidget {
  const _TestHeader({
    required this.level,
    required this.partNumber,
    required this.progress,
    required this.showProgress,
    required this.onClose,
  });

  final BrightLevel level;
  final int partNumber;
  final double progress;
  final bool showProgress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 20, 17),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: const ValueKey('vocabulary-test-close'),
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox.square(
                      dimension: 40,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KIỂM TRA TRÌNH ĐỘ',
                        style: TextStyle(
                          color: Color(0xFFA9C6FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Phần $partNumber  •  Cấp độ ${level.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/owls/owl_test.png',
                  width: 55,
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  key: const ValueKey('vocabulary-test-progress'),
                  value: progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: .17),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF56D8FF)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.questionNumber,
    required this.questionCount,
    required this.selectedChoiceIndex,
    required this.answerRevealed,
    required this.onChoiceSelected,
    required this.onSpeak,
    required this.onContinue,
    required this.onSkip,
  });

  final VocabularyTestQuestion question;
  final int questionNumber;
  final int questionCount;
  final int? selectedChoiceIndex;
  final bool answerRevealed;
  final ValueChanged<int> onChoiceSelected;
  final VoidCallback onSpeak;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  bool get _isAudio =>
      question.definition.type == VocabularyTaskType.audioThree ||
      question.definition.type == VocabularyTaskType.audioFour;

  @override
  Widget build(BuildContext context) {
    final canContinue = question.isConstructor || selectedChoiceIndex != null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CÂU $questionNumber/$questionCount',
                  style: const TextStyle(
                    color: Color(0xFF7E92AD),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _instruction,
                  style: const TextStyle(
                    color: Color(0xFF071944),
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 24),
                if (question.isConstructor)
                  _ConstructorUnavailableCard(question: question)
                else if (_isAudio)
                  _AudioPrompt(onSpeak: onSpeak)
                else
                  _TextPrompt(question: question, onSpeak: onSpeak),
                if (!question.isConstructor) ...[
                  const SizedBox(height: 24),
                  for (var index = 0; index < question.choices.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _AnswerChoiceCard(
                        index: index,
                        choice: question.choices[index],
                        selected: selectedChoiceIndex == index,
                        revealed: answerRevealed,
                        onTap: () => onChoiceSelected(index),
                      ),
                    ),
                ],
                if (answerRevealed && selectedChoiceIndex != null) ...[
                  const SizedBox(height: 4),
                  _AnswerFeedback(
                    correct: question.choices[selectedChoiceIndex!].isCorrect,
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 8, 24, 15),
          child: Column(
            children: [
              _PrimaryTestButton(
                key: const ValueKey('vocabulary-test-next'),
                label: question.isConstructor || answerRevealed
                    ? 'Tiếp theo'
                    : 'Kiểm tra',
                enabled: canContinue,
                onPressed: onContinue,
              ),
              if (!question.isConstructor)
                TextButton(
                  key: const ValueKey('vocabulary-test-skip'),
                  onPressed: onSkip,
                  child: const Text('Bỏ qua câu này'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String get _instruction {
    return switch (question.definition.type) {
      VocabularyTaskType.text => 'Từ này có nghĩa là gì?',
      VocabularyTaskType.inverseText => 'Chọn từ tiếng Anh phù hợp',
      VocabularyTaskType.audioThree ||
      VocabularyTaskType.audioFour => 'Nghe và chọn nghĩa đúng',
      VocabularyTaskType.constructor => 'Ghép thành một câu hoàn chỉnh',
    };
  }
}

class _TextPrompt extends StatelessWidget {
  const _TextPrompt({required this.question, required this.onSpeak});

  final VocabularyTestQuestion question;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final inverse = question.definition.type == VocabularyTaskType.inverseText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF3FF), Color(0xFFF6FAFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E6FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inverse ? question.translation : question.writing,
                  style: const TextStyle(
                    color: Color(0xFF071944),
                    fontSize: 27,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                if (!inverse && question.transcription.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    question.transcription,
                    style: const TextStyle(
                      color: Color(0xFF7188A8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!inverse)
            IconButton.filled(
              key: const ValueKey('vocabulary-test-speak'),
              onPressed: onSpeak,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF155CFF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.volume_up_rounded),
            ),
        ],
      ),
    );
  }
}

class _AudioPrompt extends StatelessWidget {
  const _AudioPrompt({required this.onSpeak});

  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Material(
            color: const Color(0xFF155CFF),
            shape: const CircleBorder(),
            elevation: 9,
            shadowColor: const Color(0x66155CFF),
            child: InkWell(
              key: const ValueKey('vocabulary-test-audio'),
              onTap: onSpeak,
              customBorder: const CircleBorder(),
              child: const SizedBox.square(
                dimension: 92,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Chạm để nghe lại',
            style: TextStyle(
              color: Color(0xFF7188A8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstructorUnavailableCard extends StatelessWidget {
  const _ConstructorUnavailableCard({required this.question});

  final VocabularyTestQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('vocabulary-test-constructor-coming-soon'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.construction_rounded,
            size: 44,
            color: Color(0xFF155CFF),
          ),
          const SizedBox(height: 12),
          const Text(
            'Coming soon',
            style: TextStyle(
              color: Color(0xFF071944),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dạng bài ghép câu “${question.writing}” sẽ sớm được cập nhật.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7188A8),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerChoiceCard extends StatelessWidget {
  const _AnswerChoiceCard({
    required this.index,
    required this.choice,
    required this.selected,
    required this.revealed,
    required this.onTap,
  });

  final int index;
  final VocabularyTestChoice choice;
  final bool selected;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = revealed && choice.isCorrect;
    final showWrong = revealed && selected && !choice.isCorrect;
    final borderColor = showCorrect
        ? const Color(0xFF20C988)
        : showWrong
        ? const Color(0xFFFF667D)
        : selected
        ? const Color(0xFF155CFF)
        : const Color(0xFFE1E9F3);
    final backgroundColor = showCorrect
        ? const Color(0xFFEAFFF6)
        : showWrong
        ? const Color(0xFFFFF0F3)
        : selected
        ? const Color(0xFFEDF4FF)
        : Colors.white;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('vocabulary-test-choice-$index'),
          onTap: revealed ? null : onTap,
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10234381),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: showCorrect
                        ? const Color(0xFF20C988)
                        : showWrong
                        ? const Color(0xFFFF667D)
                        : const Color(0xFFF0F4FA),
                    shape: BoxShape.circle,
                  ),
                  child: showCorrect
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                      : showWrong
                      ? const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: Color(0xFF7188A8),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    choice.text,
                    style: const TextStyle(
                      color: Color(0xFF071944),
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          correct ? Icons.check_circle_rounded : Icons.info_rounded,
          color: correct ? const Color(0xFF20C988) : const Color(0xFFFF667D),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          correct ? 'Chính xác!' : 'Chưa đúng, đáp án đúng đã được đánh dấu.',
          style: TextStyle(
            color: correct ? const Color(0xFF159A68) : const Color(0xFFD8425B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PrimaryTestButton extends StatelessWidget {
  const _PrimaryTestButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF0C4DE4), Color(0xFF147BFF)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFD3DDEA), Color(0xFFC9D4E2)],
                ),
          borderRadius: BorderRadius.circular(19),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x40155CFF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(19),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/owls/owl_test.png',
            width: 145,
            height: 145,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sẵn sàng nhé!',
            style: TextStyle(
              color: Color(0xFF071944),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$count',
              key: ValueKey(count),
              style: const TextStyle(
                color: Color(0xFF155CFF),
                fontSize: 58,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BetweenPartsView extends StatelessWidget {
  const _BetweenPartsView({
    required this.partNumber,
    required this.level,
    required this.onContinue,
  });

  final int partNumber;
  final BrightLevel level;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF155CFF),
              size: 54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tiếp tục phần $partNumber',
            style: const TextStyle(
              color: Color(0xFF071944),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Các câu hỏi tiếp theo ở cấp độ ${level.label} sẽ giúp '
            'Leximon đánh giá chính xác hơn.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7188A8),
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          _PrimaryTestButton(
            key: const ValueKey('vocabulary-test-next-part'),
            label: 'Bắt đầu phần $partNumber',
            enabled: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.resultLevel,
    required this.correct,
    required this.total,
    required this.passedParts,
    required this.onContinue,
  });

  final BrightLevel resultLevel;
  final int correct;
  final int total;
  final int passedParts;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (correct * 100 / total).round();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/owls/owl_level.png',
                  width: 132,
                  height: 132,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hoàn thành bài kiểm tra!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF071944),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trình độ tiếng Anh hiện tại của bạn là',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7188A8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 118,
                  height: 118,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0C4DE4), Color(0xFF27A2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D155CFF),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    resultLevel.label,
                    key: const ValueKey('vocabulary-test-result-level'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _ResultStat(
                        value: '$correct/$total',
                        label: 'Câu đúng',
                        color: const Color(0xFF20C988),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultStat(
                        value: '$percentage%',
                        label: 'Độ chính xác',
                        color: const Color(0xFF155CFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultStat(
                        value: '$passedParts',
                        label: 'Phần đạt',
                        color: const Color(0xFF7A5CFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 9, 24, 16),
          child: _PrimaryTestButton(
            key: const ValueKey('vocabulary-test-finish'),
            label: 'Tiếp tục',
            enabled: true,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7188A8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingTestView extends StatelessWidget {
  const _LoadingTestView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text(
            'Đang chuẩn bị câu hỏi...',
            style: TextStyle(
              color: Color(0xFF7188A8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTestView extends StatelessWidget {
  const _ErrorTestView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF667D),
              size: 52,
            ),
            const SizedBox(height: 15),
            const Text(
              'Chưa thể tải bài kiểm tra',
              style: TextStyle(
                color: Color(0xFF071944),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Vui lòng thử lại.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7188A8)),
            ),
            const SizedBox(height: 23),
            SizedBox(
              width: 190,
              child: _PrimaryTestButton(
                label: 'Thử lại',
                enabled: true,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
