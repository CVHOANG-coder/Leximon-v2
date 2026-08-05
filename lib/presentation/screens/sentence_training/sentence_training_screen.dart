import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/models/sentence_exercise.dart';
import '../../../data/services/sentence_ai_service.dart';
import '../../../data/services/sentence_lesson_service.dart';
import '../../../shared/providers/app_providers.dart';

enum _SentenceScreenStage {
  loading,
  intro,
  training,
  completing,
  result,
  error,
}

class SentenceTrainingScreen extends ConsumerStatefulWidget {
  const SentenceTrainingScreen({
    this.source = SentenceTrainingSource.additional,
    this.topicId,
    this.lessonService,
    this.aiService,
    super.key,
  });

  final SentenceTrainingSource source;
  final int? topicId;
  final SentenceLessonService? lessonService;
  final SentenceAiService? aiService;

  @override
  ConsumerState<SentenceTrainingScreen> createState() =>
      _SentenceTrainingScreenState();
}

class _SentenceTrainingScreenState
    extends ConsumerState<SentenceTrainingScreen> {
  _SentenceScreenStage _stage = _SentenceScreenStage.loading;
  SentenceLesson? _lesson;
  int _exerciseIndex = 0;
  final List<int> _selectedChoiceIndexes = [];
  bool _hintVisible = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _completionApplied = false;

  SentenceExercise get _exercise => _lesson!.exercises[_exerciseIndex];
  List<String> get _selectedTokens => _selectedChoiceIndexes
      .map((index) => _exercise.choices[index])
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    unawaited(_loadLesson());
  }

  @override
  void dispose() {
    unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  Future<void> _loadLesson() async {
    if (mounted) {
      setState(() {
        _stage = _SentenceScreenStage.loading;
        _exerciseIndex = 0;
        _correctCount = 0;
        _wrongCount = 0;
        _selectedChoiceIndexes.clear();
        _hintVisible = false;
        _completionApplied = false;
      });
    }
    try {
      final SentenceLessonService service =
          widget.lessonService ?? ref.read(sentenceLessonServiceProvider);
      final lessonFuture = service.loadLesson(topicId: widget.topicId);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final lesson = await lessonFuture;
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _stage = _SentenceScreenStage.intro;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _stage = _SentenceScreenStage.error);
    }
  }

  void _startTraining() {
    setState(() => _stage = _SentenceScreenStage.training);
    _playForCurrentExercise();
  }

  void _playForCurrentExercise() {
    if (_exercise.type != SentenceExerciseType.audio &&
        _exercise.type != SentenceExerciseType.inverse) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          TextToSpeechService.instance.speakLatest(_exercise.sentence.spelling),
        );
      }
    });
  }

  void _toggleChoice(int index) {
    if (_selectedChoiceIndexes.contains(index)) {
      setState(() => _selectedChoiceIndexes.remove(index));
      return;
    }
    if (_selectedChoiceIndexes.length >= _exercise.expectedTokens.length) {
      return;
    }
    setState(() => _selectedChoiceIndexes.add(index));
  }

  void _removeLastChoice() {
    if (_selectedChoiceIndexes.isEmpty) return;
    setState(() => _selectedChoiceIndexes.removeLast());
  }

  Future<void> _submit() async {
    if (_selectedChoiceIndexes.isEmpty) return;
    final exercise = _exercise;
    final selectedTokens = _selectedTokens;
    final isCorrect = exercise.isCorrect(selectedTokens);
    setState(() {
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });
    unawaited(
      TextToSpeechService.instance.speakLatest(exercise.sentence.spelling),
    );

    final shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x7704193A),
      builder: (_) => _AnswerSheet(
        exercise: exercise,
        selectedTokens: selectedTokens,
        isCorrect: isCorrect,
        aiService: widget.aiService ?? ref.read(sentenceAiServiceProvider),
        isLast: _exerciseIndex == _lesson!.exercises.length - 1,
      ),
    );
    if (!mounted || shouldContinue != true) return;
    await _continueTraining();
  }

  Future<void> _continueTraining() async {
    if (_exerciseIndex >= _lesson!.exercises.length - 1) {
      setState(() => _stage = _SentenceScreenStage.completing);
      await _completeLesson();
      return;
    }
    setState(() {
      _exerciseIndex++;
      _selectedChoiceIndexes.clear();
      _hintVisible = false;
    });
    _playForCurrentExercise();
  }

  Future<void> _skipListeningExercises() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ qua bài nghe?'),
        content: const Text(
          'Tất cả bài nghe còn lại trong phiên này sẽ được bỏ qua. Bạn vẫn có thể tiếp tục các dạng ghép câu khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Bỏ qua bài nghe'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final remaining = <SentenceExercise>[
      for (final entry in _lesson!.exercises.indexed)
        if (entry.$1 < _exerciseIndex ||
            entry.$2.type != SentenceExerciseType.audio)
          entry.$2,
    ];
    setState(() {
      _lesson = SentenceLesson(
        wordIds: _lesson!.wordIds,
        exercises: remaining,
        sentences: _lesson!.sentences,
      );
      _selectedChoiceIndexes.clear();
      _hintVisible = false;
      if (_exerciseIndex >= remaining.length) {
        _stage = _SentenceScreenStage.completing;
      }
    });
    if (_stage == _SentenceScreenStage.training) {
      _playForCurrentExercise();
    } else {
      await _completeLesson();
    }
  }

  Future<void> _completeLesson() async {
    try {
      if (!_completionApplied) {
        await ref
            .read(sentenceProgressServiceProvider)
            .completeLesson(_lesson!);
        _completionApplied = true;
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hoàn thành nhưng chưa thể lưu tiến độ ghép câu.'),
          ),
        );
      }
    }
    if (mounted) setState(() => _stage = _SentenceScreenStage.result);
  }

  Future<void> _handleBack() async {
    if (_stage == _SentenceScreenStage.completing) return;
    if (_stage != _SentenceScreenStage.training) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dừng phiên ghép câu?'),
        content: const Text(
          'Kết quả của phiên chưa hoàn tất sẽ không được ghi nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tiếp tục học'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_handleBack());
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFEAF7FF),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _SentenceBackdrop(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _Header(
                      stage: _stage,
                      current: _stage == _SentenceScreenStage.training
                          ? _exerciseIndex + 1
                          : 0,
                      total: _lesson?.exercises.length ?? 0,
                      onBack: _handleBack,
                    ),
                    if (_stage == _SentenceScreenStage.training) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _ProgressBar(
                          value:
                              (_exerciseIndex + 1) / _lesson!.exercises.length,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() => switch (_stage) {
    _SentenceScreenStage.loading => const _LoadingView(),
    _SentenceScreenStage.intro => _IntroView(
      exerciseCount: _lesson!.exercises.length,
      wordCount: _lesson!.wordIds.length,
      onStart: _startTraining,
    ),
    _SentenceScreenStage.training => _TrainingView(
      exercise: _exercise,
      selectedChoiceIndexes: _selectedChoiceIndexes,
      hintVisible: _hintVisible,
      onToggleChoice: _toggleChoice,
      onRemoveLast: _removeLastChoice,
      onHint: () => setState(() => _hintVisible = !_hintVisible),
      onSubmit: _submit,
      onSpeak: (slow) => TextToSpeechService.instance.speakLatest(
        _exercise.sentence.spelling,
        speechRate: slow
            ? TextToSpeechService.slowSpeechRate
            : TextToSpeechService.defaultSpeechRate,
      ),
      onSkipListening: _skipListeningExercises,
    ),
    _SentenceScreenStage.completing => const _CompletingView(),
    _SentenceScreenStage.result => _ResultView(
      correctCount: _correctCount,
      wrongCount: _wrongCount,
      wordCount: _lesson!.wordIds.length,
      onMore: widget.source == SentenceTrainingSource.daily
          ? null
          : _loadLesson,
      onFinish: () => Navigator.of(context).pop(),
    ),
    _SentenceScreenStage.error => _ErrorView(
      onRetry: _loadLesson,
      onClose: () => Navigator.of(context).pop(),
    ),
  };
}

class _SentenceBackdrop extends StatelessWidget {
  const _SentenceBackdrop();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_sentence.png',
      key: const Key('sentence-training-background'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stage,
    required this.current,
    required this.total,
    required this.onBack,
  });

  final _SentenceScreenStage stage;
  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isIntroStyle = stage != _SentenceScreenStage.training;
    return SizedBox(
      height: isIntroStyle ? 112 : 88,
      child: Stack(
        children: [
          Positioned(
            left: 26,
            top: isIntroStyle ? 29 : 15,
            child: Material(
              color: Colors.white.withValues(alpha: .92),
              elevation: 5,
              shadowColor: const Color(0x332C65A4),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: const Key('sentence-training-back-button'),
                onTap: onBack,
                borderRadius: BorderRadius.circular(18),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF123CA4),
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 98,
            top: isIntroStyle ? 30 : 16,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORDS IN SENTENCES',
                  style: TextStyle(
                    color: Color(0xFF2466DE),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Ghép câu',
                  style: TextStyle(
                    color: Color(0xFF123AA3),
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          if (stage == _SentenceScreenStage.training)
            Positioned(
              right: 26,
              top: 31,
              child: Text(
                '$current / $total',
                style: const TextStyle(
                  color: Color(0xFF155CFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2426448B),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 18),
            Text(
              'Đang chuẩn bị câu phù hợp...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Dữ liệu tiếng Việt được tải từ thiết bị',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletingView extends StatelessWidget {
  const _CompletingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Đang ghi nhận tiến độ...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.exerciseCount,
    required this.wordCount,
    required this.onStart,
  });

  final int exerciseCount;
  final int wordCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        26,
        18,
        26,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          Container(
            key: const Key('sentence-training-intro-card'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 25),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29466E9C),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 42,
                  top: 96,
                  child: _IntroSparkle(size: 14),
                ),
                const Positioned(
                  right: 46,
                  top: 42,
                  child: _IntroSparkle(size: 20),
                ),
                const Positioned(
                  right: 68,
                  top: 136,
                  child: _IntroSparkle(size: 12),
                ),
                Column(
                  children: [
                    Image.asset(
                      'assets/images/owls/owl_match_sentence.png',
                      key: const Key('sentence-training-mascot'),
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Từ vựng sống trong câu',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xFF123AA3),
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$exerciseCount thử thách từ $wordCount từ đang học. Bạn sẽ ghép, nghe và điền từ ngay trong ngữ cảnh.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6E84A9),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 27),
                    const Row(
                      children: [
                        Expanded(
                          child: _IntroChip(
                            icon: Icons.sort_by_alpha_rounded,
                            label: 'Ghép câu',
                            backgroundColor: Color(0xFFF1F7FF),
                            borderColor: Color(0xFFD8E9FF),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _IntroChip(
                            icon: Icons.headphones_rounded,
                            label: 'Nghe hiểu',
                            backgroundColor: Color(0xFFF8F6FF),
                            borderColor: Color(0xFFE8E0FF),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _IntroChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'AI giải thích',
                            backgroundColor: Color(0xFFF0FCF8),
                            borderColor: Color(0xFFD0F1E6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: _SentenceStartButton(onPressed: onStart),
          ),
        ],
      ),
    );
  }
}

class _IntroSparkle extends StatelessWidget {
  const _IntroSparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦',
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        height: 1,
        shadows: const [Shadow(color: Color(0x6685B7FF), blurRadius: 8)],
      ),
    );
  }
}

class _SentenceStartButton extends StatelessWidget {
  const _SentenceStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _SentencePrimaryButton(
      containerKey: const Key('sentence-training-start-button'),
      label: 'Bắt đầu ghép câu',
      icon: Icons.play_arrow_rounded,
      onPressed: onPressed,
      height: 64,
      fontSize: 20,
    );
  }
}

class _SentencePrimaryButton extends StatelessWidget {
  const _SentencePrimaryButton({
    required this.containerKey,
    required this.label,
    required this.onPressed,
    required this.height,
    required this.fontSize,
    this.icon,
  });

  final Key containerKey;
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final radius = height >= 60 ? 28.0 : 24.0;
    final foregroundColor = isEnabled ? Colors.white : const Color(0xFF929EAF);
    return Container(
      key: containerKey,
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isEnabled ? null : const Color(0xFFD9DEE7),
        gradient: isEnabled
            ? const LinearGradient(
                colors: [Color(0xFF55BFFF), Color(0xFF075FF2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isEnabled ? const Color(0xFF2B83F7) : const Color(0xFFE8EBF0),
          width: isEnabled ? 2.5 : 1.5,
        ),
        boxShadow: isEnabled
            ? const [
                BoxShadow(
                  color: Color(0x4D1768EF),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x183B4E66),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (isEnabled)
            const Positioned(
              right: 18,
              top: 9,
              child: Text(
                '✦',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(radius - 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: foregroundColor, size: 31),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroChip extends StatelessWidget {
  const _IntroChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12466E9C),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF2B70EB)),
          const SizedBox(width: 7),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF12347F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingView extends StatelessWidget {
  const _TrainingView({
    required this.exercise,
    required this.selectedChoiceIndexes,
    required this.hintVisible,
    required this.onToggleChoice,
    required this.onRemoveLast,
    required this.onHint,
    required this.onSubmit,
    required this.onSpeak,
    required this.onSkipListening,
  });

  final SentenceExercise exercise;
  final List<int> selectedChoiceIndexes;
  final bool hintVisible;
  final ValueChanged<int> onToggleChoice;
  final VoidCallback onRemoveLast;
  final VoidCallback onHint;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onSpeak;
  final VoidCallback onSkipListening;

  @override
  Widget build(BuildContext context) {
    final selectedTokens = selectedChoiceIndexes
        .map((index) => exercise.choices[index])
        .toList(growable: false);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 10, 18, 88 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F26448B),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _QuestionCardTitle(title: exercise.title.toUpperCase()),
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
                      _Prompt(exercise: exercise, onSpeak: onSpeak),
                      const SizedBox(height: 20),
                      _AnswerArea(
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
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (
                      var index = 0;
                      index < exercise.choices.length;
                      index++
                    )
                      _ChoiceTile(
                        label: exercise.choices[index],
                        selected: selectedChoiceIndexes.contains(index),
                        disabled:
                            selectedChoiceIndexes.length >=
                                exercise.expectedTokens.length &&
                            !selectedChoiceIndexes.contains(index),
                        onTap: () => onToggleChoice(index),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    if (exercise.type == SentenceExerciseType.audio)
                      TextButton.icon(
                        onPressed: onSkipListening,
                        icon: const Icon(
                          Icons.hearing_disabled_rounded,
                          size: 17,
                        ),
                        label: const Text('Không thể nghe'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 12 + bottomInset,
          child: _SentencePrimaryButton(
            containerKey: const Key('sentence-training-check-button'),
            label: 'Kiểm tra',
            onPressed: selectedChoiceIndexes.isEmpty ? null : onSubmit,
            height: 56,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _QuestionCardTitle extends StatelessWidget {
  const _QuestionCardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('sentence-training-question-card-title'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '✦',
          style: TextStyle(color: Color(0xFF8BC5FF), fontSize: 12, height: 1),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF176DEB),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.45,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          '✦',
          style: TextStyle(color: Color(0xFF8BC5FF), fontSize: 12, height: 1),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sentence-training-progress-track'),
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .66),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .74)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: ColoredBox(
          color: const Color(0xFFD7E9FA),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                final visibleProgress = progress <= 0
                    ? 0.0
                    : (.07 + (progress * .93)).clamp(0.0, 1.0);
                return FractionallySizedBox(
                  key: const Key('sentence-training-progress-fill'),
                  widthFactor: visibleProgress,
                  heightFactor: 1,
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF155CFF), Color(0xFF66CFF4)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.exercise, required this.onSpeak});

  final SentenceExercise exercise;
  final ValueChanged<bool> onSpeak;

  @override
  Widget build(BuildContext context) {
    if (exercise.type == SentenceExerciseType.audio) {
      return Column(
        children: [
          const Text(
            'Nhấn để nghe lại',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 10),
          _AudioButtons(onSpeak: onSpeak),
        ],
      );
    }

    final prompt = switch (exercise.type) {
      SentenceExerciseType.constructor => exercise.sentence.translation,
      SentenceExerciseType.inverse => exercise.sentence.spelling,
      SentenceExerciseType.insertWord => _maskedTask(exercise.sentence.task),
      SentenceExerciseType.audio => '',
    };
    return Column(
      children: [
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
        if (exercise.type == SentenceExerciseType.inverse) ...[
          const SizedBox(height: 12),
          _AudioButtons(onSpeak: onSpeak),
        ],
        if (exercise.type == SentenceExerciseType.insertWord) ...[
          const SizedBox(height: 8),
          Text(
            exercise.sentence.translation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _AudioButtons extends StatelessWidget {
  const _AudioButtons({required this.onSpeak});

  final ValueChanged<bool> onSpeak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AudioButton(
          icon: Icons.volume_up_rounded,
          label: '1×',
          onTap: () => onSpeak(false),
        ),
        const SizedBox(width: 10),
        _AudioButton(
          icon: Icons.speed_rounded,
          label: '0.5×',
          onTap: () => onSpeak(true),
        ),
      ],
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
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
                Material(
                  color: const Color(0xFFFF4D5E),
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    key: const Key('sentence-training-remove-token-button'),
                    onTap: onRemoveLast,
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      key: const Key(
                        'sentence-training-remove-token-decoration',
                      ),
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D5E),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFFF6675)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.backspace_outlined,
                        size: 16,
                        color: Colors.white,
                        semanticLabel: 'Xóa từ cuối',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
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

class _AnswerSheet extends StatefulWidget {
  const _AnswerSheet({
    required this.exercise,
    required this.selectedTokens,
    required this.isCorrect,
    required this.aiService,
    required this.isLast,
  });

  final SentenceExercise exercise;
  final List<String> selectedTokens;
  final bool isCorrect;
  final SentenceAiService aiService;
  final bool isLast;

  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  Future<String?>? _aiExplanation;

  @override
  void initState() {
    super.initState();
    final ratio =
        widget.selectedTokens.length / widget.exercise.expectedTokens.length;
    if (!widget.isCorrect && ratio > .6) {
      _aiExplanation = widget.aiService.explain(
        exercise: widget.exercise,
        userAnswer: widget.selectedTokens.join(' '),
      );
    }
  }

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
                  color: widget.isCorrect
                      ? const Color(0xFFDDF8EE)
                      : const Color(0xFFFFE8ED),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  widget.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: widget.isCorrect
                      ? const Color(0xFF137E68)
                      : const Color(0xFFC65375),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isCorrect ? 'Chính xác!' : 'Chưa đúng rồi',
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
          _AnswerLine(
            label: 'Câu trả lời của bạn',
            value: widget.selectedTokens.join(' '),
          ),
          const SizedBox(height: 10),
          _AnswerLine(
            label: 'Đáp án đúng',
            value: widget.exercise.fullAnswer,
            correct: true,
          ),
          if (!widget.isCorrect) ...[
            const SizedBox(height: 14),
            _ExplanationPanel(
              future: _aiExplanation,
              localExplanation: _localExplanation(
                widget.exercise,
                widget.selectedTokens,
              ),
            ),
          ],
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
              child: Text(
                widget.isLast ? 'Xem kết quả' : 'Tiếp tục',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
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

class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({
    required this.future,
    required this.localExplanation,
  });

  final Future<String?>? future;
  final String localExplanation;

  @override
  Widget build(BuildContext context) {
    if (future == null) return _explanation(localExplanation, false);
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'AI đang phân tích câu trả lời...',
                  style: TextStyle(color: AppColors.primaryDark, fontSize: 10),
                ),
              ],
            ),
          );
        }
        final explanation = snapshot.data;
        return _explanation(
          explanation ??
              'Giải thích AI sắp ra mắt. Bạn vẫn có thể tiếp tục bài học.',
          explanation != null,
        );
      },
    );
  }

  Widget _explanation(String value, bool fromAi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22155CFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fromAi
                    ? Icons.auto_awesome_rounded
                    : Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                fromAi ? 'AI giải thích' : 'Gợi ý',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value.replaceAll('**', ''),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.correctCount,
    required this.wrongCount,
    required this.wordCount,
    required this.onMore,
    required this.onFinish,
  });

  final int correctCount;
  final int wrongCount;
  final int wordCount;
  final VoidCallback? onMore;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final total = correctCount + wrongCount;
    final percent = total == 0 ? 0 : (correctCount * 100 / total).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2426448B),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/images/leximon-owl-wave.png',
              width: 112,
              height: 112,
            ),
            const Text(
              'Hoàn thành phiên ghép câu!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Bạn đã luyện $wordCount từ trong ngữ cảnh.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ResultStat(
                    value: '$percent%',
                    label: 'Chính xác',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultStat(
                    value: '$correctCount',
                    label: 'Câu đúng',
                    color: const Color(0xFF137E68),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultStat(
                    value: '$wrongCount',
                    label: 'Cần xem lại',
                    color: const Color(0xFFC65375),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onFinish,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Hoàn tất',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (onMore != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onMore,
                child: const Text('Luyện thêm 4 từ khác'),
              ),
            ],
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: AppColors.textMuted,
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa thể chuẩn bị bài ghép câu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy thử lại sau khi dữ liệu từ vựng đã được khởi tạo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            TextButton(onPressed: onClose, child: const Text('Đóng')),
          ],
        ),
      ),
    );
  }
}

String _maskedTask(String task) {
  return task.replaceAllMapped(RegExp(r'\|([^|]+)\|'), (match) {
    final length = match.group(1)!.length.clamp(4, 12);
    return List<String>.filled(length, '＿').join();
  });
}

String _localExplanation(
  SentenceExercise exercise,
  List<String> selectedTokens,
) {
  final missing = List<String>.of(exercise.expectedTokens);
  for (final token in selectedTokens) {
    missing.remove(token);
  }
  if (missing.isEmpty) {
    return 'Bạn đã chọn đủ từ nhưng thứ tự chưa chính xác. Hãy nhìn lại vị trí của từng từ trong đáp án.';
  }
  return 'Câu trả lời còn thiếu: ${missing.join(', ')}. Hãy xem lại đáp án rồi tiếp tục nhé.';
}
