import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../data/services/daily_card_service.dart';
import '../../../data/services/topic_progress_service.dart';
import '../../../data/services/topic_repetition_service.dart';
import '../../../data/models/topic.dart';
import '../../../shared/providers/app_providers.dart';
import '../../widgets/leximon_widgets.dart';
import '../repetition_practice/repetition_practice_screen.dart';
import '../word_study/word_study_screen.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({required this.topic, super.key});

  final Topic topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  bool _saved = false;
  bool _isOpeningRepetition = false;
  late TopicProgressDetails _progressDetails;

  Topic get topic => widget.topic;
  double get progress => _progressDetails.progress;
  int get learnedWords => _progressDetails.learnedWords;
  int get progressedWords => _progressDetails.progressedWords;
  int get rememberedWords =>
      (learnedWords - reviewWords).clamp(0, learnedWords);
  int get reviewWords => _progressDetails.reviewWords;
  int get activeWords => _progressDetails.activeWords;

  @override
  Widget build(BuildContext context) {
    _progressDetails =
        ref.watch(topicProgressDetailsProvider(topic.id)).valueOrNull ??
        TopicProgressDetails.empty(topic.wordCount);
    final repetitionData = ref.watch(topicRepetitionDataProvider(topic.id));
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
                        sliver: SliverToBoxAdapter(
                          child: _actionsSection(repetitionData),
                        ),
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
                        fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$progressedWords / ${_progressDetails.totalWords} từ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

  Widget _actionsSection(AsyncValue<TopicRepetitionData> repetitionData) {
    final data = repetitionData.valueOrNull;
    final repeatableCount = data?.words.length ?? 0;
    final canRepeat = data?.canStart ?? false;
    final isLoading = repetitionData.isLoading || _isOpeningRepetition;
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
            onTap: _openWordStudy,
          ),
          const SizedBox(height: 10),
          _ActionItem(
            icon: '🔁',
            title: 'Ôn lặp lại',
            description: canRepeat
                ? '$repeatableCount từ đã học sẵn sàng để ôn theo từng lượt.'
                : 'Cần ít nhất ${TopicRepetitionService.minimumWordCount} từ đã học để bắt đầu.',
            color: const Color(0xFFF3F7FF),
            iconBackground: const Color(0xFFE8F0FF),
            isLoading: isLoading,
            onTap: canRepeat && !isLoading ? _openTopicRepetition : null,
          ),
          if (!canRepeat &&
              !repetitionData.isLoading &&
              !repetitionData.hasError) ...[
            const SizedBox(height: 10),
            _RepetitionRequirement(
              current: repeatableCount,
              required: TopicRepetitionService.minimumWordCount,
            ),
          ],
          if (repetitionData.hasError) ...[
            const SizedBox(height: 10),
            const Text(
              'Chưa thể tải danh sách từ ôn. Hãy thử mở lại màn hình.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
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
                      fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
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

  Future<void> _openWordStudy() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            WordStudyScreen(topic: topic, dailyTaskType: DailyTaskType.learn),
      ),
    );
    if (!mounted) return;
    ref.invalidate(topicProgressDetailsProvider(topic.id));
    ref.invalidate(topicRepetitionDataProvider(topic.id));
  }

  Future<void> _openTopicRepetition() async {
    if (_isOpeningRepetition) return;
    setState(() => _isOpeningRepetition = true);
    try {
      ref.invalidate(topicRepetitionDataProvider(topic.id));
      final data = await ref.read(topicRepetitionDataProvider(topic.id).future);
      if (!mounted) return;
      if (!data.canStart) {
        _showMessage(
          'Bạn cần ít nhất ${TopicRepetitionService.minimumWordCount} từ đã học để bắt đầu ôn.',
        );
        return;
      }

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => RepetitionPracticeScreen(
            title: 'Ôn • ${topic.translated}',
            topicId: topic.id,
            words: data.words,
            distractorWords: data.distractorWords,
            database: ref.read(appDatabaseProvider),
          ),
        ),
      );
      if (!mounted) return;
      ref.invalidate(topicProgressDetailsProvider(topic.id));
      ref.invalidate(topicRepetitionDataProvider(topic.id));
      ref.invalidate(topicProgressProvider);
      ref.invalidate(wordProgressProvider);
      ref.invalidate(dailyCardProvider);
      ref.invalidate(progressDashboardProvider);
      ref.invalidate(vocabularyCollectionProvider);
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể mở buổi ôn lúc này. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _isOpeningRepetition = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            fontWeight: FontWeight.w700,
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
    this.isLoading = false,
  });
  final String icon;
  final String title;
  final String description;
  final Color color;
  final Color iconBackground;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null && !isLoading ? .58 : 1,
    child: InkWell(
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
                      fontWeight: FontWeight.w700,
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
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                onTap == null
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    ),
  );
}

class _RepetitionRequirement extends StatelessWidget {
  const _RepetitionRequirement({required this.current, required this.required});

  final int current;
  final int required;

  @override
  Widget build(BuildContext context) {
    final progress = (current / required).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ngay khi có 8 từ, bạn có thể bắt đầu lặp lại chúng',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$current / $required',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE3E9F3),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
