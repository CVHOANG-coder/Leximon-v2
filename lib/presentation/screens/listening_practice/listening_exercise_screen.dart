import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/listening_asset_data_source.dart';
import '../../../data/models/listening_exercise.dart';
import '../../../data/services/listening_answer_checker.dart';
import '../../../data/services/listening_progress_service.dart';
import '../../../shared/providers/app_providers.dart';

abstract class ListeningAudioController {
  bool get isPlaying;

  Stream<bool> get playingStream;

  Future<void> playUrl(
    String url, {
    required double speed,
    bool restart = true,
  });

  Future<void> pause();

  Future<void> dispose();
}

class JustAudioListeningController implements ListeningAudioController {
  final AudioPlayer _player = AudioPlayer();
  String? _loadedUrl;

  @override
  bool get isPlaying => _player.playing;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Future<void> playUrl(
    String url, {
    required double speed,
    bool restart = true,
  }) async {
    if (url.isEmpty) return;
    if (_loadedUrl != url) {
      await _player.setUrl(url);
      _loadedUrl = url;
    }
    await _player.setSpeed(speed);
    if (restart) await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}

class ListeningExerciseScreen extends ConsumerStatefulWidget {
  const ListeningExerciseScreen({
    required this.courseId,
    required this.courseIndexAsset,
    required this.lessonId,
    this.initialExercise,
    this.audioController,
    this.progressService,
    this.assetDataSource,
    super.key,
  });

  final int courseId;
  final String courseIndexAsset;
  final int lessonId;
  final ListeningExercise? initialExercise;
  final ListeningAudioController? audioController;
  final ListeningProgressService? progressService;
  final ListeningAssetDataSource? assetDataSource;

  @override
  ConsumerState<ListeningExerciseScreen> createState() =>
      _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState
    extends ConsumerState<ListeningExerciseScreen>
    with WidgetsBindingObserver {
  final _answerController = TextEditingController();
  final _answerFocusNode = FocusNode();
  final _answerChecker = const ListeningAnswerChecker();
  late final ListeningProgressService _progressService;
  late final ListeningAssetDataSource _assetDataSource;
  late final ListeningAudioController _audioController;
  late final Future<ListeningExercise> _exerciseFuture;
  StreamSubscription<bool>? _playingSubscription;
  Timer? _activeTimer;
  DateTime _lastActiveCheckpoint = DateTime.now();
  Duration _savedActiveTime = Duration.zero;
  int _currentIndex = 0;
  double _playbackSpeed = 1;
  bool _isPlaying = false;
  bool _isSessionActive = true;
  bool _showFullHint = false;
  _AnswerState _answerState = _AnswerState.idle;
  ListeningAnswerResult? _answerResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressService =
        widget.progressService ?? ref.read(listeningProgressServiceProvider);
    _assetDataSource =
        widget.assetDataSource ?? ref.read(listeningAssetDataSourceProvider);
    _audioController = widget.audioController ?? JustAudioListeningController();
    _exerciseFuture = _initializeExercise();
    _playingSubscription = _audioController.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isSessionActive) return;
      setState(() {});
      if (DateTime.now().difference(_lastActiveCheckpoint) >=
          const Duration(seconds: 30)) {
        unawaited(_checkpointActiveTime());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeTimer?.cancel();
    _playingSubscription?.cancel();
    unawaited(_checkpointActiveTime());
    unawaited(_audioController.dispose());
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastActiveCheckpoint = DateTime.now();
      _isSessionActive = true;
      return;
    }
    if (_isSessionActive) {
      unawaited(_checkpointActiveTime());
      _isSessionActive = false;
    }
  }

  Future<ListeningExercise> _initializeExercise() async {
    final exercise =
        widget.initialExercise ??
        await _assetDataSource.loadLesson(
          courseIndexAsset: widget.courseIndexAsset,
          lessonId: widget.lessonId,
        );
    final progress = await _progressService.startLesson(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      totalChallenges: exercise.challenges.length,
    );
    _savedActiveTime = await _progressService.activeTimeToday();
    _currentIndex = (progress.currentChallengePosition - 1).clamp(
      0,
      exercise.challenges.length - 1,
    );
    _answerController.text = exercise.challenges[_currentIndex].defaultInput;
    return exercise;
  }

