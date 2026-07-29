import 'dart:async';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/topic.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../review_practice/review_practice_screen.dart';

enum _WordState { newWord, learning, known }

class WordStudyScreen extends ConsumerStatefulWidget {
  const WordStudyScreen({required this.topic, this.dailyTaskType, super.key});

  final Topic topic;
  final DailyTaskType? dailyTaskType;

  @override
  ConsumerState<WordStudyScreen> createState() => _WordStudyScreenState();
}

class _WordStudyScreenState extends ConsumerState<WordStudyScreen> {
  static const _maxSelectedWords = 4;
  late int _activeTopicOrder;
  int _currentIndex = 0;
  final Map<String, _WordState> _wordStates = {};
  Map<int, _WordState> _persistedWordStates = const {};
  List<Topic>? _initialStudyTopics;
  final List<String> _selectedWordKeys = [];
  final Map<String, Map<String, dynamic>> _selectedWords = {};
  bool _openingPractice = false;

  @override
  void initState() {
    super.initState();
    _activeTopicOrder = widget.topic.order;
  }

  Topic _activeTopic(List<Topic> topics) {
    return topics.firstWhere(
      (topic) => topic.order == _activeTopicOrder,
      orElse: () => widget.topic,
    );
  }

  List<Topic> _topicsForStudy(List<Topic>? databaseTopics) {
    if (databaseTopics == null || databaseTopics.isEmpty) {
      return [widget.topic];
    }

    // The screen can also be used in isolation by previews/tests. In the
    // normal app flow the incoming topic is one of the database topics, so
    // use the complete database-backed list in that case.
    final hasDatabaseTopic = databaseTopics.any(
      (topic) => topic.id == widget.topic.id,
    );
    return hasDatabaseTopic ? databaseTopics : [widget.topic];
  }

  int? _wordId(Topic topic, int index) {
    final value = topic.words[index]['id'];
    return value is int
        ? value
        : value is num
        ? value.toInt()
        : null;
  }

  String _wordKey(Topic topic, int index) {
    final wordId = _wordId(topic, index);
    return wordId == null ? '${topic.id}-$index' : 'word-$wordId';
  }

  _WordState _stateFromProgress(LearningProgressRow? progress) {
    if (progress == null || progress.deletedByUser) {
      return _WordState.newWord;
    }
    if (progress.markedAsKnown) return _WordState.known;
    if (progress.trainingProgress > 0 ||
        progress.trainingError > 0 ||
        progress.learnedDate != null ||
        progress.repetitionStep > 0) {
      return _WordState.learning;
    }
    return _WordState.newWord;
  }

  _WordState _stateFor(Topic topic, int index) {
    final key = _wordKey(topic, index);
    return _wordStates[key] ??
        (_wordId(topic, index) == null
            ? _WordState.newWord
            : _persistedWordStates[_wordId(topic, index)] ??
                  _WordState.newWord);
  }

