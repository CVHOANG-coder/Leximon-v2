import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/data/services/iap_package_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads package metadata and sends the requested platform', () async {
    late http.Request request;
    final client = ApiClient(
      client: MockClient((incoming) async {
        request = incoming;
        return _jsonResponse(_packagesResponse);
      }),
      baseUrl: 'https://example.com',
    );
    addTearDown(client.close);

    final response = await IapPackageApiService(
      apiClient: client,
    ).getPackages(platform: 'IOS');

    expect(request.method, 'GET');
    expect(request.url.path, '/iap/packages');
    expect(request.url.queryParameters['platform'], 'IOS');
    expect(response.total, 1);
    expect(response.enabledPackages.single.productId, 'com.example.weekly');
    expect(response.enabledPackages.single.name, 'Premium - 1 tuần');
  });

  test('uses the localized store price instead of backend price', () async {
    final client = ApiClient(
      client: MockClient((_) async => _jsonResponse(_packagesResponse)),
      baseUrl: 'https://example.com',
    );
    addTearDown(client.close);

    final catalog = await IapCatalogService(
      apiService: IapPackageApiService(apiClient: client),
      storeProductQuery: (productIds) async {
        return ProductDetailsResponse(
          productDetails: [
            ProductDetails(
              id: productIds.single,
              title: 'Weekly',
              description: 'Weekly subscription',
              price: '4,99 €',
              rawPrice: 4.99,
              currencyCode: 'EUR',
              currencySymbol: '€',
            ),
          ],
          notFoundIDs: const [],
        );
      },
    ).load(platform: 'IOS');

    final package = catalog.packages.single;
    expect(package.price, 4.99);
    expect(catalog.storePriceFor(package), '4,99 €');
  });

  test('keeps API groups and exposes only the SUBSCRIPTION group', () async {
    final client = ApiClient(
      client: MockClient((_) async => _jsonResponse(_groupedPackagesResponse)),
      baseUrl: 'https://example.com',
    );
    addTearDown(client.close);

    final catalog = await IapCatalogService(
      apiService: IapPackageApiService(apiClient: client),
      storeProductQuery: (productIds) async => ProductDetailsResponse(
        productDetails: [
          for (final productId in productIds)
            ProductDetails(
              id: productId,
              title: productId,
              description: '',
              price: '\$1.00',
              rawPrice: 1,
              currencyCode: 'USD',
              currencySymbol: '\$',
            ),
        ],
        notFoundIDs: const [],
      ),
    ).load(platform: 'IOS');

    expect(catalog.apiResponse.total, 4);
    expect(
      catalog.apiResponse.packages.keys,
      containsAll(<String>['SUBSCRIPTION', 'SALE', 'LIFETIME']),
    );
    expect(catalog.packages, hasLength(4));
    expect(catalog.subscriptionPackages, hasLength(2));
    expect(
      catalog.subscriptionPackages.map((item) => item.productId),
      containsAll(<String>['com.example.weekly', 'com.example.annual']),
    );
    expect(
      catalog.subscriptionPackages.any((item) => item.group == 'SALE'),
      isFalse,
    );
  });
}

final _packagesResponse = jsonEncode({
  'success': true,
  'message': 'Packages retrieved',
  'data': {
    'packages': {
      'SUBSCRIPTION': [
        {
          'id': 1,
          'productId': 'com.example.weekly',
          'productType': 'SUBSCRIPTION',
          'name': 'Premium - 1 tuần',
          'description': 'Mở khoá toàn bộ bài học',
          'price': 4.99,
          'currency': 'USD',
          'platform': 'IOS',
          'packDurationDay': 7,
          'trialDays': 3,
          'isEnabled': true,
          'sortOrder': 1,
          'adjustEventToken': '',
          'createdAt': '2026-08-16T03:58:54.326Z',
          'updatedAt': '2026-08-16T03:58:54.326Z',
          'group': 'SUBSCRIPTION',
        },
      ],
    },
    'total': 1,
  },
});

http.Response _jsonResponse(String body) => http.Response(
  body,
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

final _groupedPackagesResponse = jsonEncode({
  'success': true,
  'message': 'Packages retrieved',
  'data': {
    'packages': {
      'SUBSCRIPTION': [
        {..._packageJson('com.example.weekly', 'SUBSCRIPTION', 1)},
        {..._packageJson('com.example.annual', 'SUBSCRIPTION', 2)},
      ],
      'SALE': [
        {
          ..._packageJson('com.example.sale', 'SALE', 3),
          'productType': 'SUBSCRIPTION',
        },
      ],
      'LIFETIME': [
        {
          ..._packageJson('com.example.lifetime', 'LIFETIME', 4),
          'productType': 'NON_CONSUMABLE',
        },
      ],
    },
    'total': 4,
  },
});

Map<String, dynamic> _packageJson(String productId, String group, int id) => {
  'id': id,
  'productId': productId,
  'productType': 'SUBSCRIPTION',
  'name': productId,
  'description': '',
  'price': 1,
  'currency': 'USD',
  'platform': 'IOS',
  'packDurationDay': 7,
  'trialDays': 0,
  'isEnabled': true,
  'sortOrder': id,
  'adjustEventToken': '',
  'createdAt': '2026-08-16T03:58:54.326Z',
  'updatedAt': '2026-08-16T03:58:54.326Z',
  'group': group,
};
