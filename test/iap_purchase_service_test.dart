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
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'subscription': {'productId': _package.productId},
              },
            }),
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
      expect(result.verificationResponse?.isPremium, isTrue);
      expect(result.verificationResponse?.data['subscription'], {
        'productId': _package.productId,
      });
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
      expect(result.message, isNull);
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
                  ? {
                      'success': true,
                      'data': {'isPremium': true},
                    }
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

  test('uses the consumable store API for consumable packages', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        return http.Response('{}', 200);
      }),
      baseUrl: 'https://example.com',
    );
    final store = _FakeStoreGateway();
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _consumablePackage,
      () async {},
    );
    addTearDown(() async {
      await service.dispose();
      await store.close();
      client.close();
    });

    final resultFuture = service.purchase(
      package: _consumablePackage,
      product: _consumableProduct,
    );
    await Future<void>.delayed(Duration.zero);

    expect(store.startedProductIds, isEmpty);
    expect(store.startedConsumableProductIds, [_consumableProduct.id]);

    store.emit([_purchaseFor(_consumableProduct.id, PurchaseStatus.canceled)]);
    expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
  });

  for (final productId in _skillPackIds) {
    test('starts a new store purchase before recovering $productId', () async {
      var verificationCalls = 0;
      final package = _skillPackPackage(productId);
      final product = _productFor(productId);
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'ownedProductIds': [productId],
              },
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [
          _purchaseFor(productId, PurchaseStatus.purchased),
        ];
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => package,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(package: package, product: product);
      await Future<void>.delayed(Duration.zero);

      expect(store.startedProductIds, [productId]);
      expect(store.unfinishedPurchaseLookups, 0);
      expect(verificationCalls, 0);

      store.emit([_purchaseFor(productId, PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    });
  }

  test(
    'does not treat premium as ownership of a recovered skill pack',
    () async {
      final package = _skillPackPackage(_speakingPackId);
      final product = _productFor(_speakingPackId);
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'ownedProductIds': [_listeningPackId],
              },
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..purchaseError = StateError('storekit_duplicate_product_object')
        ..unfinishedPurchaseDetails = [
          _purchaseFor(_speakingPackId, PurchaseStatus.purchased),
        ];
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => package,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final result = await service.purchase(package: package, product: product);

      expect(store.startedProductIds, [_speakingPackId]);
      expect(result.status, IapPurchaseResultStatus.verificationFailed);
      expect(store.completedPurchases, isEmpty);
    },
  );

  test(
    'verifies and completes a redelivered transaction without starting a new buy',
    () async {
      var verificationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
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

      store.emit([_purchase(PurchaseStatus.purchased)]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(verificationCalls, 1);
      expect(store.startedProductIds, isEmpty);
      expect(store.completedPurchases, hasLength(1));

      final newPurchase = service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.startedProductIds, [_product.id]);
      store.emit([_purchase(PurchaseStatus.canceled)]);
      expect((await newPurchase).status, IapPurchaseResultStatus.canceled);
    },
  );

  test(
    'clears an expired unfinished subscription and starts a new buy',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'isPremium': false},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [_purchase(PurchaseStatus.purchased)];
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

      expect(store.startedProductIds, [_product.id]);
      expect(store.completedPurchases, hasLength(1));
      store.emit([_purchase(PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    },
  );

  test(
    'does not start another buy when recovered subscription is still active',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'isPremium': true},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [_purchase(PurchaseStatus.purchased)];
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

      final result = await service.purchase(
        package: _package,
        product: _product,
      );

      expect(result.status, IapPurchaseResultStatus.verified);
      expect(store.startedProductIds, isEmpty);
      expect(store.completedPurchases, hasLength(1));
    },
  );

  for (final productId in const [
    'com.wordisland.learnenglish.premium.weekly',
    'com.wordisland.learnenglish.premium.monthly',
    'com.wordisland.learnenglish.premium.yearly',
  ]) {
    test('starts a new Apple buy after clearing expired $productId', () async {
      final package = _subscriptionPackage(productId);
      final product = _subscriptionProduct(productId);
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'isPremium': false},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [
          _purchaseFor(productId, PurchaseStatus.purchased),
        ];
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => package,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(package: package, product: product);
      await Future<void>.delayed(Duration.zero);

      expect(store.completedPurchases, hasLength(1));
      expect(store.startedProductIds, [productId]);
      store.emit([_purchaseFor(productId, PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    });
  }

  test(
    'clears every expired renewal before starting a new Apple buy',
    () async {
      var verificationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'isPremium': false},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [
          _purchaseFor(
            _package.productId,
            PurchaseStatus.purchased,
            purchaseId: 'old-renewal-1',
          ),
          _purchaseFor(
            _package.productId,
            PurchaseStatus.purchased,
            purchaseId: 'old-renewal-2',
          ),
        ];
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

      expect(verificationCalls, 2);
      expect(store.completedPurchases, hasLength(2));
      expect(store.startedProductIds, [_product.id]);
      store.emit([_purchase(PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    },
  );

  test(
    'recovers when StoreKit reports a duplicate during the buy call',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'isPremium': false},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..purchaseError = StateError('storekit_duplicate_product_object')
        ..purchaseErrorOnce = true
        ..returnUnfinishedAfterFirstLookup = true
        ..unfinishedPurchaseDetails = [_purchase(PurchaseStatus.purchased)];
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

      expect(store.startedProductIds, [_product.id, _product.id]);
      expect(store.completedPurchases, hasLength(1));
      store.emit([_purchase(PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    },
  );

  test(
    'maps StoreKit network exceptions without exposing technical text',
    () async {
      final client = ApiClient(
        client: MockClient((request) async => http.Response('{}', 200)),
        baseUrl: 'https://example.com',
        authToken: 'token',
      );
      final store = _FakeStoreGateway()
        ..purchaseError = StateError(
          'PlatformException(networkError, NSURLErrorDomain Code=-1005, '
          'The network connection was lost)',
        );
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

      final result = await service.purchase(
        package: _package,
        product: _product,
      );

      expect(result.status, IapPurchaseResultStatus.networkUnavailable);
      expect(result.message, isNull);
    },
  );
}

class _FakeStoreGateway implements IapStoreGateway {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool startsPurchase = true;
  Object? purchaseError;
  bool purchaseErrorOnce = false;
  bool returnUnfinishedAfterFirstLookup = false;
  var unfinishedPurchaseLookups = 0;
  List<PurchaseDetails> unfinishedPurchaseDetails = [];
  final List<String> startedProductIds = [];
  final List<String> startedConsumableProductIds = [];
  final List<PurchaseDetails> completedPurchases = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> buyNonConsumable(ProductDetails productDetails) async {
    startedProductIds.add(productDetails.id);
    final error = purchaseError;
    if (error != null) {
      if (purchaseErrorOnce) purchaseError = null;
      throw error;
    }
    return startsPurchase;
  }

  @override
  Future<bool> buyConsumable(ProductDetails productDetails) async {
    final error = purchaseError;
    if (error != null) {
      if (purchaseErrorOnce) purchaseError = null;
      throw error;
    }
    startedConsumableProductIds.add(productDetails.id);
    return startsPurchase;
  }

  @override
  Future<List<PurchaseDetails>> unfinishedPurchases(String productId) async {
    unfinishedPurchaseLookups++;
    if (returnUnfinishedAfterFirstLookup && unfinishedPurchaseLookups == 1) {
      return const [];
    }
    return unfinishedPurchaseDetails
        .where((purchase) => purchase.productID == productId)
        .toList(growable: false);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
    unfinishedPurchaseDetails.removeWhere(
      (item) => item.purchaseID == purchase.purchaseID,
    );
  }

  @override
  Future<void> restorePurchases() async {}

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  Future<void> close() => _controller.close();
}

PurchaseDetails _purchase(PurchaseStatus status) {
  return _purchaseFor(_package.productId, status);
}

PurchaseDetails _purchaseFor(
  String productId,
  PurchaseStatus status, {
  String purchaseId = '2000000123456789',
}) {
  final purchase = PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
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

ProductDetails _subscriptionProduct(String productId) => ProductDetails(
  id: productId,
  title: productId,
  description: '',
  price: r'$4.99',
  rawPrice: 4.99,
  currencyCode: 'USD',
  currencySymbol: r'$',
);

ProductDetails _productFor(String productId) => ProductDetails(
  id: productId,
  title: productId,
  description: '',
  price: r'$2.99',
  rawPrice: 2.99,
  currencyCode: 'USD',
  currencySymbol: r'$',
);

IapPackage _skillPackPackage(String productId) => IapPackage(
  id: 11,
  productId: productId,
  productType: 'NON_CONSUMABLE',
  name: productId,
  description: '',
  price: 2.99,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 36500,
  trialDays: 0,
  isEnabled: true,
  sortOrder: 12,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'SKILL_PACK',
);

const _listeningPackId = 'com.wordisland.learnenglish.ios.pack.listening';
const _grammarPackId = 'com.wordisland.learnenglish.ios.pack.grammar';
const _speakingPackId = 'com.wordisland.learnenglish.ios.pack.speaking';
const _readingPackId = 'com.wordisland.learnenglish.ios.pack.reading';
const _skillPackIds = [
  _listeningPackId,
  _grammarPackId,
  _speakingPackId,
  _readingPackId,
];

IapPackage _subscriptionPackage(String productId) => IapPackage(
  id: 10,
  productId: productId,
  productType: 'SUBSCRIPTION',
  name: productId,
  description: '',
  price: 4.99,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 30,
  trialDays: 0,
  isEnabled: true,
  sortOrder: 1,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'PREMIUM',
);

final _consumableProduct = ProductDetails(
  id: 'com.example.coins.100',
  title: '100 coins',
  description: '',
  price: r'$0.99',
  rawPrice: 0.99,
  currencyCode: 'USD',
  currencySymbol: r'$',
);

const _consumablePackage = IapPackage(
  id: 3,
  productId: 'com.example.coins.100',
  productType: 'CONSUMABLE',
  name: '100 coins',
  description: '',
  price: 0.99,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 0,
  trialDays: 0,
  isEnabled: true,
  sortOrder: 3,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'COINS',
);

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
