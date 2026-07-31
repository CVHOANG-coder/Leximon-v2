import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/learning_language_level.dart';
import '../../../shared/providers/app_providers.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  late LearningLanguageLevel _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final selectedLevels = ref.read(selectedLanguageLevelsProvider);
    _selectedLevel = selectedLevels.isEmpty
        ? LearningLanguageLevel.beginner
        : selectedLevels.first;
  }

  Future<void> _continue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final service = ref.read(appLanguageServiceProvider);
      await service.saveSelectedLearningLevel(_selectedLevel.label);
      ref.read(selectedLanguageLevelsProvider.notifier).state = {
        _selectedLevel,
      };
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.push('/onboarding/assessment-intro/survey');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu trình độ. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061D4C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/bg_choose_language.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 190,
                    child: _LevelSelectionPanel(
                      selectedLevel: _selectedLevel,
                      isSaving: _isSaving,
                      onSelected: (level) {
                        setState(() => _selectedLevel = level);
                      },
                      onContinue: _continue,
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: _LevelSelectionHeader(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelSelectionHeader extends StatelessWidget {
  const _LevelSelectionHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 10,
            child: Semantics(
              label: 'Quay lại',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/onboarding/assessment-intro');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 38,
            top: 70,
            child: Text(
              'Chọn trình độ\nAnh ngữ của bạn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 130,
            child: Text(
              'Chọn cấp độ phù hợp để chúng tôi\n'
              'xây dựng lộ trình học tốt nhất cho bạn.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                height: 1.48,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 40,
            child: Image.asset(
              'assets/images/owls/owl_level.png',
              width: 131,
              height: 165,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              cacheWidth: 700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelSelectionPanel extends StatelessWidget {
  const _LevelSelectionPanel({
    required this.selectedLevel,
    required this.isSaving,
    required this.onSelected,
    required this.onContinue,
  });

  final LearningLanguageLevel selectedLevel;
  final bool isSaving;
  final ValueChanged<LearningLanguageLevel> onSelected;
  final VoidCallback onContinue;

  static const _options = [
    _LevelOptionData(
      level: LearningLanguageLevel.beginner,
      description: 'Tôi biết một vài từ',
      imageAsset: 'assets/images/onboarding/basic.png',
      imageBackground: Color(0xFFE9F6FF),
    ),
    _LevelOptionData(
      level: LearningLanguageLevel.intermediate,
      description: 'Tôi biết khá nhiều từ và muốn học thêm',
      imageAsset: 'assets/images/onboarding/medium.png',
      imageBackground: Color(0xFFF4F0FF),
    ),
    _LevelOptionData(
      level: LearningLanguageLevel.advanced,
      description: 'Tôi muốn học những từ khó',
      imageAsset: 'assets/images/onboarding/advanced.png',
      imageBackground: Color(0xFFFFF3E4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E031A55),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 52,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    for (var index = 0; index < _options.length; index++) ...[
                      _LevelOptionCard(
                        option: _options[index],
                        selected: selectedLevel == _options[index].level,
                        onTap: () => onSelected(_options[index].level),
                      ),
                      if (index != _options.length - 1)
                        const SizedBox(height: 14),
                    ],
                    const Spacer(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSaving
                                ? const [Color(0xFF78A2FF), Color(0xFF8DB4FF)]
                                : const [Color(0xFF0C55F2), Color(0xFF1576FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40155CFF),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            key: const ValueKey('level-selection-continue'),
                            onTap: isSaving ? null : onContinue,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: isSaving
                                  ? const SizedBox.square(
                                      dimension: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Tiếp',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelOptionCard extends StatelessWidget {
  const _LevelOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LevelOptionData option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: option.level.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('level-option-${option.level.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFFF0F7FF), Color(0xFFF9FCFF)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFDFEFF)],
                    ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9FC4FF)
                    : const Color(0xFFE9EEF7),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10234381),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 78,
                  decoration: BoxDecoration(
                    color: option.imageBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    option.imageAsset,
                    fit: BoxFit.contain,
                    cacheWidth: 400,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.level.label,
                        style: const TextStyle(
                          color: Color(0xFF061D4C),
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66728F),
                          fontSize: 13,
                          height: 1.38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LevelRadio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelRadio extends StatelessWidget {
  const _LevelRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF13BD2A) : const Color(0xFFD7DDE8),
          width: 3,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF13C42D) : Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LevelOptionData {
  const _LevelOptionData({
    required this.level,
    required this.description,
    required this.imageAsset,
    required this.imageBackground,
  });

  final LearningLanguageLevel level;
  final String description;
  final String imageAsset;
  final Color imageBackground;
}
