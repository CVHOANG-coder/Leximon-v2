import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/iap_packages_response.dart';
import '../../../data/services/iap_catalog_service.dart';
import '../../../data/services/iap_purchase_service.dart';
import '../../../shared/providers/app_providers.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  String? _selectedProductId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(iapCatalogProvider);
    final catalog = catalogState.valueOrNull;
    final packages = catalog?.subscriptionPackages ?? const <IapPackage>[];
    final selectedPackage = _selectedPackage(packages, catalog);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('subscription-screen'),
        backgroundColor: const Color(0xFFF9FCFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 20,
                ),
                child: Column(
                  children: [
                    const _SubscriptionHero(),
                    _TrialHeadline(trialDays: selectedPackage?.trialDays ?? 7),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildContent(
                        context,
                        catalogState,
                        catalog,
                        packages,
                        selectedPackage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<IapCatalog> catalogState,
    IapCatalog? catalog,
    List<IapPackage> packages,
    IapPackage? selectedPackage,
  ) {
    if (packages.isEmpty && catalogState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: CircularProgressIndicator(color: Color(0xFF2271F5)),
      );
    }

    if (packages.isEmpty) {
      return _SubscriptionLoadError(
        onRetry: () => ref.invalidate(iapCatalogProvider),
      );
    }

    final package = selectedPackage!;
    final featuredPackage = _featuredPackage(packages, catalog);
    final selectedProduct = catalog?.productFor(package);
    final currentPrice = _displayPrice(selectedProduct);

    return Column(
      children: [
        ..._buildPlanCards(
          packages: packages,
          catalog: catalog,
          selectedPackage: package,
          featuredPackage: featuredPackage,
        ),
        const SizedBox(height: 16),
        const _SubscriptionBenefitsCard(),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFF8391AA), size: 17),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.l10n.text('saleSecurePayment'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF687897),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.text(
            'saleChooseAfterTrial',
            values: {'days': package.trialDays},
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF536686),
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 13),
        _SubscriptionStartButton(
          key: const ValueKey('subscription-start'),
          isLoading: _isSubmitting,
          enabled: selectedProduct != null && currentPrice != null,
          onTap: _startSubscription,
        ),
        // Temporarily hide the standalone "Free trial only" action.
        /*
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            key: const ValueKey('subscription-later'),
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10AF54),
              side: const BorderSide(color: Color(0xFF10AF54), width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              context.l10n.text('subscriptionTrialOnly'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        */
      ],
    );
  }

  List<Widget> _buildPlanCards({
    required List<IapPackage> packages,
    required IapCatalog? catalog,
    required IapPackage selectedPackage,
    required IapPackage? featuredPackage,
  }) {
    final children = <Widget>[];
    for (var index = 0; index < packages.length; index++) {
      final plan = packages[index];
      final isFeatured = plan.productId == featuredPackage?.productId;
      final previousIsFeatured =
          index > 0 &&
          packages[index - 1].productId == featuredPackage?.productId;
      final nextIsFeatured =
          index + 1 < packages.length &&
          packages[index + 1].productId == featuredPackage?.productId;

      children.add(
        _SubscriptionPlanCard(
          key: ValueKey('subscription-plan-${plan.productId}'),
          package: plan,
          product: catalog?.productFor(plan),
          selected: plan.productId == selectedPackage.productId,
          featured: isFeatured,
          topSpacing: isFeatured || previousIsFeatured ? 16 : 5,
          onTap: () => setState(() => _selectedProductId = plan.productId),
        ),
      );
      if (index + 1 < packages.length) {
        children.add(SizedBox(height: isFeatured || nextIsFeatured ? 14 : 5));
      }
    }
    return children;
  }

  IapPackage? _selectedPackage(List<IapPackage> packages, IapCatalog? catalog) {
    if (packages.isEmpty) return null;
    for (final package in packages) {
      if (package.productId == _selectedProductId) return package;
    }

    return _featuredPackage(packages, catalog);
  }

  IapPackage? _featuredPackage(List<IapPackage> packages, IapCatalog? catalog) {
    if (packages.isEmpty) return null;

    IapPackage? featured;
    var featuredPrice = double.negativeInfinity;
    for (final package in packages) {
      final storePrice = catalog?.productFor(package)?.rawPrice;
      final price = storePrice != null && storePrice.isFinite && storePrice > 0
          ? storePrice
          : package.price;
      if (featured == null || price > featuredPrice) {
        featured = package;
        featuredPrice = price;
      }
    }
    return featured;
  }

  String? _displayPrice(ProductDetails? product) {
    final price = product?.price.trim();
    return price?.isNotEmpty == true ? price : null;
  }

  Future<void> _startSubscription() async {
    if (_isSubmitting) return;
    final catalog = ref.read(iapCatalogProvider).valueOrNull;
    final packages = catalog?.subscriptionPackages ?? const <IapPackage>[];
    final package = _selectedPackage(packages, catalog);
    final product = package == null ? null : catalog?.productFor(package);
    if (package == null || product == null) {
      _showPurchaseMessage(context.l10n.text('iapProductUnavailable'));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(iapPurchaseServiceProvider)
          .purchase(package: package, product: product);
      if (!mounted) return;
      if (!result.isSuccess) {
        setState(() => _isSubmitting = false);
        if (result.status != IapPurchaseResultStatus.canceled) {
          _showPurchaseMessage(_purchaseMessage(result));
        }
        return;
      }

      final isPremium = await _reloadPremiumProfile();
      if (!mounted) return;
      if (!isPremium) {
        setState(() => _isSubmitting = false);
        _showPurchaseMessage(context.l10n.text('iapVerificationFailed'));
        return;
      }

      await ref.read(appLanguageServiceProvider).completeOnboarding();
      if (!mounted) return;
      context.go('/');
    } on Object {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showPurchaseMessage(context.l10n.text('iapPurchaseFailed'));
    }
  }

  Future<bool> _reloadPremiumProfile() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final profile = await ref.refresh(remoteUserProfileProvider.future);
        if (profile.isPremium) return true;
      } on Object {
        // The backend may still be processing the receipt. Retry below.
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    return false;
  }

  String _purchaseMessage(IapPurchaseResult result) {
    final detail = result.message?.trim();
    if (detail?.isNotEmpty == true) return detail!;

    return switch (result.status) {
      IapPurchaseResultStatus.storeUnavailable => context.l10n.text(
        'iapStoreUnavailable',
      ),
      IapPurchaseResultStatus.productUnavailable => context.l10n.text(
        'iapProductUnavailable',
      ),
      IapPurchaseResultStatus.verificationFailed => context.l10n.text(
        'iapVerificationFailed',
      ),
      IapPurchaseResultStatus.busy => context.l10n.text('iapPurchaseBusy'),
      _ => context.l10n.text('iapPurchaseFailed'),
    };
  }

  void _showPurchaseMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1586 / 908,
    child: Image.asset(
      'assets/images/in_app_purchase/banner_subcription_plan.png',
      key: const ValueKey('subscription-hero'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: 1600,
    ),
  );
}

