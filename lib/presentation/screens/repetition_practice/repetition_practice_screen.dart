import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/practice_exercise.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/services/learning_progress_service.dart';
import '../../../data/services/practice_lesson_generator.dart';
import '../../../presentation/widgets/app_dialog.dart';

class RepetitionPracticeScreen extends StatefulWidget {
  const RepetitionPracticeScreen({
    required this.words,
    required this.distractorWords,
    required this.database,
    this.title,
    this.topicId,
    this.loadNextWords,
    super.key,
  });

  final List<ExerciseWord> words;
  final List<ExerciseWord> distractorWords;
  final AppDatabase database;
  final String? title;
  final int? topicId;
  final Future<List<ExerciseWord>> Function()? loadNextWords;

  @override
  State<RepetitionPracticeScreen> createState() =>
      _RepetitionPracticeScreenState();
}

enum _RepetitionPhase { intro, countdown, practice, done }

class _RepetitionPracticeScreenState extends State<RepetitionPracticeScreen> {
  static const _chunkSize = 20;
  static const _questionSeconds = 5.0;
  static const _answerDelay = Duration(milliseconds: 250);

  List<List<ExerciseWord>> _chunks = const [];
  final _generator = PracticeLessonGenerator();

  List<PracticeExercise> _questions = const [];
  List<bool> _isRetry = const [];
  _RepetitionPhase _phase = _RepetitionPhase.intro;
  int _chunkIndex = 0;
  int _questionIndex = 0;
  int _answeredCount = 0;
  int _correctCount = 0;
  int _countdownValue = 3;
  int _dailyRepeatedCount = 0;
  double _secondsLeft = _questionSeconds;
  ExerciseWord? _selectedAnswer;
  bool _isAnswerSubmitted = false;
  bool _timedOut = false;
  String? _feedbackTitle;
  String? _sessionId;
  Timer? _timer;
  Timer? _countdownTimer;
  bool _isLoadingNext = false;
  Future<void> _sessionReady = Future<void>.value();
  Future<void> _persistenceChain = Future<void>.value();

  PracticeExercise get _question => _questions[_questionIndex];

