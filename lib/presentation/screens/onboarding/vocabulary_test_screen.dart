import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/models/onboarding_vocabulary_test.dart';
import '../../../data/models/sentence_exercise.dart';
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
  int _answeredQuestionCount = 0;
  int? _maximumTestQuestions;
  int _lastPartCorrect = 0;
  int _lastPartTotal = 0;
  int _passedParts = 0;
  int? _selectedChoiceIndex;
  final List<int> _selectedSentenceChoiceIndexes = [];
  bool _sentenceHintVisible = false;
  bool _sentenceSubmitting = false;
  bool _choiceFeedbackSheetVisible = false;
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
    unawaited(_loadMaximumTestQuestions());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  Future<void> _loadPart({required bool showCountdown}) async {
    if (showCountdown && _partNumber == 1) {
      _answeredQuestionCount = 0;
    }
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
        _selectedSentenceChoiceIndexes.clear();
        _sentenceHintVisible = false;
        _sentenceSubmitting = false;
        _choiceFeedbackSheetVisible = false;
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

  Future<void> _loadMaximumTestQuestions() async {
    try {
      final questionsByLevel = await Future.wait(
        BrightLevel.values.map(_service.loadQuestions),
      );
      final questionCountByLevel = <BrightLevel, int>{
        for (var index = 0; index < BrightLevel.values.length; index++)
          BrightLevel.values[index]: questionsByLevel[index].length,
      };
      final maximum = _maximumQuestionsFrom(_currentNode, questionCountByLevel);
      if (!mounted) return;
      setState(() => _maximumTestQuestions = maximum);
    } on Object {
      // The current-part progress remains available if local assets fail.
    }
  }

  int _maximumQuestionsFrom(
    VocabularyAssessmentNode node,
    Map<BrightLevel, int> questionCountByLevel,
  ) {
    if (node.isResult) return 0;
    final failedQuestions = node.failed == null
        ? 0
        : _maximumQuestionsFrom(node.failed!, questionCountByLevel);
    final passedQuestions = node.passed == null
        ? 0
        : _maximumQuestionsFrom(node.passed!, questionCountByLevel);
    final remainingQuestions = failedQuestions > passedQuestions
        ? failedQuestions
        : passedQuestions;
    return (questionCountByLevel[node.level] ?? 0) + remainingQuestions;
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
      _selectedSentenceChoiceIndexes.clear();
      _sentenceHintVisible = false;
      _sentenceSubmitting = false;
      _choiceFeedbackSheetVisible = false;
      _answerRevealed = false;
    });
    _showConstructorAlertIfNeeded();
  }

  void _showConstructorAlertIfNeeded() {
    if (!_question.isConstructor ||
        _question.hasSentenceExercise ||
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
    final choice = _question.choices[index];
    setState(() {
      _selectedChoiceIndex = index;
      _answerRevealed = true;
    });
    if (!choice.isCorrect) unawaited(_showWrongChoiceSheet(choice.text));
  }

  Future<void> _showWrongChoiceSheet(String selectedAnswer) async {
    if (!mounted || _choiceFeedbackSheetVisible) return;
    final question = _question;
    final correctAnswer = question.choices.firstWhere(
      (choice) => choice.isCorrect,
    );
    setState(() => _choiceFeedbackSheetVisible = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || !_answerRevealed || _selectedChoiceIndex == null) {
      if (mounted) setState(() => _choiceFeedbackSheetVisible = false);
      return;
    }
    var shouldContinue = false;
    try {
      shouldContinue =
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            enableDrag: true,
            backgroundColor: Colors.transparent,
            barrierColor: const Color(0x6604193A),
            builder: (sheetContext) => _OnboardingWrongChoiceSheet(
              selectedAnswer: selectedAnswer,
              correctAnswer: correctAnswer.text,
              onContinue: () => Navigator.of(sheetContext).pop(true),
            ),
          ) ??
          false;
    } finally {
      if (mounted) setState(() => _choiceFeedbackSheetVisible = false);
    }
    if (mounted && shouldContinue) _recordAnswer(isCorrect: false);
  }

  void _toggleSentenceChoice(int index) {
    if (_sentenceSubmitting || !_question.hasSentenceExercise) return;
    setState(() {
      final selectedIndex = _selectedSentenceChoiceIndexes.indexOf(index);
      if (selectedIndex >= 0) {
        _selectedSentenceChoiceIndexes.removeAt(selectedIndex);
        return;
      }
      final exercise = _question.sentenceExercise!;
      if (_selectedSentenceChoiceIndexes.length <
          exercise.expectedTokens.length) {
        _selectedSentenceChoiceIndexes.add(index);
      }
    });
  }

  void _removeLastSentenceChoice() {
    if (_sentenceSubmitting || _selectedSentenceChoiceIndexes.isEmpty) return;
    setState(() => _selectedSentenceChoiceIndexes.removeLast());
  }

  void _toggleSentenceHint() {
    if (_sentenceSubmitting) return;
    setState(() => _sentenceHintVisible = !_sentenceHintVisible);
  }

  void _continueQuestion() {
    if (_question.hasSentenceExercise) {
      unawaited(_submitSentenceQuestion());
      return;
    }
    if (_question.isConstructor) {
      _recordAnswer(isCorrect: false);
      return;
    }
    final selected = _selectedChoiceIndex;
    if (selected == null) return;
    _recordAnswer(isCorrect: _question.choices[selected].isCorrect);
  }

  Future<void> _submitSentenceQuestion() async {
    if (_sentenceSubmitting || _selectedSentenceChoiceIndexes.isEmpty) return;
    final exercise = _question.sentenceExercise!;
    final selectedTokens = _selectedSentenceChoiceIndexes
        .map((index) => exercise.choices[index])
        .toList(growable: false);
    final isCorrect = exercise.isCorrect(selectedTokens);
    setState(() => _sentenceSubmitting = true);
    final shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingSentenceAnswerSheet(
        selectedTokens: selectedTokens,
        correctAnswer: exercise.fullAnswer,
        isCorrect: isCorrect,
      ),
    );
    if (!mounted) return;
    setState(() => _sentenceSubmitting = false);
    if (shouldContinue == true) _recordAnswer(isCorrect: isCorrect);
  }

  void _skipQuestion() => _recordAnswer(isCorrect: false);

  void _recordAnswer({required bool isCorrect}) {
    _answeredQuestionCount++;
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
      _selectedSentenceChoiceIndexes.clear();
      _sentenceHintVisible = false;
      _sentenceSubmitting = false;
      _choiceFeedbackSheetVisible = false;
      _answerRevealed = false;
    });
    _showConstructorAlertIfNeeded();
  }

  Future<void> _finishPart() async {
    _lastPartCorrect = _correctInPart;
    _lastPartTotal = _correctInPart + _wrongInPart;
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
    final isCountdown = _phase == _TestPhase.countdown;
    final isDarkAssessmentPhase =
        isCountdown || _phase == _TestPhase.betweenParts;
    final hasQuestionProgress =
        _questions.isNotEmpty &&
        (_phase == _TestPhase.question ||
            _phase == _TestPhase.betweenParts ||
            _phase == _TestPhase.countdown);
    final progress = hasQuestionProgress
        ? (_answeredQuestionCount + 1) /
              (_maximumTestQuestions ??
                  (_answeredQuestionCount + _questions.length))
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isCountdown
            ? const Color(0xFF063BA4)
            : Colors.white,
        systemNavigationBarIconBrightness: isCountdown
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061D4C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AssessmentBackdrop(),
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
                      decoration: isDarkAssessmentPhase
                          ? null
                          : const BoxDecoration(
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
                          selectedSentenceChoiceIndexes:
                              _selectedSentenceChoiceIndexes,
                          sentenceHintVisible: _sentenceHintVisible,
                          answerRevealed: _answerRevealed,
                          onChoiceSelected: _selectChoice,
                          onSentenceChoiceSelected: _toggleSentenceChoice,
                          onRemoveLastSentenceChoice: _removeLastSentenceChoice,
                          onToggleSentenceHint: _toggleSentenceHint,
                          onSpeak: () => TextToSpeechService.instance
                              .speakLatest(_question.writing),
                          onContinue: _continueQuestion,
                          onSkip: _skipQuestion,
                        ),
                        _TestPhase.betweenParts => _BetweenPartsView(
                          partNumber: _partNumber,
                          level: _currentNode.level,
                          correct: _lastPartCorrect,
                          total: _lastPartTotal,
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

class _AssessmentBackdrop extends StatelessWidget {
  const _AssessmentBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020A38), Color(0xFF062A79), Color(0xFF064BC2)],
          stops: [0, .48, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: .16,
            child: Image.asset(
              'assets/images/onboarding/bg_choose_language.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(top: 52, left: 35, child: _BackdropStar(size: 5)),
          const Positioned(top: 85, right: 62, child: _BackdropStar(size: 4)),
          const Positioned(top: 165, right: 24, child: _BackdropStar(size: 3)),
          const Positioned(top: 265, left: 78, child: _BackdropStar(size: 3)),
        ],
      ),
    );
  }
}

