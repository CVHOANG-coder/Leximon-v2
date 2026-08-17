import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/learning_language_level.dart';
import '../../../shared/providers/app_providers.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _panelOpacity;
  late LearningLanguageLevel _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerOpacity = Tween<double>(begin: 0.01, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.58, curve: Curves.easeOutCubic),
          ),
        );
    _panelOpacity = Tween<double>(begin: 0.01, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.76, curve: Curves.easeOut),
      ),
    );
    final selectedLevels = ref.read(selectedLanguageLevelsProvider);
    _selectedLevel = selectedLevels.isEmpty
        ? LearningLanguageLevel.beginner
        : selectedLevels.first;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.languageSaveError)));
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
              opacity: Tween<double>(begin: 0.01, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0, 0.42, curve: Curves.easeOut),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 190,
                    child: FadeTransition(
                      opacity: _panelOpacity,
                      child: _LevelSelectionPanel(
                        entranceAnimation: _controller,
                        selectedLevel: _selectedLevel,
                        isSaving: _isSaving,
                        onSelected: (level) {
                          setState(() => _selectedLevel = level);
                        },
                        onContinue: _continue,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _headerOpacity,
                      child: SlideTransition(
                        position: _headerSlide,
                        transformHitTests: false,
                        child: const _LevelSelectionHeader(),
                      ),
                    ),
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
              label: context.l10n.back,
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
          Positioned(
            left: 38,
            top: 70,
            child: Text(
              context.l10n.levelSelectionTitle,
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
              context.l10n.levelSelectionSubtitle,
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
    required this.entranceAnimation,
    required this.selectedLevel,
    required this.isSaving,
    required this.onSelected,
    required this.onContinue,
  });

  final Animation<double> entranceAnimation;
  final LearningLanguageLevel selectedLevel;
  final bool isSaving;
  final ValueChanged<LearningLanguageLevel> onSelected;
  final VoidCallback onContinue;

  static const _options = [
    _LevelOptionData(
      level: LearningLanguageLevel.beginner,
      imageAsset: 'assets/images/onboarding/basic.png',
      imageBackground: Color(0xFFE9F6FF),
    ),
    _LevelOptionData(
      level: LearningLanguageLevel.intermediate,
      imageAsset: 'assets/images/onboarding/medium.png',
      imageBackground: Color(0xFFF4F0FF),
    ),
    _LevelOptionData(
      level: LearningLanguageLevel.advanced,
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
                      _AnimatedLevelOptionCard(
                        animation: entranceAnimation,
                        index: index,
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
                                  : Text(
                                      context.l10n.continueLabel,
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

class _AnimatedLevelOptionCard extends StatelessWidget {
  const _AnimatedLevelOptionCard({
    required this.animation,
    required this.index,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Animation<double> animation;
  final int index;
  final _LevelOptionData option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = 0.14 + (index * 0.14);
    final end = (start + 0.42).clamp(0.0, 1.0).toDouble();
    final cardCurve = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final opacity = Tween<double>(begin: 0.01, end: 1).animate(cardCurve);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(cardCurve);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        transformHitTests: false,
        child: _LevelOptionCard(
          option: option,
          selected: selected,
          onTap: onTap,
        ),
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
      label: _levelLabel(context, option.level),
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
                        _levelLabel(context, option.level),
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
                        _levelDescription(context, option.level),
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

String _levelLabel(BuildContext context, LearningLanguageLevel level) =>
    switch (level) {
      LearningLanguageLevel.beginner => context.l10n.levelBeginner,
      LearningLanguageLevel.intermediate => context.l10n.levelIntermediate,
      LearningLanguageLevel.advanced => context.l10n.levelAdvanced,
    };

String _levelDescription(BuildContext context, LearningLanguageLevel level) =>
    switch (level) {
      LearningLanguageLevel.beginner => context.l10n.levelBeginnerDescription,
      LearningLanguageLevel.intermediate =>
        context.l10n.levelIntermediateDescription,
      LearningLanguageLevel.advanced => context.l10n.levelAdvancedDescription,
    };

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
    required this.imageAsset,
    required this.imageBackground,
  });

  final LearningLanguageLevel level;
  final String imageAsset;
  final Color imageBackground;
}