  double get _timerProgress =>
      (_secondsLeft / _questionSeconds).clamp(0.0, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    final words = widget.words
        .where((word) => word.writing.isNotEmpty && word.translation.isNotEmpty)
        .toList(growable: false);
    _setSessionWords(words);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  void _setSessionWords(List<ExerciseWord> words) {
    final sessionWords = _eligibleSessionWords(words);
    _chunks = sessionWords.isEmpty ? const [] : [sessionWords];
  }

  List<ExerciseWord> _eligibleSessionWords(List<ExerciseWord> words) {
    return words
        .where(_hasSameTopicDistractor)
        .take(_chunkSize)
        .toList(growable: false);
  }

  bool _hasSameTopicDistractor(ExerciseWord target) {
    final targetTranslation = target.translation.trim().toLowerCase();
    return widget.distractorWords.any(
      (word) =>
          word.id != target.id &&
          word.topicId == target.topicId &&
          word.translation.trim().toLowerCase() != targetTranslation,
    );
  }

  void _startCountdown() {
    if (_chunks.isEmpty) return;
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _phase = _RepetitionPhase.countdown;
      _countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _phase != _RepetitionPhase.countdown) {
        timer.cancel();
        return;
      }
      if (_countdownValue <= 1) {
        timer.cancel();
        _startChunk(0);
      } else {
        setState(() => _countdownValue--);
      }
    });
  }

  void _startChunk(int index) {
    if (index >= _chunks.length) return;
    _timer?.cancel();
    final questions = _generator.buildRepetitionLesson(
      words: _chunks[index],
      enabledWords: widget.distractorWords,
    );
    setState(() {
      _phase = _RepetitionPhase.practice;
      _chunkIndex = index;
      _questions = List<PracticeExercise>.of(questions, growable: true);
      _isRetry = List<bool>.filled(questions.length, false, growable: true);
      _questionIndex = 0;
      _selectedAnswer = null;
      _isAnswerSubmitted = false;
      _timedOut = false;
      _feedbackTitle = null;
      _secondsLeft = _questionSeconds;
      _sessionId = null;
    });
    _sessionReady = _createSession(questions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _phase == _RepetitionPhase.practice &&
          _questions.isNotEmpty) {
        _startTimer();
        unawaited(_playWord(_question.word));
      }
    });
  }

  Future<void> _createSession(List<PracticeExercise> questions) async {
    if (questions.isEmpty) return;
    _sessionId = await LearningProgressService(widget.database).startSession(
      exercises: questions,
      requiredMask: LearningProgressService.maskForTypes(
        questions.map((question) => question.trainingExercise),
      ),
      topicId: widget.topicId,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted ||
          _isAnswerSubmitted ||
          _phase != _RepetitionPhase.practice) {
        return;
      }
      final next = _secondsLeft - .1;
      if (next <= 0) {
        _timer?.cancel();
        _answer(null, timedOut: true);
      } else {
        setState(() => _secondsLeft = next);
      }
    });
  }

  void _answer(ExerciseWord? answer, {bool timedOut = false}) {
    if (_isAnswerSubmitted || _phase != _RepetitionPhase.practice) return;
    _timer?.cancel();
    final isCorrect = !timedOut && answer?.id == _question.word.id;
    final isRetry = _isRetry[_questionIndex];
    final retryQuestion = _question;
    setState(() {
      _selectedAnswer = answer;
      _isAnswerSubmitted = true;
      _timedOut = timedOut;
      _feedbackTitle = timedOut
          ? 'repetitionTimeUp'
          : isCorrect
          ? 'repetitionAnsweredCorrectly'
          : 'repetitionNotCorrect';
      _answeredCount++;
      if (isCorrect) _correctCount++;
      if (!isCorrect && !isRetry) {
        _questions.add(
          PracticeExercise(
            word: retryQuestion.word,
            variants: retryQuestion.variants,
            trainingExercise: retryQuestion.trainingExercise,
          ),
        );
        _isRetry.add(true);
      }
    });
    _recordAnswer(
      isCorrect ? ExerciseAnswerState.correct : ExerciseAnswerState.wrong,
      isRetry: isRetry,
    );
    unawaited(_advanceAfterAnswer());
  }

  void _recordAnswer(ExerciseAnswerState answer, {required bool isRetry}) {
    final sessionReady = _sessionReady;
    final orderIndex = _questionIndex;
    _persistenceChain = _persistenceChain.then((_) async {
      await sessionReady;
      final sessionId = _sessionId;
      if (sessionId == null) return;
      await LearningProgressService(widget.database).submitAnswer(
        sessionId: sessionId,
        orderIndex: orderIndex,
        answer: answer,
        createRetryOnWrong: !isRetry,
      );
    });
  }

  Future<void> _advanceAfterAnswer() async {
    await Future<void>.delayed(_answerDelay);
    if (!mounted || !_isAnswerSubmitted) return;
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedAnswer = null;
        _isAnswerSubmitted = false;
        _timedOut = false;
        _feedbackTitle = null;
        _secondsLeft = _questionSeconds;
      });
      _startTimer();
      unawaited(_playWord(_question.word));
      return;
    }

    await _completeChunk();
  }

  Future<void> _completeChunk() async {
    await _persistenceChain;
    await _sessionReady;
    final sessionId = _sessionId;
    if (sessionId != null) {
      await LearningProgressService(
        widget.database,
      ).completeSession(sessionId, dailyTaskType: DailyTaskType.repeat);
    }
    final currentTime = DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    ).millisecondsSinceEpoch;
    final visit = await (widget.database.select(
      widget.database.visitModels,
    )..where((row) => row.date.equals(today))).getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _sessionId = null;
      _dailyRepeatedCount = visit?.repeatedWordsCount ?? 0;
      _phase = _RepetitionPhase.done;
    });
  }

  Future<void> _leave() async {
    _timer?.cancel();
    _countdownTimer?.cancel();
    if (_phase == _RepetitionPhase.practice) {
      await _persistenceChain;
      await _sessionReady;
      final sessionId = _sessionId;
      if (sessionId != null) {
        await LearningProgressService(
          widget.database,
        ).abandonSession(sessionId);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _restart() async {
    if (_isLoadingNext) return;
    setState(() => _isLoadingNext = true);
    List<ExerciseWord> words;
    try {
      words = _chunks.expand((chunk) => chunk).toList(growable: false);
      final loader = widget.loadNextWords;
      if (loader != null) {
        words = await loader();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingNext = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.text('repetitionLoadError'))),
        );
      return;
    }
    if (!mounted) return;
    final sessionWords = _eligibleSessionWords(words);
    if (sessionWords.isEmpty) {
      setState(() => _isLoadingNext = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.text('repetitionNoDueWords'))),
        );
      return;
    }
    _chunks = [sessionWords];
    _timer?.cancel();
    setState(() {
      _isLoadingNext = false;
      _answeredCount = 0;
      _correctCount = 0;
      _chunkIndex = 0;
      _questionIndex = 0;
      _questions = const [];
      _selectedAnswer = null;
      _isAnswerSubmitted = false;
      _timedOut = false;
      _feedbackTitle = null;
      _secondsLeft = _questionSeconds;
      _sessionId = null;
    });
    _startCountdown();
  }

  Future<void> _requestClose() async {
    if (_phase != _RepetitionPhase.practice) {
      await _leave();
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        imageAsset: 'assets/images/cancel_icon_dialog.png',
        title: context.l10n.text('repetitionExitTitle'),
        message: context.l10n.text('repetitionExitBody'),
        secondaryLabel: context.l10n.text('repetitionStay'),
        onSecondary: () => Navigator.of(dialogContext).pop(false),
        primaryLabel: context.l10n.text('exit'),
        onPrimary: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldLeave == true) await _leave();
  }

  Future<void> _playWord(ExerciseWord word) {
    return TextToSpeechService.instance.speak(word.writing);
  }

  @override
  Widget build(BuildContext context) {
    final currentChunkSize = _chunks.isEmpty ? 0 : _chunks[_chunkIndex].length;
    final questionProgress = _questions.isEmpty
        ? 0.0
        : (_questionIndex + (_isAnswerSubmitted ? 1 : 0)) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestClose());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _RepetitionBackdrop()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: _RepetitionTopBar(
                      title:
                          widget.title ??
                          context.l10n.text('repetitionDefaultTitle'),
                      onClose: _requestClose,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _RepetitionStats(
                      secondsLeft: _secondsLeft,
                      timerProgress: _timerProgress,
                      chunkIndex: _chunkIndex,
                      chunkCount: _chunks.length,
                      questionIndex: _questionIndex,
                      questionCount: _phase == _RepetitionPhase.practice
                          ? _questions.length
                          : currentChunkSize,
                      isRetry:
                          _phase == _RepetitionPhase.practice &&
                          _questions.isNotEmpty &&
                          _isRetry[_questionIndex],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              _phase == _RepetitionPhase.intro
                                  ? 94
                                  : math.max(
                                      28,
                                      MediaQuery.paddingOf(context).bottom + 18,
                                    ),
                            ),
                            child: _buildPhaseContent(
                              questionProgress: questionProgress,
                            ),
                          ),
                        ),
                        if (_phase == _RepetitionPhase.intro)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 16,
                            child: _RepetitionStartButton(
                              onPressed: _chunks.isEmpty
                                  ? null
                                  : _startCountdown,
                            ),
                          ),
                      ],
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

  Widget _buildPhaseContent({required double questionProgress}) {
    switch (_phase) {
      case _RepetitionPhase.intro:
        return _IntroContent(
          totalWords: _chunks.isEmpty ? 0 : _chunks.first.length,
          chunkSize: _chunks.isEmpty ? 0 : _chunks.first.length,
          chunks: _chunks.length,
          previewWords: _chunks.isEmpty
              ? const []
              : _chunks.first.take(4).toList(growable: false),
        );
      case _RepetitionPhase.countdown:
        return _CountdownContent(
          value: _countdownValue,
          totalWords: _chunks.isEmpty ? 0 : _chunks.first.length,
        );
      case _RepetitionPhase.practice:
        if (_questions.isEmpty) {
          return const _EmptyPracticeContent();
        }
        return _PracticeContent(
          question: _question,
          selectedAnswer: _selectedAnswer,
          isSubmitted: _isAnswerSubmitted,
          timedOut: _timedOut,
          secondsLeft: _secondsLeft,
          timerProgress: _timerProgress,
          questionProgress: questionProgress,
          feedbackTitle: _feedbackTitle,
          onAnswer: (answer) => _answer(answer),
          onPlay: _playWord,
        );
      case _RepetitionPhase.done:
        return _DoneContent(
          total: _chunks.isEmpty ? 0 : _chunks.first.length,
          correct: _correctCount,
          answered: _answeredCount,
          dailyRepeatedCount: _dailyRepeatedCount,
          isLoading: _isLoadingNext,
          onRestart: () => unawaited(_restart()),
          onClose: _leave,
        );
    }
  }
}

