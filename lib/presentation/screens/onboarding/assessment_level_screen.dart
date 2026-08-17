import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/onboarding_vocabulary_test.dart';

class AssessmentLevelScreen extends StatefulWidget {
  const AssessmentLevelScreen({super.key});

  @override
  State<AssessmentLevelScreen> createState() => _AssessmentLevelScreenState();
}

class _AssessmentLevelScreenState extends State<AssessmentLevelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _panelOpacity;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
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
        curve: const Interval(0.12, 0.78, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    top: 200,
                    child: FadeTransition(
                      opacity: _panelOpacity,
                      child: _AssessmentLevelPanel(
                        entranceAnimation: _controller,
                        selectedOption: _selectedOption,
                        onSelected: (index) {
                          setState(() => _selectedOption = index);
                        },
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
                        child: const _AssessmentLevelHeader(),
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

class _AssessmentLevelHeader extends StatelessWidget {
  const _AssessmentLevelHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 14,
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
            left: 30,
            top: 64,
            child: Text(
              context.l10n.text('assessmentLevelTitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 150,
            child: Text(
              context.l10n.text('assessmentLevelSubtitle'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: -3,
            top: 16,
            child: Image.asset(
              'assets/images/owls/owl_learn.png',
              width: 151,
              height: 192,
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

class _AssessmentLevelPanel extends StatelessWidget {
  const _AssessmentLevelPanel({
    required this.entranceAnimation,
    required this.selectedOption,
    required this.onSelected,
  });

  final Animation<double> entranceAnimation;
  final int? selectedOption;
  final ValueChanged<int> onSelected;

  List<_AssessmentOptionData> _options(BuildContext context) => [
    _AssessmentOptionData(
      text: context.l10n.text('assessmentLevelNew'),
      imageAsset: 'assets/images/onboarding/scooter.png',
      startingBand: VocabularyStartingBand.beginner,
    ),
    _AssessmentOptionData(
      text: context.l10n.text('assessmentLevelBasic'),
      imageAsset: 'assets/images/onboarding/bike.png',
      startingBand: VocabularyStartingBand.beginner,
    ),
    _AssessmentOptionData(
      text: context.l10n.text('assessmentLevelConversational'),
      imageAsset: 'assets/images/onboarding/car.png',
      startingBand: VocabularyStartingBand.intermediate,
    ),
    _AssessmentOptionData(
      text: context.l10n.text('assessmentLevelFluent'),
      imageAsset: 'assets/images/onboarding/rocket.png',
      startingBand: VocabularyStartingBand.advanced,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final options = _options(context);
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
          final compact = constraints.maxWidth < 430;
          final horizontalPadding = compact ? 28.0 : 33.0;
          final cardHeight = compact ? 112.0 : 103.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              26,
              horizontalPadding,
              16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 42,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    for (var index = 0; index < options.length; index++) ...[
                      _AnimatedAssessmentOptionCard(
                        animation: entranceAnimation,
                        index: index,
                        option: options[index],
                        selected: selectedOption == index,
                        compact: compact,
                        height: cardHeight,
                        onTap: () => onSelected(index),
                      ),
                      if (index != options.length - 1)
                        const SizedBox(height: 10),
                    ],
                    const Spacer(),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0C4DE4), Color(0xFF147BFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(19),
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
                          borderRadius: BorderRadius.circular(19),
                          child: InkWell(
                            key: const ValueKey('assessment-level-start'),
                            onTap: selectedOption == null
                                ? null
                                : () => context.push(
                                    '/onboarding/assessment-intro/'
                                    'vocabulary-test?band='
                                    '${options[selectedOption!].startingBand.queryValue}',
                                  ),
                            borderRadius: BorderRadius.circular(19),
                            child: Center(
                              child: Text(
                                context.l10n.text('assessmentLevelStart'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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

class _AnimatedAssessmentOptionCard extends StatelessWidget {
  const _AnimatedAssessmentOptionCard({
    required this.animation,
    required this.index,
    required this.option,
    required this.selected,
    required this.compact,
    required this.height,
    required this.onTap,
  });

  final Animation<double> animation;
  final int index;
  final _AssessmentOptionData option;
  final bool selected;
  final bool compact;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = 0.14 + (index * 0.11);
    final end = (start + 0.38).clamp(0.0, 1.0).toDouble();
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
        child: _AssessmentOptionCard(
          option: option,
          selected: selected,
          compact: compact,
          height: height,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _AssessmentOptionCard extends StatelessWidget {
  const _AssessmentOptionCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.height,
    required this.onTap,
  });

  final _AssessmentOptionData option;
  final bool selected;
  final bool compact;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: option.text.replaceAll('\n', ' '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('assessment-option-${option.imageAsset}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 11 : 10,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF2F7FF) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9FC4FF)
                    : const Color(0xFFEAF0F8),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14234381),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 74 : 84,
                  height: compact ? 86 : 83,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.all(compact ? 5 : 6),
                  child: Image.asset(
                    option.imageAsset,
                    fit: BoxFit.contain,
                    cacheWidth: 420,
                  ),
                ),
                SizedBox(width: compact ? 14 : 18),
                Expanded(
                  child: Text(
                    option.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF071944),
                      fontSize: compact ? 14.5 : 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 14),
                _AssessmentRadio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssessmentRadio extends StatelessWidget {
  const _AssessmentRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF13BD2A) : const Color(0xFFD5DDEB),
          width: 2.5,
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

class _AssessmentOptionData {
  const _AssessmentOptionData({
    required this.text,
    required this.imageAsset,
    required this.startingBand,
  });

  final String text;
  final String imageAsset;
  final VocabularyStartingBand startingBand;
}
