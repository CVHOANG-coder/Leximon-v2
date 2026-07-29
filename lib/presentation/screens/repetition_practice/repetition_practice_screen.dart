import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/practice_exercise.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/services/learning_progress_service.dart';
import '../../../data/services/practice_lesson_generator.dart';

class RepetitionPracticeScreen extends StatefulWidget {
  const RepetitionPracticeScreen({
    required this.words,
    required this.distractorWords,
    required this.database,
    this.title = 'Ôn lặp lại',
    super.key,
  });

  final List<ExerciseWord> words;
  final List<ExerciseWord> distractorWords;
  final AppDatabase database;
  final String title;

  @override
  State<RepetitionPracticeScreen> createState() =>
      _RepetitionPracticeScreenState();
}

enum _RepetitionPhase { intro, practice, between, done }

class _RepetitionPracticeScreenState extends State<RepetitionPracticeScreen> {
  static const _chunkSize = 20;
  static const _questionSeconds = 5.0;
  static const _answerDelay = Duration(milliseconds: 1100);

  late final List<List<ExerciseWord>> _chunks;
  final _generator = PracticeLessonGenerator();

  List<PracticeExercise> _questions = const [];
  _RepetitionPhase _phase = _RepetitionPhase.intro;
  int _chunkIndex = 0;
  int _questionIndex = 0;
  int _answeredCount = 0;
  int _correctCount = 0;
  double _secondsLeft = _questionSeconds;
  ExerciseWord? _selectedAnswer;
  bool _isAnswerSubmitted = false;
  bool _timedOut = false;
  String? _feedbackTitle;
  String? _sessionId;
  Timer? _timer;
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
    _chunks = [
      for (var index = 0; index < words.length; index += _chunkSize)
        words.sublist(index, math.min(index + _chunkSize, words.length)),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  void _startFirstChunk() => _startChunk(0);

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
      _questions = questions;
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
      if (mounted && _phase == _RepetitionPhase.practice) _startTimer();
    });
  }

  Future<void> _createSession(List<PracticeExercise> questions) async {
    if (questions.isEmpty) return;
    _sessionId = await LearningProgressService(widget.database).startSession(
      exercises: questions,
      requiredMask: LearningProgressService.maskForTypes(
        questions.map((question) => question.trainingExercise),
      ),
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
    setState(() {
      _selectedAnswer = answer;
      _isAnswerSubmitted = true;
      _timedOut = timedOut;
      _feedbackTitle = timedOut
          ? 'Hết giờ'
          : isCorrect
          ? 'Đã trả lời đúng'
          : 'Chưa đúng';
      _answeredCount++;
      if (isCorrect) _correctCount++;
    });
    _recordAnswer(
      isCorrect ? ExerciseAnswerState.correct : ExerciseAnswerState.wrong,
    );
    unawaited(_advanceAfterAnswer());
  }

  void _recordAnswer(ExerciseAnswerState answer) {
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
        createRetryOnWrong: false,
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
    if (!mounted) return;
    setState(() {
      _sessionId = null;
      _phase = _chunkIndex < _chunks.length - 1
          ? _RepetitionPhase.between
          : _RepetitionPhase.done;
    });
  }

  Future<void> _leave() async {
    _timer?.cancel();
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

  Future<void> _requestClose() async {
    if (_phase != _RepetitionPhase.practice) {
      await _leave();
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thoát buổi ôn?'),
        content: const Text(
          'Tiến độ của nhóm hiện tại sẽ không được ghi nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Thoát'),
          ),
        ],
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
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            const Positioned.fill(child: _RepetitionBackdrop()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: _RepetitionTopBar(
                      title: widget.title,
                      onClose: _requestClose,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _RepetitionStats(
                      secondsLeft: _secondsLeft,
                      timerProgress: _timerProgress,
                      chunkIndex: _chunkIndex,
                      chunkCount: _chunks.length,
                      questionIndex: _questionIndex,
                      questionCount: currentChunkSize,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          18,
                          24,
                          18,
                          math.max(
                            28,
                            MediaQuery.paddingOf(context).bottom + 18,
                          ),
                        ),
                        child: _buildPhaseContent(
                          questionProgress: questionProgress,
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
    );
  }

  Widget _buildPhaseContent({required double questionProgress}) {
    switch (_phase) {
      case _RepetitionPhase.intro:
        return _IntroContent(
          totalWords: widget.words.length,
          chunkSize: _chunks.isEmpty ? 0 : _chunks.first.length,
          chunks: _chunks.length,
          previewWords: widget.words.take(4).toList(growable: false),
          onStart: _chunks.isEmpty ? null : _startFirstChunk,
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
      case _RepetitionPhase.between:
        final finished = _chunkIndex * _chunkSize + _chunks[_chunkIndex].length;
        final remaining = widget.words.length - finished;
        return _BetweenContent(
          finished: finished,
          remaining: remaining,
          onContinue: () => _startChunk(_chunkIndex + 1),
          onFinish: _leave,
        );
      case _RepetitionPhase.done:
        return _DoneContent(
          total: widget.words.length,
          correct: _correctCount,
          answered: _answeredCount,
          onClose: _leave,
        );
    }
  }
}

class _RepetitionBackdrop extends StatelessWidget {
  const _RepetitionBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF091E58), Color(0xFF0D2F86), Color(0xFF215CF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .1),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -100,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: .12),
            ),
          ),
        ),
      ],
    );
  }
}