  List<Topic> _filterNewWords(
    List<Topic> topics,
    Map<int, LearningProgressRow> progressByWordId,
  ) {
    return topics
        .map(
          (topic) => Topic(
            id: topic.id,
            order: topic.order,
            original: topic.original,
            translated: topic.translated,
            words: topic.words
                .where((word) {
                  final value = word['id'];
                  final wordId = value is num ? value.toInt() : null;
                  return _stateFromProgress(
                        wordId == null ? null : progressByWordId[wordId],
                      ) ==
                      _WordState.newWord;
                })
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  int? _selectedNumberFor(Topic topic, int index) {
    final selectedIndex = _selectedWordKeys.indexOf(_wordKey(topic, index));
    return selectedIndex == -1 ? null : selectedIndex + 1;
  }

  void _selectTopic(Topic topic) {
    if (topic.order == _activeTopicOrder) return;
    setState(() {
      _activeTopicOrder = topic.order;
      _currentIndex = 0;
    });
  }

  void _goToWord(int index, int length) {
    if (length == 0) return;
    final next = (index + length) % length;
    setState(() => _currentIndex = next);
  }

  void _setWordState(Topic topic, int index, _WordState state) {
    final key = _wordKey(topic, index);
    final wasSelected = _wordStates[key] == _WordState.learning;

    if (state == _WordState.learning && !wasSelected) {
      if (_selectedWordKeys.length >= _maxSelectedWords) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn chỉ có thể chọn tối đa 4 từ.'),
            duration: Duration(milliseconds: 1200),
          ),
        );
        return;
      }
      _selectedWordKeys.add(key);
      _selectedWords[key] = {...topic.words[index], 'topicId': topic.id};
    } else if (state != _WordState.learning) {
      _selectedWordKeys.remove(key);
      _selectedWords.remove(key);
    }

    setState(() {
      _wordStates[key] = state;
      if (state != _WordState.newWord && topic.words.isNotEmpty) {
        _currentIndex = (index + 1) % topic.words.length;
      }
    });
    unawaited(_persistKnownState(topic, index, state));
    if (_selectedWordKeys.length == _maxSelectedWords) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPractice());
    }
  }

  Future<void> _persistKnownState(
    Topic topic,
    int index,
    _WordState state,
  ) async {
    final wordId = _wordId(topic, index);
    if (wordId == null) return;

    final database = ref.read(appDatabaseProvider);
    final databaseWord =
        await (database.select(database.wordModels)..where(
              (row) => row.id.equals(wordId) & row.topicId.equals(topic.id),
            ))
            .getSingleOrNull();
    if (databaseWord == null) return;

    final markedAsKnown = state == _WordState.known;
    final existing = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(wordId))).getSingleOrNull();
    if (existing == null) {
      // Selecting a word for the current lesson is a transient UI state. It
      // becomes learning progress only after the practice session is saved.
      if (!markedAsKnown) return;
      await database
          .into(database.learningProgressModels)
          .insert(
            LearningProgressModelsCompanion.insert(
              id: drift.Value(wordId),
              creationDate: DateTime.now().millisecondsSinceEpoch,
              markedAsKnown: drift.Value(markedAsKnown),
            ),
          );
    } else {
      await (database.update(
        database.learningProgressModels,
      )..where((row) => row.id.equals(wordId))).write(
        LearningProgressModelsCompanion(
          markedAsKnown: drift.Value(markedAsKnown),
        ),
      );
    }
    ref.invalidate(wordProgressProvider);
    ref.invalidate(progressDashboardProvider);
  }

  Future<void> _openPractice() async {
    if (!mounted || _openingPractice) return;
    final selectedWords = _selectedWordKeys
        .map((key) => _selectedWords[key])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (selectedWords.length != _maxSelectedWords) return;

    _openingPractice = true;
    final topics = _topicsForStudy(ref.read(topicsProvider).valueOrNull);
    final distractorWords = topics
        .expand(
          (topic) => topic.words.map(
            (word) => <String, dynamic>{...word, 'topicId': topic.id},
          ),
        )
        .toList(growable: false);
    Map<int, List<int>> similarWordIds = const {};
    try {
      similarWordIds = await ref
          .read(appDatabaseProvider)
          .similarWordIdsFor(
            selectedWords.map((word) => word['id']).whereType<int>(),
          );
    } on Object {
      // Similar words are support data; the global fallback remains valid
      // while that optional table is unavailable or still being initialized.
    }
    if (!mounted) return;
    final shouldCloseStudy = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReviewPracticeScreen(
          words: selectedWords,
          distractorWords: distractorWords,
          dailyTaskType: widget.dailyTaskType,
          similarWordIds: similarWordIds,
          database: ref.read(appDatabaseProvider),
        ),
      ),
    );
    _openingPractice = false;
    if (shouldCloseStudy == true && mounted) {
      ref.invalidate(topicProgressProvider);
      ref.invalidate(topicProgressDetailsProvider(widget.topic.id));
      ref.invalidate(dailyCardProvider);
      ref.invalidate(wordProgressProvider);
      ref.invalidate(progressDashboardProvider);
      Navigator.of(context).pop();
    }
  }

  Future<void> _playPronunciation(String word) {
    return TextToSpeechService.instance.speak(word);
  }

  Future<void> _playSlowPronunciation(String word) {
    return TextToSpeechService.instance.speak(
      word,
      speechRate: TextToSpeechService.slowSpeechRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final databaseTopics = ref.watch(topicsProvider).valueOrNull;
    final persistedProgress = ref.watch(wordProgressProvider).valueOrNull;
    if (persistedProgress != null) {
      _persistedWordStates = {
        for (final entry in persistedProgress.entries)
          entry.key: _stateFromProgress(entry.value),
      };
    }
    if (_initialStudyTopics == null &&
        databaseTopics != null &&
        persistedProgress != null) {
      _initialStudyTopics = _filterNewWords(
        _topicsForStudy(databaseTopics),
        persistedProgress,
      );
    }
    final topics = _initialStudyTopics ?? _topicsForStudy(databaseTopics);
    final topic = _activeTopic(topics);
    final words = topic.words;
    final selectedCount = List<int>.generate(words.length, (index) => index)
        .where((index) => _selectedWordKeys.contains(_wordKey(topic, index)))
        .length;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          const Positioned.fill(child: _StudyBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _StudyTopBar(
                    selectedCount: selectedCount,
                    totalCount: _maxSelectedWords,
                    onClose: () => Navigator.of(context).pop(),
                    onSettings: () {},
                  ),
                ),
                const SizedBox(height: 14),
                _TopicStrip(
                  topics: topics,
                  activeOrder: topic.order,
                  onSelected: _selectTopic,
                ),
                const SizedBox(height: 11),
                Expanded(
                  child: _DeckZone(
                    words: words,
                    topic: topic,
                    currentIndex: _currentIndex,
                    stateFor: _stateFor,
                    selectedNumberFor: _selectedNumberFor,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    onPrevious: () =>
                        _goToWord(_currentIndex - 1, words.length),
                    onNext: () => _goToWord(_currentIndex + 1, words.length),
                    onStateChanged: _setWordState,
                    onPlay: _playPronunciation,
                    onPlaySlow: _playSlowPronunciation,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -14),
                  child: _StudyFooter(
                    selectedCount: selectedCount,
                    maxSelected: _maxSelectedWords,
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

class _StudyBackdrop extends StatelessWidget {
  const _StudyBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF061C42), Color(0xFF0B347F), Color(0xFF155CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -110,
          child: _StudyOrb(
            color: AppColors.cyan.withValues(alpha: .24),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -105,
          right: -70,
          child: _StudyOrb(
            color: AppColors.purple.withValues(alpha: .24),
            size: 280,
          ),
        ),
        Positioned(
          top: 94,
          right: 74,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0x88FFFFFF),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.white, blurRadius: 14)],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudyOrb extends StatelessWidget {
  const _StudyOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _StudyTopBar extends StatelessWidget {
  const _StudyTopBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onClose,
    required this.onSettings,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onClose;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StudyIconButton(
          icon: Icons.close_rounded,
          label: 'Đóng',
          onPressed: onClose,
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'BỘ HỌC HÔM NAY',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đã chọn $selectedCount / $totalCount từ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
            ],
          ),
        ),
        _StudyIconButton(
          icon: Icons.tune_rounded,
          label: 'Cài đặt',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _StudyIconButton extends StatelessWidget {
  const _StudyIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: const Color(0x2EFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0x3DFFFFFF)),
          ),
        ),
      ),
    );
  }
}