class _RepetitionBackdrop extends StatelessWidget {
  const _RepetitionBackdrop();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/bg_repetition_practice.png',
      key: const ValueKey('repetition-practice-background'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
    );
  }
}

class _RepetitionTopBar extends StatelessWidget {
  const _RepetitionTopBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _GlassButton(icon: Icons.close_rounded, onPressed: onClose),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SELECTED REVIEW',
                    style: TextStyle(
                      color: Color(0xFF2A79D8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 300,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 31,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .9),
      elevation: 5,
      shadowColor: const Color(0x332C65A4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('repetition-practice-close-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}

class _RepetitionStats extends StatelessWidget {
  const _RepetitionStats({
    required this.secondsLeft,
    required this.timerProgress,
    required this.chunkIndex,
    required this.chunkCount,
    required this.questionIndex,
    required this.questionCount,
    required this.isRetry,
  });

  final double secondsLeft;
  final double timerProgress;
  final int chunkIndex;
  final int chunkCount;
  final int questionIndex;
  final int questionCount;
  final bool isRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: context.l10n.text('repetitionQuestionType'),
            value: context.l10n.text('repetitionTranslateMeaning'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimerStatCard(
            secondsLeft: secondsLeft,
            progress: timerProgress,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: context.l10n.text('repetitionProgress'),
            value: questionCount == 0
                ? context.l10n.text(
                    'repetitionGroupCount',
                    values: {'count': '$chunkCount'},
                  )
                : '${questionIndex + 1} / $questionCount',
            subvalue: isRetry
                ? context.l10n.text('repetitionPracticeAgain')
                : chunkCount > 1
                ? context.l10n.text(
                    'repetitionCurrentGroup',
                    values: {
                      'current': '${chunkIndex + 1}',
                      'total': '$chunkCount',
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.subvalue});

  final String label;
  final String value;
  final String? subvalue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F466E9C),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5680B7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subvalue != null)
            Text(
              subvalue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
        ],
      ),
    );
  }
}

class _TimerStatCard extends StatelessWidget {
  const _TimerStatCard({required this.secondsLeft, required this.progress});

