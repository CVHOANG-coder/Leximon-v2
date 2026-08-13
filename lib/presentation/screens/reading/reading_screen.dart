import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/reading_story.dart';
import '../../../data/services/reading_progress_service.dart';
import '../../../shared/providers/app_providers.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(readingStoriesProvider);
    final storyProgress =
        ref.watch(readingCardProgressProvider).valueOrNull ??
        const <int, bool>{};
    final storyCount = stories.valueOrNull?.length ?? 0;
    return Scaffold(
      key: const ValueKey('reading-screen'),
      body: Stack(
        children: [
          const Positioned.fill(child: _ReadingBackdrop()),
          Column(
            children: [
              _ReadingHeader(storyCount: storyCount),
              Expanded(
                child: stories.when(
                  loading: () => const _ReadingLoading(),
                  error: (error, stackTrace) => _ReadingError(
                    onRetry: () => ref.invalidate(readingStoriesProvider),
                  ),
                  data: (items) => _ReadingContent(
                    stories: items,
                    storyProgress: storyProgress,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadingContent extends ConsumerStatefulWidget {
  const _ReadingContent({required this.stories, required this.storyProgress});

  final List<ReadingStory> stories;
  final Map<int, bool> storyProgress;

  @override
  ConsumerState<_ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends ConsumerState<_ReadingContent> {
  final Set<int> _bookmarkedStoryIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const ValueKey('reading-scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _ReadingIntro()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              mainAxisExtent: 258,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final story = widget.stories[index];
              return _StoryCard(
                key: ValueKey('reading-story-${story.id}'),
                story: story,
                viewed: widget.storyProgress.containsKey(story.id),
                completed: widget.storyProgress[story.id] == true,
                bookmarked: _bookmarkedStoryIds.contains(story.id),
                onBookmark: () => setState(() {
                  if (!_bookmarkedStoryIds.add(story.id)) {
                    _bookmarkedStoryIds.remove(story.id);
                  }
                }),
                onTap: () => _openStory(story),
              );
            }, childCount: widget.stories.length),
          ),
        ),
      ],
    );
  }

  Future<void> _openStory(ReadingStory story) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ReadingDetailScreen(story: story)),
    );
    if (!mounted) return;
    ref
      ..invalidate(readingCardProgressProvider)
      ..invalidate(challengeDashboardProvider);
  }
}

class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({required this.storyCount});

  final int storyCount;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: safeTop + 70,
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 9,
            left: 14,
            child: _ReadingHeaderButton(
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: safeTop + 7,
            left: 64,
            right: 18,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCFE8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF176EE8),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 31,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$storyCount bài đọc',
                        key: const ValueKey('reading-story-count'),
                        style: const TextStyle(
                          color: Color(0xFF435D91),
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _ReadingHeaderButton extends StatelessWidget {
  const _ReadingHeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .76),
    shape: const CircleBorder(),
    child: InkWell(
      key: const ValueKey('reading-back-button'),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_rounded,
          color: AppColors.primaryDark,
          size: 21,
        ),
      ),
    ),
  );
}

