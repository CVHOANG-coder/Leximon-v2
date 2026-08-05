import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/learning_language_level.dart';
import '../../../data/models/topic.dart';
import '../../../presentation/widgets/leximon_widgets.dart';
import '../../../shared/providers/app_providers.dart';

enum _SetupStep { level, topics }

class LearningFilterScreen extends ConsumerStatefulWidget {
  const LearningFilterScreen({
    this.startAtTopics = true,
    this.onExit,
    this.onFinished,
    super.key,
  });

  final bool startAtTopics;
  final VoidCallback? onExit;
  final VoidCallback? onFinished;

  @override
  ConsumerState<LearningFilterScreen> createState() =>
      _LearningFilterScreenState();
}

class _LearningFilterScreenState extends ConsumerState<LearningFilterScreen> {
  late _SetupStep _step;
  String _selectedLevel = 'Sơ cấp';
  late final Set<int> _selectedTopicOrders;

  @override
  void initState() {
    super.initState();
    _step = widget.startAtTopics ? _SetupStep.topics : _SetupStep.level;
    _selectedLevel =
        ref.read(selectedLanguageLevelsProvider).firstOrNull?.label ??
        LearningLanguageLevel.beginner.label;
    final existingOrders = ref.read(selectedTopicOrdersProvider);
    _selectedTopicOrders = existingOrders.isEmpty
        ? {1, 2, 3}
        : {...existingOrders};
  }

