import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SurveyIntroScreen extends StatefulWidget {
  const SurveyIntroScreen({super.key});

  @override
  State<SurveyIntroScreen> createState() => _SurveyIntroScreenState();
}

class _SurveyIntroScreenState extends State<SurveyIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _iconOffset;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconOpacity = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );
    _iconOffset = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _iconController, curve: Curves.easeOutCubic),
        );
    _iconController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0870F9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0870F9),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/intro_form_bg.png',
              fit: BoxFit.cover,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final illustrationWidth = math.min(width * 0.86, height * 0.42);
                final titleSize = width < 430 ? 28.0 : 32.0;

                return Stack(
                  children: [
                    Positioned(
                      top: height * 0.18,
                      left: (width - illustrationWidth) / 2,
                      width: illustrationWidth,
                      child: FadeTransition(
                        opacity: _iconOpacity,
                        child: SlideTransition(
                          position: _iconOffset,
                          child: ScaleTransition(
                            scale: _iconScale,
                            child: Image.asset(
                              'assets/images/onboarding/intro_form_icon.png',
                              fit: BoxFit.contain,
                              cacheWidth: 1000,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.61,
                      left: 28,
                      right: 28,
                      child: Text(
                        'Hãy làm một khảo sát\nngắn nhé!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF031B65),
                          fontSize: titleSize,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.73,
                      left: 42,
                      right: 42,
                      child: Text(
                        'Dựa vào câu trả lời của bạn, Leximon sẽ\n'
                        'chọn ra cách học phù hợp nhất với bạn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF032263),
                          fontSize: width < 430 ? 17 : 19,
                          height: 1.42,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      right: 42,
                      bottom: math.max(
                        MediaQuery.paddingOf(context).bottom + 28,
                        42,
                      ),
                      child: SizedBox(
                        height: 68,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF9FCFF),
                                Color(0xFFEAF6FF),
                                Color(0xFFF9FCFF),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x701B8CFF),
                                blurRadius: 26,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color(0x80FFFFFF),
                                blurRadius: 12,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(34),
                            child: InkWell(
                              key: const ValueKey('survey-intro-continue'),
                              onTap: () => context.push(
                                '/onboarding/assessment-intro/survey/questions',
                              ),
                              borderRadius: BorderRadius.circular(34),
                              child: const Center(
                                child: Text(
                                  'Tiếp',
                                  style: TextStyle(
                                    color: Color(0xFF1263F4),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
