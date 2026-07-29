import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';
import '../topic_detail/topic_detail_screen.dart';
import '../word_study/word_study_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showAllTopics = false;

  @override
  void dispose() {
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
            padding: EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: _LearningHeader(),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  sliver: SliverToBoxAdapter(child: const _DailyCard()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                      child: Column(
                        children: [
                          const SectionHeader(
                            kicker: 'Thư viện từ vựng',
                            title: 'Chọn chủ đề để học',
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
                            error: (error, stack) => const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Không thể tải chủ đề.'),
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
                                            ? 'Thu gọn'
                                            : 'Xem tất cả ${topicPool.length} chủ đề',
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
                                          fontFamily: 'Be Vietnam Pro',
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
                                        size: 18,
                                      ),
                                      label: const Text('Thiết lập thêm topic'),
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
                                          fontFamily: 'Be Vietnam Pro',
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
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverToBoxAdapter(child: _QuickPractice()),
                ),
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
          filter == 'Tất cả' ||
          (filter == 'Đang học' && progress > 0) ||
          (filter == 'Cơ bản' && topic.order <= 10) ||
          (filter == 'Giao tiếp' &&
              topic.original.toLowerCase().contains('communication')) ||
          (filter == 'Công việc' &&
              topic.original.toLowerCase().contains('work'));
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'XIN CHÀO, HỌC GIẢ!',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .72,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Leximon',
                style: TextStyle(
                  color: Colors.white,
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
      label: 'Thông báo',
      child: GestureDetector(
        onTap: () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF173B82),
                          width: 2,
                        ),
                      ),
                    ),
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
      child: const Text(
        'Chưa thể tải nhiệm vụ hôm nay.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _DailyCardContent extends ConsumerWidget {
  const _DailyCardContent({required this.snapshot});

  final DailyCardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedTasks = snapshot.tasks.where((task) => task.isDone).length;
    final title = snapshot.isComplete
        ? 'Hẹn bạn ngày mai nhé!'
        : snapshot.isFirstLearningDay &&
              snapshot.tasks.every((task) => task.completed == 0)
        ? 'Bắt đầu học từ mới'
        : 'Học thêm một chút hôm nay';
    final description = snapshot.isComplete
        ? 'Bạn đã hoàn thành mọi nhiệm vụ chính.'
        : 'Mỗi ngày vài phút, vốn từ của bạn sẽ tiến xa hơn.';

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEAF3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2426448B),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: snapshot.isComplete
                      ? const Color(0xFFDDF8EE)
                      : const Color(0xFFFFF3BF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  snapshot.isComplete
                      ? '✓  Đã hoàn thành'
                      : '🔥  NHIỆM VỤ HÔM NAY',
                  style: TextStyle(
                    color: snapshot.isComplete
                        ? const Color(0xFF137E68)
                        : const Color(0xFF8B5B00),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$completedTasks / ${snapshot.tasks.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          ...snapshot.tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DailyTaskTile(
                task: task,
                showMascot:
                    task.type == DailyTaskType.learn &&
                    task.completed == 0 &&
                    !snapshot.isComplete,
                onTap: task.isDone
                    ? null
                    : () => _openTask(context, ref, task.type),
              ),
            ),
          ),
          if (snapshot.isComplete) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => _showAdditionalTasks(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm nhiệm vụ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0x29155CFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openTask(
    BuildContext context,
    WidgetRef ref,
    DailyTaskType type,
  ) async {
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
    ref.invalidate(dailyCardProvider);
    ref.invalidate(progressDashboardProvider);
  }

  Future<void> _showAdditionalTasks(BuildContext context, WidgetRef ref) async {
    final selectedType = await showModalBottomSheet<DailyTaskType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdditionalTasksSheet(types: snapshot.additionalTasks),
    );
    if (selectedType != null && context.mounted) {
      await _openTask(context, ref, selectedType);
    }
  }
}

class _DailyTaskTile extends StatelessWidget {
  const _DailyTaskTile({
    required this.task,
    required this.onTap,
    this.showMascot = false,
  });

  final DailyTaskSnapshot task;
  final VoidCallback? onTap;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final colors = _dailyTaskColors(task.type, done);
    return Semantics(
      button: onTap != null,
      label:
          '${_dailyTaskLabel(task.type)} ${task.completed} trên ${task.count}',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.iconBackground,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : _dailyTaskIcon(task.type),
                      color: colors.icon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dailyTaskLabel(task.type),
                          style: TextStyle(
                            color: colors.title,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (!done)
                          Text(
                            '${task.completed} / ${task.count} từ',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const Text(
                            'Đã hoàn thành hôm nay',
                            style: TextStyle(
                              color: Color(0xFF719187),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!done)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.icon,
                      size: 19,
                    ),
                ],
              ),
            ),
          ),
          if (showMascot)
            const Positioned(right: -24, top: -13, child: _WavingOwl(size: 72)),
        ],
      ),
    );
  }
}

