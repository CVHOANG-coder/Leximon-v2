import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/topic.dart';
import '../../../data/services/profile_statistics_service.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsState = ref.watch(topicsProvider);
    final topics = topicsState.valueOrNull ?? const <Topic>[];
    final selectedTopicOrders = ref.watch(selectedTopicOrdersProvider);
    final progressByTopic =
        ref.watch(topicProgressProvider).valueOrNull ?? const <int, double>{};
    final statistics = ref.watch(profileStatisticsProvider).valueOrNull;
    final totalWords = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.wordCount,
    );
    final favorites = topics
        .where((topic) => selectedTopicOrders.contains(topic.order))
        .take(3)
        .toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            sliver: const SliverToBoxAdapter(child: _ProfileHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _ProfileHero(totalWords: totalWords),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _OverviewSection(
                statistics: statistics,
                trackedTopicCountFallback: selectedTopicOrders.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: _BadgeSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: _GoalsSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _FavoritesSection(
                favorites: favorites,
                progressByTopic: progressByTopic,
                isLoading: topicsState.isLoading,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            sliver: SliverToBoxAdapter(child: _SettingsSection()),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

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
                'PERSONAL HUB',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tôi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Quản lý hồ sơ, thành tích học tập và các thiết lập cá nhân.',
                style: TextStyle(
                  color: Color(0xFFDCEBFF),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.edit_outlined, color: Colors.white, size: 19),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.totalWords});
  final int totalWords;

  @override
  Widget build(BuildContext context) {
    return LeximonSurface(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  const OwlAvatar(size: 84, radius: 28),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explorer Lv.12',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Việt Hoàng',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '@lexi_hoang • Học viên hệ từ vựng theo chủ đề',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Đổi ảnh',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.cyan,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x361258FF),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1.248 XP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '752 XP nữa để lên hạng Master Explorer',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ProgressLine(value: .62, dark: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _HeroStat(value: '7', label: 'Ngày streak'),
              const SizedBox(width: 9),
              _HeroStat(value: '$totalWords', label: 'Từ trong thư viện'),
              const SizedBox(width: 9),
              const _HeroStat(value: '18', label: 'Energy'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
          ),
        ],
      ),
    ),
  );
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.statistics,
    required this.trackedTopicCountFallback,
  });

  final ProfileStatisticsSnapshot? statistics;
  final int trackedTopicCountFallback;

  @override
  Widget build(BuildContext context) {
    final trackedTopicCount =
        statistics?.trackedTopicCount ?? trackedTopicCountFallback;
    final weekAccuracy = statistics?.weekAccuracy;
    final accuracyLabel = statistics == null
        ? '—'
        : weekAccuracy == null
        ? 'Chưa có'
        : '${(weekAccuracy * 100).round()}%';

    return LeximonSurface(
      child: Column(
        children: [
          const SectionHeader(
            kicker: 'Quick overview',
            title: 'Tóm tắt học tập',
            action: 'Xem tiến độ',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: '📚',
                  title: '$trackedTopicCount chủ đề',
                  body: 'Đang theo dõi',
                  color: AppColors.surfaceBlue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  icon: '🎯',
                  title: accuracyLabel,
                  body: 'Độ chính xác tuần này',
                  color: Color(0xFFDDF9EF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _SummaryWide(statistics: statistics),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 21)),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    ),
  );
}

class _SummaryWide extends StatelessWidget {
  const _SummaryWide({required this.statistics});

  final ProfileStatisticsSnapshot? statistics;

  @override
  Widget build(BuildContext context) {
    final usageDayCount = statistics?.usageDayCount ?? 0;
    final value = statistics == null
        ? 'Đang tính...'
        : _formatAverageUsage(statistics!.averageDailyUsage, usageDayCount);
    final detail = statistics == null
        ? 'Đang tổng hợp thời gian sử dụng'
        : usageDayCount == 0
        ? 'Bắt đầu ghi nhận từ lần sử dụng này'
        : 'Trung bình trong $usageDayCount ngày gần nhất';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDFF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 21)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
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

String _formatAverageUsage(Duration duration, int usageDayCount) {
  if (usageDayCount == 0) return 'Chưa có dữ liệu';
  final minutes = duration.inMinutes;
  if (minutes < 1) return '< 1 phút / ngày';
  if (minutes < 60) return '$minutes phút / ngày';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) return '$hours giờ / ngày';
  return '$hours giờ $remainingMinutes phút / ngày';
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Achievements',
          title: 'Huy hiệu của bạn',
          action: 'Tủ huy hiệu',
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _BadgeCard(
                icon: '🏆',
                title: '7-Day Streak',
                body: 'Giữ chuỗi học 7 ngày',
                color: AppColors.yellow,
              ),
              SizedBox(width: 10),
              _BadgeCard(
                icon: '🚀',
                title: 'Speed Learner',
                body: '3 phiên trong 1 ngày',
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              _BadgeCard(
                icon: '🔒',
                title: 'Boss Hunter',
                body: 'Đánh bại 10 boss',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
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
  Widget build(BuildContext context) => SizedBox(
    width: 126,
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 25)),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Goals',
          title: 'Mục tiêu cá nhân',
          action: 'Chỉnh sửa',
        ),
        const SizedBox(height: 15),
        const _GoalItem(
          title: 'Hoàn thành 12 từ mới mỗi ngày',
          body: 'Hôm nay: 8 / 12 từ',
          value: .67,
        ),
        const SizedBox(height: 14),
        const _GoalItem(
          title: 'Hoàn thành 5 phiên luyện mỗi tuần',
          body: 'Tuần này: 3 / 5 phiên',
          value: .6,
          purple: true,
        ),
      ],
    ),
  );
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({
    required this.title,
    required this.body,
    required this.value,
    this.purple = false,
  });
  final String title;
  final String body;
  final double value;
  final bool purple;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: purple ? AppColors.purple : AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ProgressLine(value: value),
    ],
  );
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.favorites,
    required this.progressByTopic,
    required this.isLoading,
  });

  final List<Topic> favorites;
  final Map<int, double> progressByTopic;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Saved topics',
          title: 'Chủ đề đang theo dõi',
          action: 'Thư viện từ',
        ),
        const SizedBox(height: 14),
        if (favorites.isEmpty)
          Text(
            isLoading ? 'Đang tải chủ đề...' : 'Bạn chưa theo dõi chủ đề nào.',
            style: const TextStyle(color: AppColors.textSecondary),
          )
        else
          ...favorites.map(
            (topic) => _FavoriteItem(
              topic: topic,
              progress: progressByTopic[topic.id] ?? 0,
            ),
          ),
      ],
    ),
  );
}