  final double secondsLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F466E9C),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.text('repetitionTime'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5680B7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5.5,
                      backgroundColor: const Color(0xFFFFD9B1),
                      color: AppColors.orange,
                    ),
                    Text(
                      secondsLeft.ceil().toString(),
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({
    required this.totalWords,
    required this.chunkSize,
    required this.chunks,
    required this.previewWords,
  });

  final int totalWords;
  final int chunkSize;
  final int chunks;
  final List<ExerciseWord> previewWords;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: Icons.bolt_rounded,
          title: context.l10n.text('repetitionReadyTitle'),
          description: context.l10n.text('repetitionReadyBody'),
          child: Column(
            children: [
              _InfoRow(
                label: context.l10n.text('repetitionTotalWords'),
                value: context.l10n.text(
                  'repetitionWordsValue',
                  values: {'count': '$totalWords'},
                ),
              ),
              const Divider(height: 1, color: Color(0xFFDCE7F3)),
              _InfoRow(
                label: context.l10n.text('repetitionPerRound'),
                value: context.l10n.text(
                  'repetitionWordsValue',
                  values: {'count': '$chunkSize'},
                ),
              ),
              const Divider(height: 1, color: Color(0xFFDCE7F3)),
              _InfoRow(
                label: context.l10n.text('repetitionRoundCount'),
                value: context.l10n.text(
                  'repetitionGroupCount',
                  values: {'count': '$chunks'},
                ),
              ),
            ],
          ),
        ),
        if (previewWords.isNotEmpty) ...[
          const SizedBox(height: 14),
          _WordPreviewCard(words: previewWords),
        ],
      ],
    );
  }
}

class _RepetitionStartButton extends StatelessWidget {
  const _RepetitionStartButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('repetition-practice-start-button'),
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65C7FF), Color(0xFF1768EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF72C9FF), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D1768EF),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded, size: 27),
        label: Text(context.l10n.text('repetitionStart')),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
        ),
      ),
    );
  }
}