  Future<void> _checkpointActiveTime() async {
    if (!_isSessionActive) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastActiveCheckpoint);
    if (elapsed < const Duration(milliseconds: 250)) return;
    _lastActiveCheckpoint = now;
    _savedActiveTime += elapsed;
    await _progressService.addActiveTime(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      duration: elapsed,
      now: now,
    );
  }

  Duration get _visibleActiveTime =>
      _savedActiveTime +
      (_isSessionActive
          ? DateTime.now().difference(_lastActiveCheckpoint)
          : Duration.zero);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bannerHeight = screenHeight / 3;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFE7EEF9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('listening-exercise-screen'),
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEAF6FF),
                      Color(0xFFF9FCFF),
                      Color(0xFFEAF3FF),
                    ],
                    stops: [0, .56, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bannerHeight,
              child: Image.asset(
                'assets/images/practice_listen/banner_header_all_course.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned(
              top: bannerHeight - 54,
              left: 0,
              right: 0,
              height: 56,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00F9FCFF), Color(0xFFF9FCFF)],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: FutureBuilder<ListeningExercise>(
                future: _exerciseFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return _ExerciseLoadError(
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  }
                  return _buildExercise(context, snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercise(BuildContext context, ListeningExercise exercise) {
    final challenge = exercise.challenges[_currentIndex];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            children: [
              _ExerciseHeader(
                lessonName: exercise.name,
                activeTime: _visibleActiveTime,
                onBack: () => Navigator.of(context).maybePop(),
                onClose: () => Navigator.of(context).maybePop(),
                onMore: _showOptions,
              ),
              const SizedBox(height: 24),
              _PlaybackNavigation(
                isPlaying: _isPlaying,
                speed: _playbackSpeed,
                current: _currentIndex + 1,
                total: exercise.challenges.length,
                onPlay: () => _toggleAudio(challenge),
                onSpeed: _cyclePlaybackSpeed,
                onPrevious: _currentIndex == 0
                    ? null
                    : () => _moveTo(exercise, _currentIndex - 1),
                onNext: _currentIndex == exercise.challenges.length - 1
                    ? null
                    : () => _moveTo(exercise, _currentIndex + 1),
              ),
              const SizedBox(height: 14),
              _AnswerArea(
                controller: _answerController,
                focusNode: _answerFocusNode,
                state: _answerState,
                challenge: challenge,
                translation: exercise.translations[challenge.id],
                onListen: () => _playAudio(challenge, restart: true),
                onChanged: (_) {
                  if (_answerState == _AnswerState.incorrect) {
                    setState(() {
                      _answerState = _AnswerState.idle;
                      _answerResult = null;
                    });
                  }
                },
              ),
              if (_answerState == _AnswerState.incorrect &&
                  _answerResult != null) ...[
                const SizedBox(height: 10),
                _CorrectionHint(
                  result: _answerResult!,
                  translation: exercise.translations[challenge.id],
                  revealAll: _showFullHint,
                  onReveal: () =>
                      setState(() => _showFullHint = !_showFullHint),
                ),
              ],
              const SizedBox(height: 14),
              _ExerciseActions(
                isCorrect: _answerState == _AnswerState.correct,
                onLeading: _answerState == _AnswerState.correct
                    ? _redo
                    : () => _skip(exercise),
                onListenAgain: () => _playAudio(challenge, restart: true),
                onPrimary: _answerState == _AnswerState.correct
                    ? () => _nextAfterCorrect(exercise)
                    : () => _checkAnswer(exercise),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAudio(ListeningChallenge challenge) async {
    if (_audioController.isPlaying) {
      await _audioController.pause();
    } else {
      await _playAudio(challenge, restart: false);
    }
  }

  Future<void> _playAudio(
    ListeningChallenge challenge, {
    required bool restart,
  }) async {
    try {
      await _audioController.playUrl(
        challenge.audioUrl,
        speed: _playbackSpeed,
        restart: restart,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Không thể phát audio lúc này.')),
        );
    }
  }

  void _cyclePlaybackSpeed() {
    const speeds = [.75, 1.0, 1.25, 1.5];
    final current = speeds.indexOf(_playbackSpeed);
    setState(() => _playbackSpeed = speeds[(current + 1) % speeds.length]);
  }

  Future<void> _checkAnswer(ListeningExercise exercise) async {
    final challenge = exercise.challenges[_currentIndex];
    final answer = _answerController.text;
    if (answer.trim().isEmpty) {
      _answerFocusNode.requestFocus();
      return;
    }
    final result = _answerChecker.check(answer, challenge);
    await _progressService.saveAttempt(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      challengeId: challenge.id,
      position: challenge.position,
      totalChallenges: exercise.challenges.length,
      answer: answer,
      isCorrect: result.isCorrect,
    );
    if (!mounted) return;
    setState(() {
      _answerResult = result;
      _answerState = result.isCorrect
          ? _AnswerState.correct
          : _AnswerState.incorrect;
      _showFullHint = false;
    });
  }

  Future<void> _skip(ListeningExercise exercise) async {
    final challenge = exercise.challenges[_currentIndex];
    await _progressService.saveAttempt(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      challengeId: challenge.id,
      position: challenge.position,
      totalChallenges: exercise.challenges.length,
      answer: _answerController.text,
      isCorrect: false,
      isSkipped: true,
    );
    if (!mounted) return;
    if (_currentIndex == exercise.challenges.length - 1) {
      Navigator.of(context).pop(true);
    } else {
      await _moveTo(exercise, _currentIndex + 1);
    }
  }

  Future<void> _nextAfterCorrect(ListeningExercise exercise) async {
    if (_currentIndex == exercise.challenges.length - 1) {
      await _checkpointActiveTime();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      await _moveTo(exercise, _currentIndex + 1);
    }
  }

  Future<void> _moveTo(ListeningExercise exercise, int index) async {
    await _audioController.pause();
    await _progressService.updateCurrentPosition(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      position: exercise.challenges[index].position,
    );
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _answerState = _AnswerState.idle;
      _answerResult = null;
      _showFullHint = false;
      _answerController.text = exercise.challenges[index].defaultInput;
    });
    _answerFocusNode.requestFocus();
  }

  void _redo() {
    setState(() {
      _answerState = _AnswerState.idle;
      _answerResult = null;
      _showFullHint = false;
      _answerController.clear();
    });
    _answerFocusNode.requestFocus();
  }

  Future<void> _showOptions() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tốc độ phát',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final speed in const [.75, 1.0, 1.25, 1.5])
                    ChoiceChip(
                      label: Text('${speed}x'),
                      selected: speed == _playbackSpeed,
                      onSelected: (_) {
                        setState(() => _playbackSpeed = speed);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AnswerState { idle, incorrect, correct }

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.lessonName,
    required this.activeTime,
    required this.onBack,
    required this.onClose,
    required this.onMore,
  });

  final String lessonName;
  final Duration activeTime;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(90, 12, 90, 0),
        child: Column(
          children: [
            const Text(
              'LISTEN & TYPE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.1,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              lessonName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 25,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: Color(0xFF6681AC),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Active time today: ${_formatActiveTime(activeTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6681AC),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Positioned(
        left: 0,
        child: _HeaderSquareButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
      ),
      Positioned(
        right: 48,
        child: _HeaderSquareButton(
          icon: Icons.more_horiz_rounded,
          onTap: onMore,
        ),
      ),
      Positioned(
        right: 0,
        child: _HeaderSquareButton(icon: Icons.close_rounded, onTap: onClose),
      ),
    ],
  );
}

class _HeaderSquareButton extends StatelessWidget {
  const _HeaderSquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A2E72B8),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: AppColors.primary, size: 22),
    ),
  );
}

