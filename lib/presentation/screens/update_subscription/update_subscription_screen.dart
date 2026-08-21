import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/iap_packages_response.dart';
import '../../../data/models/user_profile_response.dart';
import '../../../data/services/iap_catalog_service.dart';
import '../../../data/services/iap_purchase_service.dart';
import '../../../shared/providers/app_providers.dart';

/// The account subscription is deliberately resolved separately from the IAP
/// catalogue. The catalogue describes what can be purchased; the profile
/// describes what this user already owns.
IapPackage? resolveCurrentSubscriptionPackage({
  required UserProfile? profile,
  required List<IapPackage> packages,
}) {
  if (profile == null) return null;

  final subscription = profile.subscription;
  if (subscription != null) {
    for (final package in packages) {
      if (_mapContainsPackage(subscription, package) ||
          _mapContainsDuration(subscription, package)) {
        return package;
      }
    }
  }

  // Some API versions expose the active product in ownedProducts, while
  // newer versions also expose the flattened ownedProductIds list.
  final ownedMatches = <IapPackage>[];
  for (final package in packages) {
    final inOwnedProducts = profile.ownedProducts.any(
      (product) =>
          _mapContainsPackage(product, package) ||
          _mapContainsDuration(product, package),
    );
    final inOwnedIds = profile.ownedProductIds.any(
      (id) => id.trim() == package.productId.trim(),
    );
    if (inOwnedProducts || inOwnedIds) ownedMatches.add(package);
  }

  if (ownedMatches.isEmpty) return null;
  ownedMatches.sort((a, b) => b.packDurationDay.compareTo(a.packDurationDay));
  return profile.isPremium || subscription != null ? ownedMatches.first : null;
}

/// Returns the current plan plus only plans that are valid upgrades.
///
/// The comparison uses the API duration instead of product names, so package
/// naming can change without changing the upgrade flow.
List<IapPackage> visibleSubscriptionPackages({
  required List<IapPackage> packages,
  required IapPackage? current,
}) {
  if (current == null) return packages;
  return packages
      .where(
        (package) =>
            package.productId == current.productId ||
            package.packDurationDay > current.packDurationDay,
      )
      .toList(growable: false);
}

/// An upgrade is complete only when the refreshed profile reports the target
/// package in its subscription payload. `isPremium` alone is insufficient
/// because the user was already premium before upgrading.
bool isSubscriptionPackageActive({
  required UserProfile profile,
  required IapPackage package,
}) {
  if (!profile.isPremium) return false;
  final subscription = profile.subscription;
  if (subscription == null) return false;
  return _mapContainsPackage(subscription, package) ||
      _mapContainsDuration(subscription, package);
}

UserProfile? profileFromIapPurchaseResult(IapPurchaseResult result) {
  final data = result.verificationResponse?.data;
  if (data == null || data.isEmpty) return null;
  try {
    return UserProfile.fromJson(data);
  } on Object {
    return null;
  }
}

IapPackage? selectSubscriptionUpgradePackage({
  required List<IapPackage> packages,
  required IapPackage? current,
  required IapPackage? recommended,
  required String? selectedProductId,
}) {
  for (final package in packages) {
    if (package.productId != current?.productId &&
        package.productId == selectedProductId) {
      return package;
    }
  }
  if (recommended != null && recommended.productId != current?.productId) {
    return recommended;
  }
  return packages.firstWhereOrNull(
    (package) => package.productId != current?.productId,
  );
}

bool _mapContainsPackage(Map<String, dynamic> map, IapPackage package) {
  final productId = package.productId.trim();
  if (productId.isEmpty) return false;

  bool visit(Object? value) {
    if (value is Map) return value.values.any(visit);
    if (value is Iterable) return value.any(visit);
    return value?.toString().trim() == productId;
  }

  return visit(map);
}

bool _mapContainsDuration(Map<String, dynamic> map, IapPackage package) {
  const durationKeys = {
    'packDurationDay',
    'packDurationDays',
    'durationDay',
    'durationDays',
    'duration',
  };
  for (final entry in map.entries) {
    if (durationKeys.contains(entry.key) &&
        int.tryParse('${entry.value}') == package.packDurationDay) {
      return true;
    }
    if (entry.value is Map<String, dynamic> &&
        _mapContainsDuration(entry.value as Map<String, dynamic>, package)) {
      return true;
    }
  }
  return false;
}

enum _PlanKind { week, month, year, other }

_PlanKind _planKind(IapPackage package) {
  final days = package.packDurationDay;
  if (days > 0 && days <= 14) return _PlanKind.week;
  if (days >= 330) return _PlanKind.year;
  if (days >= 28) return _PlanKind.month;
  return _PlanKind.other;
}