class _CountdownContent extends StatelessWidget {
  const _CountdownContent({required this.value, required this.totalWords});

  final int value;
  final int totalWords;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('repetition-countdown-card'),
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.fromLTRB(24, 43, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21466E9C),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '✦',
                style: TextStyle(color: Color(0xFF83B3FF), fontSize: 16),
              ),
              const SizedBox(width: 13),
              Text(
                context.l10n.text('repetitionReadyEyebrow'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 13),
              const Text(
                '✦',
                style: TextStyle(color: Color(0xFF83B3FF), fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 198,
            height: 198,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28155CFF),
                          blurRadius: 22,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFF9FBFF), Color(0xFFEAF2FF)],
                        ),
                      ),
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 82,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -3,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 18,
                  right: 5,
                  child: _CountdownSparkle(size: 28),
                ),
                const Positioned(
                  left: 20,
                  top: 74,
                  child: _CountdownSparkle(size: 13),
                ),
                const Positioned(
                  left: 23,
                  bottom: 24,
                  child: _CountdownSparkle(size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            context.l10n.text(
              'repetitionStartingWords',
              values: {'count': '$totalWords'},
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            context.l10n.text('repetitionTimerHint'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownSparkle extends StatelessWidget {
  const _CountdownSparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦',
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        height: 1,
        shadows: const [Shadow(color: Color(0x6682B5FF), blurRadius: 7)],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F466E9C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordPreviewCard extends StatelessWidget {
  const _WordPreviewCard({required this.words});

  final List<ExerciseWord> words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A466E9C),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('repetitionUpcomingWords'),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < words.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      words[index].writing,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      words[index].translation,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Color(0xFF6481A9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != words.length - 1)
              const Divider(height: 1, color: Color(0xFFDCE7F3)),
          ],
        ],
      ),
    );
  }
}

class _PracticeContent extends StatelessWidget {
  const _PracticeContent({
    required this.question,
    required this.selectedAnswer,
    required this.isSubmitted,
    required this.timedOut,
    required this.secondsLeft,
    required this.timerProgress,
    required this.questionProgress,
    required this.feedbackTitle,
    required this.onAnswer,
    required this.onPlay,
  });

