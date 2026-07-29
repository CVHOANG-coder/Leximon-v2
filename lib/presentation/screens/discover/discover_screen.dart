import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/topic.dart';
import '../../../data/models/vocabulary_collection.dart';
import '../../../data/services/progress_dashboard_service.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';
import '../vocabulary_collection/vocabulary_collection_screen.dart';

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
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            sliver: const SliverToBoxAdapter(child: _ProgressHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _ProgressHero(
                dashboard: dashboard,
                totalWords: totalWords,
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
                      body: 'Những từ bạn thường nhầm hoặc mất nhiều thời gian',
                      color: AppColors.orange,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dashboard.weekSessionCount} phiên học',
                                  style: TextStyle(fontWeight: FontWeight.w800),
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
                    const SectionHeader(
                      kicker: 'Learning map',
                      title: 'Bản đồ tiến độ chủ đề',
                      action: 'Tất cả chủ đề',
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
                              progress: progressByTopicId[entry.value.id] ?? 0,
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
                              style: TextStyle(fontWeight: FontWeight.w800),
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
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hành trình của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Theo dõi tiến độ theo cách trực quan hơn, nhiều động lực hơn.',
                style: TextStyle(
                  color: Color(0xFFDCEBFF),
                  fontSize: 11,
                  height: 1.4,
                ),
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
  const _ProgressHero({required this.dashboard, required this.totalWords});

  final ProgressDashboardSnapshot dashboard;
  final int totalWords;

  @override
  Widget build(BuildContext context) {
    return LeximonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG QUAN TUẦN NÀY',
                      style: TextStyle(
                        color: Color(0xFF7990B0),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Theo dõi vốn từ',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Báo cáo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ProgressCard(dashboard: dashboard)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _SmallStat(
                      icon: '🔥',
                      title: '${dashboard.currentStreak} ngày',
                      body: 'Chuỗi học liên tiếp',
                      color: Color(0xFFFFF0D8),
                    ),
                    SizedBox(height: 10),
                    _SmallStat(
                      icon: '📘',
                      title: '${dashboard.progressedWords} từ',
                      body: 'Đã có tiến độ',
                      color: Color(0xFFDDF9EF),
                    ),
                    SizedBox(height: 10),
                    _SmallStat(
                      icon: '⚡',
                      title: '${dashboard.weekSessionCount} phiên',
                      body: 'Đã hoàn thành tuần này',
                      color: Color(0xFFFFF5C9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalWords từ đang có trong thư viện Leximon',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.dashboard});

  final ProgressDashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF1D8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x361258FF),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: dashboard.overallProgress,
                    strokeWidth: 13,
                    backgroundColor: Color(0x2BFFFFFF),
                    valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${dashboard.progressedWords}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'TỪ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(dashboard.overallProgress * 100).round()}% vốn từ đã tiến bộ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          ProgressLine(value: dashboard.overallProgress, dark: true),
          const SizedBox(height: 7),
          Text(
            '${dashboard.masteredWords} từ đã học hoàn tất',
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  final String icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    height: 1.2,
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

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.title,
    required this.value,
    required this.body,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String value;
  final String body;
  final Color color;
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
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
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
                  fontWeight: FontWeight.w900,
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
        AppColors.surfaceSoft,
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
      AppColors.surfaceSoft,
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
              ),
            ),
          )
          .toList(),
    );
  }
}
