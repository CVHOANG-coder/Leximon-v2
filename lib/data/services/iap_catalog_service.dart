import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/iap_packages_response.dart';
import 'iap_package_api_service.dart';

typedef StoreProductQuery =
    Future<ProductDetailsResponse> Function(Set<String> productIds);

class IapCatalog {
  const IapCatalog({required this.apiResponse, required this.storeProducts});

  final IapPackagesResponse apiResponse;
  final Map<String, ProductDetails> storeProducts;

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
}

class IapCatalogService {
  IapCatalogService({
    required this.apiService,
    StoreProductQuery? storeProductQuery,
  }) : _storeProductQuery =
           storeProductQuery ?? InAppPurchase.instance.queryProductDetails;

  final IapPackageApiService apiService;
  final StoreProductQuery _storeProductQuery;

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
        storeProducts = {
          for (final product in storeResponse.productDetails)
            product.id: product,
        };
        if (storeResponse.error != null) {
          debugPrint(
            'IAP product query failed: ${storeResponse.error!.message}',
          );
        }
      } on Object catch (error) {
        debugPrint('IAP product query failed: $error');
      }
    }

    return IapCatalog(apiResponse: apiResponse, storeProducts: storeProducts);
  }
}
