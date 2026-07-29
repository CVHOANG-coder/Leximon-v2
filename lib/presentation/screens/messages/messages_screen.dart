import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicName =
        ref.watch(topicsProvider).valueOrNull?.firstOrNull?.translated ??
        'Du lịch';
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            sliver: const SliverToBoxAdapter(child: _PracticeHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverToBoxAdapter(
              child: _ChallengeHero(topicName: topicName),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: _ModesSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: _FocusSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: _MissionsSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            sliver: const SliverToBoxAdapter(child: _BossCard()),
          ),
        ],
      ),
    );
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader();

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
                'CHALLENGE ARENA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Luyện tập thông minh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Biến việc học từ vựng thành các thử thách ngắn, rõ mục tiêu và có cảm giác chinh phục.',
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                '18',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.topicName});
  final String topicName;

  @override
  Widget build(BuildContext context) {
    return LeximonSurface(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THỬ THÁCH HÔM NAY',
                      style: TextStyle(
                        color: Color(0xFF7990B0),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Word Sprint',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ],
                ),
              ),
              _CountdownBadge(),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              topicName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.purple,
                ],
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
                const Row(
                  children: [
                    Text(
                      '+120 XP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '8 từ khó',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '3 lượt sai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến trình chặng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '2 / 5 thử thách',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const ProgressLine(value: .4, dark: true),
                const SizedBox(height: 16),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBlue,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bắt đầu ngay',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Chơi thử thách',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
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

class _CountdownBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        Text(
          'CÒN LẠI',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 3),
        Text(
          '12:48',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ModesSection extends StatelessWidget {
  const _ModesSection();

  @override
  Widget build(BuildContext context) {
    return LeximonSurface(
      child: Column(
        children: [
          const SectionHeader(
            kicker: 'Chế độ luyện',
            title: 'Chọn cách bạn muốn học',
            action: 'Xem tất cả',
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .92,
            children: const [
              _ModeCard(
                icon: '🎧',
                title: 'Nghe nhanh',
                body: 'Nghe phát âm và chọn đúng nghĩa trong thời gian ngắn.',
                tag: '3 phút',
                color: AppColors.primary,
              ),
              _ModeCard(
                icon: '🧩',
                title: 'Ghép nghĩa',
                body: 'Ghép từ với nghĩa hoặc ví dụ đúng để tăng phản xạ.',
                tag: '10 câu',
                color: AppColors.orange,
              ),
              _ModeCard(
                icon: '🗣️',
                title: 'Phát âm',
                body: 'Luyện nói lại từ mới và hoàn thành combo chuẩn.',
                tag: 'Mic bật',
                color: AppColors.green,
              ),
              _ModeCard(
                icon: '⚔️',
                title: 'Boss challenge',
                body: 'Trả lời đúng liên tiếp để đánh bại thử thách cuối ngày.',
                tag: 'Hiếm',
                color: AppColors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
    required this.color,
  });
  final String icon;
  final String title;
  final String body;
  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              height: 1.25,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FocusSection extends StatelessWidget {
  const _FocusSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Phiên gợi ý',
          title: 'Luyện tập ưu tiên hôm nay',
          action: 'Dựa trên SRS',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surfaceBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OwlAvatar(size: 52, radius: 17),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ôn lại nhóm từ sắp quên',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '14 từ trong chủ đề Du lịch cần ôn lại trong hôm nay để giữ streak ghi nhớ.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      '⏱️ 4 phút   📘 14 từ   🎯 92% phù hợp',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ôn ngay',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MissionsSection extends StatelessWidget {
  const _MissionsSection();

  @override
  Widget build(BuildContext context) => LeximonSurface(
    child: Column(
      children: [
        const SectionHeader(
          kicker: 'Missions',
          title: 'Nhiệm vụ nhận thưởng',
          action: 'Kho phần thưởng',
        ),
        const SizedBox(height: 14),
        const _MissionItem(
          icon: '✓',
          title: 'Hoàn thành 1 phiên nghe nhanh',
          body: 'Nhận 40 XP + 1 energy',
          status: 'Hoàn tất',
          done: true,
        ),
        const _MissionItem(
          icon: '2',
          title: 'Đạt combo 5 câu đúng liên tiếp',
          body: 'Tiến độ 3 / 5 • thưởng 60 XP',
          status: 'Tiếp tục',
        ),
        const _MissionItem(
          icon: '★',
          title: 'Đánh bại boss challenge hôm nay',
          body: 'Mở rương hiếm và cộng streak challenge',
          status: 'Chơi',
        ),
      ],
    ),
  );
}

class _MissionItem extends StatelessWidget {
  const _MissionItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    this.done = false,
  });
  final String icon;
  final String title;
  final String body;
  final String status;
  final bool done;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done
                ? AppColors.green.withValues(alpha: .14)
                : AppColors.surfaceBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                color: done ? AppColors.green : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: done ? AppColors.green : AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _BossCard extends StatelessWidget {
  const _BossCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF2A185F), Color(0xFF155CFF), Color(0xFF56D8FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x361258FF),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
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
                    'BOSS MINI GAME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Thử thách đối kháng từ vựng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Mới',
              style: TextStyle(
                color: Color(0xFF8A3A00),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mini boss hôm nay',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
                SizedBox(height: 4),
                Text(
                  'Captain Misword',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              'Lv.12',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HP Boss',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '68 / 100',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const ProgressLine(value: .68, dark: true),
        const SizedBox(height: 17),
        Row(
          children: [
            const Expanded(
              child: Text(
                '🏆 1 rương    💎 20 gem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              child: const Text('Vào trận'),
            ),
          ],
        ),
      ],
    ),
  );
}
