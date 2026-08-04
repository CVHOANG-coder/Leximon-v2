import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TrialReminderScreen extends StatefulWidget {
  const TrialReminderScreen({super.key});

  @override
  State<TrialReminderScreen> createState() => _TrialReminderScreenState();
}

class _TrialReminderScreenState extends State<TrialReminderScreen>
    with SingleTickerProviderStateMixin {
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
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _illustrationScale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.62, curve: Curves.easeOutBack),
      ),
    );
    _illustrationSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.58, curve: Curves.easeOutCubic),
          ),
        );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.8, curve: Curves.easeOut),
    );
    _copySlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.32, 0.84, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.34), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.64, 1, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _reminderDateLabel {
    final reminderDate = DateTime.now().add(const Duration(days: 5));
    return '${reminderDate.day}/${reminderDate.month}';
  }

  void _openSubscriptionPlans() {
    context.push('/onboarding/assessment-intro/survey/subscription');
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
                    child: Stack(
                      children: [
                        Column(
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
                                      'assets/images/onboarding/notification_icon.png',
                                      key: const ValueKey(
                                        'trial-reminder-illustration',
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
                                  key: const ValueKey('trial-reminder-copy'),
                                  children: [
                                    const Text(
                                      'Chúng tôi sẽ nhắc bạn',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
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
                                    const SizedBox(height: 5),
                                    const Text(
                                      '2 ngày trước khi',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
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
                                    const SizedBox(height: 7),
                                    const Text(
                                      'kết thúc thời gian dùng thử',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
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
                                    const SizedBox(height: 22),
                                    Text(
                                      'Thông báo đẩy sẽ được gửi vào ngày '
                                      '$_reminderDateLabel',
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
                                child: _TrialReminderButton(
                                  isLoading: false,
                                  onTap: _openSubscriptionPlans,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                        Positioned(
                          top: 2,
                          left: -12,
                          child: IconButton(
                            key: const ValueKey('trial-reminder-back'),
                            tooltip: 'Quay lại',
                            onPressed: context.pop,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 32,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF2887FF),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
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

class _TrialReminderButton extends StatelessWidget {
  const _TrialReminderButton({required this.isLoading, required this.onTap});

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
            key: const ValueKey('trial-reminder-start'),
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
                  : const Text(
                      'Dùng thử miễn phí',
                      style: TextStyle(
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
