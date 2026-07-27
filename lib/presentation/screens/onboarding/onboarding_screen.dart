import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

enum _SetupStep { level, topics }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.onExit, this.onFinished, super.key});

  final VoidCallback? onExit;
  final VoidCallback? onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _SetupStep _step = _SetupStep.level;
  String _selectedLevel = 'Sơ cấp';
  final Set<int> _selectedTopicOrders = {1, 2, 3};

  void _continue() {
    if (_step == _SetupStep.level) {
      setState(() => _step = _SetupStep.topics);
      return;
    }

    ref.read(selectedTopicOrdersProvider.notifier).state = {
      ..._selectedTopicOrders,
    };
    widget.onFinished?.call();
    if (widget.onFinished == null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _toggleTopic(int order) {
    setState(() {
      if (_selectedTopicOrders.contains(order)) {
        _selectedTopicOrders.remove(order);
      } else {
        _selectedTopicOrders.add(order);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTopicsStep = _step == _SetupStep.topics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SetupBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _SetupHeader(
                      step: _step,
                      onBack: _step == _SetupStep.level
                          ? widget.onExit
                          : () => setState(() => _step = _SetupStep.level),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _SetupTabs(
                      step: _step,
                      onChanged: (step) => setState(() => _step = step),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: isTopicsStep
                          ? _TopicsStep(
                              selectedOrders: _selectedTopicOrders,
                              onToggle: _toggleTopic,
                            )
                          : _LevelStep(
                              selectedLevel: _selectedLevel,
                              onSelected: (level) =>
                                  setState(() => _selectedLevel = level),
                            ),
                    ),
                  ),
                ),
                _SetupBottomBar(
                  step: _step,
                  selectedLevel: _selectedLevel,
                  selectedTopicCount: _selectedTopicOrders.length,
                  onContinue: _continue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBackdrop extends StatelessWidget {
  const _SetupBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .18, .44, 1],
              colors: [
                Color(0xFF061C42),
                Color(0xFF0A347F),
                Color(0xFFEFF4FF),
                Color(0xFFF7FAFF),
              ],
            ),
          ),
        ),
        Positioned(
          top: -70,
          left: -90,
          child: _SetupOrb(
            color: AppColors.cyan.withValues(alpha: .32),
            size: 250,
          ),
        ),
        Positioned(
          top: 95,
          right: -80,
          child: _SetupOrb(
            color: AppColors.primary.withValues(alpha: .28),
            size: 220,
          ),
        ),
        Positioned(
          top: 130,
          right: 72,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x88FFFFFF),
              boxShadow: [BoxShadow(color: Colors.white, blurRadius: 12)],
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupOrb extends StatelessWidget {
  const _SetupOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.step, required this.onBack});

  final _SetupStep step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
          enabled: onBack != null,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETUP JOURNEY',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cá nhân hóa lộ trình',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x2EFFFFFF),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0x3DFFFFFF)),
          ),
          child: Text(
            step == _SetupStep.level ? 'Bước 1 / 2' : 'Bước 2 / 2',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0x3DFFFFFF)),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.white : const Color(0x66FFFFFF),
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupTabs extends StatelessWidget {
  const _SetupTabs({required this.step, required this.onChanged});

  final _SetupStep step;
  final ValueChanged<_SetupStep> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xCFFFFFFF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xBFFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14163873),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _SetupTab(
            label: 'Cấp độ',
            selected: step == _SetupStep.level,
            onTap: () => onChanged(_SetupStep.level),
          ),
          _SetupTab(
            label: 'Chủ đề',
            selected: step == _SetupStep.topics,
            onTap: () => onChanged(_SetupStep.topics),
          ),
        ],
      ),
    );
  }
}

class _SetupTab extends StatelessWidget {
  const _SetupTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  )
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x301558FF),
                      blurRadius: 13,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.selectedLevel, required this.onSelected});

  final String selectedLevel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const levels = [
      (
        title: 'Sơ cấp',
        tag: 'Khuyên dùng',
        emoji: '🌱',
        color: Color(0xFFDDF7EE),
        description:
            'Bắt đầu từ những từ quen thuộc, dễ tiếp cận và dễ ghi nhớ.',
        meta: ['Từ cơ bản', 'Câu ngắn', 'Dễ ghi nhớ'],
      ),
      (
        title: 'Trung bình',
        tag: 'Intermediate',
        emoji: '⚡',
        color: Color(0xFFEAE4FF),
        description:
            'Mở rộng vốn từ theo các tình huống thực tế và đa chủ đề hơn.',
        meta: ['Đa chủ đề', 'Ngữ cảnh hơn', 'Ôn sâu hơn'],
      ),
      (
        title: 'Nâng cao',
        tag: 'Advanced',
        emoji: '🚀',
        color: Color(0xFFFFE9C7),
        description:
            'Chinh phục từ khó, sắc thái sâu và ngôn ngữ trong công việc.',
        meta: ['Từ khó', 'Ngữ nghĩa sâu', 'Thử thách hơn'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SetupIntro(
          icon: '🎯',
          label: 'Chọn trình độ',
          title: 'Bạn muốn bắt đầu ở mức nào?',
          description:
              'Leximon sẽ điều chỉnh độ khó, nhóm từ vựng và thử thách luyện tập dựa trên lựa chọn của bạn.',
        ),
        const SizedBox(height: 14),
        for (final level in levels) ...[
          _LevelOption(
            title: level.title,
            tag: level.tag,
            emoji: level.emoji,
            iconColor: level.color,
            description: level.description,
            meta: level.meta,
            selected: selectedLevel == level.title,
            onTap: () => onSelected(level.title),
          ),
          const SizedBox(height: 10),
        ],
        const _SetupHelper(),
      ],
    );
  }
}

