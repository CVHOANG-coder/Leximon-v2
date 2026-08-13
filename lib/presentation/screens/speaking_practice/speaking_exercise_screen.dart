import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/listening_asset_data_source.dart';
import '../../../data/models/listening_exercise.dart';
import '../../../data/services/speaking_answer_checker.dart';
import '../../../data/services/speaking_progress_service.dart';
import '../../../shared/providers/app_providers.dart';

abstract class SpeakingRecorderController {
  Future<bool> hasPermission();
  Future<void> start(String path);
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class DeviceSpeakingRecorder implements SpeakingRecorderController {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) => _recorder.start(
    const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    ),
    path: path,
  );

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}

abstract class SpeakingRecognizerController {
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  });
  Future<void> listen(ValueChanged<String> onResult);
  Future<void> stop();
  Future<void> cancel();
}

class DeviceSpeakingRecognizer implements SpeakingRecognizerController {
  final SpeechToText _speech = SpeechToText();

  @override
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) => _speech.initialize(
    onStatus: onStatus,
    onError: (error) => onError(error.errorMsg),
  );

  @override
  Future<void> listen(ValueChanged<String> onResult) => _speech.listen(
    listenOptions: SpeechListenOptions(
      localeId: 'en_US',
      partialResults: true,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 4),
      listenMode: ListenMode.dictation,
    ),
    onResult: (result) => onResult(result.recognizedWords),
  );

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

abstract class SpeakingPlaybackController {
  Future<void> playUrl(String url);
  Future<void> playFile(String path);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioSpeakingPlayback implements SpeakingPlaybackController {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playUrl(String url) async {
    if (url.isEmpty) return;
    await _player.setUrl(url);
    await _player.play();
  }

  @override
  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class SpeakingExerciseScreen extends ConsumerStatefulWidget {
  const SpeakingExerciseScreen({
    required this.courseId,
    required this.courseIndexAsset,
    required this.lessonId,
    this.initialExercise,
    this.progressService,
    this.assetDataSource,
    this.recorder,
    this.recognizer,
    this.playback,
    this.recordingPathFactory,
    super.key,
  });

  final int courseId;
  final String courseIndexAsset;
  final int lessonId;
  final ListeningExercise? initialExercise;
  final SpeakingProgressService? progressService;
  final ListeningAssetDataSource? assetDataSource;
  final SpeakingRecorderController? recorder;
  final SpeakingRecognizerController? recognizer;
  final SpeakingPlaybackController? playback;
  final Future<String> Function()? recordingPathFactory;

  @override
  ConsumerState<SpeakingExerciseScreen> createState() =>
      _SpeakingExerciseScreenState();
}

class _SpeakingExerciseScreenState
    extends ConsumerState<SpeakingExerciseScreen> {
  static const _checker = SpeakingAnswerChecker();

  late final SpeakingProgressService _progressService;
  late final ListeningAssetDataSource _assetDataSource;
  late final SpeakingRecorderController _recorder;
  late final SpeakingRecognizerController _recognizer;
  late final SpeakingPlaybackController _playback;
  late final Future<ListeningExercise> _exerciseFuture;
  ListeningExercise? _exercise;
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isFinishingRecording = false;
  bool _recognizerReady = false;
  String _transcript = '';
  String? _recordingPath;
  String? _error;
  SpeakingAssessment? _assessment;

  @override
  void initState() {
    super.initState();
    _progressService =
        widget.progressService ?? ref.read(speakingProgressServiceProvider);
    _assetDataSource =
        widget.assetDataSource ?? ref.read(listeningAssetDataSourceProvider);
    _recorder = widget.recorder ?? DeviceSpeakingRecorder();
    _recognizer = widget.recognizer ?? DeviceSpeakingRecognizer();
    _playback = widget.playback ?? JustAudioSpeakingPlayback();
    _exerciseFuture = _initialize();
  }

  Future<ListeningExercise> _initialize() async {
    final exercise =
        widget.initialExercise ??
        await _assetDataSource.loadLesson(
          courseIndexAsset: widget.courseIndexAsset,
          lessonId: widget.lessonId,
        );
    if (exercise.challenges.isEmpty) {
      throw const FormatException('Bài học không có câu để luyện nói.');
    }
    final progress = await _progressService.startLesson(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      totalSentences: exercise.challenges.length,
    );
    _exercise = exercise;
    _currentIndex = (progress.currentSentencePosition - 1).clamp(
      0,
      exercise.challenges.length - 1,
    );
    return exercise;
  }

  @override
  void dispose() {
    unawaited(_recognizer.cancel());
    unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    unawaited(_playback.dispose());
    super.dispose();
  }

  ListeningChallenge get _sentence => _exercise!.challenges[_currentIndex];

  Future<void> _playSample() async {
    final url = _sentence.audioUrl.isNotEmpty
        ? _sentence.audioUrl
        : _exercise!.audioUrl;
    try {
      await _playback.playUrl(url);
    } on Object {
      if (mounted) setState(() => _error = 'Không thể phát audio mẫu.');
    }
  }

  Future<void> _toggleRecording() async {
    if (_assessment != null) return;
    if (_isRecording) {
      await _finishRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    await _playback.stop();
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (mounted) {
        setState(() => _error = 'Hãy cấp quyền microphone để luyện nói.');
      }
      return;
    }
    _recognizerReady = await _recognizer.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isRecording) {
          unawaited(_finishRecording(stopRecognizer: false));
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _error = 'Nhận dạng giọng nói: $message');
      },
    );
    if (!_recognizerReady) {
      if (mounted) {
        setState(
          () => _error = 'Thiết bị chưa hỗ trợ nhận dạng giọng nói tiếng Anh.',
        );
      }
      return;
    }

