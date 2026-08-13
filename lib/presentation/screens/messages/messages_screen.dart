import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/challenge_dashboard_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../grammar_practice/grammar_exercise_screen.dart';
import '../grammar_practice/grammar_practice_screen.dart';
import '../listening_practice/listening_exercise_screen.dart';
import '../listening_practice/listening_practice_screen.dart';
import '../pronunciation/ipa_sound_detail_screen.dart';
import '../pronunciation/pronunciation_screen.dart';
import '../reading/reading_screen.dart';
import '../speaking_practice/speaking_exercise_screen.dart';
import '../speaking_practice/speaking_practice_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak =
        ref.watch(progressDashboardProvider).valueOrNull?.currentStreak ?? 0;
    final dashboard = ref.watch(challengeDashboardProvider).valueOrNull;

    return SafeArea(
      key: const ValueKey('challenge-screen'),
      bottom: false,
      child: CustomScrollView(
        key: const ValueKey('challenge-scroll'),
        slivers: [
          SliverToBoxAdapter(child: _ChallengeHero(streak: streak)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _WeeklyGoalCard(
                dashboard: dashboard,
                onRecommendationTap: () =>
                    _openRecommendation(context, ref, dashboard),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
            sliver: SliverToBoxAdapter(
              child: _PracticeModesSection(
                dashboard: dashboard,
                onReturn: () {
                  if (context.mounted) {
                    ref.invalidate(challengeDashboardProvider);
                  }
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverToBoxAdapter(
              child: _ChallengeInsightsSection(dashboard: dashboard),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecommendation(
    BuildContext context,
    WidgetRef ref,
    ChallengeDashboardSnapshot? dashboard,
  ) async {
    final recommendation = dashboard?.recommendation;
    if (recommendation == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const ListeningPracticeScreen()),
      );
      if (!context.mounted) return;
      ref.invalidate(challengeDashboardProvider);
      return;
    }

    Widget? destination;
    switch (recommendation.skill) {
      case PracticeSkill.listening:
        final lessonId = int.tryParse(recommendation.contentId ?? '');
        if (lessonId != null &&
            recommendation.parentId != null &&
            recommendation.assetPath != null) {
          destination = ListeningExerciseScreen(
            courseId: recommendation.parentId!,
            courseIndexAsset: recommendation.assetPath!,
            lessonId: lessonId,
          );
        }
        break;
      case PracticeSkill.speaking:
        final lessonId = int.tryParse(recommendation.contentId ?? '');
        if (lessonId != null &&
            recommendation.parentId != null &&
            recommendation.assetPath != null) {
          destination = SpeakingExerciseScreen(
            courseId: recommendation.parentId!,
            courseIndexAsset: recommendation.assetPath!,
            lessonId: lessonId,
          );
        }
        break;
      case PracticeSkill.grammar:
        final packs = await ref.read(grammarPacksProvider.future);
        final packContent = packs
            .where((pack) => pack.id == recommendation.parentId)
            .firstOrNull;
        final topicId = int.tryParse(recommendation.contentId ?? '');
        final topicContent = packContent?.topics
            .where((topic) => topic.id == topicId)
            .firstOrNull;
        if (packContent != null && topicContent != null) {
          destination = GrammarExerciseScreen(
            pack: GrammarPack.fromContent(packContent),
            topic: GrammarTopic.fromContent(topicContent),
          );
        }
        break;
      case PracticeSkill.pronunciation:
        final sounds = await ref.read(ipaSoundsProvider.future);
        final sound = sounds
            .where((item) => item.symbol == recommendation.contentId)
            .firstOrNull;
        if (sound != null) destination = IpaSoundDetailScreen(sound: sound);
        break;
      case PracticeSkill.reading:
        final stories = await ref.read(readingStoriesProvider.future);
        final storyId = int.tryParse(recommendation.contentId ?? '');
        final story = stories.where((item) => item.id == storyId).firstOrNull;
        if (story != null) destination = ReadingDetailScreen(story: story);
        break;
    }
    destination ??= switch (recommendation.skill) {
      PracticeSkill.listening => const ListeningPracticeScreen(),
      PracticeSkill.speaking => const SpeakingPracticeScreen(),
      PracticeSkill.grammar => const GrammarPracticeScreen(),
      PracticeSkill.pronunciation => const PronunciationScreen(),
      PracticeSkill.reading => const ReadingScreen(),
    };
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => destination!));
    if (!context.mounted) return;
    ref
      ..invalidate(challengeDashboardProvider)
      ..invalidate(progressDashboardProvider)
      ..invalidate(grammarPacksProvider);
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 26,
                left: 21,
                child: Text(
                  'THỬ THÁCH MỖI NGÀY',
                  style: TextStyle(
                    color: const Color(0xFF52749E),
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
              Positioned(
                top: 57,
                left: 21,
                width: compact ? 205 : 245,
                child: Text(
                  'Thử thách mỗi ngày',
                  style: TextStyle(
                    color: const Color(0xFF092F75),
                    fontSize: compact ? 27 : 31,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              Positioned(
                left: 21,
                bottom: 31,
                width: compact ? 205 : 252,
                child: Text(
                  'Rèn đủ 5 kỹ năng, tiến bộ đều mỗi ngày.',
                  maxLines: compact ? 2 : 1,
                  style: TextStyle(
                    color: const Color(0xFF6683A8),
                    fontSize: compact ? 10 : 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                right: compact ? -12 : -5,
                bottom: -2,
                width: compact ? 150 : 174,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/owls/owl_challenge.png',
                    key: const ValueKey('challenge-owl'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 17,
                right: 18,
                child: _StreakBadge(streak: streak),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: .82)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12285D9B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 26, height: 1)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak ngày',
                style: const TextStyle(
                  color: Color(0xFF0A3274),
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'liên tiếp',
                style: TextStyle(
                  color: Color(0xFF7188A8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({
    required this.dashboard,
    required this.onRecommendationTap,
  });

  final ChallengeDashboardSnapshot? dashboard;
  final VoidCallback onRecommendationTap;

  @override
  Widget build(BuildContext context) {
    final completed = dashboard?.weekCompleted ?? 0;
    final goal = dashboard?.weekGoal ?? ChallengeDashboardService.weekGoal;
    final remaining = (goal - completed).clamp(0, goal);
    final progress = dashboard?.weekProgress ?? 0;
    final progressPercent = (progress * 100).round();
    final recommendation = dashboard?.recommendation;
    final recommendationColor = _skillColor(recommendation?.skill);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .91),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A154D94),
            blurRadius: 34,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MỤC TIÊU TUẦN NÀY',
                      style: TextStyle(
                        color: Color(0xFF60799C),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed / $goal phiên luyện',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF071D49),
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      remaining == 0
                          ? 'Bạn đã hoàn thành mục tiêu tuần này'
                          : 'Còn $remaining phiên để hoàn thành mục tiêu tuần này',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7187A5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProgressRing(
                value: progress,
                color: const Color(0xFF2168ED),
                size: 67,
                label: '$progressPercent%',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RoundedProgressBar(value: progress, color: const Color(0xFF2168ED)),
          const SizedBox(height: 16),
          Material(
            color: const Color(0xFFF2F6FC),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('weekly-recommendation-action'),
              onTap: onRecommendationTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _skillIcon(recommendation?.skill),
                        color: recommendationColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GỢI Ý TIẾP THEO',
                            style: TextStyle(
                              color: Color(0xFF758BA8),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation?.title ?? 'Đang tìm bài phù hợp…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF092857),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (recommendation != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              recommendation.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF758BA8),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${recommendation?.durationMinutes ?? 5} phút',
                      style: const TextStyle(
                        color: Color(0xFF7288A6),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7890AF),
                      size: 20,
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

  IconData _skillIcon(PracticeSkill? skill) => switch (skill) {
    PracticeSkill.grammar => Icons.account_tree_rounded,
    PracticeSkill.speaking => Icons.mic_rounded,
    PracticeSkill.pronunciation => Icons.record_voice_over_rounded,
    PracticeSkill.reading => Icons.menu_book_rounded,
    _ => Icons.headphones_rounded,
  };

  Color _skillColor(PracticeSkill? skill) => switch (skill) {
    PracticeSkill.grammar => const Color(0xFFFF7B24),
    PracticeSkill.speaking => const Color(0xFFEE5C8A),
    PracticeSkill.pronunciation => const Color(0xFF17C889),
    PracticeSkill.reading => const Color(0xFF7A4EF4),
    _ => const Color(0xFF2168ED),
  };
}

class _PracticeModesSection extends StatelessWidget {
  const _PracticeModesSection({
    required this.dashboard,
    required this.onReturn,
  });

  final ChallengeDashboardSnapshot? dashboard;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final listening = dashboard?.progressFor(PracticeSkill.listening);
    final speaking = dashboard?.progressFor(PracticeSkill.speaking);
    final grammar = dashboard?.progressFor(PracticeSkill.grammar);
    final pronunciation = dashboard?.progressFor(PracticeSkill.pronunciation);
    final reading = dashboard?.progressFor(PracticeSkill.reading);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5 kỹ năng chính',
          style: TextStyle(
            color: Color(0xFF071D49),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Chọn một kỹ năng để tiếp tục luyện tập',
          style: TextStyle(color: Color(0xFF7187A5), fontSize: 10),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final aspectRatio = constraints.maxWidth >= 360
                ? 1.20
                : constraints.maxWidth >= 300
                ? 1.0
                : .84;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: aspectRatio,
              children: [
                _PracticeModeCard(
                  key: const ValueKey('listening-mode-card'),
                  actionKey: const ValueKey('listening-mode-card-action'),
                  icon: Icons.headphones_rounded,
                  title: 'Luyện nghe',
                  description: 'Nghe hiểu & phản xạ',
                  progressText: _progressText(listening, 'bài'),
                  progress: listening?.ratio ?? 0,
                  color: const Color(0xFF1767F2),
                  onTap: () => _open(context, const ListeningPracticeScreen()),
                ),
                _PracticeModeCard(
                  key: const ValueKey('grammar-mode-card'),
                  actionKey: const ValueKey('grammar-mode-card-action'),
                  icon: Icons.account_tree_rounded,
                  title: 'Ngữ pháp',
                  description: 'Cấu trúc & vận dụng',
                  progressText: _progressText(grammar, 'chủ đề'),
                  progress: grammar?.ratio ?? 0,
                  color: const Color(0xFFFF7B24),
                  onTap: () => _open(context, const GrammarPracticeScreen()),
                ),
                _PracticeModeCard(
                  key: const ValueKey('speaking-mode-card'),
                  actionKey: const ValueKey('speaking-mode-card-action'),
                  icon: Icons.mic_rounded,
                  title: 'Luyện nói',
                  description: 'Nghe mẫu & nói lại',
                  progressText: _progressText(speaking, 'bài'),
                  progress: speaking?.ratio ?? 0,
                  color: const Color(0xFFEE5C8A),
                  onTap: () => _open(context, const SpeakingPracticeScreen()),
                ),
                _PracticeModeCard(
                  key: const ValueKey('pronunciation-mode-card'),
                  actionKey: const ValueKey('pronunciation-mode-card-action'),
                  icon: Icons.record_voice_over_rounded,
                  title: 'IPA & phát âm',
                  description: 'Khẩu hình & âm chuẩn',
                  progressText: _progressText(pronunciation, 'âm'),
                  progress: pronunciation?.ratio ?? 0,
                  color: const Color(0xFF17C889),
                  onTap: () => _open(context, const PronunciationScreen()),
                ),
                _PracticeModeCard(
                  key: const ValueKey('reading-mode-card'),
                  actionKey: const ValueKey('reading-mode-card-action'),
                  icon: Icons.menu_book_rounded,
                  title: 'Luyện đọc',
                  description: 'Đọc hiểu & từ vựng',
                  progressText: _progressText(reading, 'bài'),
                  progress: reading?.ratio ?? 0,
                  color: const Color(0xFF7A4EF4),
                  onTap: () => _open(context, const ReadingScreen()),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) => onReturn());
  }

  String _progressText(PracticeModeProgress? progress, String unit) {
    if (progress == null) return 'Đang tải…';
    return '${_formatNumber(progress.completed)} / '
        '${_formatNumber(progress.total)} $unit';
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

class _ChallengeInsightsSection extends StatelessWidget {
  const _ChallengeInsightsSection({required this.dashboard});

  final ChallengeDashboardSnapshot? dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeeklyActivityChart(points: dashboard?.weeklyActivity ?? const []),
        const SizedBox(height: 16),
        _PracticeHistoryCard(entries: dashboard?.recentHistory ?? const []),
      ],
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.points});

  final List<WeeklyPracticeActivity> points;

  @override
  Widget build(BuildContext context) {
    final sessions = List<int>.generate(
      7,
      (index) => index < points.length ? points[index].sessions : 0,
      growable: false,
    );
    final total = sessions.fold<int>(0, (sum, value) => sum + value);
    final maxSessions = sessions.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = DateTime.now();

    return Container(
      key: const ValueKey('weekly-activity-chart'),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
      decoration: _insightDecoration,
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
                      'Hoạt động tuần này',
                      style: TextStyle(
                        color: Color(0xFF071D49),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Số phiên hoàn thành theo ngày',
                      style: TextStyle(color: Color(0xFF7187A5), fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$total phiên',
                  style: const TextStyle(
                    color: Color(0xFF1767F2),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (index) {
                final value = sessions[index];
                final pointDate = index < points.length
                    ? points[index].date
                    : null;
                final isToday =
                    pointDate != null &&
                    pointDate.year == today.year &&
                    pointDate.month == today.month &&
                    pointDate.day == today.day;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text(
                          '$value',
                          style: TextStyle(
                            color: isToday
                                ? const Color(0xFF1767F2)
                                : const Color(0xFF60799C),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final ratio = value / maxSessions;
                              final height = value == 0
                                  ? 4.0
                                  : (constraints.maxHeight * ratio).clamp(
                                      8.0,
                                      constraints.maxHeight,
                                    );
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  width: 18,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: value == 0
                                        ? const Color(0xFFE7EEF9)
                                        : isToday
                                        ? const Color(0xFF1767F2)
                                        : const Color(0xFF80AEFA),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: isToday
                                ? const Color(0xFF1767F2)
                                : const Color(0xFF7B90AB),
                            fontSize: 9,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeHistoryCard extends StatelessWidget {
  const _PracticeHistoryCard({required this.entries});

  final List<PracticeHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('practice-history'),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 10),
      decoration: _insightDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch sử gần đây',
            style: TextStyle(
              color: Color(0xFF071D49),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Các bài bạn vừa hoàn thành',
            style: TextStyle(color: Color(0xFF7187A5), fontSize: 9),
          ),
          const SizedBox(height: 11),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 12, 2, 18),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: Color(0xFF9AAEC7),
                    size: 25,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Chưa có phiên hoàn thành. Hãy hoàn thành một bài để bắt đầu lịch sử.',
                      style: TextStyle(
                        color: Color(0xFF7187A5),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var index = 0; index < entries.length; index++) ...[
              _PracticeHistoryRow(
                key: ValueKey('practice-history-item-$index'),
                entry: entries[index],
              ),
              if (index < entries.length - 1)
                const Divider(height: 1, color: Color(0xFFE9EFF7)),
            ],
        ],
      ),
    );
  }
}

class _PracticeHistoryRow extends StatelessWidget {
  const _PracticeHistoryRow({required this.entry, super.key});

  final PracticeHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _historySkillColor(entry.skill);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_historySkillIcon(entry.skill), color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071D49),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.contextLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7187A5), fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatHistoryTime(entry.completedAt),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF8A9DB5),
              fontSize: 8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

const _insightDecoration = BoxDecoration(
  color: Color(0xF7FFFFFF),
  borderRadius: BorderRadius.all(Radius.circular(24)),
  boxShadow: [
    BoxShadow(color: Color(0x14235C93), blurRadius: 22, offset: Offset(0, 9)),
  ],
);

IconData _historySkillIcon(PracticeSkill skill) => switch (skill) {
  PracticeSkill.listening => Icons.headphones_rounded,
  PracticeSkill.speaking => Icons.mic_rounded,
  PracticeSkill.grammar => Icons.account_tree_rounded,
  PracticeSkill.pronunciation => Icons.record_voice_over_rounded,
  PracticeSkill.reading => Icons.menu_book_rounded,
};

Color _historySkillColor(PracticeSkill skill) => switch (skill) {
  PracticeSkill.listening => const Color(0xFF1767F2),
  PracticeSkill.speaking => const Color(0xFFEE5C8A),
  PracticeSkill.grammar => const Color(0xFFFF7B24),
  PracticeSkill.pronunciation => const Color(0xFF17C889),
  PracticeSkill.reading => const Color(0xFF7A4EF4),
};

String _formatHistoryTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  final now = DateTime.now();
  final time = '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Hôm nay\n$time';
  }
  return '${twoDigits(value.day)}/${twoDigits(value.month)}\n$time';
}

class _PracticeModeCard extends StatelessWidget {
  const _PracticeModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.progressText,
    required this.progress,
    required this.color,
    required this.onTap,
    this.actionKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String progressText;
  final double progress;
  final Color color;
  final VoidCallback onTap;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: color.withValues(alpha: .20), width: 1),
    );
    return Material(
      color: Colors.white.withValues(alpha: .72),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: actionKey,
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const Spacer(),
                  _ProgressRing(
                    value: progress,
                    color: color,
                    size: 43,
                    label: _percentageLabel(progress),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: Color(0xFF071D49),
                    fontFamily: 'M PLUS Rounded 1c',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.25,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF7187A5), fontSize: 9),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 7),
              _RoundedProgressBar(value: progress, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

String _percentageLabel(double value) {
  if (value <= 0) return '0%';
  if (value < .01) return '<1%';
  return '${(value * 100).round()}%';
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.value,
    required this.color,
    required this.size,
    required this.label,
  });

  final double value;
  final Color color;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: size >= 60 ? 6 : 4,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: color.withValues(alpha: .10),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF071D49),
                fontSize: size >= 60 ? 13 : 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedProgressBar extends StatelessWidget {
  const _RoundedProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 5,
        color: color,
        backgroundColor: color.withValues(alpha: .10),
      ),
    );
  }
}
