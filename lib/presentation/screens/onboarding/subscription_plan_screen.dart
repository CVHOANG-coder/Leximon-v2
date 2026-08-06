import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/app_providers.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends ConsumerState<SubscriptionPlanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _illustrationOpacity;
  late final Animation<double> _illustrationScale;
  late final Animation<Offset> _illustrationSlide;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _plansOpacity;
  late final Animation<Offset> _plansSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  int _selectedPlanMonths = 12;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _illustrationOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.34, curve: Curves.easeOut),
    );
    _illustrationScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _illustrationSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.48, curve: Curves.easeOutCubic),
          ),
        );
    _headlineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.62, curve: Curves.easeOut),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.22, 0.66, curve: Curves.easeOutCubic),
          ),
        );
    _plansOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.86, curve: Curves.easeOut),
    );
    _plansSlide = Tween<Offset>(begin: const Offset(0, 0.24), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.44, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.32), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.68, 1, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSubscription() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ref.read(appLanguageServiceProvider).completeOnboarding();
      if (!mounted) return;
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hoàn tất thiết lập. Vui lòng thử lại.'),
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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _illustrationOpacity,
                          child: SlideTransition(
                            position: _illustrationSlide,
                            child: ScaleTransition(
                              scale: _illustrationScale,
                              child: SizedBox(
                                height: 238,
                                width: double.infinity,
                                child: Image.asset(
                                  'assets/images/onboarding/in_app_puchase.png',
                                  key: const ValueKey(
                                    'subscription-illustration',
                                  ),
                                  fit: BoxFit.contain,
                                  cacheWidth: 1200,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FadeTransition(
                          opacity: _headlineOpacity,
                          child: SlideTransition(
                            position: _headlineSlide,
                            child: const Column(
                              key: ValueKey('subscription-headline'),
                              children: [
                                _TwentyEightDayHeadline(),
                                SizedBox(height: 8),
                                Text(
                                  'tiếng Anh của bạn sẽ trở thành công cụ\n'
                                  'đáng tin cậy trong công việc',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.3,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xA000144D),
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        FadeTransition(
                          opacity: _plansOpacity,
                          child: SlideTransition(
                            position: _plansSlide,
                            child: Column(
                              key: const ValueKey('subscription-plans'),
                              children: [
                                _SubscriptionPlanCard(
                                  key: const ValueKey(
                                    'subscription-plan-2-month',
                                  ),
                                  months: 2,
                                  totalPrice: '799.000 đ',
                                  monthlyPrice: '399.500 đ / thg',
                                  selected: _selectedPlanMonths == 2,
                                  onTap: () {
                                    setState(() => _selectedPlanMonths = 2);
                                  },
                                ),
                                const SizedBox(height: 28),
                                _SubscriptionPlanCard(
                                  key: const ValueKey(
                                    'subscription-plan-12-month',
                                  ),
                                  months: 12,
                                  originalPrice: '4.770.500 đ',
                                  totalPrice: '2.099.000 đ',
                                  monthlyPrice: '174.917 đ / thg',
                                  isPopular: true,
                                  selected: _selectedPlanMonths == 12,
                                  onTap: () {
                                    setState(() => _selectedPlanMonths = 12);
                                  },
                                ),
                                const SizedBox(height: 13),
                                const Text(
                                  'Chọn gói đăng ký\n'
                                  'sau 7 ngày dùng thử miễn phí',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFAAC7FF),
                                    fontSize: 15,
                                    height: 1.25,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        FadeTransition(
                          opacity: _buttonOpacity,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: _SubscriptionStartButton(
                              isLoading: _isSubmitting,
                              onTap: _startSubscription,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 31,
                          shadows: [
                            Shadow(color: Color(0xFF287EFF), blurRadius: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 2,
                    left: 12,
                    child: IconButton(
                      key: const ValueKey('subscription-back'),
                      tooltip: 'Quay lại',
                      onPressed: context.pop,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 32,
                        shadows: [
                          Shadow(color: Color(0xFF2887FF), blurRadius: 10),
                        ],
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

class _TwentyEightDayHeadline extends StatelessWidget {
  const _TwentyEightDayHeadline();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 29,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.7,
      shadows: [
        Shadow(color: Color(0xFF287BFF), blurRadius: 10),
        Shadow(color: Color(0xA000144D), blurRadius: 7, offset: Offset(0, 3)),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Trong ', style: style),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF082C93).withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6AD8FF), width: 1.1),
              boxShadow: const [
                BoxShadow(color: Color(0xFF267CFF), blurRadius: 16),
              ],
            ),
            child: const Text('28', style: style),
          ),
          const Text(' ngày', style: style),
        ],
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    super.key,
    required this.months,
    required this.totalPrice,
    required this.monthlyPrice,
    required this.selected,
    required this.onTap,
    this.originalPrice,
    this.isPopular = false,
  });

  final int months;
  final String? originalPrice;
  final String totalPrice;
  final String monthlyPrice;
  final bool isPopular;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? const Color(0xFF061541) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: originalPrice == null ? 82 : 98,
          padding: EdgeInsets.fromLTRB(21, isPopular ? 25 : 14, 19, 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFEAF4FF)],
                  )
                : const LinearGradient(
                    colors: [Color(0xB512326F), Color(0xB506154B)],
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF62CFFF)
                  : const Color(0xFF4A7CFF),
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0xB02583FF)
                    : const Color(0x70113DAD),
                blurRadius: selected ? 20 : 13,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$months tháng',
                          maxLines: 1,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 20,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (originalPrice == null)
                          Text(
                            totalPrice,
                            style: const TextStyle(
                              color: Color(0xFF8AAEFF),
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    originalPrice!,
                                    style: const TextStyle(
                                      color: Color(0xFFD72B36),
                                      fontSize: 15.5,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Color(0xFFD72B36),
                                      decorationThickness: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Text(
                                    totalPrice,
                                    style: TextStyle(
                                      color: foregroundColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 9,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          monthlyPrice,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF1657E8)
                                : const Color(0xFF8AAEFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isPopular)
                Positioned(
                  // The Stack is inside the card's top padding. Move the
                  // badge above that padding so it never covers the plan.
                  top: -40,
                  left: -24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF65DFFF), Color(0xFF176BFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCC1684FF),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'PHỔ BIẾN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (selected)
                Positioned(
                  top: -30,
                  right: -27,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF55D86B), Color(0xFF0DBB48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x9900D85A), blurRadius: 12),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionStartButton extends StatelessWidget {
  const _SubscriptionStartButton({
    required this.isLoading,
    required this.onTap,
  });

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
            colors: [Color(0xFFFFFFFF), Color(0xFFDDECFF), Color(0xFF7FB5FF)],
            stops: [0, 0.6, 1],
          ),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFF72D5FF), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xD02B7DFF),
              blurRadius: 23,
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
            key: const ValueKey('subscription-start'),
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
                      'Dùng thử miễn phí\nvà đăng ký',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF155BF3),
                        fontSize: 20,
                        height: 1.05,
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
