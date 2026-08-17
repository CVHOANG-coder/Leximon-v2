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
