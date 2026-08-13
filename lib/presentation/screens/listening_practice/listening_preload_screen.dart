import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/listening_lesson_preloader.dart';
import '../../../shared/providers/app_providers.dart';
import 'listening_exercise_screen.dart';

class ListeningPreloadScreen extends ConsumerStatefulWidget {
  const ListeningPreloadScreen({
    required this.courseId,
    required this.courseIndexAsset,
    required this.lessonId,
    required this.lessonName,
    this.preloader,
    super.key,
  });

  final int courseId;
  final String courseIndexAsset;
  final int lessonId;
  final String lessonName;
  final ListeningLessonPreloader? preloader;

  @override
  ConsumerState<ListeningPreloadScreen> createState() =>
      _ListeningPreloadScreenState();
}

class _ListeningPreloadScreenState
    extends ConsumerState<ListeningPreloadScreen> {
  ListeningPreloadProgress _progress =
      const ListeningPreloadProgress.loadingLesson();
  Object? _error;
  bool _openingExercise = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_preload);
  }

  Future<void> _preload() async {
    if (mounted) {
      setState(() {
        _error = null;
        _openingExercise = false;
        _progress = const ListeningPreloadProgress.loadingLesson();
      });
    }
    final preloader =
        widget.preloader ??
        CachedListeningLessonPreloader(
          assetDataSource: ref.read(listeningAssetDataSourceProvider),
        );
    try {
      final exercise = await preloader.preload(
        courseIndexAsset: widget.courseIndexAsset,
        lessonId: widget.lessonId,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      setState(() => _openingExercise = true);
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ListeningExerciseScreen(
            courseId: widget.courseId,
            courseIndexAsset: widget.courseIndexAsset,
            lessonId: widget.lessonId,
            initialExercise: exercise,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FAFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('listening-preload-screen'),
        backgroundColor: const Color(0xFFF7FAFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/loading/bg_loading.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 720;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 26 : 34,
                      compact ? 20 : 46,
                      compact ? 26 : 34,
                      compact ? 20 : 34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang tải bài nghe',
                          key: const ValueKey('listening-preload-title'),
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: compact ? 31 : 38,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Đang chuẩn bị dữ liệu phần Nghe & Gõ\n'
                          'cho bài “$_visibleLessonName”.',
                          key: const ValueKey('listening-preload-description'),
                          style: TextStyle(
                            color: const Color(0xFF6F88AD),
                            fontSize: compact ? 15 : 17,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              'assets/images/loading/owl_loading.png',
                              key: const ValueKey('listening-preload-owl'),
                              fit: BoxFit.contain,
                              width: mathMin(
                                constraints.maxWidth * .92,
                                compact ? 370 : 440,
                              ),
                            ),
                          ),
                        ),
                        if (error == null)
                          _LoadingDetails(
                            progress: _progress,
                            openingExercise: _openingExercise,
                          )
                        else
                          _LoadingError(onRetry: _preload),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _visibleLessonName => _progress.lessonName.isNotEmpty
      ? _progress.lessonName
      : widget.lessonName;
}

class _LoadingDetails extends StatelessWidget {
  const _LoadingDetails({
    required this.progress,
    required this.openingExercise,
  });

  final ListeningPreloadProgress progress;
  final bool openingExercise;

  @override
  Widget build(BuildContext context) {
    final total = progress.totalAudioCount;
    final loaded = progress.loadedAudioCount;
    final percent = (progress.fraction * 100).round();
    final isLoadingLesson =
        progress.stage == ListeningPreloadStage.loadingLesson;
    final status = openingExercise
        ? 'Đã sẵn sàng!'
        : isLoadingLesson
        ? 'Đang tải nội dung bài học...'
        : total == 0
        ? 'Đang chuẩn bị trình phát...'
        : 'Đang tải audio $loaded/$total...';
    final countLabel = isLoadingLesson
        ? 'Đang đọc dữ liệu bài học'
        : total == 0
        ? 'Bài học không có audio riêng'
        : 'Đã tải $loaded/$total audio';

    return Column(
      key: const ValueKey('listening-preload-progress'),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 17,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFDCE9F9)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress.fraction),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0964FF), Color(0xFF04B7EE)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 48,
              child: Text(
                '$percent%',
                key: const ValueKey('listening-preload-percent'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF0964E9),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          countLabel,
          key: const ValueKey('listening-preload-audio-count'),
          style: const TextStyle(
            color: Color(0xFF59759D),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          status,
          key: const ValueKey('listening-preload-status'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Vui lòng chờ trong giây lát',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7A91B2),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoadingError extends StatelessWidget {
  const _LoadingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('listening-preload-error'),
      children: [
        const Text(
          'Chưa tải đủ audio của bài nghe',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Kiểm tra kết nối mạng rồi thử lại nhé.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7A91B2),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const ValueKey('listening-preload-retry'),
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double mathMin(double first, double second) => first < second ? first : second;