class _RepetitionTopBar extends StatelessWidget {
  const _RepetitionTopBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassButton(icon: Icons.close_rounded, onPressed: onClose),
        Expanded(
          child: Column(
            children: [
              const Text(
                'SELECTED REVIEW',
                style: TextStyle(
                  color: Color(0xB8FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 44),
      ],
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
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
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
  });

  final double secondsLeft;
  final double timerProgress;
  final int chunkIndex;
  final int chunkCount;
  final int questionIndex;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StatCard(label: 'Dạng câu hỏi', value: 'Dịch nghĩa'),
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
            label: 'Tiến độ',
            value: questionCount == 0
                ? '$chunkCount nhóm'
                : '${questionIndex + 1} / $questionCount',
            subvalue: chunkCount > 1
                ? 'Nhóm ${chunkIndex + 1}/$chunkCount'
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
      height: 82,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24072762),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subvalue != null)
            Text(
              subvalue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFDCE4F3),
                  color: AppColors.orange,
                ),
                Text(
                  secondsLeft.ceil().toString(),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Flexible(
            child: Text(
              'Thời gian',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    required this.onStart,
  });

  final int totalWords;
  final int chunkSize;
  final int chunks;
  final List<ExerciseWord> previewWords;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: Icons.bolt_rounded,
          title: 'Sẵn sàng ôn lại?',
          description:
              'Mỗi từ có 5 giây để trả lời. Các từ được chia thành nhóm tối đa 20 từ để bạn giữ nhịp học tập.',
          child: Column(
            children: [
              _InfoRow(label: 'Tổng số từ', value: '$totalWords từ'),
              _InfoRow(label: 'Mỗi lượt', value: '$chunkSize từ'),
              _InfoRow(label: 'Số lượt', value: '$chunks nhóm'),
            ],
          ),
        ),
        if (previewWords.isNotEmpty) ...[
          const SizedBox(height: 14),
          _WordPreviewCard(words: previewWords),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Bắt đầu ôn'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18072762),
            blurRadius: 30,
            offset: Offset(0, 12),
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
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 14,
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
        color: AppColors.surfaceBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TỪ SẮP ÔN',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...words.map(
            (word) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      word.writing,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      word.translation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.textSecondary),
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
          padding: const EdgeInsets.all(22),
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
                    child: const Text(
                      '⚡ 5 giây / từ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onPlay(question.word),
                    icon: const Icon(Icons.volume_up_rounded),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Chọn bản dịch đúng cho từ bên dưới',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                question.word.writing,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 39,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              if (question.word.transliteration.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  question.word.transliteration,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSubmitted
                        ? (timedOut
                              ? 'Đã hết thời gian'
                              : 'Đã ghi nhận câu trả lời')
                        : 'Tự động chuyển sau ${secondsLeft.ceil()} giây',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${(questionProgress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: timerProgress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE9EEF7),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'CHỌN MỘT ĐÁP ÁN',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
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
            title: feedbackTitle!,
            isCorrect: !timedOut && selectedAnswer?.id == question.word.id,
            correctTranslation: question.word.translation,
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Trả lời nhanh để giữ nhịp ôn tập.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: isSubmitted ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
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
                          fontSize: 19,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  answer.translation,
                  style: TextStyle(
                    color: isSubmitted && (isCorrect || isWrong)
                        ? accent
                        : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                isSubmitted && isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSubmitted && isCorrect ? accent : AppColors.textMuted,
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
                  'Đáp án đúng: “$correctTranslation”.',
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

class _BetweenContent extends StatelessWidget {
  const _BetweenContent({
    required this.finished,
    required this.remaining,
    required this.onContinue,
    required this.onFinish,
  });

  final int finished;
  final int remaining;
  final VoidCallback onContinue;
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Bạn muốn ôn tiếp?',
      description:
          'Bạn đã hoàn thành $finished từ. Còn $remaining từ trong danh sách.',
      primaryLabel: 'Ôn nhóm tiếp theo',
      secondaryLabel: 'Dừng tại đây',
      onPrimary: onContinue,
      onSecondary: onFinish,
    );
  }
}

class _DoneContent extends StatelessWidget {
  const _DoneContent({
    required this.total,
    required this.correct,
    required this.answered,
    required this.onClose,
  });

  final int total;
  final int correct;
  final int answered;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.emoji_events_rounded,
      title: 'Hoàn thành rồi!',
      description: 'Bạn đã ôn xong toàn bộ $total từ trong danh sách.',
      primaryLabel: 'Đóng',
      onPrimary: () => unawaited(onClose()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ResultMetric(label: 'Đúng', value: '$correct'),
          _ResultMetric(label: 'Đã ôn', value: '$answered'),
          _ResultMetric(
            label: 'Tỷ lệ',
            value: answered == 0
                ? '0%'
                : '${(correct / answered * 100).round()}%',
          ),
        ],
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
    this.secondaryLabel,
    this.onSecondary,
    this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;
  final Widget? child;

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
              fontWeight: FontWeight.w900,
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
          if (child != null) ...[const SizedBox(height: 22), child!],
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
          if (secondaryLabel != null && onSecondary != null)
            TextButton(
              onPressed: () => onSecondary!(),
              child: Text(secondaryLabel!),
            ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _EmptyPracticeContent extends StatelessWidget {
  const _EmptyPracticeContent();

  @override
  Widget build(BuildContext context) {
    return const _ResultCard(
      icon: Icons.menu_book_rounded,
      title: 'Chưa có từ để ôn',
      description: 'Danh sách này hiện không có từ phù hợp để bắt đầu.',
      primaryLabel: 'Đóng',
      onPrimary: null,
    );
  }
}
