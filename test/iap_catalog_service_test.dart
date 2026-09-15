import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/data/services/iap_package_api_service.dart';

void main() {
  test('advertises a trial only after store eligibility succeeds', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'packages': {
                'SUBSCRIPTION': [
                  {
                    'id': 1,
                    'productId': 'subscription.annual',
                    'productType': 'SUBSCRIPTION',
                    'name': 'Annual',
                    'price': 29.99,
                    'currency': 'USD',
                    'platform': 'IOS',
                    'packDurationDay': 365,
                    'trialDays': 7,
                    'isEnabled': true,
                    'sortOrder': 1,
                    'group': 'SUBSCRIPTION',
                  },
                ],
              },
              'total': 1,
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'https://example.com',
      authToken: 'token',
    );
    addTearDown(client.close);
    final product = ProductDetails(
      id: 'subscription.annual',
      title: 'Annual',
      description: '',
      price: r'$29.99',
      rawPrice: 29.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    );

    final eligibleCatalog = await IapCatalogService(
      apiService: IapPackageApiService(apiClient: client),
      storeProductQuery: (_) async => ProductDetailsResponse(
        productDetails: [product],
        notFoundIDs: const [],
      ),
      introductoryOfferEligibilityQuery: (_) async => true,
    ).load(platform: 'IOS');
    final package = eligibleCatalog.subscriptionPackages.single;

    expect(eligibleCatalog.trialDaysFor(package), 7);

    final ineligibleCatalog = await IapCatalogService(
      apiService: IapPackageApiService(apiClient: client),
      storeProductQuery: (_) async => ProductDetailsResponse(
        productDetails: [product],
        notFoundIDs: const [],
      ),
      introductoryOfferEligibilityQuery: (_) async => false,
    ).load(platform: 'IOS');

    expect(ineligibleCatalog.trialDaysFor(package), 0);
  });
}