    try {
      final path =
          await (widget.recordingPathFactory ?? _createRecordingPath)();
      await _recorder.start(path);
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _transcript = '';
        _recordingPath = null;
        _assessment = null;
        _error = null;
      });
      await _recognizer.listen((value) {
        if (mounted) setState(() => _transcript = value);
      });
    } on Object {
      await _recorder.cancel();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _error = 'Không thể bắt đầu ghi âm. Hãy thử lại.';
        });
      }
    }
  }

  Future<String> _createRecordingPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/leximon-speaking-'
        '${widget.courseId}-${widget.lessonId}-${_sentence.id}-'
        '${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _finishRecording({bool stopRecognizer = true}) async {
    if (_isFinishingRecording || !_isRecording) return;
    _isFinishingRecording = true;
    try {
      if (stopRecognizer) await _recognizer.stop();
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingPath = path;
        if (_transcript.trim().isEmpty) {
          _error = 'Chưa nhận ra giọng nói. Bạn có thể ghi âm lại.';
        }
      });
    } finally {
      _isFinishingRecording = false;
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null) return;
    try {
      await _playback.playFile(path);
    } on Object {
      if (mounted) setState(() => _error = 'Không thể phát bản ghi âm.');
    }
  }

  Future<void> _check() async {
    if (_isRecording || _transcript.trim().isEmpty || _assessment != null) {
      return;
    }
    final result = _checker.check(
      expected: _sentence.content,
      transcript: _transcript,
    );
    await _progressService.saveAssessment(
      courseId: widget.courseId,
      lessonId: widget.lessonId,
      challengeId: _sentence.id,
      position: _sentence.position,
      totalSentences: _exercise!.challenges.length,
      transcript: _transcript,
      accuracyPercent: result.accuracyPercent,
      isCorrect: result.isCorrect,
    );
    if (mounted) setState(() => _assessment = result);
  }

  void _next() {
    final exercise = _exercise!;
    if (_currentIndex == exercise.challenges.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _currentIndex++;
      _isRecording = false;
      _transcript = '';
      _recordingPath = null;
      _assessment = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const ValueKey('speaking-exercise-screen'),
        backgroundColor: const Color(0xFFF3F8FF),
        body: FutureBuilder<ListeningExercise>(
          future: _exerciseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _SpeakingLoadError(
                onBack: () => Navigator.of(context).maybePop(),
              );
            }
            return SafeArea(
              child: Column(
                children: [
                  _SpeakingHeader(
                    title: snapshot.data!.name,
                    current: _currentIndex + 1,
                    total: snapshot.data!.challenges.length,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                      child: _SpeakingSentenceCard(
                        sentence: _sentence.content,
                        isRecording: _isRecording,
                        transcript: _transcript,
                        recordingReady: _recordingPath != null,
                        assessment: _assessment,
                        error: _error,
                        onPlaySample: _playSample,
                        onRecord: _toggleRecording,
                        onPlayRecording: _playRecording,
                        onCheck: _check,
                        onNext: _next,
                        isLast:
                            _currentIndex ==
                            snapshot.data!.challenges.length - 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpeakingHeader extends StatelessWidget {
  const _SpeakingHeader({
    required this.title,
    required this.current,
    required this.total,
    required this.onBack,
  });

  final String title;
  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$current/$total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 7,
            backgroundColor: const Color(0xFFDDE9F8),
            color: const Color(0xFFEE5C8A),
          ),
        ),
      ],
    ),
  );
}

class _SpeakingSentenceCard extends StatelessWidget {
  const _SpeakingSentenceCard({
    required this.sentence,
    required this.isRecording,
    required this.transcript,
    required this.recordingReady,
    required this.assessment,
    required this.error,
    required this.onPlaySample,
    required this.onRecord,
    required this.onPlayRecording,
    required this.onCheck,
    required this.onNext,
    required this.isLast,
  });

  final String sentence;
  final bool isRecording;
  final String transcript;
  final bool recordingReady;
  final SpeakingAssessment? assessment;
  final String? error;
  final Future<void> Function() onPlaySample;
  final Future<void> Function() onRecord;
  final Future<void> Function() onPlayRecording;
  final Future<void> Function() onCheck;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFDCE8F7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14214B82),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NGHE VÀ NÓI LẠI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7890AD),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          sentence,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 23,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            key: const ValueKey('speaking-sample-audio'),
            onPressed: onPlaySample,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Nghe câu mẫu'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2774F5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: InkWell(
            key: const ValueKey('speaking-sentence-record-button'),
            onTap: assessment == null ? onRecord : null,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isRecording ? 104 : 94,
              height: isRecording ? 104 : 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? const Color(0xFFFF4F6D)
                    : const Color(0xFFEE5C8A),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4DEE5C8A),
                    blurRadius: 24,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isRecording
              ? 'Đang ghi âm… nhấn để dừng'
              : recordingReady
              ? 'Đã ghi âm — nghe lại hoặc kiểm tra'
              : 'Nhấn microphone và nói cả câu',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7A8DA7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE34F55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (recordingReady && !isRecording) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: const ValueKey('speaking-recording-playback'),
            onPressed: onPlayRecording,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Nghe lại giọng của tôi'),
          ),
        ],
        if (assessment == null && transcript.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('speaking-check-button'),
            onPressed: onCheck,
            icon: const Icon(Icons.check_rounded),
            label: const Text('CHECK'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF20BE78),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
        if (assessment != null) ...[
          const SizedBox(height: 22),
          _SpeakingResult(assessment: assessment!),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('speaking-next-button'),
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2774F5),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(isLast ? 'HOÀN THÀNH' : 'CÂU TIẾP THEO'),
          ),
        ],
      ],
    ),
  );
}