class _BackdropStar extends StatelessWidget {
  const _BackdropStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF8DE8FF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51D7FF).withValues(alpha: .9),
            blurRadius: size * 3,
            spreadRadius: size / 2,
          ),
        ],
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
      height: 130,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 20, 12),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: const Color(0x332D65C8),
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    key: const ValueKey('vocabulary-test-close'),
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(17),
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 29,
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
                          color: Color(0xFF58DCFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Phần $partNumber • Cấp độ ${level.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: Image.asset(
                          'assets/images/owls/owl_test.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.contain,
                          color: const Color(0xFF65E4FF),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      Image.asset(
                        'assets/images/owls/owl_test.png',
                        width: 78,
                        height: 78,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 10),
              _ExamProgressIndicator(progress: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExamProgressIndicator extends StatelessWidget {
  const _ExamProgressIndicator({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('vocabulary-test-progress'),
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0x332B6DCA),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x553B8CFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x442B9DFF), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB4F7FF), Color(0xFF39BFFF)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
            ),
          );
        },
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
    required this.selectedSentenceChoiceIndexes,
    required this.sentenceHintVisible,
    required this.answerRevealed,
    required this.onChoiceSelected,
    required this.onSentenceChoiceSelected,
    required this.onRemoveLastSentenceChoice,
    required this.onToggleSentenceHint,
    required this.onSpeak,
    required this.onContinue,
    required this.onSkip,
  });

  final VocabularyTestQuestion question;
  final int questionNumber;
  final int questionCount;
  final int? selectedChoiceIndex;
  final List<int> selectedSentenceChoiceIndexes;
  final bool sentenceHintVisible;
  final bool answerRevealed;
  final ValueChanged<int> onChoiceSelected;
  final ValueChanged<int> onSentenceChoiceSelected;
  final VoidCallback onRemoveLastSentenceChoice;
  final VoidCallback onToggleSentenceHint;
  final VoidCallback onSpeak;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  bool get _isAudio =>
      question.definition.type == VocabularyTaskType.audioThree ||
      question.definition.type == VocabularyTaskType.audioFour;

  @override
  Widget build(BuildContext context) {
    final canContinue = question.hasSentenceExercise
        ? selectedSentenceChoiceIndexes.isNotEmpty
        : question.isConstructor || selectedChoiceIndex != null;
    final sentenceExercise = question.sentenceExercise;
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
                if (question.hasSentenceExercise)
                  _SentenceConstructorCard(
                    exercise: sentenceExercise!,
                    selectedChoiceIndexes: selectedSentenceChoiceIndexes,
                    onChoiceSelected: onSentenceChoiceSelected,
                    hintVisible: sentenceHintVisible,
                    onRemoveLast: onRemoveLastSentenceChoice,
                    onHint: onToggleSentenceHint,
                  )
                else if (question.isConstructor)
                  _ConstructorUnavailableCard(question: question)
                else if (_isAudio)
                  _AudioPrompt(onSpeak: onSpeak)
                else
                  _TextPrompt(question: question, onSpeak: onSpeak),
                if (!question.isConstructor &&
                    !question.hasSentenceExercise) ...[
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
                label: question.hasSentenceExercise
                    ? 'Kiểm tra'
                    : question.isConstructor || answerRevealed
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

class _SentenceConstructorCard extends StatelessWidget {
  const _SentenceConstructorCard({
    required this.exercise,
    required this.selectedChoiceIndexes,
    required this.onChoiceSelected,
    required this.hintVisible,
    required this.onRemoveLast,
    required this.onHint,
  });

  final SentenceExercise exercise;
  final List<int> selectedChoiceIndexes;
  final ValueChanged<int> onChoiceSelected;
  final bool hintVisible;
  final VoidCallback onRemoveLast;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final selectedTokens = selectedChoiceIndexes
        .map((index) => exercise.choices[index])
        .toList(growable: false);
    return Column(
      key: const ValueKey('vocabulary-test-sentence-constructor'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value:
                selectedChoiceIndexes.length / exercise.expectedTokens.length,
            minHeight: 7,
            backgroundColor: const Color(0xFFDDE8FA),
            color: const Color(0xFF56D8FF),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F26448B),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  exercise.title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  exercise.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  exercise.sentence.translation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 20),
                _OnboardingAnswerArea(
                  tokens: selectedTokens,
                  emptySlots: exercise.expectedTokens.length,
                  onRemoveLast: onRemoveLast,
                ),
                if (hintVisible) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Gợi ý: ${exercise.answer}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8B6500),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var index = 0; index < exercise.choices.length; index++)
              _SentenceTokenChoice(
                key: ValueKey('vocabulary-test-sentence-token-$index'),
                label: exercise.choices[index],
                selected: selectedChoiceIndexes.contains(index),
                disabled:
                    selectedChoiceIndexes.length >=
                        exercise.expectedTokens.length &&
                    !selectedChoiceIndexes.contains(index),
                onTap: () => onChoiceSelected(index),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onHint,
          icon: Icon(
            hintVisible
                ? Icons.visibility_off_outlined
                : Icons.lightbulb_outline_rounded,
            size: 17,
          ),
          label: Text(hintVisible ? 'Ẩn gợi ý' : 'Xem gợi ý'),
        ),
      ],
    );
  }
}