class _TrialHeadline extends StatelessWidget {
  const _TrialHeadline({required this.trialDays});

  final int trialDays;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: context.l10n.text('subscriptionIn')),
              TextSpan(
                text: '$trialDays',
                style: const TextStyle(color: Color(0xFF1466EE)),
              ),
              TextSpan(text: context.l10n.text('subscriptionDaySuffix')),
            ],
          ),
          key: const ValueKey('subscription-headline'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF071735),
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.text('subscriptionHeadlineSubtitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF526584),
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    super.key,
    required this.package,
    required this.product,
    required this.selected,
    required this.featured,
    required this.topSpacing,
    required this.onTap,
  });

  final IapPackage package;
  final ProductDetails? product;
  final bool selected;
  final bool featured;
  final double topSpacing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentPrice = _displayPrice(product);
    final weeklyPrice = _weeklyPrice(context, product, package);
    final originalPrice = featured
        ? _formatStorePrice(context, product, multiplier: 2.27)
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: topSpacing),
              padding: EdgeInsets.fromLTRB(12, 16, 12, 24),
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFFCFEFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1D6AF2)
                      : const Color(0xFFE5EDF7),
                  width: selected ? 2.5 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0x241D6AF2)
                        : const Color(0x122D70B5),
                    blurRadius: selected ? 18 : 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    package.packDurationDay >= 330
                        ? 'assets/images/in_app_purchase/one_year.png'
                        : 'assets/images/in_app_purchase/one_week.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _title(context, package),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF071735),
                            fontSize: 18,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (originalPrice != null)
                          Text(
                            originalPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7E8BA2),
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (currentPrice != null)
                          Text(
                            currentPrice,
                            key: const ValueKey('subscription-price'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF071735)
                                  : const Color(0xFF657492),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (weeklyPrice != null) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 126,
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: weeklyPrice,
                                style: const TextStyle(
                                  color: Color(0xFF2168E8),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' ${context.l10n.text('salePerWeek')}',
                                style: const TextStyle(
                                  color: Color(0xFF657492),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (featured)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8ED),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                context.l10n.text(
                  'subscriptionSavingPercent',
                  values: const {'percent': 56},
                ),
                style: const TextStyle(
                  color: Color(0xFF0E9148),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (featured)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 20, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B8BFF), Color(0xFF1768EE)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: Text(
                context.l10n.text('salePopular'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (selected)
          Positioned(
            top: -2,
            right: -5,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF2675F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
      ],
    );
  }

  String? _displayPrice(ProductDetails? product) {
    final price = product?.price.trim();
    return price?.isNotEmpty == true ? price : null;
  }

  String? _weeklyPrice(
    BuildContext context,
    ProductDetails? product,
    IapPackage package,
  ) {
    if (product == null ||
        package.packDurationDay <= 0 ||
        !product.rawPrice.isFinite ||
        product.rawPrice <= 0) {
      return null;
    }
    final amount = product.rawPrice * 7 / package.packDurationDay;
    if (!amount.isFinite || amount <= 0) return null;
    return _formatStorePrice(context, product, amount: amount);
  }

  String? _formatStorePrice(
    BuildContext context,
    ProductDetails? product, {
    double? amount,
    double? multiplier,
  }) {
    if (product == null ||
        !product.rawPrice.isFinite ||
        product.rawPrice <= 0) {
      return null;
    }
    final value = amount ?? product.rawPrice * (multiplier ?? 1);
    if (!value.isFinite || value <= 0) return null;
    final currencyCode = product.currencyCode.trim().toUpperCase();
    if (currencyCode.isEmpty) return null;
    final currencySymbol = product.currencySymbol.trim();
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      name: currencyCode,
      symbol: currencySymbol.isEmpty ? currencyCode : currencySymbol,
    ).format(value);
  }

  static String _title(BuildContext context, IapPackage package) {
    if (package.name.trim().isNotEmpty) return package.name.trim();
    if (package.packDurationDay >= 36500) {
      return context.l10n.text('subscriptionLifetime');
    }
    if (package.packDurationDay >= 330) {
      return context.l10n.text('subscriptionYears', values: const {'count': 1});
    }
    return context.l10n.text(
      'subscriptionMonths',
      values: {'count': (package.packDurationDay / 30).round()},
    );
  }
}

