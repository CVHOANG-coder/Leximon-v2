import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/daily_notification_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/models/topic.dart';
import '../../../data/services/profile_statistics_service.dart';
import '../../../presentation/widgets/app_dialog.dart';
import 'edit_profile_screen.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../presentation/widgets/streak_indicator.dart';
import '../../../shared/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({this.onViewProgress, super.key});

  final VoidCallback? onViewProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsState = ref.watch(topicsProvider);
    final topics = topicsState.valueOrNull ?? const <Topic>[];
    final selectedTopicOrders = ref.watch(selectedTopicOrdersProvider);
    final statistics = ref.watch(profileStatisticsProvider).valueOrNull;
    final dashboard = ref.watch(progressDashboardProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final topicWordCount = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.wordCount,
    );
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: _ProfileHeader(
              onEditProfile: () => _openEditProfile(context, profile),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverToBoxAdapter(
                    child: _ProfileHero(
                      totalWords: dashboard?.totalWords ?? topicWordCount,
                      learnedWordCount: dashboard?.progressedWords,
                      currentStreak: dashboard?.currentStreak,
                      profile: profile,
                      onEditProfile: () => _openEditProfile(context, profile),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: _OverviewSection(
                      statistics: statistics,
                      trackedTopicCountFallback: selectedTopicOrders.length,
                      onViewProgress: onViewProgress,
                    ),
                  ),
                ),
                // SliverPadding(
                //   padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                //   sliver: SliverToBoxAdapter(child: _BadgeSection()),
                // ),
                // SliverPadding(
                //   padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                //   sliver: SliverToBoxAdapter(child: _GoalsSection()),
                // ),
                // SliverPadding(
                //   padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                //   sliver: SliverToBoxAdapter(
                //     child: _FavoritesSection(
                //       favorites: favorites,
                //       progressByTopic: progressByTopic,
                //       isLoading: topicsState.isLoading,
                //     ),
                //   ),
                // ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  sliver: SliverToBoxAdapter(child: _SettingsSection()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context, UserProfileRow? profile) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEditProfile});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.profileEyebrow,
                style: TextStyle(
                  color: Color(0xFF52739A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.profileTitle,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(height: 10),
              Text(
                context.l10n.profileSubtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEditProfile,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: .9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x142A70B8),
                    blurRadius: 16,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.path,
    required this.size,
    required this.radius,
  });

  final String? path;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = path == null
        ? Image.asset('assets/images/leximon-owl.png', fit: BoxFit.cover)
        : Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/images/leximon-owl.png', fit: BoxFit.cover),
          );

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D75FF), Color(0xFF064EE0)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x361258FF),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: image,
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.totalWords,
    required this.learnedWordCount,
    required this.currentStreak,
    required this.profile,
    required this.onEditProfile,
  });
  final int totalWords;
  final int? learnedWordCount;
  final int? currentStreak;
  final UserProfileRow? profile;
  final VoidCallback onEditProfile;

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
                  _ProfileAvatar(
                    path: profile?.avatarPath,
                    size: 84,
                    radius: 28,
                  ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explorer Lv.0',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      profile?.name ?? 'Leximon',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      profile?.email ?? 'hello@leximon.app',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEditProfile,
                child: Text(context.l10n.text('edit')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Container(
          //   padding: const EdgeInsets.all(14),
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(22),
          //     gradient: const LinearGradient(
          //       colors: [
          //         AppColors.primaryDark,
          //         AppColors.primary,
          //         AppColors.cyan,
          //       ],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //     boxShadow: const [
          //       BoxShadow(
          //         color: Color(0x361258FF),
          //         blurRadius: 16,
          //         offset: Offset(0, 8),
          //       ),
          //     ],
          //   ),
          //   child: const Column(
          //     children: [
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text(
          //             '1.248 XP',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontSize: 21,
          //               fontWeight: FontWeight.w800,
          //             ),
          //           ),
          //           SizedBox(width: 8),
          //           Expanded(
          //             child: Text(
          //               '752 XP nữa để lên hạng Master Explorer',
          //               textAlign: TextAlign.right,
          //               style: TextStyle(color: Colors.white70, fontSize: 9),
          //             ),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: 10),
          //       ProgressLine(value: .62, dark: true),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                iconAsset: streakIconAsset,
                value: currentStreak?.toString() ?? '—',
                label: context.l10n.text('streakDaysLabel'),
              ),
              const SizedBox(width: 9),
              _HeroStat(
                iconAsset: 'assets/svgs/word.svg',
                value: '$totalWords',
                label: context.l10n.text('profileLibraryWords'),
              ),
              const SizedBox(width: 9),
              _HeroStat(
                iconAsset: 'assets/svgs/word_learn_done.svg',
                value: learnedWordCount?.toString() ?? '—',
                label: context.l10n.text('profileLearnedWords'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.iconAsset,
    required this.value,
    required this.label,
  });
  final String iconAsset;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .82)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24144099),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconAsset,
            key: ValueKey(iconAsset),
            width: 36,
            height: 36,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
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
    this.onViewProgress,
  });

  final ProfileStatisticsSnapshot? statistics;
  final int trackedTopicCountFallback;
  final VoidCallback? onViewProgress;

  @override
  Widget build(BuildContext context) {
    final trackedTopicCount =
        statistics?.trackedTopicCount ?? trackedTopicCountFallback;
    final weekAccuracy = statistics?.weekAccuracy;
    final accuracyLabel = statistics == null
        ? '—'
        : weekAccuracy == null
        ? context.l10n.text('noDataShort')
        : '${(weekAccuracy * 100).round()}%';

    return LeximonSurface(
      child: Column(
        children: [
          SectionHeader(
            kicker: 'Quick overview',
            title: context.l10n.text('profileOverviewTitle'),
            action: context.l10n.text('profileViewProgress'),
            onAction: onViewProgress,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  iconAsset: 'assets/svgs/book.svg',
                  title: context.l10n.text(
                    'topicCount',
                    values: {'count': trackedTopicCount},
                  ),
                  body: context.l10n.text('profileTracking'),
                  color: AppColors.surfaceBlue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  iconAsset: 'assets/svgs/target.svg',
                  title: accuracyLabel,
                  body: context.l10n.text('profileWeeklyAccuracy'),
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
    required this.iconAsset,
    required this.title,
    required this.body,
    required this.color,
  });
  final String iconAsset;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white.withValues(alpha: .75)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F144099),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(iconAsset, width: 40, height: 40),
        const SizedBox(height: 8),
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
        ? context.l10n.text('profileCalculating')
        : _formatAverageUsage(
            context,
            statistics!.averageDailyUsage,
            usageDayCount,
          );
    final detail = statistics == null
        ? context.l10n.text('profileCalculatingUsage')
        : usageDayCount == 0
        ? context.l10n.text('profileUsageStartsNow')
        : context.l10n.text(
            'profileUsageAverageDays',
            values: {'count': usageDayCount},
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F144099),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/svgs/time.svg', width: 40, height: 40),
          const SizedBox(width: 12),
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

String _formatAverageUsage(
  BuildContext context,
  Duration duration,
  int usageDayCount,
) {
  if (usageDayCount == 0) return context.l10n.text('noData');
  final minutes = duration.inMinutes;
  if (minutes < 1) {
    return context.l10n.text('minutesPerDay', values: {'count': '< 1'});
  }
  if (minutes < 60) {
    return context.l10n.text('minutesPerDay', values: {'count': minutes});
  }
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) {
    return context.l10n.text('hoursPerDay', values: {'count': hours});
  }
  return context.l10n.text(
    'hoursMinutesPerDay',
    values: {'hours': hours, 'minutes': remainingMinutes},
  );
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        SectionHeader(
          kicker: 'Achievements',
          title: context.l10n.text('profileBadgesTitle'),
          action: context.l10n.text('profileBadgeCollection'),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _BadgeCard(
                icon: '🏆',
                title: '7-Day Streak',
                body: context.l10n.text('profileBadgeStreakBody'),
                color: AppColors.yellow,
              ),
              const SizedBox(width: 10),
              _BadgeCard(
                icon: '🚀',
                title: 'Speed Learner',
                body: context.l10n.text('profileBadgeSpeedBody'),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _BadgeCard(
                icon: '🔒',
                title: 'Boss Hunter',
                body: context.l10n.text('profileBadgeBossBody'),
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
        SectionHeader(
          kicker: 'Goals',
          title: context.l10n.text('profileGoalsTitle'),
          action: context.l10n.text('edit'),
        ),
        const SizedBox(height: 15),
        _GoalItem(
          title: context.l10n.text('profileDailyWordGoal'),
          body: context.l10n.text('profileDailyWordProgress'),
          value: .67,
        ),
        const SizedBox(height: 14),
        _GoalItem(
          title: context.l10n.text('profileWeeklySessionGoal'),
          body: context.l10n.text('profileWeeklySessionProgress'),
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
        SectionHeader(
          kicker: 'Saved topics',
          title: context.l10n.text('profileTrackedTopicsTitle'),
          action: context.l10n.text('profileWordLibrary'),
        ),
        const SizedBox(height: 14),
        if (favorites.isEmpty)
          Text(
            context.l10n.text(
              isLoading ? 'profileLoadingTopics' : 'profileNoTrackedTopics',
            ),
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
                  context.l10n.text(
                    'topicWordProgress',
                    values: {
                      'completed': (topic.wordCount * progress).round(),
                      'total': topic.wordCount,
                      'percent': (progress * 100).round(),
                    },
                  ),
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

class _SettingsSection extends StatefulWidget {
  const _SettingsSection();

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection>
    with WidgetsBindingObserver {
  static const _pronunciationKey = 'profile.pronunciation_enabled';
  static const _listeningKey = 'profile.listening_enabled';
  static const _dailyReminderEnabledKey = 'profile.daily_reminder_enabled';
  static const _dailyReminderHourKey = 'profile.daily_reminder_hour';
  static const _dailyReminderMinuteKey = 'profile.daily_reminder_minute';

  final SpeechToText _speechToText = SpeechToText();
  SharedPreferences? _preferences;
  bool _pronunciationEnabled = true;
  bool _listeningEnabled = true;
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _hasMicPermission = false;
  bool _isLoading = true;
  bool _isPronunciationUpdating = false;
  bool _isDailyReminderUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadSettings());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshMicPermission());
    }
  }

  Future<void> _loadSettings() async {
    SharedPreferences? preferences;
    var hasMicPermission = false;
    try {
      preferences = await SharedPreferences.getInstance();
      hasMicPermission = await _speechToText.hasPermission;
    } on Object {
      // A freshly added native plugin can be unavailable until the app is
      // fully restarted. Keep the defaults and avoid crashing the screen.
    }
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _pronunciationEnabled = preferences?.getBool(_pronunciationKey) ?? true;
      _listeningEnabled = preferences?.getBool(_listeningKey) ?? true;
      _dailyReminderEnabled =
          preferences?.getBool(_dailyReminderEnabledKey) ?? false;
      _dailyReminderTime = TimeOfDay(
        hour: preferences?.getInt(_dailyReminderHourKey) ?? 20,
        minute: preferences?.getInt(_dailyReminderMinuteKey) ?? 0,
      );
      _hasMicPermission = hasMicPermission;
      _isLoading = false;
    });
  }

  Future<void> _refreshMicPermission() async {
    bool hasMicPermission;
    try {
      hasMicPermission = await _speechToText.hasPermission;
    } on Object {
      hasMicPermission = false;
    }
    if (!mounted) return;
    setState(() => _hasMicPermission = hasMicPermission);
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    } on Object {
      // Keep the UI responsive if the native preferences channel is not
      // available during a hot reload or a partial app restart.
    }
  }

  Future<void> _setListeningEnabled(bool enabled) async {
    setState(() => _listeningEnabled = enabled);
    await _saveSetting(_listeningKey, enabled);
  }

  Future<void> _setDailyReminderEnabled(bool enabled) async {
    if (_isDailyReminderUpdating) return;
    final localizations = context.l10n;
    if (!enabled) {
      setState(() {
        _dailyReminderEnabled = false;
        _isDailyReminderUpdating = true;
      });
      await _saveSetting(_dailyReminderEnabledKey, false);
      try {
        await DailyNotificationService.instance.cancelDaily();
      } on Object {
        // Keep the preference off even if the native notification service is
        // temporarily unavailable during a hot reload.
      }
      if (mounted) setState(() => _isDailyReminderUpdating = false);
      return;
    }

    setState(() => _isDailyReminderUpdating = true);
    try {
      final permissionResult = await DailyNotificationService.instance
          .requestPermission();
      if (permissionResult != DailyNotificationPermissionResult.granted) {
        if (!mounted) return;
        setState(() => _dailyReminderEnabled = false);
        await _saveSetting(_dailyReminderEnabledKey, false);
        if (permissionResult ==
            DailyNotificationPermissionResult.permanentlyDenied) {
          await _showNotificationPermissionDialog();
        }
        return;
      }

      await DailyNotificationService.instance.scheduleDaily(
        hour: _dailyReminderTime.hour,
        minute: _dailyReminderTime.minute,
        localizations: localizations,
      );
      await _saveSetting(_dailyReminderEnabledKey, true);
      if (mounted) setState(() => _dailyReminderEnabled = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _dailyReminderEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text(
              'profileReminderEnableError',
              values: {'error': error},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDailyReminderUpdating = false);
    }
  }

  Future<void> _pickDailyReminderTime() async {
    final localizations = context.l10n;
    final TimeOfDay? pickedTime;
    if (Platform.isIOS) {
      pickedTime = await _showCupertinoTimePicker();
    } else {
      if (!mounted) return;
      pickedTime = await showTimePicker(
        context: context,
        initialTime: _dailyReminderTime,
        helpText: context.l10n.text('profileReminderTimeTitle'),
        cancelText: context.l10n.cancel,
        confirmText: context.l10n.save,
      );
    }
    final selectedTime = pickedTime;
    if (selectedTime == null || !mounted) return;

    setState(() => _dailyReminderTime = selectedTime);
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      await preferences.setInt(_dailyReminderHourKey, selectedTime.hour);
      await preferences.setInt(_dailyReminderMinuteKey, selectedTime.minute);

      if (_dailyReminderEnabled) {
        await DailyNotificationService.instance.scheduleDaily(
          hour: selectedTime.hour,
          minute: selectedTime.minute,
          localizations: localizations,
        );
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text(
              'profileReminderUpdateError',
              values: {'error': error},
            ),
          ),
        ),
      );
    }
  }

  Future<TimeOfDay?> _showCupertinoTimePicker() {
    var temporaryTime = _dailyReminderTime;
    final initialDateTime = DateTime(
      2024,
      1,
      1,
      _dailyReminderTime.hour,
      _dailyReminderTime.minute,
    );

    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 320,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.text('profileReminderTimeTitle'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.cancel),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 12),
                        onPressed: () =>
                            Navigator.of(context).pop(temporaryTime),
                        child: Text(context.l10n.save),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      primaryColor: AppColors.primary,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: initialDateTime,
                      use24hFormat: true,
                      minuteInterval: 1,
                      onDateTimeChanged: (dateTime) {
                        setModalState(() {
                          temporaryTime = TimeOfDay(
                            hour: dateTime.hour,
                            minute: dateTime.minute,
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNotificationPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.notifications_none_rounded,
        title: context.l10n.text('profileNotificationPermissionTitle'),
        message: context.l10n.text('profileNotificationPermissionBody'),
        secondaryLabel: context.l10n.later,
        onSecondary: () => Navigator.of(context).pop(),
        primaryLabel: context.l10n.openSettings,
        onPrimary: () async {
          Navigator.of(context).pop();
          await AppSettingsService.openAppSettings();
        },
      ),
    );
  }

  Future<void> _setPronunciationEnabled(bool enabled) async {
    if (_isPronunciationUpdating) return;
    if (!enabled) {
      setState(() => _pronunciationEnabled = false);
      await _saveSetting(_pronunciationKey, false);
      return;
    }

    setState(() => _isPronunciationUpdating = true);
    var hasMicPermission = false;
    try {
      hasMicPermission = await _speechToText.hasPermission;
    } on Object {
      hasMicPermission = false;
    }
    if (!hasMicPermission) {
      try {
        // initialize() requests permission when the system still allows the
        // app to show the permission prompt.
        hasMicPermission = await _speechToText.initialize();
      } on Object {
        hasMicPermission = false;
      }
    }

    if (!mounted) return;
    setState(() {
      _hasMicPermission = hasMicPermission;
      _isPronunciationUpdating = false;
    });

    if (!hasMicPermission) {
      await _showMicPermissionDialog();
      return;
    }

    setState(() => _pronunciationEnabled = true);
    await _saveSetting(_pronunciationKey, true);
  }

  Future<void> _showMicPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.mic_none_rounded,
        title: context.l10n.text('profileMicPermissionTitle'),
        message: context.l10n.text('profileMicPermissionBody'),
        secondaryLabel: context.l10n.later,
        onSecondary: () => Navigator.of(context).pop(),
        primaryLabel: context.l10n.openSettings,
        onPrimary: () async {
          Navigator.of(context).pop();
          await AppSettingsService.openAppSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pronunciationStatus = !_hasMicPermission && _pronunciationEnabled
        ? context.l10n.text('profileMicPermissionNeeded')
        : _pronunciationEnabled
        ? context.l10n.enabled
        : context.l10n.disabled;
    final dailyReminderStatus = _dailyReminderEnabled
        ? context.l10n.enabled
        : context.l10n.disabled;

    return LeximonSurface(
      child: Column(
        children: [
          SectionHeader(
            kicker: context.l10n.quickSettings,
            title: context.l10n.quickSettingsTitle,
            // action: 'Tất cả',
          ),
          const SizedBox(height: 10),
          _SettingItem(
            iconAsset: 'assets/svgs/bell.svg',
            title: context.l10n.dailyReminder,
            body: _dailyReminderEnabled
                ? context.l10n.text(
                    'profileReminderEnabledBody',
                    values: {'time': _formatTime(_dailyReminderTime)},
                  )
                : context.l10n.text('profileReminderDisabledBody'),
            status: _isLoading ? context.l10n.loading : dailyReminderStatus,
            statusColor: _dailyReminderEnabled
                ? AppColors.green
                : AppColors.textMuted,
            showTopBorder: true,
            toggleValue: _dailyReminderEnabled,
            onToggle: _setDailyReminderEnabled,
            onTap: _dailyReminderEnabled
                ? _pickDailyReminderTime
                : () => _setDailyReminderEnabled(true),
            isUpdating: _isLoading || _isDailyReminderUpdating,
          ),
          _SettingItem(
            iconAsset: 'assets/svgs/mic.svg',
            title: context.l10n.pronunciationPractice,
            body: _hasMicPermission
                ? context.l10n.text('profileMicGranted')
                : context.l10n.text('profileMicNotGranted'),
            status: _isLoading ? context.l10n.loading : pronunciationStatus,
            statusColor: _hasMicPermission ? AppColors.green : AppColors.orange,
            showTopBorder: true,
            toggleValue: _pronunciationEnabled && _hasMicPermission,
            onToggle: _setPronunciationEnabled,
            isUpdating: _isLoading || _isPronunciationUpdating,
          ),
          _SettingItem(
            iconAsset: 'assets/svgs/speaker.svg',
            title: context.l10n.listeningPractice,
            body: _listeningEnabled
                ? context.l10n.text('profileSpeakerEnabled')
                : context.l10n.text('profileSpeakerDisabled'),
            status: _isLoading
                ? context.l10n.loading
                : (_listeningEnabled
                      ? context.l10n.enabled
                      : context.l10n.disabled),
            showTopBorder: true,
            toggleValue: _listeningEnabled,
            onToggle: _setListeningEnabled,
            isUpdating: _isLoading,
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.iconAsset,
    required this.title,
    required this.body,
    this.status,
    this.statusColor = AppColors.green,
    this.showTopBorder = false,
    this.toggleValue,
    this.onToggle,
    this.onTap,
    this.isUpdating = false,
  });
  final String iconAsset;
  final String title;
  final String body;
  final String? status;
  final Color statusColor;
  final bool showTopBorder;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(top: showTopBorder ? 5 : 0),
    decoration: showTopBorder
        ? const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
          )
        : null,
    child: Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: SvgPicture.asset(iconAsset, width: 28, height: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
        subtitle: Text(
          body,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
        trailing: onToggle != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null)
                    Text(
                      status!,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Switch.adaptive(
                    key: ValueKey('profile-setting-toggle-$title'),
                    value: toggleValue ?? false,
                    onChanged: isUpdating ? null : onToggle,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              )
            : status != null
            ? Text(
                status!,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              )
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
      ),
    ),
  );
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
