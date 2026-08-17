import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/practice_exercise.dart';
import '../../../data/models/sentence_exercise.dart';
import '../../../data/services/additional_task_service.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../presentation/widgets/app_bottom_sheet.dart';
import '../../../data/services/home_main_task_service.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';
import '../repetition_practice/repetition_practice_screen.dart';
import '../review_practice/review_practice_screen.dart';
import '../sentence_training/sentence_training_screen.dart';
import '../topic_detail/topic_detail_screen.dart';
import '../word_study/word_study_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showAllTopics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate the local day and reschedule midnight after the device's
      // clock or time zone may have changed while the app was in background.
      ref.invalidate(dailyCardProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final topicProgressById =
        ref.watch(topicProgressProvider).valueOrNull ?? const <int, double>{};
    final filter = ref.watch(selectedTopicFilterProvider);
    final selectedTopicOrders = ref.watch(selectedTopicOrdersProvider);
    final topicSelectionReady = ref
        .watch(selectedTopicOrdersHydrationProvider)
        .hasValue;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _LearningHeader(),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: const _DailyCard(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                      child: Column(
                        children: [
                          SectionHeader(
                            kicker: context.l10n.homeLibraryKicker,
                            title: context.l10n.homeLibraryTitle,
                          ),
                          const SizedBox(height: 15),
                          _SearchRow(
                            controller: _searchController,
                            onChanged: (value) => setState(() {
                              _search = value.trim().toLowerCase();
                              _showAllTopics = false;
                            }),
                            onFilterTap: () =>
                                ref
                                        .read(topicSetupOpenProvider.notifier)
                                        .state =
                                    true,
                          ),
                          const SizedBox(height: 13),
                          _FilterChips(
                            selected: filter,
                            onSelected: (_) =>
                                setState(() => _showAllTopics = false),
                          ),
                          const SizedBox(height: 15),
                          topicsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(context.l10n.topicsLoadError),
                            ),
                            data: (topics) {
                              if (!topicSelectionReady) {
                                return const Padding(
                                  padding: EdgeInsets.all(30),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final allMatchingTopics = _filterTopics(
                                topics,
                                filter,
                                _search,
                                topicProgressById,
                              );
                              final selectedTopics = selectedTopicOrders.isEmpty
                                  ? allMatchingTopics
                                  : allMatchingTopics
                                        .where(
                                          (topic) => selectedTopicOrders
                                              .contains(topic.order),
                                        )
                                        .toList();
                              final hasTopicSetup =
                                  selectedTopicOrders.isNotEmpty;
                              final topicPool = hasTopicSetup
                                  ? selectedTopics
                                  : allMatchingTopics;
                              final visibleTopics = _showAllTopics
                                  ? topicPool
                                  : topicPool.take(10).toList();
                              final showTopicToggle = topicPool.length > 10;
                              return Column(
                                children: [
                                  _TopicGrid(
                                    topics: visibleTopics,
                                    progressByTopicId: topicProgressById,
                                  ),
                                  if (showTopicToggle) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => setState(
                                        () => _showAllTopics = !_showAllTopics,
                                      ),
                                      icon: Icon(
                                        _showAllTopics
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _showAllTopics
                                            ? context.l10n.showLess
                                            : context.l10n.showAllTopics(
                                                topicPool.length,
                                              ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          45,
                                        ),
                                        padding: EdgeInsets.zero,
                                        foregroundColor: AppColors.primary,
                                        backgroundColor: AppColors.surfaceBlue,
                                        side: BorderSide.none,
                                        textStyle: const TextStyle(
                                          inherit: false,
                                          fontFamily: 'M PLUS Rounded 1c',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      key: const Key(
                                        'setup-more-topics-button',
                                      ),
                                      onPressed: () {
                                        ref
                                                .read(
                                                  topicSetupStartAtTopicsProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;
                                        ref
                                                .read(
                                                  topicSetupOpenProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 20,
                                      ),
                                      label: Text(context.l10n.addTopic),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          40,
                                        ),
                                        padding: EdgeInsets.zero,
                                        foregroundColor: const Color(
                                          0xFF1769E8,
                                        ),
                                        backgroundColor: const Color(
                                          0xFFF0F6FF,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFCFE1FA),
                                        ),
                                        textStyle: const TextStyle(
                                          inherit: false,
                                          fontFamily: 'M PLUS Rounded 1c',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Topic> _filterTopics(
    List<Topic> topics,
    String filter,
    String search,
    Map<int, double> progressByTopicId,
  ) {
    final filteredTopics = topics.where((topic) {
      final matchesSearch =
          search.isEmpty ||
          topic.translated.toLowerCase().contains(search) ||
          topic.original.toLowerCase().contains(search);
      final progress = progressByTopicId[topic.id] ?? 0;
      final matchesFilter =
          filter == 'topicFilterAll' ||
          (filter == 'topicFilterLearning' && progress > 0 && progress < 1) ||
          (filter == 'topicFilterNotStarted' && progress == 0) ||
          (filter == 'topicFilterCompleted' && progress >= 1);
      return matchesSearch && matchesFilter;
    }).toList();
    return filteredTopics;
  }
}

class _LearningHeader extends StatelessWidget {
  const _LearningHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandMark(),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.text('homeGreetingEyebrow'),
                style: const TextStyle(
                  color: Color(0xFF3D628D),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .72,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Leximon',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.15,
                ),
              ),
            ],
          ),
        ),
        const _NotificationButton(),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D75FF), Color(0xFF064EE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Color(0x61FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x48011647),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            left: -18,
            top: -18,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xA856D8FF), Color(0x0056D8FF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xCC1D75FF), Color(0x001D75FF)],
                  ),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 1.14,
            child: Image.asset(
              'assets/images/leximon-owl.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.text('notifications'),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A3478B9),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.white.withValues(alpha: .76),
              child: InkWell(
                key: const ValueKey('home-notification-button'),
                onTap: () {},
                child: Stack(
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/svgs/bell_home.svg',
                        key: const ValueKey('home-notification-icon'),
                        width: 19,
                        height: 19,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends ConsumerWidget {
  const _DailyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(dailyCardProvider)
        .when(
          loading: () => const _DailyCardLoading(),
          error: (error, stack) => const _DailyCardError(),
          data: (snapshot) => _DailyCardContent(snapshot: snapshot),
        );
  }
}

class _DailyCardLoading extends StatelessWidget {
  const _DailyCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}

class _DailyCardError extends StatelessWidget {
  const _DailyCardError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        context.l10n.text('homeDailyLoadError'),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _DailyCardContent extends ConsumerWidget {
  const _DailyCardContent({required this.snapshot});

  final DailyCardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingVocabularyTask = ref
        .watch(readingVocabularyTaskProvider)
        .valueOrNull;
    final completedTasks = snapshot.tasks.where((task) => task.isDone).length;
    final firstIncompleteIndex = snapshot.tasks.indexWhere(
      (task) => !task.isDone,
    );
    final showFirstTrainingGreeting =
        snapshot.isFirstLearningDay &&
        snapshot.tasks.length == 1 &&
        !snapshot.isComplete;
    final title = snapshot.isComplete
        ? context.l10n.text('homeAllTasksComplete')
        : context.l10n.text('homeTodayTasks');
    final description = snapshot.isComplete
        ? context.l10n.text('homeTomorrowTasks')
        : showFirstTrainingGreeting
        ? context.l10n.text('homeFirstWordsDescription')
        : context.l10n.text('homeFourMoreDescription');

    return Container(
      key: const Key('home-daily-card'),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xF9FFFFFF), Color(0xF2F5FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .86)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F26448B),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DailyCardHero(
            completedTasks: completedTasks,
            taskCount: snapshot.tasks.length,
            complete: snapshot.isComplete,
            title: title,
            description: description,
          ),
          if (showFirstTrainingGreeting) ...[
            const _FirstTrainingGreeting(),
            const SizedBox(height: 11),
          ],
          ...snapshot.tasks.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DailyTaskTile(
                task: entry.$2,
                isSuggested: entry.$1 == firstIncompleteIndex,
                onTap: entry.$2.isDone
                    ? null
                    : () => _openTask(context, ref, entry.$2.type),
              ),
            ),
          ),
          if (readingVocabularyTask?.isAvailable == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReadingVocabularyTaskTile(
                pendingCount: readingVocabularyTask!.pendingCount,
                onTap: () => _openReadingVocabularyTask(context, ref),
              ),
            ),
          if (snapshot.isComplete) ...[
            const SizedBox(height: 2),
            Text(
              context.l10n.text('homeMorePracticeQuestion'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.text('homeMorePracticeBody'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const _AdditionalTasksLauncher(),
          ],
        ],
      ),
    );
  }

  Future<void> _openReadingVocabularyTask(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(readingVocabularyServiceProvider);
    final task = await service.loadTask();
    if (!context.mounted) return;
    if (!task.isAvailable) {
      ref.invalidate(readingVocabularyTaskProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('homeReadingWordsUnavailable')),
        ),
      );
      return;
    }

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReviewPracticeScreen(
          title: context.l10n.text('homeReadingWordsTitle'),
          kicker: 'READING WORDS',
          words: task.words.map(_exerciseMapFromRow).toList(growable: false),
          distractorWords: task.distractorWords
              .map(_exerciseMapFromRow)
              .toList(growable: false),
          dailyTaskType: DailyTaskType.learn,
          similarWordIds: task.similarWordIds,
          database: ref.read(appDatabaseProvider),
        ),
      ),
    );
    if (!context.mounted) return;
    if (completed == true) await service.completeBatch(task.words);
    _invalidateHomeProgress(ref);
  }

  Future<void> _openTask(
    BuildContext context,
    WidgetRef ref,
    DailyTaskType type,
  ) async {
    if (type == DailyTaskType.sentences) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const SentenceTrainingScreen(
            source: SentenceTrainingSource.daily,
          ),
        ),
      );
      if (!context.mounted) return;
      _invalidateHomeProgress(ref);
      return;
    }
    if (type != DailyTaskType.learn) {
      try {
        final data = await ref
            .read(homeMainTaskServiceProvider)
            .prepareTask(type);
        if (!context.mounted) return;
        await _launchMainTask(context, ref, data);
      } on HomeMainTaskUnavailableException {
        if (!context.mounted) return;
        ref.invalidate(dailyCardProvider);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.text('homeTaskChanged'))),
          );
      }
      if (!context.mounted) return;
      _invalidateHomeProgress(ref);
      return;
    }

    final topics = ref.read(topicsProvider).valueOrNull ?? const <Topic>[];
    final topic = topics.cast<Topic?>().firstWhere(
      (item) => item != null && item.words.isNotEmpty,
      orElse: () => null,
    );
    if (topic == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WordStudyScreen(topic: topic, dailyTaskType: type),
      ),
    );
    if (!context.mounted) return;
    _invalidateHomeProgress(ref);
  }

  Future<void> _launchMainTask(
    BuildContext context,
    WidgetRef ref,
    HomeMainTaskLaunchData data,
  ) {
    switch (data.type) {
      case DailyTaskType.repeat:
        return Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => RepetitionPracticeScreen(
              title: context.l10n.text('homeReviewWordsTitle'),
              words: data.words
                  .map(_exerciseWordFromRow)
                  .toList(growable: false),
              distractorWords: data.distractorWords
                  .map(_exerciseWordFromRow)
                  .toList(growable: false),
              database: ref.read(appDatabaseProvider),
              loadNextWords: () async {
                try {
                  final next = await ref
                      .read(homeMainTaskServiceProvider)
                      .prepareTask(DailyTaskType.repeat);
                  return next.words
                      .map(_exerciseWordFromRow)
                      .toList(growable: false);
                } on HomeMainTaskUnavailableException {
                  return const <ExerciseWord>[];
                }
              },
            ),
          ),
        );
      case DailyTaskType.train:
      case DailyTaskType.difficult:
        return Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ReviewPracticeScreen(
              title: data.type == DailyTaskType.train
                  ? context.l10n.text('homeTrainWordsTitle')
                  : context.l10n.text('difficultWords'),
              kicker: data.type == DailyTaskType.train
                  ? 'FAST BRAIN'
                  : 'DIFFICULT WORDS',
              words: data.words
                  .map(_exerciseMapFromRow)
                  .toList(growable: false),
              distractorWords: data.distractorWords
                  .map(_exerciseMapFromRow)
                  .toList(growable: false),
              dailyTaskType: data.type,
              exerciseMasksByWordId: data.exerciseMasksByWordId,
              database: ref.read(appDatabaseProvider),
            ),
          ),
        );
      case DailyTaskType.learn:
        throw StateError('Learn tasks use WordStudyScreen.');
      case DailyTaskType.sentences:
        throw StateError('Sentence tasks use SentenceTrainingScreen.');
    }
  }
}

