import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/iap_packages_response.dart';
import '../../../data/services/iap_catalog_service.dart';
import '../../../data/services/iap_purchase_service.dart';
import '../../../shared/providers/app_providers.dart';

class SalePackageScreen extends ConsumerStatefulWidget {
  const SalePackageScreen({super.key});

  @override
  ConsumerState<SalePackageScreen> createState() => _SalePackageScreenState();
}

class _SalePackageScreenState extends ConsumerState<SalePackageScreen> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(iapCatalogProvider);
    final catalog = catalogState.valueOrNull;
    final package = catalog?.salePackages.firstOrNull;
    final regularPackage = _findRegularPackage(catalog, package);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('sale-package-screen'),
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
                    const _SaleHero(),
                    _SaleHeadline(trialDays: package?.trialDays ?? 7),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPackageContent(
                        catalogState,
                        catalog,
                        package,
                        regularPackage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 16,
              child: Material(
                color: Colors.white.withValues(alpha: .86),
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: const Color(0x33295282),
                child: IconButton(
                  key: const ValueKey('sale-package-back'),
                  tooltip: context.l10n.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF112958),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageContent(
    AsyncValue<IapCatalog> catalogState,
    IapCatalog? catalog,
    IapPackage? package,
    IapPackage? regularPackage,
  ) {
    if (package == null && catalogState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: CircularProgressIndicator(color: Color(0xFF2271F5)),
      );
    }

    if (package == null) {
      return _LoadError(onRetry: () => ref.invalidate(iapCatalogProvider));
    }

    final currentPrice = _displayPrice(catalog, package);
    final originalPrice = regularPackage == null
        ? null
        : _displayPrice(catalog, regularPackage);
    final saving = regularPackage == null
        ? null
        : _savingLabel(package, regularPackage);
    final trialDays = package.trialDays;

    return Column(
      children: [
        _SalePlanCard(
          package: package,
          currentPrice: currentPrice,
          originalPrice: originalPrice,
          saving: saving,
          monthlyPrice: _monthlyPriceLabel(package),
        ),
        const SizedBox(height: 16),
        const _BenefitsCard(),
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
            values: {'days': trialDays},
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
        _SaleButton(
          loading: _isPurchasing,
          enabled: !_isPurchasing,
          label: context.l10n.text('saleStartTrial'),
          onTap: _buy,
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            key: const ValueKey('sale-package-later'),
            onPressed: _isPurchasing
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
              context.l10n.text('saleLater'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  IapPackage? _findRegularPackage(
    IapCatalog? catalog,
    IapPackage? salePackage,
  ) {
    if (catalog == null || salePackage == null) return null;
    IapPackage? bestMatch;
    for (final candidate in catalog.subscriptionPackages) {
      if (candidate.packDurationDay != salePackage.packDurationDay) continue;
      if (bestMatch == null || candidate.price > bestMatch.price) {
        bestMatch = candidate;
      }
    }
    return bestMatch;
  }

  String _displayPrice(IapCatalog? catalog, IapPackage package) {
    final storePrice = catalog?.storePriceFor(package)?.trim();
    if (storePrice?.isNotEmpty == true) return storePrice!;
    return _formatCurrency(package, package.price);
  }

  String? _savingLabel(IapPackage sale, IapPackage regular) {
    final amount = regular.price - sale.price;
    if (!amount.isFinite || amount <= 0) return null;
    return _formatCurrency(sale, amount);
  }

  String? _monthlyPriceLabel(IapPackage package) {
    if (package.packDurationDay < 28 || package.price <= 0) return null;
    final months = package.packDurationDay / (365 / 12);
    if (months <= 0) return null;
    return _formatCurrency(package, package.price / months);
  }

  String _formatCurrency(IapPackage package, double amount) {
    final fixed = amount.toStringAsFixed(2);
    final value = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    final currency = package.currency.trim().toUpperCase();
    if (currency.isEmpty || currency == 'USD' || currency == r'$') {
      return '\$$value';
    }
    return '$value $currency';
  }

  Future<void> _buy() async {
    if (_isPurchasing) return;
    final catalog = ref.read(iapCatalogProvider).valueOrNull;
    final package = catalog?.salePackages.firstOrNull;
    final product = package == null ? null : catalog?.productFor(package);
    if (package == null || product == null) {
      _showMessage(context.l10n.text('salePackageUnavailable'));
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      final result = await ref
          .read(iapPurchaseServiceProvider)
          .purchase(package: package, product: product);
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      if (result.isSuccess) {
        ref.invalidate(remoteUserProfileProvider);
        Navigator.of(context).pop(true);
        return;
      }
      if (result.status != IapPurchaseResultStatus.canceled) {
        _showMessage(_purchaseMessage(result));
      }
    } on Object {
      if (!mounted) return;
      setState(() => _isPurchasing = false);
      _showMessage(context.l10n.text('salePurchaseError'));
    }
  }

  String _purchaseMessage(IapPurchaseResult result) => switch (result.status) {
    IapPurchaseResultStatus.storeUnavailable => context.l10n.text(
      'iapStoreUnavailable',
    ),
    IapPurchaseResultStatus.productUnavailable => context.l10n.text(
      'salePackageUnavailable',
    ),
    IapPurchaseResultStatus.verificationFailed =>
      result.message?.trim().isNotEmpty == true
          ? result.message!
          : context.l10n.text('iapVerificationFailed'),
    IapPurchaseResultStatus.busy => context.l10n.text('iapPurchaseBusy'),
    _ => context.l10n.text('salePurchaseError'),
  };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SaleHero extends StatelessWidget {
  const _SaleHero();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1586 / 908,
    child: Image.asset(
      'assets/images/in_app_purchase/banner_sale_plan.png',
      key: const ValueKey('sale-package-hero'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: 1600,
    ),
  );
}

class _SaleHeadline extends StatelessWidget {
  const _SaleHeadline({required this.trialDays});

  final int trialDays;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: context.l10n.text('saleHeadlinePrefix')),
              TextSpan(
                text: context.l10n.text(
                  'saleHeadlineDays',
                  values: {'days': trialDays},
                ),
                style: const TextStyle(color: Color(0xFF1466EE)),
              ),
            ],
          ),
          key: const ValueKey('sale-package-headline'),
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
          context.l10n.text('saleHeadlineSubtitle'),
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

class _SalePlanCard extends StatelessWidget {
  const _SalePlanCard({
    required this.package,
    required this.currentPrice,
    required this.originalPrice,
    required this.saving,
    required this.monthlyPrice,
  });

  final IapPackage package;
  final String currentPrice;
  final String? originalPrice;
  final String? saving;
  final String? monthlyPrice;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        key: const ValueKey('sale-package-plan-card'),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(16, 34, 16, 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9E6F8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x182D70B5),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/in_app_purchase/calendar_sale_icon.png',
                  width: 82,
                  height: 88,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _planTitle(context, package.packDurationDay),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF071735),
                          fontSize: 21,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              currentPrice,
                              key: const ValueKey('sale-package-price'),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF1B61EA),
                                fontSize: 28,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              _periodLabel(context, package.packDurationDay),
                              style: const TextStyle(
                                color: Color(0xFF657492),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                originalPrice!,
                                style: const TextStyle(
                                  color: Color(0xFF7B879F),
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (monthlyPrice != null || saving != null) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  if (monthlyPrice != null)
                    Expanded(
                      child: Text(
                        context.l10n.text(
                          'saleApproxMonthly',
                          values: {'price': monthlyPrice},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF637392),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (monthlyPrice != null && saving != null)
                    const SizedBox(width: 8),
                  if (saving != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        context.l10n.text(
                          'saleSaveAmount',
                          values: {'amount': saving},
                        ),
                        style: const TextStyle(
                          color: Color(0xFF079342),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66A8FF), Color(0xFF1461F0)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(19),
              topRight: Radius.circular(19),
              bottomRight: Radius.circular(19),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Text(
                context.l10n.text('salePopular'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 34,
        right: 15,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF08C86D), Color(0xFF00A94F)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            context.l10n.text('saleBigSaving'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      if (package.trialDays > 0)
        Positioned(
          bottom: -1,
          left: 105,
          right: 105,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/in_app_purchase/gift.png',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    context.l10n.text(
                      'saleTrialDays',
                      values: {'days': package.trialDays},
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF079342),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  static String _planTitle(BuildContext context, int days) {
    if (days >= 330) return context.l10n.text('saleAnnualPlan');
    if (days >= 28) return context.l10n.text('saleMonthlyPlan');
    return context.l10n.text('saleWeeklyPlan');
  }

  static String _periodLabel(BuildContext context, int days) {
    if (days >= 330) return context.l10n.text('salePerYear');
    if (days >= 28) return context.l10n.text('salePerMonth');
    return context.l10n.text('salePerWeek');
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
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
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/open_all_course.png',
            label: context.l10n.text('saleBenefitUnlock'),
          ),
        ),
        const _BenefitDivider(),
        Expanded(
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/no_ads.png',
            label: context.l10n.text('saleBenefitNoAds'),
          ),
        ),
        const _BenefitDivider(),
        Expanded(
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/tien_bo_moi_ngay.png',
            label: context.l10n.text('saleBenefitProgress'),
          ),
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(asset, width: 42, height: 42, fit: BoxFit.contain),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 3,
          style: const TextStyle(
            color: Color(0xFF28446F),
            fontSize: 11,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFFDDE6F1));
}

class _SaleButton extends StatelessWidget {
  const _SaleButton({
    required this.loading,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2B72FA), Color(0xFF20D4C8)],
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3A1F8FF1),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: const ValueKey('sale-package-purchase'),
        onPressed: enabled ? onTap : null,
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
        child: loading
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
                      label,
                      maxLines: 1,
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Text(
          context.l10n.text('saleLoadError'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF526584), fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}
