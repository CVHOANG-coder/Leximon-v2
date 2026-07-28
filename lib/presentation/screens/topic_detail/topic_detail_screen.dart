import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/models/topic.dart';
import '../../widgets/leximon_widgets.dart';
import '../word_study/word_study_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({required this.topic, super.key});

  final Topic topic;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  bool _saved = false;

  Topic get topic => widget.topic;
  double get progress => topicProgress(topic);
  int get learnedWords => (topic.wordCount * progress).round();
  int get rememberedWords => (learnedWords * .62).round();
  int get reviewWords => (learnedWords * .16).round();
  int get activeWords =>
      (learnedWords - rememberedWords - reviewWords).clamp(0, learnedWords);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _DetailBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _topBar(),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(child: _topicSummary()),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        sliver: SliverToBoxAdapter(child: _quickStats()),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        sliver: SliverToBoxAdapter(child: _actionsSection()),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        sliver: SliverToBoxAdapter(child: _previewSection()),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                        sliver: SliverToBoxAdapter(child: _tipCard()),
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

  Widget _topBar() {
    return Row(
      children: [
        _GlassButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Text(
            'Chi tiết chủ đề',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
        _GlassButton(
          icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          onPressed: () => setState(() => _saved = !_saved),
          iconColor: _saved ? AppColors.yellow : Colors.white,
        ),
      ],
    );
  }

  Widget _topicSummary() {
    return LeximonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: topicGradient(topic)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x261558FF),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: TopicArtwork(topic: topic, padding: 12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TopicLabel(),
                    const SizedBox(height: 8),
                    Text(
                      topic.translated,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _topicDescription(topic),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIẾN ĐỘ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$learnedWords / ${topic.wordCount} từ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 11),
                ProgressLine(value: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_rounded,
            value: '$rememberedWords',
            label: 'Đã nhớ',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.refresh_rounded,
            value: '$reviewWords',
            label: 'Cần ôn',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            value: '$activeWords',
            label: 'Đang học',
            color: AppColors.yellow,
          ),
        ),
      ],
    );
  }

  Widget _actionsSection() {
    return LeximonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            kicker: 'Hành động chính',
            title: 'Bạn muốn làm gì?',
          ),
          const SizedBox(height: 15),
          _ActionItem(
            icon: '💡',
            title: 'Học từ mới',
            description: 'Bắt đầu với những từ bạn chưa học trong chủ đề này.',
            color: const Color(0xFFFFF9E8),
            iconBackground: const Color(0xFFFFF0BD),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WordStudyScreen(topic: topic),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionItem(
            icon: '🔁',
            title: 'Ôn lại từ',
            description: 'Ôn các từ đang đến hạn để giữ trí nhớ lâu hơn.',
            color: const Color(0xFFF3F7FF),
            iconBackground: const Color(0xFFE8F0FF),
            onTap: () => _showComingSoon('Ôn lại từ'),
          ),
        ],
      ),
    );
  }

  Widget _previewSection() {
    final previewWords = topic.words.take(3).toList();
    return LeximonSurface(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionHeading(
                  kicker: 'Xem nhanh',
                  title: 'Một vài từ trong chủ đề',
                ),
              ),
              TextButton(
                onPressed: () => _showComingSoon('Danh sách từ'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (previewWords.isEmpty)
            const Text(
              'Chưa có từ trong topic này.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            )
          else
            ...previewWords.map(_wordRow),
        ],
      ),
    );
  }

  Widget _wordRow(Map<String, dynamic> word) {
    final writing = word['writing'] as String? ?? '';
    final translation = word['translation'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDF1F7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    writing,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    translation,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _speakWord(writing),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE9FB)),
      ),
      child: Row(
        children: [
          const OwlAvatar(size: 46, radius: 15),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Gợi ý từ Leximon\n',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Hãy ôn các từ đang đến hạn trước khi học từ mới để đạt hiệu quả tốt hơn.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action sẽ được mở rộng ở bước tiếp theo.')),
    );
  }

  void _speakWord(String word) {
    unawaited(TextToSpeechService.instance.speak(word));
  }

  String _topicDescription(Topic value) {
    switch (value.order) {
      case 1:
        return 'Từ vựng dùng khi di chuyển, đặt phòng, hỏi đường và giao tiếp trong chuyến đi.';
      case 2:
        return 'Những từ thường gặp khi mua sắm, chọn sản phẩm và thanh toán.';
      case 3:
        return 'Từ vựng để nói về gia đình, bạn bè và các mối quan hệ.';
      default:
        return 'Khám phá những từ vựng thiết yếu trong chủ đề ${value.translated}.';
    }
  }
}

class _DetailBackdrop extends StatelessWidget {
  const _DetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(46)),
            gradient: LinearGradient(
              colors: [Color(0xFF061C42), Color(0xFF0A347F), Color(0xFF155CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: 70,
          left: -86,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: .18),
              ),
            ),
          ),
        ),
        Positioned(
          top: -52,
          right: -56,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, color: iconColor, size: 20),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.white24),
      ),
    ),
  );
}

class _TopicLabel extends StatelessWidget {
  const _TopicLabel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'Chủ đề đang học',
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEDF1F7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F27477F),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.kicker, required this.title});
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        kicker.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF7990B0),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 21,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -.7,
        ),
      ),
    ],
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.iconBackground,
    required this.onTap,
  });
  final String icon;
  final String title;
  final String description;
  final Color color;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF1F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