class _SetupIntro extends StatelessWidget {
  const _SetupIntro({
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
  });

  final String icon;
  final String label;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xCCFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1426448B),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(height: 13),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.title,
    required this.tag,
    required this.emoji,
    required this.iconColor,
    required this.description,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String tag;
  final String emoji;
  final Color iconColor;
  final String description;
  final List<String> meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : const Color(0xEFFFFFFF),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xCFFFFFFF),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1426448B),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 23)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tag,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [for (final item in meta) _MetaPill(item)],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FA),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 19,
      height: 19,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primary : Colors.transparent,
        ),
      ),
    );
  }
}

class _SetupHelper extends StatelessWidget {
  const _SetupHelper();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xDFFFFFFF),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xCFFFFFFF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 19)),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Nếu bạn chưa chắc nên chọn gì, hãy bắt đầu với ',
                children: [
                  TextSpan(
                    text: 'Sơ cấp',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text:
                        '. Bạn luôn có thể đổi lại cấp độ sau trong phần thiết đặt.',
                  ),
                ],
              ),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsStep extends ConsumerWidget {
  const _TopicsStep({required this.selectedOrders, required this.onToggle});

  final Set<int> selectedOrders;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SetupIntro(
          icon: '📚',
          label: 'Chọn chủ đề',
          title: 'Những chủ đề nào phù hợp với bạn?',
          description:
              'Bạn có thể chọn nhiều chủ đề để Leximon ưu tiên trong giai đoạn đầu. Đề xuất tốt nhất là 3–5 chủ đề.',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedOrders.length} chủ đề đã chọn',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bắt đầu tốt với một nhóm nhỏ trước',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EDFF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Khuyên dùng',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        topicsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const _TopicFallback(),
          data: (topics) => Column(
            children: [
              for (final topic in topics) ...[
                _TopicOption(
                  topic: topic,
                  selected: selectedOrders.contains(topic.order),
                  onTap: () => onToggle(topic.order),
                ),
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicFallback extends StatelessWidget {
  const _TopicFallback();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'Không thể tải danh sách chủ đề.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}

class _TopicOption extends StatelessWidget {
  const _TopicOption({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final Topic topic;
  final bool selected;
  final VoidCallback onTap;

  static const _descriptions = <int, String>{
    1: 'Từ vựng cần thiết khi đi lại, đặt phòng và di chuyển.',
    2: 'Nhóm từ cơ bản khi xem giá, hỏi món hàng và thanh toán.',
    3: 'Chủ đề gần gũi, dễ bắt đầu và dễ áp dụng khi giao tiếp.',
    4: 'Phù hợp với môi trường học tập, môn học và hoạt động trong lớp.',
    5: 'Từ vựng liên quan tới công việc, nhiệm vụ và nghề nghiệp.',
    6: 'Luyện cách giao tiếp tự tin trong các cuộc phỏng vấn.',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : const Color(0xEFFFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xCFFFFFFF),
            width: selected ? 1.35 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1426448B),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 47,
              height: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: topicGradient(topic)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TopicArtwork(topic: topic, padding: 9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.translated,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${topic.wordCount} từ',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _descriptions[topic.order] ??
                        'Mở rộng vốn từ theo các tình huống quen thuộc trong cuộc sống.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            _CheckIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  const _CheckIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _SetupBottomBar extends StatelessWidget {
  const _SetupBottomBar({
    required this.step,
    required this.selectedLevel,
    required this.selectedTopicCount,
    required this.onContinue,
  });

  final _SetupStep step;
  final String selectedLevel;
  final int selectedTopicCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isLevel = step == _SetupStep.level;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xEFFFFFFF),
            border: Border(top: BorderSide(color: Color(0xD6FFFFFF))),
            boxShadow: [
              BoxShadow(
                color: Color(0x1426448B),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(18, 11, 18, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLevel
                              ? 'Đã chọn: $selectedLevel'
                              : '$selectedTopicCount chủ đề đã chọn',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Leximon sẽ chuẩn bị bộ từ vựng phù hợp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isLevel || selectedTopicCount > 0
                          ? onContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFB9C7DC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text(isLevel ? 'Tiếp tục' : 'Hoàn tất'),
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