class _SpeakingResult extends StatelessWidget {
  const _SpeakingResult({required this.assessment});

  final SpeakingAssessment assessment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: assessment.isCorrect
          ? const Color(0xFFEAFBF3)
          : const Color(0xFFFFF6EA),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          assessment.isCorrect
              ? 'Rất tốt! ${assessment.accuracyPercent}%'
              : 'Cần luyện thêm • ${assessment.accuracyPercent}%',
          style: TextStyle(
            color: assessment.isCorrect
                ? const Color(0xFF159A62)
                : const Color(0xFFD47613),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: [
            for (final word in assessment.words) _ResultWord(word: word),
          ],
        ),
        const SizedBox(height: 13),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 5,
          children: [
            _ResultLegend(color: Color(0xFF18A866), label: 'Đúng'),
            _ResultLegend(color: Color(0xFFE14E58), label: 'Sai/thừa'),
            _ResultLegend(color: Color(0xFFE69A20), label: 'Thiếu'),
          ],
        ),
      ],
    ),
  );
}

class _ResultWord extends StatelessWidget {
  const _ResultWord({required this.word});

  final SpeakingWordResult word;

  @override
  Widget build(BuildContext context) {
    final color = switch (word.status) {
      SpeakingWordStatus.correct => const Color(0xFF18A866),
      SpeakingWordStatus.incorrect ||
      SpeakingWordStatus.extra => const Color(0xFFE14E58),
      SpeakingWordStatus.missing => const Color(0xFFE69A20),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        word.text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ResultLegend extends StatelessWidget {
  const _ResultLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF74849A),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SpeakingLoadError extends StatelessWidget {
  const _SpeakingLoadError({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_off_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
          const Text('Không thể tải bài luyện nói'),
          TextButton(onPressed: onBack, child: const Text('Quay lại')),
        ],
      ),
    ),
  );
}
