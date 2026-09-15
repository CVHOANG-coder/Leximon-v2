import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../models/iap_packages_response.dart';
import 'iap_package_api_service.dart';

typedef StoreProductQuery =
    Future<ProductDetailsResponse> Function(Set<String> productIds);
typedef IntroductoryOfferEligibilityQuery =
    Future<bool> Function(ProductDetails product);

class IapCatalog {
  const IapCatalog({
    required this.apiResponse,
    required this.storeProducts,
    this.trialEligibleProductIds = const {},
  });

  final IapPackagesResponse apiResponse;
  final Map<String, ProductDetails> storeProducts;
  final Set<String> trialEligibleProductIds;

  List<IapPackage> get packages => apiResponse.enabledPackages;

  /// SubscriptionPlanScreen displays only packages in the API's
  /// `packages.SUBSCRIPTION` group. Other groups (including SALE) belong to
  /// separate catalogue sections, even when their productType is also
  /// SUBSCRIPTION.
  List<IapPackage> get subscriptionPackages {
    final subscriptionItems = <IapPackage>[];
    for (final entry in apiResponse.packages.entries) {
      if (entry.key.trim().toUpperCase() != 'SUBSCRIPTION') continue;
      subscriptionItems.addAll(entry.value.where((item) => item.isEnabled));
    }
    subscriptionItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return subscriptionItems.toList(growable: false);
  }

  /// Promotional subscriptions returned in the API's `SALE` group.
  List<IapPackage> get salePackages {
    final saleItems = <IapPackage>[];
    for (final entry in apiResponse.packages.entries) {
      if (entry.key.trim().toUpperCase() != 'SALE') continue;
      saleItems.addAll(entry.value.where((item) => item.isEnabled));
    }
    saleItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return saleItems.toList(growable: false);
  }

  /// One-time skill packs (listening, speaking, reading and grammar).
  List<IapPackage> get skillPackPackages {
    final skillItems = <IapPackage>[];
    for (final entry in apiResponse.packages.entries) {
      if (entry.key.trim().toUpperCase() != 'SKILL_PACK') continue;
      skillItems.addAll(entry.value.where((item) => item.isEnabled));
    }
    skillItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return skillItems.toList(growable: false);
  }

  ProductDetails? productFor(IapPackage package) =>
      storeProducts[package.productId];

  /// This is the localized price returned by StoreKit/Google Play.
  String? storePriceFor(IapPackage package) => productFor(package)?.price;

  int trialDaysFor(IapPackage package) =>
      trialEligibleProductIds.contains(package.productId)
      ? package.trialDays
      : 0;
}

class IapCatalogService {
  IapCatalogService({
    required this.apiService,
    StoreProductQuery? storeProductQuery,
    IntroductoryOfferEligibilityQuery? introductoryOfferEligibilityQuery,
  }) : _storeProductQuery =
           storeProductQuery ?? InAppPurchase.instance.queryProductDetails,
       _introductoryOfferEligibilityQuery =
           introductoryOfferEligibilityQuery ??
           _defaultIntroductoryOfferEligibilityQuery;

  final IapPackageApiService apiService;
  final StoreProductQuery _storeProductQuery;
  final IntroductoryOfferEligibilityQuery _introductoryOfferEligibilityQuery;

  Future<IapCatalog> load({required String platform}) async {
    final apiResponse = await apiService.getPackages(platform: platform);
    final productIds = apiResponse.enabledPackages
        .map((item) => item.productId.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    var storeProducts = <String, ProductDetails>{};
    if (productIds.isNotEmpty) {
      try {
        final storeResponse = await _storeProductQuery(productIds);
        for (final product in storeResponse.productDetails) {
          final current = storeProducts[product.id];
          if (current == null ||
              (_hasGooglePlayFreeTrial(product) &&
                  !_hasGooglePlayFreeTrial(current))) {
            storeProducts[product.id] = product;
          }
        }
        if (storeResponse.error != null) {
          debugPrint(
            'IAP product query failed: ${storeResponse.error!.message}',
          );
        }
      } on Object catch (error) {
        debugPrint('IAP product query failed: $error');
      }
    }

    final trialEligibleProductIds = <String>{};
    for (final package in apiResponse.enabledPackages) {
      if (package.trialDays <= 0 ||
          !package.productType.toUpperCase().contains('SUBSCRIPTION')) {
        continue;
      }
      final product = storeProducts[package.productId];
      if (product == null) continue;
      try {
        if (await _introductoryOfferEligibilityQuery(product)) {
          trialEligibleProductIds.add(package.productId);
        }
      } on Object catch (error) {
        debugPrint(
          'Could not determine introductory offer eligibility for '
          '${package.productId}: $error',
        );
      }
    }

    return IapCatalog(
      apiResponse: apiResponse,
      storeProducts: storeProducts,
      trialEligibleProductIds: trialEligibleProductIds,
    );
  }

  static Future<bool> _defaultIntroductoryOfferEligibilityQuery(
    ProductDetails product,
  ) async {
    if (product is GooglePlayProductDetails) {
      return _hasGooglePlayFreeTrial(product);
    }
    if (product is AppStoreProduct2Details) {
      return SK2Product.isIntroductoryOfferEligible(product.id);
    }
    return false;
  }

  static bool _hasGooglePlayFreeTrial(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return false;
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return false;
    return offers[index].pricingPhases.any(
      (phase) => phase.priceAmountMicros == 0 && phase.billingCycleCount > 0,
    );
  }
}
