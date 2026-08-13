import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/topic.dart';
import '../../../data/models/vocabulary_collection.dart';
import '../../../data/services/progress_dashboard_service.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../presentation/widgets/streak_indicator.dart';
import '../../../shared/providers/app_providers.dart';
import '../vocabulary_collection/vocabulary_collection_screen.dart';
import '../word_study/word_study_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider).valueOrNull ?? const <Topic>[];
    final totalWords = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.wordCount,
    );
    final progressByTopicId =
        ref.watch(topicProgressProvider).valueOrNull ?? const <int, double>{};
    final dashboard =
        ref.watch(progressDashboardProvider).valueOrNull ??
        ProgressDashboardSnapshot.empty();
    final collection = ref.watch(vocabularyCollectionProvider).valueOrNull;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: _ProgressHeader(),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverToBoxAdapter(
                    child: _ProgressHero(
                      dashboard: dashboard,
                      totalWords: totalWords,
                      onOpenVocabulary: topics.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      WordStudyScreen(topic: topics.first),
                                ),
                              );
                            },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      child: Column(
                        children: [
                          const SectionHeader(
                            kicker: 'Mastery board',
                            title: 'Phân tầng vốn từ',
                            action: 'Xem chi tiết',
                          ),
                          const SizedBox(height: 16),
                          _MasteryCard(
                            title: 'Đã nắm chắc',
                            value:
                                '${collection?.countFor(VocabularyCollectionStatus.mastered) ?? 0}',
                            body: 'Từ đã đúng nhiều lần và nhớ ổn định',
                            color: AppColors.green,
                            icon: Icons.star_rounded,
                            onTap: () => _openCollection(
                              context,
                              VocabularyCollectionStatus.mastered,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MasteryCard(
                            title: 'Đang ôn',
                            value:
                                '${collection?.countFor(VocabularyCollectionStatus.reviewing) ?? 0}',
                            body: 'Cần lặp lại theo lịch SRS trong 2 ngày tới',
                            color: AppColors.primary,
                            icon: Icons.autorenew_rounded,
                            onTap: () => _openCollection(
                              context,
                              VocabularyCollectionStatus.reviewing,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MasteryCard(
                            title: 'Cần luyện thêm',
                            value:
                                '${collection?.countFor(VocabularyCollectionStatus.needsPractice) ?? 0}',
                            body:
                                'Những từ bạn thường nhầm hoặc mất nhiều thời gian',
                            color: AppColors.orange,
                            icon: Icons.track_changes_rounded,
                            onTap: () => _openCollection(
                              context,
                              VocabularyCollectionStatus.needsPractice,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      child: Column(
                        children: [
                          const SectionHeader(
                            kicker: 'Rhythm tracker',
                            title: 'Nhịp học 7 ngày',
                            action: 'Theo tuần',
                          ),
                          const SizedBox(height: 18),
                          _ActivityChart(values: dashboard.weekActivityRatios),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${dashboard.weekSessionCount} phiên học',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${dashboard.weekActivityTotal} lượt từ được ghi nhận trong tuần này.',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  dashboard.currentStreak > 0
                                      ? 'Giữ chuỗi'
                                      : 'Bắt đầu học',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      child: Column(
                        children: [
                          SectionHeader(
                            kicker: 'Learning map',
                            title: 'Bản đồ tiến độ chủ đề',
                            action: 'Tất cả chủ đề',
                            onAction: topics.isEmpty
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => WordStudyScreen(
                                          topic: topics.first,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          if (topics.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            )
                          else
                            ...topics
                                .take(4)
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (entry) => _JourneyItem(
                                    index: entry.key,
                                    topic: entry.value,
                                    progress:
                                        progressByTopicId[entry.value.id] ?? 0,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  sliver: SliverToBoxAdapter(
                    child: LeximonSurface(
                      child: Column(
                        children: [
                          SectionHeader(
                            kicker: 'Monthly pulse',
                            title: 'Dấu chân tháng này',
                            action: dashboard.monthLabel,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${dashboard.activeDaysThisMonth} ngày hoạt động',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Bạn bỏ lỡ ${dashboard.missedDaysThisMonth} ngày trong tháng này.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              _HeatLegend(),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _Heatmap(values: dashboard.monthActivityLevels),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCollection(
    BuildContext context,
    VocabularyCollectionStatus status,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyCollectionScreen(status: status),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BẢNG ĐIỀU KHIỂN HỌC TẬP',
                style: TextStyle(
                  color: Color(0xFF52739A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hành trình của bạn',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Theo dõi tiến độ theo cách trực quan hơn, nhiều động lực hơn.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const OwlAvatar(size: 76, radius: 24),
      ],
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.dashboard,
    required this.totalWords,
    this.onOpenVocabulary,
  });

  final ProgressDashboardSnapshot dashboard;
  final int totalWords;
  final VoidCallback? onOpenVocabulary;

  @override
  Widget build(BuildContext context) {
    final libraryWords = dashboard.totalWords > 0
        ? dashboard.totalWords
        : totalWords;

    return LeximonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIẾN ĐỘ TUẦN NÀY',
                      style: TextStyle(
                        color: Color(0xFF7990B0),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Vốn từ của bạn',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Báo cáo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressCard(dashboard: dashboard, totalWords: libraryWords),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeeklyMetric(
                  iconAsset: streakIconAsset,
                  value: '${dashboard.currentStreak}',
                  label: streakLabel,
                  accent: streakAccentColor,
                  background: streakBackgroundColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeeklyMetric(
                  iconAsset: 'assets/svgs/book.svg',
                  value: '${dashboard.masteredWords}',
                  label: 'Đã thuộc',
                  accent: AppColors.primary,
                  background: const Color(0xFFEEF3FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeeklyMetric(
                  iconAsset: 'assets/svgs/thunder.svg',
                  value: '${dashboard.weekSessionCount}',
                  label: 'Phiên tuần',
                  accent: const Color(0xFFE6A600),
                  background: const Color(0xFFFFF8E3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF5F8FD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('open-vocabulary-library'),
              onTap: onOpenVocabulary,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/svgs/word.svg',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Kho từ vựng  ',
                          children: [
                            TextSpan(
                              text: '$libraryWords từ',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.dashboard, required this.totalWords});

  final ProgressDashboardSnapshot dashboard;
  final int totalWords;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33155CFF),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          key: const Key('progress-card-banner'),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/card_progress_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .16,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: .18,
                                        ),
                                      ),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/svgs/word_learn_done.svg',
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Expanded(
                                    child: Text(
                                      'VỐN TỪ ĐÃ TIẾN BỘ',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFFDCEAFF),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  text: '${dashboard.progressedWords}',
                                  children: const [
                                    TextSpan(
                                      text: ' từ',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.4,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${dashboard.masteredWords} từ đã thuộc hoàn toàn',
                                style: const TextStyle(
                                  color: Color(0xFFC7DCFF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: CircularProgressIndicator(
                                      key: const Key(
                                        'vocabulary-progress-ring',
                                      ),
                                      value: dashboard.overallProgress,
                                      strokeWidth: 9,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor: const Color(0x44FFFFFF),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFFE6FFF1),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 68,
                                      child: FittedBox(
                                        key: const Key(
                                          'vocabulary-progress-percentage',
                                        ),
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${(dashboard.overallProgress * 100).toStringAsFixed(2)}%',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'TỔNG',
                                      style: TextStyle(
                                        color: Color(0xFFD9EFFF),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ProgressLine(value: dashboard.overallProgress, dark: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${dashboard.progressedWords}/$totalWords',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'từ trong lộ trình',
                            style: TextStyle(
                              color: Color(0xFFBFD6FF),
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const Text(
                          'Keep going!',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyMetric extends StatelessWidget {
  const _WeeklyMetric({
    required this.iconAsset,
    required this.value,
    required this.label,
    required this.accent,
    required this.background,
  });

  final String iconAsset;
  final String value;
  final String label;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 10, 8, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              iconAsset,
              key: ValueKey(iconAsset),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.title,
    required this.value,
    required this.body,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String value;
  final String body;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: .2),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.values});

  final List<double> values;
  static const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          values.length,
          (index) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 24,
                    height: 90 * values[index],
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: LinearGradient(
                        colors: index == values.length - 1
                            ? [AppColors.primary, AppColors.cyan]
                            : [
                                const Color(0xFFCFE0FF),
                                const Color(0xFF8EB7FF),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyItem extends StatelessWidget {
  const _JourneyItem({
    required this.index,
    required this.topic,
    required this.progress,
  });
  final int index;
  final Topic topic;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progress > 0 ? AppColors.primary : AppColors.surfaceSoft,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: progress > 0 ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.translated,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(topic.wordCount * progress).round()} / ${topic.wordCount} từ • ${progress > .5 ? 'đang học' : 'nên quay lại ôn'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 7),
                ProgressLine(value: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final color in [
        const Color(0xFFE1E9F4),
        const Color(0xFFB8D0FF),
        AppColors.primary,
      ]) ...[
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: color == const Color(0xFFE1E9F4)
                ? Border.all(color: const Color(0xFFCFDAE9))
                : null,
          ),
        ),
        const SizedBox(width: 2),
      ],
    ],
  );
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFE1E9F4),
      Color(0xFFD6E4FF),
      Color(0xFF8EB7FF),
      AppColors.primary,
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      children: values
          .map(
            (level) => Container(
              decoration: BoxDecoration(
                color: colors[level],
                borderRadius: BorderRadius.circular(4),
                border: level == 0
                    ? Border.all(color: const Color(0xFFCFDAE9))
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}