  void _applyFilters() {
    final selectedOrders = {..._selectedTopicOrders};
    ref.read(selectedTopicOrdersProvider.notifier).state = selectedOrders;
    ref.read(selectedLanguageLevelsProvider.notifier).state = {
      LearningLanguageLevel.fromLabel(_selectedLevel),
    };
    unawaited(_persistSelectedTopics(selectedOrders));
    widget.onFinished?.call();
    if (widget.onFinished == null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _persistSelectedTopics(Set<int> selectedOrders) async {
    try {
      await ref
          .read(topicRepositoryProvider)
          .saveSelectedTopicOrders(selectedOrders);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu chủ đề đã chọn.')),
      );
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
                    child: _SetupHeader(onBack: widget.onExit),
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
                  selectedLevel: _selectedLevel,
                  selectedTopicCount: _selectedTopicOrders.length,
                  onApply: _applyFilters,
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
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        FractionallySizedBox(
          alignment: Alignment.topCenter,
          heightFactor: .48,
          child: Image.asset(
            'assets/images/banner_header.png',
            key: const ValueKey('learning-filter-header-background'),
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .46, .72, 1],
              colors: [
                Color(0x00000000),
                Color(0x00F7FAFF),
                Color(0xB8F7FAFF),
                AppColors.background,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.onBack});

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
                'LEARNING FILTERS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 4),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cá nhân hóa lộ trình',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(width: 10),
        // Container(
        //   key: const Key('learning-filter-header-button'),
        //   height: 38,
        //   padding: const EdgeInsets.symmetric(horizontal: 12),
        //   alignment: Alignment.center,
        //   decoration: BoxDecoration(
        //     color: Colors.white.withValues(alpha: .5),
        //     borderRadius: BorderRadius.circular(99),
        //     border: Border.all(color: const Color(0xFF2A7DF4), width: 1.1),
        //     boxShadow: const [
        //       BoxShadow(
        //         color: Color(0x142A7DF4),
        //         blurRadius: 12,
        //         offset: Offset(0, 4),
        //       ),
        //     ],
        //   ),
        //   child: const Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(Icons.tune_rounded, color: Color(0xFF2A7DF4), size: 16),
        //       SizedBox(width: 7),
        //       Text(
        //         'BỘ LỌC HỌC',
        //         style: TextStyle(
        //           color: Color(0xFF2475E6),
        //           fontSize: 9,
        //           fontWeight: FontWeight.w800,
        //           letterSpacing: .15,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F2E72B8),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : const Color(0x669AA8BB),
              size: 21,
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
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14163873),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return SizedBox(
            height: 42,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: step == _SetupStep.level ? 0 : tabWidth,
                  top: 0,
                  width: tabWidth,
                  height: 42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1658D3), Color(0xFF2481FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3D1558FF),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
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
              ],
            ),
          );
        },
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
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF8796AA),
                fontSize: selected ? 13 : 12.5,
                fontWeight: FontWeight.w800,
              ),
              child: Text(label),
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
        iconAsset: 'assets/svgs/plant.svg',
        color: Color(0xFFDDF7EE),
        description:
            'Bắt đầu từ những từ quen thuộc, dễ tiếp cận và dễ ghi nhớ.',
        meta: ['Từ cơ bản', 'Câu ngắn', 'Dễ ghi nhớ'],
      ),
      (
        title: 'Trung bình',
        tag: 'Intermediate',
        iconAsset: 'assets/svgs/thunder.svg',
        color: Color(0xFFEAE4FF),
        description:
            'Mở rộng vốn từ theo các tình huống thực tế và đa chủ đề hơn.',
        meta: ['Đa chủ đề', 'Ngữ cảnh hơn', 'Ôn sâu hơn'],
      ),
      (
        title: 'Nâng cao',
        tag: 'Advanced',
        iconAsset: 'assets/svgs/rocket.svg',
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
          iconAsset: 'assets/svgs/target_3d.svg',
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
            iconAsset: level.iconAsset,
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
    required this.iconAsset,
    required this.label,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String label;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6C8FB4),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                iconAsset,
                key: ValueKey(iconAsset),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                  ),
                ),
                // const SizedBox(height: 10),
                // Text(
                //   description,
                //   style: const TextStyle(
                //     color: AppColors.textSecondary,
                //     fontSize: 11,
                //     height: 1.45,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
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
    required this.iconAsset,
    required this.iconColor,
    required this.description,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String tag;
  final String iconAsset;
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
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: SvgPicture.asset(
                  iconAsset,
                  key: ValueKey(iconAsset),
                  fit: BoxFit.contain,
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
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/svgs/new.svg',
            key: const ValueKey('assets/svgs/new.svg'),
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Nếu bạn chưa chắc nên chọn gì, hãy bắt đầu với ',
                children: [
                  TextSpan(
                    text: 'Sơ cấp',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
          iconAsset: 'assets/svgs/book.svg',
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bắt đầu tốt với một nhóm nhỏ trước',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Khuyên dùng',
                style: TextStyle(
                  color: Color(0xFF2475E6),
                  fontSize: 10,
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
        key: ValueKey('learning-filter-topic-${topic.order}'),
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .96)
              : Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2A7DF4) : const Color(0xFFDCE5F0),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x242A7DF4)
                  : const Color(0x176C89A8),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: topicGradient(topic)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TopicArtwork(topic: topic, padding: 8),
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${topic.wordCount} từ',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
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
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? null : Colors.white.withValues(alpha: .4),
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF3A8EFF), Color(0xFF155CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xFF1C69F4) : const Color(0xFFAAB6C5),
          width: 1.5,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x33216AF4),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

class _SetupBottomBar extends StatelessWidget {
  const _SetupBottomBar({
    required this.selectedLevel,
    required this.selectedTopicCount,
    required this.onApply,
  });

  final String selectedLevel;
  final int selectedTopicCount;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
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
                          '$selectedLevel  •  $selectedTopicCount chủ đề',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Áp dụng đồng thời hai bộ lọc học',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    constraints: const BoxConstraints(minWidth: 128),
                    height: 48,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: selectedTopicCount > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF9FD2FF), Color(0xFF62A9FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selectedTopicCount > 0
                          ? null
                          : const Color(0xFFD2DAE7),
                      boxShadow: selectedTopicCount > 0
                          ? const [
                              BoxShadow(
                                color: Color(0x3D286BEF),
                                blurRadius: 15,
                                offset: Offset(0, 7),
                              ),
                            ]
                          : null,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selectedTopicCount > 0
                            ? null
                            : const Color(0xFFB9C7DC),
                        gradient: selectedTopicCount > 0
                            ? const LinearGradient(
                                colors: [Color(0xFF4A8CFF), Color(0xFF245CEB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextButton(
                        key: const Key('learning-filter-apply-button'),
                        onPressed: selectedTopicCount > 0 ? onApply : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Áp dụng'),
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