class _TopicStrip extends StatelessWidget {
  const _TopicStrip({
    required this.topics,
    required this.activeOrder,
    required this.onSelected,
  });

  final List<Topic> topics;
  final int activeOrder;
  final ValueChanged<Topic> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, index) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final active = topic.order == activeOrder;
          return GestureDetector(
            onTap: () => onSelected(topic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? Colors.white : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: active ? Colors.white : const Color(0x2EFFFFFF),
                ),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x2B00184F),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                active ? '★  ${topic.translated}' : topic.translated,
                style: TextStyle(
                  color: active
                      ? AppColors.primaryDark
                      : const Color(0xD6FFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeckZone extends StatefulWidget {
  const _DeckZone({
    required this.words,
    required this.topic,
    required this.currentIndex,
    required this.stateFor,
    required this.selectedNumberFor,
    required this.onPageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onStateChanged,
    required this.onPlay,
    required this.onPlaySlow,
  });

  final List<Map<String, dynamic>> words;
  final Topic topic;
  final int currentIndex;
  final _WordState Function(Topic topic, int index) stateFor;
  final int? Function(Topic topic, int index) selectedNumberFor;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(Topic topic, int index, _WordState state) onStateChanged;
  final Future<void> Function(String word) onPlay;
  final Future<void> Function(String word) onPlaySlow;

  @override
  State<_DeckZone> createState() => _DeckZoneState();
}

class _DeckZoneState extends State<_DeckZone> {
  late final CarouselSliderController _carouselController;
  late final ValueNotifier<double> _scrollPosition;
  int _pageRequestId = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
    _scrollPosition = ValueNotifier(widget.currentIndex.toDouble());
  }

  @override
  void dispose() {
    _scrollPosition.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DeckZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic.order != widget.topic.order) {
      _scrollPosition.value = 0;
      _schedulePageChange(0, animate: false);
    } else if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollPosition.value = widget.currentIndex.toDouble();
      _schedulePageChange(widget.currentIndex, animate: true);
    }
  }

  void _schedulePageChange(int page, {required bool animate}) {
    final requestId = ++_pageRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _pageRequestId) return;
      if (!_carouselController.ready) return;
      if (animate) {
        _carouselController.animateToPage(
          page,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _carouselController.jumpToPage(page);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return const Center(
        child: Text(
          'Chủ đề này chưa có từ để học.',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final arrowTop = (constraints.maxHeight - 58) / 2;
        final carouselHeight = (constraints.maxHeight - 52)
            .clamp(0, constraints.maxHeight)
            .toDouble();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CarouselSlider.builder(
              itemCount: widget.words.length,
              carouselController: _carouselController,
              itemBuilder: (context, index, realIndex) {
                return ValueListenableBuilder<double>(
                  valueListenable: _scrollPosition,
                  builder: (context, scrollPosition, child) {
                    final distance = index - scrollPosition;
                    final rotation = (distance * .045)
                        .clamp(-.07, .07)
                        .toDouble();
                    final opacity = (1 - distance.abs() * .35)
                        .clamp(.8, 1)
                        .toDouble();
                    return Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Transform.rotate(angle: rotation, child: child),
                      ),
                    );
                  },
                  child: _WordCard(
                    key: ValueKey('${widget.topic.order}-$index'),
                    topic: widget.topic,
                    word: widget.words[index],
                    index: index,
                    total: widget.words.length,
                    state: widget.stateFor(widget.topic, index),
                    selectedNumber: widget.selectedNumberFor(
                      widget.topic,
                      index,
                    ),
                    onStateChanged: (state) =>
                        widget.onStateChanged(widget.topic, index, state),
                    onPlay: widget.onPlay,
                    onPlaySlow: widget.onPlaySlow,
                  ),
                );
              },
              options: CarouselOptions(
                height: carouselHeight,
                viewportFraction: constraints.maxWidth >= 390 ? .82 : .84,
                initialPage: widget.currentIndex,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                enlargeFactor: .12,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                padEnds: true,
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: (index, reason) {
                  _scrollPosition.value = index.toDouble();
                  if (widget.currentIndex == index) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && widget.currentIndex != index) {
                      widget.onPageChanged(index);
                    }
                  });
                },
                onScrolled: (value) {
                  if (value == null) return;
                  _scrollPosition.value = value;
                },
              ),
            ),
            Positioned(
              left: 5,
              top: arrowTop,
              child: _DeckArrow(
                icon: Icons.chevron_left_rounded,
                onTap: widget.onPrevious,
              ),
            ),
            Positioned(
              right: 5,
              top: arrowTop,
              child: _DeckArrow(
                icon: Icons.chevron_right_rounded,
                onTap: widget.onNext,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeckArrow extends StatelessWidget {
  const _DeckArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: icon == Icons.chevron_left_rounded ? 'Từ trước' : 'Từ tiếp theo',
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 21),
        style: IconButton.styleFrom(
          fixedSize: const Size(34, 58),
          backgroundColor: const Color(0x1FFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0x2EFFFFFF)),
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.topic,
    required this.word,
    required this.index,
    required this.total,
    required this.state,
    required this.selectedNumber,
    required this.onStateChanged,
    required this.onPlay,
    required this.onPlaySlow,
    super.key,
  });

  final Topic topic;
  final Map<String, dynamic> word;
  final int index;
  final int total;
  final _WordState state;
  final int? selectedNumber;
  final ValueChanged<_WordState> onStateChanged;
  final Future<void> Function(String word) onPlay;
  final Future<void> Function(String word) onPlaySlow;

  String get writing => word['writing'] as String? ?? '';
  String get translation => word['translation'] as String? ?? '';
  String get transcription => word['transcription'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    final isLearning = state == _WordState.learning;
    final isKnown = state == _WordState.known;
    final topLineColors = isLearning
        ? const [Color(0xFFFFAE21), Color(0xFFFFC928)]
        : isKnown
        ? const [Color(0xFF12AA73), Color(0xFF60DFB2)]
        : const [AppColors.primary, AppColors.cyan];
    final stateLabel = isLearning
        ? 'Đang học'
        : isKnown
        ? 'Đã biết từ này'
        : 'Chưa phân loại';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF9FBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xDEFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38001852),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: topLineColors,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 17, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.original,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8394AA),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isLearning
                                    ? const Color(0xFFFFF1CD)
                                    : isKnown
                                    ? const Color(0xFFE4FBF1)
                                    : AppColors.surfaceBlue,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                stateLabel,
                                style: TextStyle(
                                  color: isLearning
                                      ? const Color(0xFFA45F00)
                                      : isKnown
                                      ? const Color(0xFF13845D)
                                      : AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.open_in_full_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceBlue,
                        fixedSize: const Size(40, 40),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 17, 4, 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: selectedNumber == null
                                    ? const SizedBox(height: 58)
                                    : Text(
                                        selectedNumber!.toString().padLeft(
                                          2,
                                          '0',
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFFEDF2FA),
                                          fontSize: 58,
                                          height: 1,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -4,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      writing,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 43,
                                        height: .98,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          translation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6A7F9B),
                            fontSize: 21,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (transcription.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            transcription,
                            style: const TextStyle(
                              color: Color(0xFF98A7BA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SlowAudioButton(onTap: () => onPlaySlow(writing)),
                            const SizedBox(width: 15),
                            _AudioButton(onTap: () => onPlay(writing)),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Một từ vựng quan trọng trong chủ đề ${topic.translated}.',
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              color: Color(0xFF637A98),
                              fontSize: 9,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: _WordActionButton(
                        label: isKnown ? 'Tôi không biết' : 'Đã biết',
                        known: isKnown,
                        onTap: () => onStateChanged(
                          isKnown ? _WordState.newWord : _WordState.known,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 11,
                      child: _WordActionButton(
                        label: isLearning
                            ? 'Bỏ chọn'
                            : isKnown
                            ? 'Học lại'
                            : 'Học từ này',
                        primary: !isLearning,
                        learning: isLearning,
                        onTap: () => onStateChanged(
                          isLearning ? _WordState.newWord : _WordState.learning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlowAudioButton extends StatefulWidget {
  const _SlowAudioButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  State<_SlowAudioButton> createState() => _SlowAudioButtonState();
}

class _SlowAudioButtonState extends State<_SlowAudioButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _controller.repeat(reverse: true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Phát âm chậm 0.75x',
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: _isPlaying
                ? const Color(0xFFE0ECFF)
                : const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: _isPlaying ? AppColors.primary : const Color(0xFFDCE8FF),
            ),
            boxShadow: _isPlaying
                ? const [
                    BoxShadow(
                      color: Color(0x33155CFF),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                child: SvgPicture.asset(
                  'assets/svgs/slow.svg',
                  width: 26,
                  height: 26,
                ),
                builder: (context, child) {
                  final progress = Curves.easeInOut.transform(
                    _controller.value,
                  );
                  return Transform.translate(
                    offset: Offset(progress * 7, 0),
                    child: child,
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                '0.75×',
                style: TextStyle(
                  color: _isPlaying
                      ? AppColors.primary
                      : const Color(0xFF3B68B5),
                  fontSize: 8,
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

class _AudioButton extends StatefulWidget {
  const _AudioButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  State<_AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<_AudioButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _controller.repeat(reverse: true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Phát âm bình thường',
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D155CFF),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: .88, end: 1.08).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordActionButton extends StatelessWidget {
  const _WordActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.learning = false,
    this.known = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool learning;
  final bool known;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? const LinearGradient(colors: [Color(0xFFFFAE21), Color(0xFFFFC928)])
        : learning
        ? const LinearGradient(colors: [Color(0xFFFFF1CC), Color(0xFFFFF1CC)])
        : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: background,
          color: primary || learning
              ? null
              : known
              ? const Color(0xFFFFF0F2)
              : const Color(0xFFE4FBF1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary || learning
                ? learning
                      ? const Color(0xFFFFE09B)
                      : Colors.transparent
                : known
                ? const Color(0xFFFFDADD)
                : const Color(0xFFC8F3DF),
          ),
          boxShadow: primary
              ? const [
                  BoxShadow(
                    color: Color(0x38FFB923),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primary
                ? Colors.white
                : learning
                ? const Color(0xFF8B5900)
                : known
                ? const Color(0xFFB34B56)
                : const Color(0xFF13845D),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StudyFooter extends StatelessWidget {
  const _StudyFooter({required this.selectedCount, required this.maxSelected});

  final int selectedCount;
  final int maxSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỪ ĐÃ CHỌN',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selectedCount / $maxSelected từ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Chọn tối đa 4 từ',
                style: TextStyle(
                  color: Color(0xA3FFFFFF),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              for (var index = 0; index < maxSelected; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index < selectedCount
                          ? Colors.white
                          : const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (index != maxSelected - 1) const SizedBox(width: 7),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
