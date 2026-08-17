import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/iap_packages_response.dart';
import '../../../data/services/iap_catalog_service.dart';
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

  String? _selectedProductId;
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
        SnackBar(content: Text(context.l10n.text('subscriptionCompleteError'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(iapCatalogProvider);
    final catalog = catalogState.valueOrNull;
    final packages = catalog?.packages ?? const <IapPackage>[];

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
                            child: Column(
                              key: const ValueKey('subscription-headline'),
                              children: [
                                const _TwentyEightDayHeadline(),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n.text(
                                    'subscriptionHeadlineSubtitle',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
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
                              children: _buildPlanContent(
                                catalogState: catalogState,
                                catalog: catalog,
                                packages: packages,
                              ),
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
                      tooltip: context.l10n.back,
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

  List<Widget> _buildPlanContent({
    required AsyncValue<IapCatalog> catalogState,
    required IapCatalog? catalog,
    required List<IapPackage> packages,
  }) {
    if (packages.isEmpty && catalogState.isLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: Color(0xFF8CCBFF)),
        ),
        Text(
          context.l10n.text('subscriptionLoadingPlans'),
          style: const TextStyle(color: Color(0xFFAAC7FF), fontSize: 15),
        ),
      ];
    }

    if (packages.isEmpty) {
      return [
        Text(
          context.l10n.text('subscriptionLoadError'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFAAC7FF), fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.invalidate(iapCatalogProvider),
          child: Text(context.l10n.retry),
        ),
      ];
    }

    final selectedPackage = packages.firstWhere(
      (item) => item.productId == _selectedProductId,
      orElse: () => packages.first,
    );

    final children = <Widget>[];
    for (var index = 0; index < packages.length; index++) {
      final package = packages[index];
      final isSelected = package.productId == selectedPackage.productId;
      final storePrice = catalog?.storePriceFor(package);
      children.add(
        _SubscriptionPlanCard(
          key: ValueKey('subscription-plan-${package.productId}'),
          title: package.name,
          description: package.description,
          durationLabel: _durationLabel(package.packDurationDay),
          storePrice:
              storePrice ??
              context.l10n.text('subscriptionStorePriceUnavailable'),
          badgeLabel: package.group == 'SALE'
              ? context.l10n.text('subscriptionSale')
              : null,
          selected: isSelected,
          onTap: () {
            setState(() => _selectedProductId = package.productId);
          },
        ),
      );
      if (index < packages.length - 1) {
        children.add(const SizedBox(height: 18));
      }
    }

    if (selectedPackage.trialDays > 0) {
      children.add(const SizedBox(height: 13));
      children.add(
        Text(
          context.l10n.text(
            'subscriptionTrialDays',
            values: {'days': selectedPackage.trialDays},
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFAAC7FF),
            fontSize: 15,
            height: 1.25,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return children;
  }

  String _durationLabel(int days) {
    if (days >= 36500) return context.l10n.text('subscriptionLifetime');
    if (days >= 365) {
      return context.l10n.text(
        'subscriptionYears',
        values: {'count': (days / 365).round()},
      );
    }
    if (days >= 30) {
      return context.l10n.text(
        'subscriptionMonths',
        values: {'count': (days / 30).round()},
      );
    }
    if (days >= 7) {
      return context.l10n.text(
        'subscriptionWeeks',
        values: {'count': (days / 7).round()},
      );
    }
    return context.l10n.text('subscriptionDays', values: {'count': days});
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
          Text(context.l10n.text('subscriptionIn'), style: style),
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
          Text(context.l10n.text('subscriptionDaySuffix'), style: style),
        ],
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    super.key,
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.storePrice,
    required this.selected,
    required this.onTap,
    this.badgeLabel,
  });

  final String title;
  final String description;
  final String durationLabel;
  final String storePrice;
  final String? badgeLabel;
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
          constraints: const BoxConstraints(minHeight: 116),
          padding: EdgeInsets.fromLTRB(
            21,
            badgeLabel == null ? 15 : 25,
            19,
            15,
          ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          durationLabel,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF1657E8)
                                : const Color(0xFF8AAEFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 18,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF405A91)
                                : const Color(0xFFAAC7FF),
                            fontSize: 12.5,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      storePrice,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF1657E8)
                            : const Color(0xFF8AAEFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (badgeLabel != null)
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          badgeLabel!,
                          style: const TextStyle(
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
                  : Text(
                      context.l10n.text('subscriptionStart'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