class _WavingOwl extends StatefulWidget {
  const _WavingOwl({required this.size});

  final double size;

  @override
  State<_WavingOwl> createState() => _WavingOwlState();
}

class _WavingOwlState extends State<_WavingOwl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        child: Image.asset(
          'assets/images/leximon-owl-wave.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        builder: (context, child) {
          final wave = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -2.5 * wave),
            child: Transform.rotate(
              angle: (wave - .5) * .08,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _AdditionalTasksSheet extends StatelessWidget {
  const _AdditionalTasksSheet({required this.types});

  final List<DailyTaskType> types;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhiệm vụ thêm',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Hoàn thành thêm nếu bạn vẫn còn hứng học.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 15),
            ...types.map(
              (type) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEAF1FF),
                  child: Icon(
                    _dailyTaskIcon(type),
                    color: AppColors.primary,
                    size: 19,
                  ),
                ),
                title: Text(
                  _dailyTaskLabel(type),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dailyTaskLabel(DailyTaskType type) {
  switch (type) {
    case DailyTaskType.repeat:
      return 'Ôn lại từ';
    case DailyTaskType.learn:
      return 'Học từ mới';
    case DailyTaskType.train:
      return 'Luyện nhanh';
    case DailyTaskType.difficult:
      return 'Từ khó';
  }
}

IconData _dailyTaskIcon(DailyTaskType type) {
  switch (type) {
    case DailyTaskType.repeat:
      return Icons.sync_rounded;
    case DailyTaskType.learn:
      return Icons.lightbulb_outline_rounded;
    case DailyTaskType.train:
      return Icons.bolt_rounded;
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
  return (
    background: Colors.white.withValues(alpha: .82),
    border: const Color(0x1A155CFF),
    iconBackground: const Color(0xFFEAF1FF),
    icon: AppColors.primary,
    title: AppColors.textPrimary,
  );
}

// Kept as a visual fallback for future onboarding variants.
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
                          child: const Text(
                            'Khởi động hành trình',
                            style: TextStyle(
                              color: Color(0xFF0F57DF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nhiệm vụ cho hôm nay',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bạn chưa học từ nào cả. Hãy bắt đầu với một chủ đề đầu tiên để Leximon tạo lộ trình phù hợp cho bạn.',
                          style: TextStyle(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào!',
            style: TextStyle(
              color: Color(0xFF173661),
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bắt đầu cùng mình nhé!',
            style: TextStyle(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MỤC TIÊU NGÀY 1',
                      style: TextStyle(
                        color: Color(0xFF96711B),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Học 8 từ đầu tiên',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '0 / 8 từ đã hoàn thành',
                      style: TextStyle(color: Color(0xFF7D8796), fontSize: 10),
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
        const Expanded(
          child: _EmptyActionCard(
            primary: true,
            icon: Icons.play_arrow_rounded,
            eyebrow: 'Bắt đầu ngay',
            title: 'Học từ mới',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _EmptyActionCard(
            icon: Icons.sync_rounded,
            eyebrow: 'Chưa khả dụng',
            title: 'Ôn lại từ',
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
      padding: const EdgeInsets.all(14),
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
            width: 48,
            height: 48,
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
              size: 22,
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
                    fontWeight: FontWeight.w900,
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
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              hintText: 'Tìm chủ đề hoặc từ vựng',
              hintStyle: TextStyle(fontSize: 11),
              contentPadding: EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Semantics(
          button: true,
          label: 'Mở bộ lọc chủ đề',
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
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const labels = ['Tất cả', 'Đang học', 'Cơ bản', 'Giao tiếp', 'Công việc'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels
            .map(
              (label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected == label,
                  onSelected: (_) {
                    ref.read(selectedTopicFilterProvider.notifier).state =
                        label;
                    onSelected?.call(label);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceSoft,
                  labelStyle: TextStyle(
                    color: selected == label
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide.none,
                ),
              ),
            )
            .toList(),
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
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Không có chủ đề phù hợp.',
          style: TextStyle(color: AppColors.textSecondary),
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

class _QuickPractice extends StatelessWidget {
  const _QuickPractice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x19155CFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF9EF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.sync_rounded, color: Color(0xFF137E68)),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ôn nhanh hôm nay',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '4 từ sắp quên • khoảng 2 phút',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