class _DailyCardHero extends StatelessWidget {
  const _DailyCardHero({
    required this.completedTasks,
    required this.taskCount,
    required this.complete,
    required this.title,
    required this.description,
  });

  final int completedTasks;
  final int taskCount;
  final bool complete;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -28,
            width: 172,
            height: 160,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/owl_daily_home.png',
                key: const ValueKey('home-daily-owl'),
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                filterQuality: FilterQuality.high,
                cacheWidth: 820,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: complete
                    ? const Color(0xFFDDF8EE)
                    : const Color(0xFFFFF3C7),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                context.l10n.text(
                  complete ? 'homeTaskCompleteBadge' : 'homeTaskTodayBadge',
                ),
                style: TextStyle(
                  color: complete
                      ? const Color(0xFF137E68)
                      : const Color(0xFF986100),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .25,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            width: 194,
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 9,
            width: 208,
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: 0,
            child: Text(
              '$completedTasks / $taskCount',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalTasksLauncher extends ConsumerStatefulWidget {
  const _AdditionalTasksLauncher();

  @override
  ConsumerState<_AdditionalTasksLauncher> createState() =>
      _AdditionalTasksLauncherState();
}

class _AdditionalTasksLauncherState
    extends ConsumerState<_AdditionalTasksLauncher> {
  bool _isOpening = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _isOpening ? null : _openAdditionalTasks,
        icon: _isOpening
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded, size: 18),
        label: Text(
          context.l10n.text(
            _isOpening ? 'homeChecking' : 'homeMorePracticeAction',
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: .55),
          side: const BorderSide(color: Color(0x29155CFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> _openAdditionalTasks() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    DailyTaskType? requestedType;
    try {
      final service = ref.read(additionalTaskServiceProvider);
      final types = await service.loadAvailableTasks();
      if (!mounted) return;
      setState(() => _isOpening = false);

      final selectedType = await showModalBottomSheet<DailyTaskType>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AdditionalTasksSheet(types: types),
      );
      if (selectedType == null || !mounted) return;
      requestedType = selectedType;

      if (selectedType == DailyTaskType.sentences) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const SentenceTrainingScreen(
              source: SentenceTrainingSource.additional,
            ),
          ),
        );
        if (!mounted) return;
        _invalidateHomeProgress(ref);
        return;
      }

      setState(() => _isOpening = true);
      final launchData = await service.prepareTask(selectedType);
      if (!mounted) return;
      await _launchTask(launchData);
      if (!mounted) return;
      _invalidateHomeProgress(ref);
    } on AdditionalTasksLockedException {
      if (!mounted) return;
      ref.invalidate(dailyCardProvider);
      _showMessage(context.l10n.text('homeAdditionalTasksLocked'));
    } on AdditionalTaskUnavailableException {
      if (!mounted) return;
      ref.invalidate(dailyCardProvider);
      _showMessage(
        requestedType == DailyTaskType.repeat
            ? context.l10n.text('homeNoReviewWords')
            : context.l10n.text('homeTaskUnavailable'),
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _launchTask(AdditionalTaskLaunchData data) async {
    switch (data.type) {
      case DailyTaskType.learn:
        final topics = ref.read(topicsProvider).valueOrNull ?? const <Topic>[];
        final topic = topics.cast<Topic?>().firstWhere(
          (item) => item != null && item.words.isNotEmpty,
          orElse: () => null,
        );
        if (topic == null) {
          throw const AdditionalTaskUnavailableException(DailyTaskType.learn);
        }
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => WordStudyScreen(
              topic: topic,
              dailyTaskType: DailyTaskType.learn,
            ),
          ),
        );
        return;
      case DailyTaskType.repeat:
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RepetitionPracticeScreen(
              title: context.l10n.text('homeAdditionalReviewTitle'),
              words: data.words
                  .map(_exerciseWordFromRow)
                  .toList(growable: false),
              distractorWords: data.distractorWords
                  .map(_exerciseWordFromRow)
                  .toList(growable: false),
              database: ref.read(appDatabaseProvider),
              loadNextWords: () async {
                try {
                  final next = await ref
                      .read(additionalTaskServiceProvider)
                      .prepareTask(DailyTaskType.repeat);
                  return next.words
                      .map(_exerciseWordFromRow)
                      .toList(growable: false);
                } on AdditionalTasksLockedException {
                  return const <ExerciseWord>[];
                } on AdditionalTaskUnavailableException {
                  return const <ExerciseWord>[];
                }
              },
            ),
          ),
        );
        return;
      case DailyTaskType.train:
      case DailyTaskType.difficult:
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ReviewPracticeScreen(
              title: data.type == DailyTaskType.train
                  ? context.l10n.text('homeTrainWordsTitle')
                  : context.l10n.text('difficultWords'),
              kicker: 'WANT MORE',
              words: data.words
                  .map(_exerciseMapFromRow)
                  .toList(growable: false),
              distractorWords: data.distractorWords
                  .map(_exerciseMapFromRow)
                  .toList(growable: false),
              dailyTaskType: data.type,
              similarWordIds: data.similarWordIds,
              exerciseMasksByWordId: data.exerciseMasksByWordId,
              database: ref.read(appDatabaseProvider),
            ),
          ),
        );
        return;
      case DailyTaskType.sentences:
        throw StateError('Sentence tasks launch before prepareTask.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

void _invalidateHomeProgress(WidgetRef ref) {
  ref.invalidate(dailyCardProvider);
  ref.invalidate(readingVocabularyTaskProvider);
  ref.invalidate(wordProgressProvider);
  ref.invalidate(topicProgressProvider);
  ref.invalidate(progressDashboardProvider);
  ref.invalidate(vocabularyCollectionProvider);
}

ExerciseWord _exerciseWordFromRow(WordRow word) {
  return ExerciseWord(
    id: word.id,
    topicId: word.topicId,
    writing: word.writing,
    translation: word.translation,
    transliteration: word.transliteration ?? word.transcription ?? '',
  );
}

Map<String, dynamic> _exerciseMapFromRow(WordRow word) {
  return {
    'id': word.id,
    'topicId': word.topicId,
    'writing': word.writing,
    'translation': word.translation,
    'transliteration': word.transliteration ?? word.transcription ?? '',
  };
}

class _FirstTrainingGreeting extends StatelessWidget {
  const _FirstTrainingGreeting();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2E3FF)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/leximon-owl-wave.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.text('homeFirstTrainingGreeting'),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskTile extends StatefulWidget {
  const _DailyTaskTile({
    required this.task,
    required this.onTap,
    this.isSuggested = false,
  });

  final DailyTaskSnapshot task;
  final VoidCallback? onTap;
  final bool isSuggested;

  @override
  State<_DailyTaskTile> createState() => _DailyTaskTileState();
}

class _DailyTaskTileState extends State<_DailyTaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintController;
  late final Animation<double> _hintScale;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hintScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 1.012), weight: 45),
          TweenSequenceItem(tween: Tween(begin: 1.012, end: 1), weight: 55),
        ]).animate(
          CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
        );
    _syncHintAnimation();
  }

  @override
  void didUpdateWidget(covariant _DailyTaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSuggested != widget.isSuggested ||
        oldWidget.task.isDone != widget.task.isDone) {
      _syncHintAnimation();
    }
  }

  void _syncHintAnimation() {
    if (widget.isSuggested && !widget.task.isDone) {
      _hintController.forward(from: 0);
    } else {
      _hintController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task.isDone;
    final colors = _dailyTaskColors(task.type, done);
    final title = _dailyTaskTitle(context, task);
    return AnimatedBuilder(
      animation: _hintController,
      builder: (context, child) =>
          Transform.scale(scale: _hintScale.value, child: child),
      child: Semantics(
        key: ValueKey('daily-task-${task.type.name}'),
        button: widget.onTap != null,
        enabled: widget.onTap != null,
        label: done
            ? title
            : context.l10n.text(
                'dailyTaskProgressSemantics',
                values: {
                  'label': _dailyTaskLabel(context, task.type),
                  'completed': task.completed,
                  'total': task.count,
                },
              ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border, width: 1.15),
            boxShadow: widget.isSuggested && !done
                ? [
                    BoxShadow(
                      color: colors.icon.withValues(alpha: .16),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : _dailyTaskIcon(task.type),
                        color: colors.icon,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: colors.title,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!done) ...[
                            const SizedBox(height: 3),
                            Text(
                              context.l10n.text(
                                'wordProgress',
                                values: {
                                  'completed': task.completed,
                                  'total': task.count,
                                },
                              ),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!done)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.icon,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingVocabularyTaskTile extends StatelessWidget {
  const _ReadingVocabularyTaskTile({
    required this.pendingCount,
    required this.onTap,
  });

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('reading-vocabulary-task'),
      color: const Color(0xFFF2EEFF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7CDFB), width: 1.15),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4DCFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF6551B9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('homeReadingTaskTitle'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.text(
                        'homeReadingTaskBody',
                        values: {'count': pendingCount},
                      ),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6551B9),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdditionalTasksSheet extends StatelessWidget {
  const _AdditionalTasksSheet({required this.types});

  final List<DailyTaskType> types;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('homeAdditionalTasksTitle'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.text('homeAdditionalTasksSubtitle'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5FC),
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: const Color(0xFFF7F9FE),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(type),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _additionalTaskColor(
                              type,
                            ).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _dailyTaskIcon(type),
                            color: _additionalTaskColor(type),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _additionalTaskLabel(context, type),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _additionalTaskDescription(context, type),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _additionalTaskLabel(BuildContext context, DailyTaskType type) {
  return switch (type) {
    DailyTaskType.learn => context.l10n.text('taskLearnNewWords'),
    DailyTaskType.repeat => context.l10n.text('taskReview'),
    DailyTaskType.train => context.l10n.text('taskTrainWords'),
    DailyTaskType.sentences => context.l10n.text('taskBuildSentences'),
    DailyTaskType.difficult => context.l10n.text('taskDifficultWords'),
  };
}

String _additionalTaskDescription(BuildContext context, DailyTaskType type) {
  return switch (type) {
    DailyTaskType.learn => context.l10n.text('taskLearnDescription'),
    DailyTaskType.repeat => context.l10n.text('taskReviewDescription'),
    DailyTaskType.train => context.l10n.text('taskTrainDescription'),
    DailyTaskType.sentences => context.l10n.text('taskSentencesDescription'),
    DailyTaskType.difficult => context.l10n.text('taskDifficultDescription'),
  };
}

Color _additionalTaskColor(DailyTaskType type) {
  return switch (type) {
    DailyTaskType.learn => AppColors.primary,
    DailyTaskType.repeat => const Color(0xFF5E55C9),
    DailyTaskType.train => const Color(0xFFE28A00),
    DailyTaskType.sentences => const Color(0xFF5E55C9),
    DailyTaskType.difficult => const Color(0xFFDB5C73),
  };
}

String _dailyTaskLabel(BuildContext context, DailyTaskType type) {
  switch (type) {
    case DailyTaskType.repeat:
      return context.l10n.text('dailyTaskRepeat');
    case DailyTaskType.learn:
      return context.l10n.text('dailyTaskLearn');
    case DailyTaskType.train:
      return context.l10n.text('dailyTaskTrain');
    case DailyTaskType.sentences:
      return context.l10n.text('dailyTaskSentences');
    case DailyTaskType.difficult:
      return context.l10n.text('dailyTaskDifficult');
  }
}

String _dailyTaskTitle(BuildContext context, DailyTaskSnapshot task) {
  if (!task.isDone) return _dailyTaskLabel(context, task.type);
  return switch (task.type) {
    DailyTaskType.repeat => context.l10n.text(
      'dailyTaskRepeated',
      values: {'count': task.count},
    ),
    DailyTaskType.learn => context.l10n.text(
      'dailyTaskLearned',
      values: {'count': task.count},
    ),
    DailyTaskType.train => context.l10n.text(
      'dailyTaskTrained',
      values: {'count': task.count},
    ),
    DailyTaskType.sentences => context.l10n.text(
      'dailyTaskSentencesDone',
      values: {'count': task.count},
    ),
    DailyTaskType.difficult => context.l10n.text(
      'dailyTaskDifficultDone',
      values: {'count': task.count},
    ),
  };
}

IconData _dailyTaskIcon(DailyTaskType type) {
  switch (type) {
    case DailyTaskType.repeat:
      return Icons.sync_rounded;
    case DailyTaskType.learn:
      return Icons.lightbulb_outline_rounded;
    case DailyTaskType.train:
      return Icons.bolt_rounded;
    case DailyTaskType.sentences:
      return Icons.sort_by_alpha_rounded;
    case DailyTaskType.difficult:
      return Icons.psychology_alt_outlined;
  }
}

({
  Color background,
  Color border,
  Color iconBackground,
  Color icon,
  Color title,
})
_dailyTaskColors(DailyTaskType type, bool done) {
  if (done) {
    return (
      background: const Color(0xFFF0F7F4),
      border: const Color(0xFFD9EEE6),
      iconBackground: const Color(0xFFDDF8EE),
      icon: const Color(0xFF137E68),
      title: const Color(0xFF608378),
    );
  }
  return switch (type) {
    DailyTaskType.repeat => (
      background: const Color(0xFFF0F5FF),
      border: const Color(0xFFC8DAFF),
      iconBackground: const Color(0xFFDCE8FF),
      icon: const Color(0xFF426FD0),
      title: AppColors.textPrimary,
    ),
    DailyTaskType.learn => (
      background: const Color(0xFFFFF8DF),
      border: const Color(0xFFF3DC91),
      iconBackground: const Color(0xFFFFEAA8),
      icon: const Color(0xFFAE7500),
      title: AppColors.textPrimary,
    ),
    DailyTaskType.train => (
      background: const Color(0xFFEEF9F2),
      border: const Color(0xFFC5E9D3),
      iconBackground: const Color(0xFFD8F2E2),
      icon: const Color(0xFF27845D),
      title: AppColors.textPrimary,
    ),
    DailyTaskType.sentences => (
      background: const Color(0xFFF3F1FF),
      border: const Color(0xFFD9D3FF),
      iconBackground: const Color(0xFFE5E1FF),
      icon: const Color(0xFF5E55C9),
      title: AppColors.textPrimary,
    ),
    DailyTaskType.difficult => (
      background: const Color(0xFFFFF0F4),
      border: const Color(0xFFF1CCDA),
      iconBackground: const Color(0xFFF9DDE6),
      icon: const Color(0xFFC65375),
      title: AppColors.textPrimary,
    ),
  };
}

// Kept as a visual fallback for future learning-filter variants.
// ignore: unused_element
class _EmptyDailyCard extends StatelessWidget {
  const _EmptyDailyCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _EmptyWelcomePanel(),
        SizedBox(height: 18),
        _EmptyStartActions(),
      ],
    );
  }
}

class _EmptyWelcomePanel extends StatelessWidget {
  const _EmptyWelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xF7FFFFFF), Color(0xF0F2F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x1211397A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2426448B),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 142, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            context.l10n.text('homeJourneyStart'),
                            style: const TextStyle(
                              color: Color(0xFF0F57DF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.text('homeNoWordsTitle'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            height: 1.02,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.text('homeNoWordsBody'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -24,
                  bottom: -25,
                  width: 186,
                  child: Image.asset(
                    'assets/images/leximon-owl-wave.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const Positioned(top: 7, right: 12, child: _MascotSpeech()),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const _EmptyMissionCard(),
        ],
      ),
    );
  }
}

class _MascotSpeech extends StatelessWidget {
  const _MascotSpeech();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
          bottomLeft: Radius.circular(17),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C031F52),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('hello'),
            style: const TextStyle(
              color: Color(0xFF173661),
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.text('homeMascotStart'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMissionCard extends StatelessWidget {
  const _EmptyMissionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6D9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFFEFBA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC928), Color(0xFFFFB520)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('homeDayOneGoal'),
                      style: const TextStyle(
                        color: Color(0xFF96711B),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.text('homeLearnFirstEight'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.text('homeZeroOfEight'),
                      style: const TextStyle(
                        color: Color(0xFF7D8796),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E7C7),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStartActions extends StatelessWidget {
  const _EmptyStartActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EmptyActionCard(
            primary: true,
            icon: Icons.play_arrow_rounded,
            eyebrow: context.l10n.text('startNow'),
            title: context.l10n.text('taskLearnNewWords'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EmptyActionCard(
            icon: Icons.sync_rounded,
            eyebrow: context.l10n.text('notAvailable'),
            title: context.l10n.text('homeReviewWordsTitle'),
          ),
        ),
      ],
    );
  }
}

class _EmptyActionCard extends StatelessWidget {
  const _EmptyActionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.primary = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: primary
            ? const LinearGradient(
                colors: [Color(0xFFFFBF21), Color(0xFFFF9E14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: primary ? null : const Color(0xFFF3F6FB),
        border: Border.all(
          color: primary ? const Color(0x80FFC928) : const Color(0xFFE1E8F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F174295),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary
                  ? const Color(0x2EFFFFFF)
                  : const Color(0xFFE3E9F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : const Color(0xFF9AA8BB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: primary
                        ? const Color(0xE6FFFFFF)
                        : const Color(0xFF9AA8BB),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: primary ? Colors.white : const Color(0xFF8C9AAF),
                    fontSize: 15,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
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

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              hintText: context.l10n.text('homeSearchHint'),
              hintStyle: const TextStyle(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Semantics(
          button: true,
          label: context.l10n.text('homeOpenTopicFilters'),
          child: SizedBox(
            width: 46,
            height: 46,
            child: IconButton(
              onPressed: onFilterTap,
              padding: EdgeInsets.zero,
              splashRadius: 23,
              icon: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1658D3), Color(0xFF2481FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332F80ED),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.selected, this.onSelected});
  final String selected;
  final ValueChanged<String>? onSelected;

  static const _labels = [
    'topicFilterAll',
    'topicFilterLearning',
    'topicFilterNotStarted',
    'topicFilterCompleted',
  ];
  static final _chipKeys = List<GlobalKey>.generate(
    _labels.length,
    (_) => GlobalKey(),
  );

  void _scrollToChip(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipContext = _chipKeys[index].currentContext;
      if (chipContext == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: .5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _labels.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: _chipKeys[index],
              label: Text(context.l10n.text(label)),
              selected: selected == label,
              onSelected: (_) {
                ref.read(selectedTopicFilterProvider.notifier).state = label;
                onSelected?.call(label);
                _scrollToChip(index);
              },
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected == label
                    ? Colors.white
                    : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: selected == label
                    ? AppColors.primary
                    : const Color(0xFFD8E3F1),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics, required this.progressByTopicId});
  final List<Topic> topics;
  final Map<int, double> progressByTopicId;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          context.l10n.text('homeNoMatchingTopics'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 84,
      ),
      itemBuilder: (context, index) => TopicCard(
        topic: topics[index],
        progress: progressByTopicId[topics[index].id] ?? 0,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TopicDetailScreen(topic: topics[index]),
          ),
        ),
      ),
    );
  }
}
