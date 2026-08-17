import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/services/iap_purchase_service.dart';
import 'package:leximon/data/services/iap_transaction_api_service.dart';

void main() {
  test(
    'verifies on the server before completing the store transaction',
    () async {
      Map<String, dynamic>? verificationBody;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'success': true, 'data': {}}),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway();
      var authenticated = false;
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (productId) async => productId == _package.productId ? _package : null,
        () async => authenticated = true,
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.startedProductIds, [_package.productId]);

      final purchase = _purchase(PurchaseStatus.purchased);
      store.emit([purchase]);
      final result = await resultFuture;

      expect(result.status, IapPurchaseResultStatus.verified);
      expect(authenticated, isTrue);
      expect(verificationBody, {
        'platform': 'IOS',
        'receipt': {
          'productId': _package.productId,
          'signedTransaction': 'storekit-jws',
        },
      });
      expect(store.completedPurchases, [purchase]);
    },
  );

  test(
    'does not complete a transaction when server verification fails',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Invalid receipt'}),
            422,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway();
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => _package,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);
      store.emit([_purchase(PurchaseStatus.purchased)]);
      final result = await resultFuture;

      expect(result.status, IapPurchaseResultStatus.verificationFailed);
      expect(store.completedPurchases, isEmpty);
    },
  );

  test(
    'retries the unfinished transaction instead of starting a duplicate purchase',
    () async {
      var verificationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
          final verified = verificationCalls == 2;
          return http.Response(
            jsonEncode(
              verified
                  ? {'success': true, 'data': {}}
                  : {'success': false, 'message': 'Invalid receipt'},
            ),
            verified ? 200 : 422,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway();
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => _package,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final purchase = _purchase(PurchaseStatus.purchased);
      final firstResultFuture = service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);
      store.emit([purchase]);

      expect(
        (await firstResultFuture).status,
        IapPurchaseResultStatus.verificationFailed,
      );
      expect(store.startedProductIds, [_package.productId]);
      expect(store.completedPurchases, isEmpty);

      final retryResult = await service.purchase(
        package: _package,
        product: _product,
      );

      expect(retryResult.status, IapPurchaseResultStatus.verified);
      expect(verificationCalls, 2);
      expect(store.startedProductIds, [_package.productId]);
      expect(store.completedPurchases, [purchase]);
    },
  );

  test('returns canceled without calling transaction verification', () async {
    var verificationCalls = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        verificationCalls++;
        return http.Response('{}', 200);
      }),
      baseUrl: 'https://example.com',
    );
    final store = _FakeStoreGateway();
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _package,
      () async {},
    );
    addTearDown(() async {
      await service.dispose();
      await store.close();
      client.close();
    });

    final resultFuture = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);
    store.emit([_purchase(PurchaseStatus.canceled)]);

    expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    expect(verificationCalls, 0);
    expect(store.completedPurchases, isEmpty);
  });
}

class _FakeStoreGateway implements IapStoreGateway {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool startsPurchase = true;
  final List<String> startedProductIds = [];
  final List<PurchaseDetails> completedPurchases = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> buyNonConsumable(ProductDetails productDetails) async {
    startedProductIds.add(productDetails.id);
    return startsPurchase;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases() async {}

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  Future<void> close() => _controller.close();
}

PurchaseDetails _purchase(PurchaseStatus status) {
  final purchase = PurchaseDetails(
    purchaseID: '2000000123456789',
    productID: _package.productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local-storekit-transaction',
      serverVerificationData: 'storekit-jws',
      source: 'app_store',
    ),
    transactionDate: '1786880400000',
    status: status,
  );
  purchase.pendingCompletePurchase = status == PurchaseStatus.purchased;
  return purchase;
}

final _product = ProductDetails(
  id: 'com.example.annual.sale',
  title: 'Annual sale',
  description: '',
  price: r'$29.99',
  rawPrice: 29.99,
  currencyCode: 'USD',
  currencySymbol: r'$',
);

const _package = IapPackage(
  id: 2,
  productId: 'com.example.annual.sale',
  productType: 'SUBSCRIPTION',
  name: 'Annual sale',
  description: '',
  price: 29.99,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 365,
  trialDays: 7,
  isEnabled: true,
  sortOrder: 2,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'SALE',
);