  final PracticeExercise question;
  final ExerciseWord? selectedAnswer;
  final bool isSubmitted;
  final bool timedOut;
  final double secondsLeft;
  final double timerProgress;
  final double questionProgress;
  final String? feedbackTitle;
  final ValueChanged<ExerciseWord> onAnswer;
  final Future<void> Function(ExerciseWord word) onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('repetition-question-card'),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x21466E9C),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFFFF8A20),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.l10n.text('repetitionSecondsPerWord'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7FAFF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x24466E9C),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: context.l10n.text('pronunciation'),
                      onPressed: () => onPlay(question.word),
                      icon: const Icon(Icons.volume_up_rounded, size: 27),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.text('repetitionChooseTranslation'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                question.word.writing,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.7,
                ),
              ),
              if (question.word.transliteration.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  question.word.transliteration,
                  style: const TextStyle(
                    color: Color(0xFF7891B6),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSubmitted
                        ? (timedOut
                              ? context.l10n.text('repetitionTimeExpired')
                              : context.l10n.text('repetitionAnswerRecorded'))
                        : context.l10n.text(
                            'repetitionAutoAdvance',
                            values: {'seconds': '${secondsLeft.ceil()}'},
                          ),
                    style: const TextStyle(
                      color: Color(0xFF5276AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${(questionProgress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: timerProgress,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFDDE7F5),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            context.l10n.text('chooseOneAnswer'),
            style: const TextStyle(
              color: Color(0xFF4F76B0),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...question.variants.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnswerTile(
              answer: entry.value,
              index: entry.key,
              correctAnswerId: question.word.id,
              selectedAnswerId: selectedAnswer?.id,
              isSubmitted: isSubmitted,
              onTap: () => onAnswer(entry.value),
            ),
          ),
        ),
        if (isSubmitted && feedbackTitle != null)
          _FeedbackToast(
            title: context.l10n.text(feedbackTitle!),
            isCorrect: !timedOut && selectedAnswer?.id == question.word.id,
            correctTranslation: question.word.translation,
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 2),
            child: Text(
              context.l10n.text('repetitionKeepPaceHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6686B5),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.answer,
    required this.index,
    required this.correctAnswerId,
    required this.selectedAnswerId,
    required this.isSubmitted,
    required this.onTap,
  });

  final ExerciseWord answer;
  final int index;
  final int correctAnswerId;
  final int? selectedAnswerId;
  final bool isSubmitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer.id == correctAnswerId;
    final isSelected = answer.id == selectedAnswerId;
    final isWrong = isSubmitted && isSelected && !isCorrect;
    final background = isSubmitted && isCorrect
        ? const Color(0xFFE6F8EE)
        : isWrong
        ? const Color(0xFFFFE7E8)
        : Colors.white;
    final border = isSubmitted && isCorrect
        ? AppColors.green
        : isWrong
        ? const Color(0xFFFF646A)
        : AppColors.divider;
    final accent = isSubmitted && isCorrect
        ? AppColors.green
        : isWrong
        ? const Color(0xFFFF646A)
        : AppColors.primary;

    return Material(
      color: background,
      elevation: isSubmitted ? 0 : 2,
      shadowColor: const Color(0x24466E9C),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isSubmitted ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: isSubmitted && isCorrect
                    ? Icon(Icons.check_rounded, color: accent)
                    : isWrong
                    ? Icon(Icons.close_rounded, color: accent)
                    : Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  answer.translation,
                  style: TextStyle(
                    color: isSubmitted && (isCorrect || isWrong)
                        ? accent
                        : AppColors.textPrimary,
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSubmitted && isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSubmitted && isCorrect
                    ? accent
                    : const Color(0xFF7893B9),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackToast extends StatelessWidget {
  const _FeedbackToast({
    required this.title,
    required this.isCorrect,
    required this.correctTranslation,
  });

  final String title;
  final bool isCorrect;
  final String correctTranslation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF20B2158),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
            color: isCorrect
                ? const Color(0xFF89FFB2)
                : const Color(0xFFFFB0B4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.text(
                    'repetitionCorrectAnswer',
                    values: {'answer': correctTranslation},
                  ),
                  style: const TextStyle(
                    color: Color(0xCCE6F0FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneContent extends StatelessWidget {
  const _DoneContent({
    required this.total,
    required this.correct,
    required this.answered,
    required this.dailyRepeatedCount,
    required this.isLoading,
    required this.onRestart,
    required this.onClose,
  });

  final int total;
  final int correct;
  final int answered;
  final int dailyRepeatedCount;
  final bool isLoading;
  final VoidCallback onRestart;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: .96),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2773BD),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .91),
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 135,
              child: Image.asset(
                'assets/images/cup_done_practice.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.text('repetitionCompleteTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF103D93),
                fontSize: 29,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                text: '${context.l10n.text('repetitionCompletePrefix')} ',
                children: [
                  TextSpan(
                    text: '$dailyRepeatedCount',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: ' ${context.l10n.text('repetitionCompleteSuffix')}',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7C91B5),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    icon: Icons.check_rounded,
                    color: const Color(0xFF45B68A),
                    label: context.l10n.text('repetitionCorrectStat'),
                    value: '$correct',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultMetric(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                    label: context.l10n.text('repetitionOriginalWordStat'),
                    value: '$total',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultMetric(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF6044E8),
                    label: context.l10n.text('repetitionAttemptStat'),
                    value: '$answered',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _ResultPrimaryButton(
              label: isLoading
                  ? context.l10n.text('loading')
                  : context.l10n.text('repetitionContinue'),
              onPressed: isLoading ? null : onRestart,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(context.l10n.text('repetitionFinish')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPrimaryButton extends StatelessWidget {
  const _ResultPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? const [Color(0xFF9CB7E9), Color(0xFF8CA9DE)]
              : const [Color(0xFF377FF5), Color(0xFF155CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D155CFF),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final IconData icon;
  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18072762),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 52, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .18), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -15,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: .16),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B84B4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPracticeContent extends StatelessWidget {
  const _EmptyPracticeContent();

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.menu_book_rounded,
      title: context.l10n.text('repetitionEmptyTitle'),
      description: context.l10n.text('repetitionEmptyBody'),
      primaryLabel: context.l10n.text('close'),
      onPrimary: null,
    );
  }
}
