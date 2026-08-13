import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/reading_story.dart';
import '../../../data/services/reading_progress_service.dart';
import '../../../data/services/reading_vocabulary_service.dart';
import '../../../presentation/widgets/app_bottom_sheet.dart';
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
  ReadingVocabularyService? _vocabularyService;
  ProviderContainer? _providerContainer;
  Future<void>? _openProgressFuture;
  bool _didRecordOpen = false;
  bool _didComplete = false;
  bool _isHandlingWordTap = false;

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
      _vocabularyService = container.read(readingVocabularyServiceProvider);
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

  Future<void> _openWord(String text) async {
    if (_isHandlingWordTap) return;
    final service = _vocabularyService;
    if (service == null) return;
    _isHandlingWordTap = true;
    try {
      final word = await service.findWord(text);
      if (word == null) {
        await _openTranslatedWord(text);
        return;
      }
      if (!mounted) return;
      final isSaved = await service.isSaved(word);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6604193A),
        builder: (_) => _ReadingWordSheet(
          word: word,
          initiallySaved: isSaved,
          onAdd: () async {
            await service.saveWord(word: word, storyId: widget.story.id);
            _providerContainer?.invalidate(readingVocabularyTaskProvider);
          },
        ),
      );
    } finally {
      _isHandlingWordTap = false;
    }
  }

  Future<void> _openTranslatedWord(String text) async {
    final container = _providerContainer;
    if (container == null || !mounted) return;

    // Do not instantiate anything from google_mlkit_translation until the
    // database lookup has failed and the fallback sheet is actually needed.
    final translator = container.read(readingWordTranslatorProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x6604193A),
      builder: (_) => _ReadingTranslatedWordSheet(
        word: text,
        translate: () => translator.translateWord(text),
      ),
    );
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
                                onWordTap: _showTranslation ? null : _openWord,
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

class _ReadingStoryText extends StatefulWidget {
  const _ReadingStoryText({
    required this.content,
    required this.onWordTap,
    super.key,
  });

  final String content;
  final ValueChanged<String>? onWordTap;

  @override
  State<_ReadingStoryText> createState() => _ReadingStoryTextState();
}

class _ReadingStoryTextState extends State<_ReadingStoryText> {
  static final _wordPattern = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*");
  final List<TapGestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(covariant _ReadingStoryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.onWordTap != widget.onWordTap) {
      _rebuildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _rebuildSpans() {
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _wordPattern.allMatches(widget.content)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: widget.content.substring(cursor, match.start)),
        );
      }
      final word = match.group(0)!;
      final onWordTap = widget.onWordTap;
      final recognizer = onWordTap == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onWordTap(word));
      if (recognizer != null) _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: word,
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        ),
      );
      cursor = match.end;
    }
    if (cursor < widget.content.length) {
      spans.add(TextSpan(text: widget.content.substring(cursor)));
    }
    _spans = spans;
  }

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
      TextSpan(children: _spans, style: style),
      key: const ValueKey('reading-story-content'),
    );
  }
}

class _ReadingWordSheet extends StatefulWidget {
  const _ReadingWordSheet({
    required this.word,
    required this.initiallySaved,
    required this.onAdd,
  });

  final WordRow word;
  final bool initiallySaved;
  final Future<void> Function() onAdd;

  @override
  State<_ReadingWordSheet> createState() => _ReadingWordSheetState();
}

class _ReadingWordSheetState extends State<_ReadingWordSheet> {
  late bool _isSaved;
  bool _isSaving = false;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
  }

  Future<void> _save() async {
    if (_isSaved || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onAdd();
      if (mounted) setState(() => _isSaved = true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _speak() {
    _hasSpoken = true;
    unawaited(TextToSpeechService.instance.speakLatest(widget.word.writing));
  }

  @override
  void dispose() {
    if (_hasSpoken) unawaited(TextToSpeechService.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pronunciation =
        widget.word.transliteration ?? widget.word.transcription;
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBottomSheetTitle(
            title: 'Từ trong bài đọc',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD6E5FA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.word.writing,
                        key: const ValueKey('reading-word-writing'),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const ValueKey('reading-word-speaker-button'),
                      onPressed: _speak,
                      tooltip: 'Phát âm từ ${widget.word.writing}',
                      icon: const Icon(Icons.volume_up_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF2778D7),
                        backgroundColor: const Color(0xFFE2EFFF),
                      ),
                    ),
                  ],
                ),
                if (pronunciation != null && pronunciation.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      pronunciation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.word.translation,
                  key: const ValueKey('reading-word-meaning'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('reading-add-word-button'),
              onPressed: _isSaved || _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isSaved
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                    ),
              label: Text(
                _isSaved ? 'Đã thêm vào danh sách học' : 'Thêm từ học',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingTranslatedWordSheet extends StatefulWidget {
  const _ReadingTranslatedWordSheet({
    required this.word,
    required this.translate,
  });

  final String word;
  final Future<String> Function() translate;

  @override
  State<_ReadingTranslatedWordSheet> createState() =>
      _ReadingTranslatedWordSheetState();
}

class _ReadingTranslatedWordSheetState
    extends State<_ReadingTranslatedWordSheet> {
  Future<String>? _translation;

  @override
  void initState() {
    super.initState();
    // Let the bottom-sheet animation paint its first frame before starting
    // model checks/downloads and constructing the native translator.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final translation = Future<String>.sync(widget.translate);
      setState(() {
        _translation = translation;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBottomSheetTitle(
            title: 'Dịch từ trong bài đọc',
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD6E5FA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.word,
                  key: const ValueKey('reading-translated-word-writing'),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<String>(
                  future: _translation,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Row(
                        key: ValueKey('reading-word-translation-loading'),
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đang tải mô hình và dịch nghĩa…',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    if (snapshot.hasError ||
                        (snapshot.data?.trim().isEmpty ?? true)) {
                      return const Text(
                        'Chưa thể dịch từ này. Vui lòng kiểm tra kết nối mạng và thử lại.',
                        key: ValueKey('reading-word-translation-error'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      snapshot.data!,
                      key: const ValueKey('reading-word-translation'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bản dịch được tạo trên thiết bị bằng Google ML Kit.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
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