class _FavoriteItem extends StatelessWidget {
  const _FavoriteItem({required this.topic, required this.progress});

  final Topic topic;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(colors: topicGradient(topic)),
            ),
            child: TopicArtwork(topic: topic, padding: 8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.translated,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(topic.wordCount * progress).round()} / ${topic.wordCount} từ • ${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Quick settings',
          title: 'Truy cập nhanh',
          action: 'Tất cả',
        ),
        const SizedBox(height: 10),
        const _SettingItem(
          icon: '🔔',
          title: 'Nhắc học hằng ngày',
          body: '20:00 mỗi tối',
          status: 'Bật',
        ),
        const _SettingItem(
          icon: '🎙️',
          title: 'Luyện phát âm',
          body: 'Micro đang được cấp quyền',
          status: 'Sẵn sàng',
        ),
        const _SettingItem(
          icon: '🌙',
          title: 'Chế độ hiển thị',
          body: 'Light theme',
        ),
      ],
    ),
  );
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.body,
    this.status,
  });
  final String icon;
  final String title;
  final String body;
  final String? status;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Text(icon, style: const TextStyle(fontSize: 22)),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
    ),
    subtitle: Text(
      body,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
    ),
    trailing: status != null
        ? Text(
            status!,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          )
        : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
  );
}