class _OnboardingAnswerArea extends StatelessWidget {
  const _OnboardingAnswerArea({
    required this.tokens,
    required this.emptySlots,
    required this.onRemoveLast,
  });

  final List<String> tokens;
  final int emptySlots;
  final VoidCallback onRemoveLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.divider),
      ),
      child: tokens.isEmpty
          ? Center(
              child: Text(
                '$emptySlots vị trí đang chờ',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final token in tokens)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      token,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onRemoveLast,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Xóa từ cuối',
                  icon: const Icon(Icons.backspace_outlined, size: 18),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
    );
  }
}

class _SentenceTokenChoice extends StatelessWidget {
  const _SentenceTokenChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: selected || disabled ? .42 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        elevation: selected ? 0 : 1,
        shadowColor: const Color(0x2526448B),
        child: InkWell(
          onTap: disabled && !selected ? null : onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingWrongChoiceSheet extends StatelessWidget {
  const _OnboardingWrongChoiceSheet({
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onContinue,
  });

  final String selectedAnswer;
  final String correctAnswer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFAFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F163873),
            blurRadius: 30,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE7F3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chú ý',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hãy xem lại sự khác nhau giữa câu trả lời bạn chọn và đáp án đúng.',
            style: TextStyle(
              color: Color(0xFF6F84A2),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _OnboardingChoiceFeedbackCard(
            label: 'Câu trả lời của bạn',
            value: selectedAnswer,
            accent: const Color(0xFFEC5B42),
          ),
          const SizedBox(height: 12),
          _OnboardingChoiceFeedbackCard(
            label: 'Câu trả lời đúng',
            value: correctAnswer,
            accent: const Color(0xFF18B865),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF20C873),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                elevation: 0,
              ),
              child: const Text('Tiếp tục'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingChoiceFeedbackCard extends StatelessWidget {
  const _OnboardingChoiceFeedbackCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDF1F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8193AC),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSentenceAnswerSheet extends StatelessWidget {
  const _OnboardingSentenceAnswerSheet({
    required this.selectedTokens,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final List<String> selectedTokens;
  final String correctAnswer;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DFEE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFDDF8EE)
                      : const Color(0xFFFFE8ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: isCorrect
                      ? const Color(0xFF137E68)
                      : const Color(0xFFC65375),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? 'Chính xác!' : 'Chưa đúng rồi',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OnboardingAnswerLine(
            label: 'Câu trả lời của bạn',
            value: selectedTokens.join(' '),
          ),
          const SizedBox(height: 10),
          _OnboardingAnswerLine(
            label: 'Đáp án đúng',
            value: correctAnswer,
            correct: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAnswerLine extends StatelessWidget {
  const _OnboardingAnswerLine({
    required this.label,
    required this.value,
    this.correct = false,
  });

  final String label;
  final String value;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFF0F9F5) : const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: correct ? const Color(0xFF137E68) : AppColors.textPrimary,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
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
        Expanded(
          child: Text(
            correct ? 'Chính xác!' : 'Chưa đúng, đáp án đúng đã được đánh dấu.',
            style: TextStyle(
              color: correct
                  ? const Color(0xFF159A68)
                  : const Color(0xFFD8425B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 32).clamp(0.0, 430.0);
        final cardHeight = (cardWidth * 1.52).clamp(490.0, 620.0);
        return SingleChildScrollView(
          key: const ValueKey('vocabulary-test-countdown'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/onboarding/frame_exam_test.png',
                    fit: BoxFit.fill,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Image.asset(
                              'assets/images/owls/owl_test.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sẵn sàng nhé!',
                            style: TextStyle(
                              color: Color(0xFF0B2A71),
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Container(
                              width: 146,
                              height: 146,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .55),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .8),
                                  width: 7,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x665FB9FF),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  '$count',
                                  key: ValueKey(count),
                                  style: const TextStyle(
                                    color: Color(0xFF0C5BEB),
                                    fontSize: 82,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BetweenPartsView extends StatelessWidget {
  const _BetweenPartsView({
    required this.partNumber,
    required this.level,
    required this.correct,
    required this.total,
    required this.onContinue,
  });

  final int partNumber;
  final BrightLevel level;
  final int correct;
  final int total;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('vocabulary-test-between-parts'),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        children: [
          SizedBox(
            height: 255,
            child: Image.asset(
              'assets/images/onboarding/good_job_exam_test.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18C85B),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8818C85B),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '$correct/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'đáp án đúng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          const Text(
            'Tuyệt vời!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
              shadows: [Shadow(color: Color(0xFF4D9CFF), blurRadius: 16)],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Đã xong nửa chặng đường!\n'
            'Bạn đã làm rất tốt với những từ này. Hãy thử\n'
            'các câu hỏi thử thách hơn nhé',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC8D9FF),
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FF),
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xAA2D8CFF),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(36),
                child: InkWell(
                  key: const ValueKey('vocabulary-test-next-part'),
                  onTap: onContinue,
                  borderRadius: BorderRadius.circular(36),
                  child: const Center(
                    child: Text(
                      'Tiếp',
                      style: TextStyle(
                        color: Color(0xFF145CE8),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cấp độ tiếp theo: ${level.label} · Phần $partNumber',
            style: const TextStyle(
              color: Color(0xFF8FB7FF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