class _PlaybackNavigation extends StatelessWidget {
  const _PlaybackNavigation({
    required this.isPlaying,
    required this.speed,
    required this.current,
    required this.total,
    required this.onPlay,
    required this.onSpeed,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isPlaying;
  final double speed;
  final int current;
  final int total;
  final VoidCallback onPlay;
  final VoidCallback onSpeed;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 98,
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x142E72B8),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _CompactControl(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: onPlay,
                  highlighted: true,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: onSpeed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${speed}x'.replaceFirst('.0', ''),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 112,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x162E72B8),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _PagerArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrevious,
                ),
                Expanded(
                  child: Text(
                    '$current / $total',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _PagerArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PagerArrow extends StatelessWidget {
  const _PagerArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 28, height: 38),
    style: IconButton.styleFrom(
      minimumSize: const Size(28, 38),
      maximumSize: const Size(28, 38),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      disabledForegroundColor: AppColors.textMuted.withValues(alpha: .4),
    ),
    icon: Icon(icon, color: AppColors.primary, size: 18),
  );
}

class _CompactControl extends StatelessWidget {
  const _CompactControl({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    width: 45,
    height: 32,
    decoration: BoxDecoration(
      color: highlighted ? AppColors.surfaceBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
    ),
    child: IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: AppColors.primary, size: 24),
    ),
  );
}

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.challenge,
    required this.translation,
    required this.onListen,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final _AnswerState state;
  final ListeningChallenge challenge;
  final String? translation;
  final VoidCallback onListen;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A2E72B8),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const _RoundSymbol(icon: Icons.edit_rounded),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Type what you hear...',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _RoundSymbol(icon: Icons.graphic_eq_rounded, onTap: onListen),
          ],
        ),
        const SizedBox(height: 12),
        if (state == _AnswerState.correct)
          _CorrectAnswer(content: challenge.content, translation: translation)
        else ...[
          TextField(
            key: const ValueKey('listening-answer-field'),
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLength: 200,
            maxLines: 5,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Start typing here...',
              hintStyle: const TextStyle(
                color: Color(0xFF98A6BE),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .72),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: state == _AnswerState.incorrect
                      ? AppColors.orange
                      : const Color(0xFFD5DFEF),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: state == _AnswerState.incorrect
                      ? AppColors.orange
                      : AppColors.primary,
                  width: 1.3,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          if (state == _AnswerState.incorrect)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orange,
                    size: 21,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Something seems missing or incorrect.',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Listen carefully and type exactly what you hear.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5873A0),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}

class _RoundSymbol extends StatelessWidget {
  const _RoundSymbol({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceBlue,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
    ),
  );
}

class _CorrectAnswer extends StatelessWidget {
  const _CorrectAnswer({required this.content, required this.translation});

  final String content;
  final String? translation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FFF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MiniPill(label: '+ Note'),
                SizedBox(width: 8),
                _MiniPill(label: 'IPA'),
              ],
            ),
          ],
        ),
      ),
      if (translation?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        Text(
          translation!,
          style: const TextStyle(
            color: Color(0xFF6681AC),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.green.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF15933C),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _CorrectionHint extends StatelessWidget {
  const _CorrectionHint({
    required this.result,
    required this.translation,
    required this.revealAll,
    required this.onReveal,
  });

  final ListeningAnswerResult result;
  final String? translation;
  final bool revealAll;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final words = result.acceptedAnswer.split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];
    for (var index = 0; index < words.length; index++) {
      final isMatched = index < result.matchingPrefixLength;
      final isNext = index == result.matchingPrefixLength;
      final visible = revealAll || isMatched || isNext;
      final text = visible ? words[index] : '*' * words[index].length;
      spans.add(
        TextSpan(
          text: '${index == 0 ? '' : ' '}$text',
          style: TextStyle(
            color: isNext && !revealAll
                ? AppColors.orange
                : AppColors.primaryDark,
            fontWeight: isNext && !revealAll
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F0FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142E72B8),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: spans),
                  style: const TextStyle(fontSize: 14, height: 1.2),
                ),
                if (translation?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    translation!,
                    style: const TextStyle(
                      color: Color(0xFF7890B9),
                      fontSize: 11,
                      height: 1.2,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onReveal,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 52,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE8F8)),
                ),
                child: Icon(
                  revealAll
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseActions extends StatelessWidget {
  const _ExerciseActions({
    required this.isCorrect,
    required this.onLeading,
    required this.onListenAgain,
    required this.onPrimary,
  });

  final bool isCorrect;
  final VoidCallback onLeading;
  final VoidCallback onListenAgain;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 4,
        child: _ActionButton(
          iconAsset: isCorrect
              ? 'assets/svgs/listen_again.svg'
              : 'assets/svgs/skip_listen.svg',
          label: isCorrect ? 'Redo' : 'Skip',
          onTap: onLeading,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 5,
        child: _ActionButton(
          iconAsset: 'assets/svgs/listen_again.svg',
          label: 'Listen again',
          onTap: onListenAgain,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 5,
        child: _ActionButton(
          iconAsset: isCorrect
              ? 'assets/svgs/next_listen.svg'
              : 'assets/svgs/check.svg',
          label: isCorrect ? 'Next' : 'Check',
          onTap: onPrimary,
          primary: true,
          success: isCorrect,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.success = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final gradient = primary
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: success
                ? const [Color(0xFF62DC70), Color(0xFF16BE43)]
                : const [Color(0xFF4A95FF), Color(0xFF0068F5)],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .95),
              const Color(0xFFF7FAFF).withValues(alpha: .9),
            ],
          );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18235B95),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    primary ? Colors.white : AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: primary ? Colors.white : AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

class _ExerciseLoadError extends StatelessWidget {
  const _ExerciseLoadError({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.headphones_rounded,
            size: 54,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          const Text(
            'Không thể mở bài luyện nghe này.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onBack, child: const Text('Quay lại')),
        ],
      ),
    ),
  );
}

String _formatActiveTime(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 1) return '< 1 minute';
  return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
}
