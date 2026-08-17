import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';

class LevelAssessmentIntroScreen extends StatefulWidget {
  const LevelAssessmentIntroScreen({super.key});

  @override
  State<LevelAssessmentIntroScreen> createState() =>
      _LevelAssessmentIntroScreenState();
}

class _LevelAssessmentIntroScreenState extends State<LevelAssessmentIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _panelOpacity;
  late final Animation<double> _skipOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _backgroundOpacity = Tween<double>(begin: 0.01, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.42, curve: Curves.easeOut),
      ),
    );
    _headerOpacity = Tween<double>(begin: 0.01, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.04, 0.52, curve: Curves.easeOut),
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
        curve: const Interval(0.14, 0.76, curve: Curves.easeOut),
      ),
    );
    _skipOpacity = Tween<double>(begin: 0.01, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 1, curve: Curves.easeOut),
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
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/bg_choose_language.png',
              fit: BoxFit.cover,
              opacity: _backgroundOpacity,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _headerOpacity,
                    child: SlideTransition(
                      position: _headerSlide,
                      transformHitTests: false,
                      child: const _AssessmentHeader(),
                    ),
                  ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _panelOpacity,
                      child: _AssessmentPanel(
                        isFinishing: false,
                        onStartTest: () => context.push(
                          '/onboarding/assessment-intro/assessment-level',
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: _skipOpacity,
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                      child: TextButton(
                        key: const ValueKey('assessment-skip'),
                        onPressed: () =>
                            context.push('/onboarding/assessment-intro/level'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF155CFF),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: Text(context.l10n.assessmentSkip),
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

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 16,
            child: Semantics(
              label: context.l10n.back,
              button: true,
              child: InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/onboarding/language');
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 45,
            // right: 135,
            top: 70,
            child: Text(
              context.l10n.assessmentTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Positioned(
            left: 35,
            // right: 125,
            top: 100,
            child: Text(
              context.l10n.assessmentSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12.5,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 45,
            child: Image.asset(
              'assets/images/owls/owl_test.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentPanel extends StatelessWidget {
  const _AssessmentPanel({
    required this.isFinishing,
    required this.onStartTest,
  });

  final bool isFinishing;
  final VoidCallback onStartTest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFF),
        borderRadius: BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x29031A55),
            blurRadius: 28,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 38,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Spacer(),
                    SizedBox(
                      width: 240,
                      height: 190,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 38,
                            top: 8,
                            child: SizedBox.square(
                              dimension: 164,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEAF2FF),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 45,
                            top: 24,
                            width: 150,
                            child: ClipPath(
                              clipper: const _BadgeAssetClipper(),
                              child: Opacity(
                                opacity: 0.72,
                                child: Image.asset(
                                  'assets/images/onboarding/target_question.png',
                                  cacheWidth: 700,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 20,
                            top: 123,
                            child: _FourPointSparkle(
                              size: 14,
                              color: Color(0xFF9DBFFF),
                            ),
                          ),
                          const Positioned(
                            left: 77,
                            top: 32,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(dimension: 5),
                            ),
                          ),
                          const Positioned(
                            right: 63,
                            top: 33,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFC4D9FF),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(dimension: 5),
                            ),
                          ),
                          const Positioned(
                            left: 185,
                            top: 13,
                            child: _FourPointSparkle(
                              size: 15,
                              color: Color(0xFFA8C6FF),
                            ),
                          ),
                          const Positioned(
                            right: 24,
                            top: 132,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFCFDDF8),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(dimension: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.assessmentTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF061D4C),
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 17),
                    const _AssessmentBenefits(),
                    const Spacer(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        key: const ValueKey('assessment-start'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFinishing
                                ? const [Color(0xFF78A2FF), Color(0xFF8DB4FF)]
                                : const [
                                    Color(0xFF063AAE),
                                    Color(0xFF0C54E7),
                                    Color(0xFF1676FF),
                                  ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D155CFF),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: isFinishing ? null : onStartTest,
                            borderRadius: BorderRadius.circular(18),
                            child: Center(
                              child: isFinishing
                                  ? const SizedBox.square(
                                      dimension: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      context.l10n.assessmentStart,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
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

class _AssessmentBenefits extends StatelessWidget {
  const _AssessmentBenefits();

  @override
  Widget build(BuildContext context) {
    final benefits = [
      context.l10n.assessmentBenefitLevel,
      context.l10n.assessmentBenefitVocabulary,
      context.l10n.assessmentBenefitAdapt,
    ];
    return Column(
      children: [
        for (final benefit in benefits)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/svgs/onboarding/choose_checked.svg',
                  width: 23,
                  height: 23,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      color: Color(0xFF082657),
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BadgeAssetClipper extends CustomClipper<Path> {
  const _BadgeAssetClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.77, size.height * 0.09),
          radius: size.width * 0.07,
        ),
      );
  }

  @override
  bool shouldReclip(_BadgeAssetClipper oldClipper) => false;
}

class _FourPointSparkle extends StatelessWidget {
  const _FourPointSparkle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FourPointSparklePainter(color),
    );
  }
}

class _FourPointSparklePainter extends CustomPainter {
  const _FourPointSparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.62, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.62, size.height * 0.62)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.62)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.38)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FourPointSparklePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