class UpdateSubscriptionScreen extends ConsumerStatefulWidget {
  const UpdateSubscriptionScreen({super.key});

  @override
  ConsumerState<UpdateSubscriptionScreen> createState() =>
      _UpdateSubscriptionScreenState();
}

class _UpdateSubscriptionScreenState
    extends ConsumerState<UpdateSubscriptionScreen> {
  String? _selectedProductId;
  bool _isSubmitting = false;
  UserProfile? _latestProfile;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(iapCatalogProvider);
    final profileState = ref.watch(remoteUserProfileProvider);
    final catalog = catalogState.valueOrNull;
    final packages = catalog?.subscriptionPackages ?? const <IapPackage>[];
    final profile = _latestProfile ?? profileState.valueOrNull;
    final current = resolveCurrentSubscriptionPackage(
      profile: profile,
      packages: packages,
    );
    final visiblePackages = visibleSubscriptionPackages(
      packages: packages,
      current: current,
    );
    final recommended = _recommendedPackage(visiblePackages, current);
    final selected = _selectedPackage(visiblePackages, recommended, current);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF9FCFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('update-subscription-screen'),
        backgroundColor: const Color(0xFFF9FCFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 22,
                ),
                child: Column(
                  children: [
                    const _SubscribedHero(),
                    _UpgradeHeadline(current: current),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildContent(
                        context,
                        catalogState,
                        catalog,
                        visiblePackages,
                        current,
                        recommended,
                        selected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x33236AEF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const ValueKey('subscription-back'),
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 54,
                        height: 54,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF172267),
                          size: 28,
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
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<IapCatalog> catalogState,
    IapCatalog? catalog,
    List<IapPackage> packages,
    IapPackage? current,
    IapPackage? recommended,
    IapPackage? selected,
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

    final selectedProduct = selected == null
        ? null
        : catalog?.productFor(selected);
    return Column(
      children: [
        if (current != null) ...[
          _CurrentSubscriptionCard(
            package: current,
            product: catalog?.productFor(current),
          ),
          if (packages.any((package) => package.productId != current.productId))
            const SizedBox(height: 16),
        ],
        for (final package in packages.where(
          (package) => package.productId != current?.productId,
        )) ...[
          _UpgradePackageCard(
            key: ValueKey('subscription-plan-${package.productId}'),
            package: package,
            product: catalog?.productFor(package),
            selected: package.productId == selected?.productId,
            recommended: package.productId == recommended?.productId,
            current: current,
            onTap: () => setState(() => _selectedProductId = package.productId),
          ),
          if (package != packages.last) const SizedBox(height: 14),
        ],
        const SizedBox(height: 16),
        const _BenefitsCard(),
        const SizedBox(height: 16),
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
        _UpgradeButton(
          key: const ValueKey('subscription-start'),
          package: selected,
          product: selectedProduct,
          isLoading: _isSubmitting,
          onTap: _startSubscription,
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            key: const ValueKey('subscription-later'),
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10AF54),
              side: const BorderSide(color: Color(0xFF10AF54), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              context.l10n.text('saleLater'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  IapPackage? _recommendedPackage(
    List<IapPackage> packages,
    IapPackage? current,
  ) {
    final upgrades = packages
        .where((package) => package.productId != current?.productId)
        .toList();
    if (upgrades.isEmpty) return null;
    upgrades.sort((a, b) => a.packDurationDay.compareTo(b.packDurationDay));
    return upgrades.first;
  }

  IapPackage? _selectedPackage(
    List<IapPackage> packages,
    IapPackage? recommended,
    IapPackage? current,
  ) => selectSubscriptionUpgradePackage(
    packages: packages,
    current: current,
    recommended: recommended,
    selectedProductId: _selectedProductId,
  );

  Future<void> _startSubscription() async {
    if (_isSubmitting) return;
    final catalog = ref.read(iapCatalogProvider).valueOrNull;
    final packages = catalog?.subscriptionPackages ?? const <IapPackage>[];
    final profile =
        _latestProfile ?? ref.read(remoteUserProfileProvider).valueOrNull;
    final current = resolveCurrentSubscriptionPackage(
      profile: profile,
      packages: packages,
    );
    final visible = visibleSubscriptionPackages(
      packages: packages,
      current: current,
    );
    final package = _selectedPackage(
      visible,
      _recommendedPackage(visible, current),
      current,
    );
    final product = package == null ? null : catalog?.productFor(package);
    if (package == null || product == null) {
      _showMessage(context.l10n.text('iapProductUnavailable'));
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
          _showMessage(_purchaseMessage(result));
        }
        return;
      }

      final responseProfile = profileFromIapPurchaseResult(result);
      if (responseProfile != null &&
          isSubscriptionPackageActive(
            profile: responseProfile,
            package: package,
          )) {
        setState(() {
          _isSubmitting = false;
          _selectedProductId = null;
          _latestProfile = responseProfile;
        });
        ref.invalidate(remoteUserProfileProvider);
        _showMessage('Giao dịch thành công. Gói của bạn đã được cập nhật.');
        return;
      }

      final upgradedProfile = await _reloadSubscriptionProfile(package);
      if (!mounted) return;
      if (upgradedProfile == null) {
        setState(() => _isSubmitting = false);
        _showMessage(context.l10n.text('iapVerificationFailed'));
        return;
      }

      setState(() {
        _isSubmitting = false;
        _selectedProductId = null;
        _latestProfile = upgradedProfile;
      });
      _showMessage('Giao dịch thành công. Gói của bạn đã được cập nhật.');
    } on Object {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(context.l10n.text('iapPurchaseFailed'));
    }
  }

  Future<UserProfile?> _reloadSubscriptionProfile(
    IapPackage targetPackage,
  ) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final profile = await ref.refresh(remoteUserProfileProvider.future);
        if (isSubscriptionPackageActive(
          profile: profile,
          package: targetPackage,
        )) {
          return profile;
        }
      } on Object {
        // The backend may still be processing the receipt. Retry below.
      }
      if (attempt < 4) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    return null;
  }

  String _purchaseMessage(IapPurchaseResult result) => switch (result.status) {
    IapPurchaseResultStatus.storeUnavailable => context.l10n.text(
      'iapStoreUnavailable',
    ),
    IapPurchaseResultStatus.productUnavailable => context.l10n.text(
      'iapProductUnavailable',
    ),
    IapPurchaseResultStatus.verificationFailed =>
      result.message?.trim().isNotEmpty == true
          ? result.message!
          : context.l10n.text('iapVerificationFailed'),
    IapPurchaseResultStatus.busy => context.l10n.text('iapPurchaseBusy'),
    _ => context.l10n.text('iapPurchaseFailed'),
  };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SubscribedHero extends StatelessWidget {
  const _SubscribedHero();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1586 / 908,
    child: Image.asset(
      'assets/images/in_app_purchase/banner_subcriptioned.png',
      key: const ValueKey('subscription-hero'),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: 1600,
    ),
  );
}

class _UpgradeHeadline extends StatelessWidget {
  const _UpgradeHeadline({required this.current});

  final IapPackage? current;

  @override
  Widget build(BuildContext context) {
    final kind = current == null ? null : _planKind(current!);
    final target = switch (kind) {
      _PlanKind.week => 'month',
      _PlanKind.month => 'year',
      _ => null,
    };
    final currentLabel = current == null
        ? null
        : _localizedDuration(context, current!);
    final targetLabel = target == 'month' ? 'tháng' : 'năm';
    final title = target == null
        ? (current == null
              ? 'Nâng cấp để học không gián đoạn'
              : 'Gói đăng ký của bạn')
        : 'Nâng cấp lên gói $targetLabel';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: target == null
                  ? [TextSpan(text: title)]
                  : [
                      const TextSpan(text: 'Nâng cấp lên gói '),
                      TextSpan(
                        text: targetLabel,
                        style: const TextStyle(color: Color(0xFF1466EE)),
                      ),
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
            currentLabel == null
                ? 'Chọn gói phù hợp để mở khoá toàn bộ bài học.'
                : target == null
                ? 'Bạn đang dùng $currentLabel. Tất cả bài học đã được mở khoá.'
                : 'Bạn đang dùng $currentLabel. Nâng cấp lên gói $targetLabel để tiết kiệm hơn và học liên tục không gián đoạn.',
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
}

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.package,
    required this.product,
  });

  final IapPackage package;
  final ProductDetails? product;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('subscription-current'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE9FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x132D70B5),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _PlanIcon(package: package, current: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GÓI HIỆN TẠI',
                    style: const TextStyle(
                      color: Color(0xFF1C66DE),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _packageTitle(context, package),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071735),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  package.description.trim().isNotEmpty
                      ? package.description.trim()
                      : _localizedDuration(context, package),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637594),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F6E7),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF139A48), size: 17),
                SizedBox(width: 5),
                Text(
                  'Đang dùng',
                  style: TextStyle(
                    color: Color(0xFF139A48),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradePackageCard extends StatelessWidget {
  const _UpgradePackageCard({
    super.key,
    required this.package,
    required this.product,
    required this.selected,
    required this.recommended,
    required this.current,
    required this.onTap,
  });

  final IapPackage package;
  final ProductDetails? product;
  final bool selected;
  final bool recommended;
  final IapPackage? current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _packageTitle(context, package);
    final price = product?.price.trim();
    final isYear = _planKind(package) == _PlanKind.year;
    final hasPrice = price?.isNotEmpty == true;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: product == null ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 17),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .98),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: recommended || selected
                      ? const Color(0xFF1E77F7)
                      : const Color(0xFFE0E9F6),
                  width: recommended || selected ? 2 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x132D70B5),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PlanIcon(package: package),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF071735),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          package.description.trim().isNotEmpty
                              ? package.description.trim()
                              : _localizedDuration(context, package),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF637594),
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                        if (hasPrice) ...[
                          const SizedBox(height: 7),
                          Wrap(
                            children: [
                              Text(
                                price!,
                                key: const ValueKey('subscription-price'),
                                style: const TextStyle(
                                  color: Color(0xFF1466EE),
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                isYear ? ' / năm' : ' / kỳ',
                                style: const TextStyle(
                                  color: Color(0xFF637594),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_weeklyPrice(context, product, package) != null)
                            Text.rich(
                              TextSpan(
                                text:
                                    '${_weeklyPrice(context, product, package)} ',
                                style: const TextStyle(
                                  color: Color(0xFF637594),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: context.l10n.text('salePerWeek'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (current != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Tiết kiệm hơn so với ${_localizedDuration(context, current!)}',
                            style: const TextStyle(
                              color: Color(0xFF637594),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (recommended)
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF1B72F1),
                      size: 27,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (recommended)
          Positioned(
            top: -12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C96FF), Color(0xFF176CF0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '★  ĐỀ XUẤT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
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
    final currencyCode = product.currencyCode.trim().toUpperCase();
    if (!amount.isFinite || amount <= 0 || currencyCode.isEmpty) return null;
    final symbol = product.currencySymbol.trim();
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      name: currencyCode,
      symbol: symbol.isEmpty ? currencyCode : symbol,
    ).format(amount);
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.package, this.current = false});

  final IapPackage package;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final asset = current
        ? 'assets/images/in_app_purchase/subcriptioned.png'
        : switch (_planKind(package)) {
            _PlanKind.week => 'assets/images/in_app_purchase/one_week.png',
            _PlanKind.month => 'assets/images/in_app_purchase/moth_sub.png',
            _PlanKind.year =>
              'assets/images/in_app_purchase/calendar_sale_icon.png',
            _PlanKind.other => 'assets/images/in_app_purchase/one_week.png',
          };
    return Image.asset(asset, width: 72, height: 72, fit: BoxFit.contain);
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EBF7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x132D70B5),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/hoc_khong_gioi_han.png',
            label: context.l10n.text('subscriptionBenefitUnlimited'),
          ),
        ),
        const _BenefitDivider(),
        Expanded(
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/no_ads.png',
            label: 'Không\nquảng cáo',
          ),
        ),
        const _BenefitDivider(),
        Expanded(
          child: _Benefit(
            asset: 'assets/images/in_app_purchase/tien_bo_moi_ngay.png',
            label: context.l10n.text('subscriptionBenefitProgress'),
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

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFFDDE6F1));
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({
    super.key,
    required this.package,
    required this.product,
    required this.isLoading,
    required this.onTap,
  });

  final IapPackage? package;
  final ProductDetails? product;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = package != null && product != null && !isLoading;
    final label = package == null
        ? 'Gói năm đang hoạt động'
        : 'Nâng cấp lên gói ${_planKind(package!) == _PlanKind.year ? 'năm' : 'tháng'}';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [Color(0xFF347CF8), Color(0xFF16D6BD)]
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
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
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

String _packageTitle(BuildContext context, IapPackage package) {
  if (package.name.trim().isNotEmpty) return package.name.trim();
  return _localizedDuration(context, package);
}

String _localizedDuration(BuildContext context, IapPackage package) {
  final kind = _planKind(package);
  return switch (kind) {
    _PlanKind.week => context.l10n.text(
      'subscriptionWeeks',
      values: const {'count': 1},
    ),
    _PlanKind.month => context.l10n.text(
      'subscriptionMonths',
      values: {'count': (package.packDurationDay / 30).round()},
    ),
    _PlanKind.year => context.l10n.text(
      'subscriptionYears',
      values: const {'count': 1},
    ),
    _PlanKind.other => context.l10n.text(
      'subscriptionDays',
      values: {'count': package.packDurationDay},
    ),
  };
}

extension on List<IapPackage> {
  IapPackage? firstWhereOrNull(bool Function(IapPackage package) test) {
    for (final package in this) {
      if (test(package)) return package;
    }
    return null;
  }
}
