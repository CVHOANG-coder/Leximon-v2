import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/services/iap_transaction_api_service.dart';

void main() {
  test('posts StoreKit verification data to transaction-buy', () async {
    late http.Request capturedRequest;
    final client = ApiClient(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Purchase verified',
            'data': {
              'isPremium': true,
              'lifetimeProductId': null,
              'ownedProductIds': ['com.example.annual.sale'],
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'https://example.com',
      authToken: 'access-token',
    );
    addTearDown(client.close);

    final response = await IapTransactionApiService(client).verifyPurchase(
      const IapTransactionBuyRequest(
        platform: 'IOS',
        productId: 'com.example.annual.sale',
        signedTransaction: 'signed-storekit-transaction-jws',
      ),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/iap/transaction-buy');
    expect(capturedRequest.headers['authorization'], 'Bearer access-token');
    expect(jsonDecode(capturedRequest.body), {
      'platform': 'IOS',
      'receipt': {
        'productId': 'com.example.annual.sale',
        'signedTransaction': 'signed-storekit-transaction-jws',
      },
    });
    expect(response.success, isTrue);
    expect(response.isPremium, isTrue);
    expect(response.lifetimeProductId, isNull);
    expect(response.ownedProductIds, {'com.example.annual.sale'});
  });
}