class _ReadingIntro extends StatelessWidget {
  const _ReadingIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/reading/star_icon.png',
            key: const ValueKey('reading-star-icon'),
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            cacheWidth: 160,
            semanticLabel: 'Ngôi sao Reading',
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn một câu chuyện',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 25,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chọn một bài đọc ngắn và bắt đầu học',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.3,
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

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.viewed,
    required this.completed,
    required this.bookmarked,
    required this.onBookmark,
    required this.onTap,
    super.key,
  });

  final ReadingStory story;
  final bool viewed;
  final bool completed;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  static const _accentColors = <Color>[
    Color(0xFF61A8FF),
    Color(0xFF66D187),
    Color(0xFFB995FF),
    Color(0xFFFF8EBD),
    Color(0xFFFFC857),
    Color(0xFF43C7A5),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[story.id % _accentColors.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F336592),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: AspectRatio(
                          aspectRatio: 1.28,
                          child: Image.asset(
                            story.imageAsset,
                            fit: BoxFit.cover,
                            cacheWidth: 420,
                          ),
                        ),
                      ),
                      if (viewed)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            key: ValueKey(
                              completed
                                  ? 'reading-completed-${story.id}'
                                  : 'reading-viewed-${story.id}',
                            ),
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: completed
                                  ? const Color(0xFF19B96E)
                                  : const Color(0xFF287BE8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33071A3D),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              completed
                                  ? Icons.check_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Dễ',
                          style: TextStyle(
                            color: Color(0xFF2BB678),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkResponse(
                        key: ValueKey('reading-bookmark-${story.id}'),
                        onTap: onBookmark,
                        radius: 22,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1C294E7B),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            bookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReadingDetailScreen extends StatefulWidget {
  const ReadingDetailScreen({required this.story, super.key});

  final ReadingStory story;

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  bool _showTranslation = false;
  final ScrollController _scrollController = ScrollController();
  ReadingProgressService? _progressService;
  ProviderContainer? _providerContainer;
  Future<void>? _openProgressFuture;
  bool _didRecordOpen = false;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_recordScrollProgress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRecordOpen) return;
    _didRecordOpen = true;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      _providerContainer = container;
      _progressService = container.read(readingProgressServiceProvider);
      _openProgressFuture = _progressService!.recordOpened(widget.story.id);
      unawaited(_openProgressFuture);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recordScrollProgress();
      });
    } on Object {
      // Standalone previews/tests can render without a ProviderScope.
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_recordScrollProgress)
      ..dispose();
    super.dispose();
  }

  void _recordScrollProgress() {
    if (_didComplete || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final percent = position.maxScrollExtent <= 0
        ? 100
        : (position.pixels / position.maxScrollExtent * 100).round();
    if (percent < ReadingProgressService.completionThreshold) return;
    _didComplete = true;
    unawaited(_completeReading(percent));
  }

  Future<void> _completeReading(int percent) async {
    await _openProgressFuture;
    await _progressService?.recordScrollProgress(widget.story.id, percent);
    _providerContainer?.invalidate(challengeDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final title = _showTranslation ? story.title : story.originalTitle;
    final content = _showTranslation ? story.content : story.originalContent;
    return Scaffold(
      key: const ValueKey('reading-detail-screen'),
      backgroundColor: const Color(0xFFE7F5FF),
      body: Stack(
        children: [
          const Positioned.fill(child: _ReadingDetailBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ReadingHeaderButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            title,
                            key: ValueKey(
                              'reading-detail-title-$_showTranslation',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 23,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ReadingDetailActionButton(
                        tooltip: _showTranslation
                            ? 'Xem bản tiếng Anh'
                            : 'Xem bản dịch',
                        onTap: story.hasTranslation
                            ? () => setState(
                                () => _showTranslation = !_showTranslation,
                              )
                            : () {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    key: const ValueKey('reading-detail-scroll'),
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 26, 18, 48),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .96),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F2B6AA3),
                                  blurRadius: 30,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _ReadingStoryText(
                                key: ValueKey(
                                  'reading-detail-content-$_showTranslation',
                                ),
                                content: content,
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
        ],
      ),
    );
  }
}

class _ReadingStoryText extends StatelessWidget {
  const _ReadingStoryText({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final style = TextStyle(
      color: const Color(0xFF07143D),
      fontSize: compact ? 17 : 19,
      height: compact ? 1.75 : 1.85,
      fontWeight: FontWeight.w500,
      letterSpacing: .05,
    );

    return SelectableText.rich(
      TextSpan(text: content, style: style),
      key: const ValueKey('reading-story-content'),
    );
  }
}

class _ReadingDetailBackdrop extends StatelessWidget {
  const _ReadingDetailBackdrop();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bg_reading.png',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    cacheWidth: 1200,
  );
}

class _ReadingDetailActionButton extends StatelessWidget {
  const _ReadingDetailActionButton({
    required this.tooltip,
    required this.onTap,
  });

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .76),
    shape: const CircleBorder(),
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        key: const ValueKey('reading-translate-action'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.translate_rounded,
            color: AppColors.primaryDark,
            size: 21,
          ),
        ),
      ),
    ),
  );
}

class _ReadingBackdrop extends StatelessWidget {
  const _ReadingBackdrop();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bg_reading_screen.png',
    fit: BoxFit.cover,
    alignment: Alignment.topCenter,
    cacheWidth: 1200,
  );
}

class _ReadingLoading extends StatelessWidget {
  const _ReadingLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ReadingError extends StatelessWidget {
  const _ReadingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa thể mở danh sách bài đọc',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
