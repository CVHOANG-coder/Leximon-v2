import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/daily_notification_service.dart';

class FreeTrialOfferScreen extends StatefulWidget {
  const FreeTrialOfferScreen({super.key});

  @override
  State<FreeTrialOfferScreen> createState() => _FreeTrialOfferScreenState();
}

class _FreeTrialOfferScreenState extends State<FreeTrialOfferScreen>
    with SingleTickerProviderStateMixin {
  bool _saleReminderArmed = false;
  late final AnimationController _controller;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _illustrationScale;
  late final Animation<Offset> _illustrationSlide;
  late final Animation<double> _copyOpacity;
  late final Animation<Offset> _copySlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _illustrationOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _illustrationScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _illustrationSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.56, curve: Curves.easeOutCubic),
          ),
        );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.78, curve: Curves.easeOut),
    );
    _copySlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.32, 0.82, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 1, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.62, 1, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_saleReminderArmed) return;
    _saleReminderArmed = true;
    unawaited(
      DailyNotificationService.instance
          .armAnnualSaleNotification(localizations: context.l10n)
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTrialReminder() {
    context.push('/onboarding/assessment-intro/survey/trial-reminder');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF01062A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF01062A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/bg_open_knowleage.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final illustrationHeight = (constraints.maxHeight * 0.43)
                      .clamp(275.0, 350.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _illustrationOpacity,
                          child: SlideTransition(
                            position: _illustrationSlide,
                            child: ScaleTransition(
                              scale: _illustrationScale,
                              child: SizedBox(
                                height: illustrationHeight,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/images/onboarding/calendar_free_7_days.png',
                                  key: const ValueKey(
                                    'free-trial-illustration',
                                  ),
                                  fit: BoxFit.contain,
                                  cacheWidth: 1200,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: _copyOpacity,
                          child: SlideTransition(
                            position: _copySlide,
                            child: Column(
                              key: const ValueKey('free-trial-copy'),
                              children: [
                                Text(
                                  context.l10n.text('freeTrialGift'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    height: 1.15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xA000144D),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  context.l10n.text('freeTrialDuration'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 35,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF297BFF),
                                        blurRadius: 15,
                                      ),
                                      Shadow(
                                        color: Color(0xA000144D),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  context.l10n.text('freeTrialPurpose'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.4,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xA000144D),
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 22),
                                Text(
                                  context.l10n.text('freeTrialNoPayment'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF9EBEFF),
                                    fontSize: 16.5,
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        FadeTransition(
                          opacity: _buttonOpacity,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: _FreeTrialButton(
                              isLoading: false,
                              onTap: _openTrialReminder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeTrialButton extends StatelessWidget {
  const _FreeTrialButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFEAF4FF), Color(0xFFFDFEFF)],
          ),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF4C83FF), width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0xC02275FF),
              blurRadius: 22,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Color(0x702579FF),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(38),
          child: InkWell(
            key: const ValueKey('free-trial-start'),
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(38),
            child: Center(
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 25,
                      child: CircularProgressIndicator(
                        color: Color(0xFF155BF3),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      context.l10n.text('freeTrialStart'),
                      style: const TextStyle(
                        color: Color(0xFF155BF3),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