class _SubscriptionBenefitsCard extends StatelessWidget {
  const _SubscriptionBenefitsCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EBF7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x132D70B5),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _SubscriptionBenefit(
            asset: 'assets/images/in_app_purchase/hoc_khong_gioi_han.png',
            label: context.l10n.text('subscriptionBenefitUnlimited'),
          ),
        ),
        const _SubscriptionBenefitDivider(),
        Expanded(
          child: _SubscriptionBenefit(
            asset: 'assets/images/in_app_purchase/baihoc_chat_luong_cao.png',
            label: context.l10n.text('subscriptionBenefitQuality'),
          ),
        ),
        const _SubscriptionBenefitDivider(),
        Expanded(
          child: _SubscriptionBenefit(
            asset: 'assets/images/in_app_purchase/tien_bo_moi_ngay.png',
            label: context.l10n.text('subscriptionBenefitProgress'),
          ),
        ),
      ],
    ),
  );
}

class _SubscriptionBenefit extends StatelessWidget {
  const _SubscriptionBenefit({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(asset, width: 36, height: 36, fit: BoxFit.contain),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 3,
          style: const TextStyle(
            color: Color(0xFF28446F),
            fontSize: 11,
            height: 1.25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _SubscriptionBenefitDivider extends StatelessWidget {
  const _SubscriptionBenefitDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFFDDE6F1));
}

class _SubscriptionStartButton extends StatelessWidget {
  const _SubscriptionStartButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: enabled
            ? const [Color(0xFF21D86A), Color(0xFF08B95C)]
            : const [Color(0xFFB8CCE5), Color(0xFFB9DEDB)],
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: enabled
          ? const [
              BoxShadow(
                color: Color(0x3A1F8FF1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ]
          : null,
    ),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 23,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/in_app_purchase/vip_icon.png',
                    width: 32,
                    height: 27,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 11),
                  Flexible(
                    child: Text(
                      context.l10n.text('subscriptionStart'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _SubscriptionLoadError extends StatelessWidget {
  const _SubscriptionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Text(
          context.l10n.text('subscriptionLoadError'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF526584), fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}
