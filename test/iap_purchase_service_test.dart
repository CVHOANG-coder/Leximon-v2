import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
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
      var subscriptionRecorded = false;
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (productId) async => productId == _package.productId ? _package : null,
        () async => authenticated = true,
        subscriptionPurchaseRecorder: () async {
          subscriptionRecorded = true;
        },
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
      expect(subscriptionRecorded, isTrue);
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

  test('releases the UI before StoreKit finish returns', () async {
    final client = ApiClient(
      client: MockClient((request) async {
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
    final completionGate = Completer<void>();
    final store = _FakeStoreGateway()
      ..completePurchaseGate = completionGate.future;
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _package,
      () async {},
    );
    addTearDown(() async {
      if (!completionGate.isCompleted) completionGate.complete();
      await service.dispose();
      await store.close();
      client.close();
    });

    final resultFuture = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);
    final purchase = _purchase(PurchaseStatus.purchased);
    store.emit([purchase]);

    final result = await resultFuture.timeout(
      const Duration(milliseconds: 100),
    );
    expect(result.status, IapPurchaseResultStatus.verified);
    expect(store.completedPurchases, [purchase]);
    expect(completionGate.isCompleted, isFalse);

    completionGate.complete();
  });

  test(
    'does not start another purchase while StoreKit finish is pending',
    () async {
      final client = ApiClient(
        client: MockClient((request) async {
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
      final completionGate = Completer<void>();
      final store = _FakeStoreGateway()
        ..completePurchaseGate = completionGate.future;
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => _package,
        () async {},
      );
      addTearDown(() async {
        if (!completionGate.isCompleted) completionGate.complete();
        await service.dispose();
        await store.close();
        client.close();
      });

      final firstResultFuture = service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);
      store.emit([_purchase(PurchaseStatus.purchased)]);
      expect(
        (await firstResultFuture).status,
        IapPurchaseResultStatus.verified,
      );

      final repeatedResult = await service.purchase(
        package: _package,
        product: _product,
      );

      expect(repeatedResult.status, IapPurchaseResultStatus.pending);
      expect(store.startedProductIds, [_package.productId]);
      expect(store.completedPurchases, hasLength(1));

      completionGate.complete();
    },
  );

  test('releases the UI while backend verification continues', () async {
    final verificationResponse = Completer<http.Response>();
    final client = ApiClient(
      client: MockClient((request) => verificationResponse.future),
      baseUrl: 'https://example.com',
      authToken: 'token',
    );
    final store = _FakeStoreGateway();
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _package,
      () async {},
      verificationUiTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(() async {
      if (!verificationResponse.isCompleted) {
        verificationResponse.complete(http.Response('{}', 500));
      }
      await service.dispose();
      await store.close();
      client.close();
    });

    final resultFuture = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);
    final purchase = _purchase(PurchaseStatus.purchased);
    store.emit([purchase]);

    final result = await resultFuture.timeout(
      const Duration(milliseconds: 100),
    );
    expect(result.status, IapPurchaseResultStatus.pending);
    expect(store.completedPurchases, isEmpty);

    verificationResponse.complete(
      http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'isPremium': true,
            'subscription': {'productId': _package.productId},
          },
        }),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(store.completedPurchases, [purchase]);
  });

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
          _purchaseFor(
            productId,
            PurchaseStatus.purchased,
            environment: 'Production',
          ),
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
      expect(store.unfinishedPurchaseLookups, 1);
      expect(store.completedPurchases, isEmpty);
      expect(verificationCalls, 0);

      store.emit([_purchaseFor(productId, PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    });
  }

  for (final productId in _skillPackIds) {
    test(
      'finishes old sandbox $productId and sends only the new purchase',
      () async {
        final package = _skillPackPackage(productId);
        final product = _productFor(productId);
        var verificationCalls = 0;
        final client = ApiClient(
          client: MockClient((request) async {
            verificationCalls++;
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
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
        final stalePurchase = _purchaseFor(
          productId,
          PurchaseStatus.purchased,
          purchaseId: 'stale-sandbox-transaction',
          environment: 'Sandbox',
        );
        final store = _FakeStoreGateway()
          ..unfinishedPurchaseDetails = [stalePurchase];
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

        final resultFuture = service.purchase(
          package: package,
          product: product,
        );
        await Future<void>.delayed(Duration.zero);

        expect(store.completedPurchases, [stalePurchase]);
        expect(store.unfinishedPurchaseDetails, isEmpty);
        expect(store.startedProductIds, [productId]);
        expect(verificationCalls, 0);

        // StoreKit may have queued the stale update before completePurchase.
        // It must not reach the backend after local cleanup.
        store.emit([stalePurchase]);
        await Future<void>.delayed(Duration.zero);
        expect(verificationCalls, 0);

        final newPurchase = _purchaseFor(
          productId,
          PurchaseStatus.purchased,
          purchaseId: 'new-sandbox-transaction',
          environment: 'Sandbox',
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        store.emit([newPurchase]);

        expect((await resultFuture).status, IapPurchaseResultStatus.verified);
        expect(verificationCalls, 1);
        expect(store.completedPurchases, [stalePurchase, newPurchase]);
      },
    );
  }

  test(
    'finishes a sandbox skill pack found during duplicate check and retries buy',
    () async {
      final package = _skillPackPackage(_listeningPackId);
      final product = _productFor(_listeningPackId);
      var verificationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
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
      final stalePurchase = _purchaseFor(
        _listeningPackId,
        PurchaseStatus.purchased,
        purchaseId: 'late-stale-sandbox-transaction',
        environment: 'Sandbox',
      );
      final store = _FakeStoreGateway()
        ..purchaseError = StateError('storekit_duplicate_product_object')
        ..purchaseErrorOnce = true
        ..returnUnfinishedAfterFirstLookup = true
        ..unfinishedPurchaseDetails = [stalePurchase];
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
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(store.completedPurchases, [stalePurchase]);
      expect(store.startedProductIds, [_listeningPackId, _listeningPackId]);
      expect(verificationCalls, 0);

      store.emit([stalePurchase]);
      await Future<void>.delayed(Duration.zero);
      expect(verificationCalls, 0);

      final newPurchase = _purchaseFor(
        _listeningPackId,
        PurchaseStatus.purchased,
        purchaseId: 'new-sandbox-transaction-after-duplicate',
        environment: 'Sandbox',
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      store.emit([newPurchase]);

      expect((await resultFuture).status, IapPurchaseResultStatus.verified);
      expect(verificationCalls, 1);
      expect(store.completedPurchases, [stalePurchase, newPurchase]);
    },
  );

  test('retries buy after a delayed old sandbox skill-pack update', () async {
    final package = _skillPackPackage(_listeningPackId);
    final product = _productFor(_listeningPackId);
    var verificationCalls = 0;
    final client = ApiClient(
      client: MockClient((request) async {
        verificationCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
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
    final store = _FakeStoreGateway();
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
    expect(store.startedProductIds, [_listeningPackId]);

    final stalePurchase = _purchaseFor(
      _listeningPackId,
      PurchaseStatus.purchased,
      purchaseId: 'delayed-old-sandbox-transaction',
      environment: 'Sandbox',
    );
    store.unfinishedPurchaseDetails.add(stalePurchase);
    store.emit([stalePurchase]);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(store.completedPurchases, [stalePurchase]);
    expect(store.startedProductIds, [_listeningPackId, _listeningPackId]);
    expect(verificationCalls, 0);

    final newPurchase = _purchaseFor(
      _listeningPackId,
      PurchaseStatus.purchased,
      purchaseId: 'new-transaction-after-delayed-old-update',
      environment: 'Sandbox',
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    store.emit([newPurchase]);

    expect((await resultFuture).status, IapPurchaseResultStatus.verified);
    expect(verificationCalls, 1);
    expect(store.completedPurchases, [stalePurchase, newPurchase]);
  });

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
        ..unfinishedPurchaseDetails = [
          _purchaseFor(
            _package.productId,
            PurchaseStatus.purchased,
            expiresDate: DateTime.now()
                .subtract(const Duration(minutes: 1))
                .millisecondsSinceEpoch,
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
            productId,
            PurchaseStatus.purchased,
            localVerificationData: 'local-storekit-transaction',
            serverVerificationData: _signedTransaction({
              'environment': 'Sandbox',
              'expiresDate': DateTime.now()
                  .subtract(const Duration(minutes: 1))
                  .millisecondsSinceEpoch,
            }),
          ),
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
      expect(verificationCalls, 1);
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
            expiresDate: DateTime.now()
                .subtract(const Duration(minutes: 2))
                .millisecondsSinceEpoch,
          ),
          _purchaseFor(
            _package.productId,
            PurchaseStatus.purchased,
            purchaseId: 'old-renewal-2',
            expiresDate: DateTime.now()
                .subtract(const Duration(minutes: 1))
                .millisecondsSinceEpoch,
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
        ..completePurchaseRemovalDelayLookups = 2
        ..unfinishedPurchaseDetails = [
          _purchaseFor(
            _package.productId,
            PurchaseStatus.purchased,
            expiresDate: DateTime.now()
                .subtract(const Duration(minutes: 1))
                .millisecondsSinceEpoch,
          ),
        ];
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => _package,
        () async {},
        storeQueuePollDelay: const Duration(milliseconds: 1),
        storeQueueClearTimeout: const Duration(milliseconds: 50),
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
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(store.startedProductIds, [_product.id, _product.id]);
      expect(store.completedPurchases, hasLength(1));
      store.emit([_purchase(PurchaseStatus.canceled)]);
      expect((await resultFuture).status, IapPurchaseResultStatus.canceled);
    },
  );

  test('returns pending when StoreKit still reports a duplicate', () async {
    final reportedCodes = <String>[];
    final client = ApiClient(
      client: MockClient((request) async => http.Response('{}', 200)),
      baseUrl: 'https://example.com',
    );
    final store = _FakeStoreGateway()
      ..purchaseError = StateError('storekit_duplicate_product_object');
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _package,
      () async {},
      storeQueuePollDelay: Duration.zero,
      storeQueueClearTimeout: Duration.zero,
      purchaseErrorLogger:
          ({required productId, required phase, required code}) async {
            reportedCodes.add(code);
          },
    );
    addTearDown(() async {
      await service.dispose();
      await store.close();
      client.close();
    });

    final result = await service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);

    expect(result.status, IapPurchaseResultStatus.pending);
    expect(store.startedProductIds, [_package.productId, _package.productId]);
    expect(reportedCodes, [
      'storekit_duplicate_product_object',
      'storekit_duplicate_product_object',
    ]);
  });

  test(
    'keeps a current ungranted subscription transaction unfinished',
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
      final unfinished = _purchaseFor(
        _package.productId,
        PurchaseStatus.purchased,
        expiresDate: DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch,
      );
      final store = _FakeStoreGateway()
        ..unfinishedPurchaseDetails = [unfinished];
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

      expect(result.status, IapPurchaseResultStatus.pending);
      expect(store.completedPurchases, isEmpty);
      expect(store.startedProductIds, isEmpty);
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

  test(
    'maps StoreKit account and product errors to actionable states',
    () async {
      final reportedCodes = <String>[];
      final client = ApiClient(
        client: MockClient((request) async => http.Response('{}', 200)),
        baseUrl: 'https://example.com',
      );
      final store = _FakeStoreGateway()
        ..purchaseError = PlatformException(
          code: 'storekit2_failed_to_fetch_product',
        );
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => _package,
        () async {},
        purchaseErrorLogger:
            ({required productId, required phase, required code}) async {
              reportedCodes.add(code);
            },
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final unavailable = await service.purchase(
        package: _package,
        product: _product,
      );
      store.purchaseError = PlatformException(code: 'payment_not_allowed');
      final notAllowed = await service.purchase(
        package: _package,
        product: _product,
      );
      await Future<void>.delayed(Duration.zero);

      expect(unavailable.status, IapPurchaseResultStatus.productUnavailable);
      expect(notAllowed.status, IapPurchaseResultStatus.purchaseNotAllowed);
      expect(reportedCodes, [
        'storekit2_failed_to_fetch_product',
        'payment_not_allowed',
      ]);
    },
  );

  test('returns pending without leaving the purchase service busy', () async {
    final client = ApiClient(
      client: MockClient((request) async => http.Response('{}', 200)),
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
    store.emit([_purchase(PurchaseStatus.pending)]);

    expect((await resultFuture).status, IapPurchaseResultStatus.pending);
    expect(
      (await service.purchase(package: _package, product: _product)).status,
      IapPurchaseResultStatus.pending,
    );
    expect(store.startedProductIds, [_package.productId]);
  });

  test('a repeated tap waits for the same active store purchase', () async {
    final client = ApiClient(
      client: MockClient((request) async => http.Response('{}', 200)),
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

    final first = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);
    final second = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);

    expect(store.startedProductIds, [_package.productId]);
    store.emit([_purchase(PurchaseStatus.canceled)]);
    expect((await first).status, IapPurchaseResultStatus.canceled);
    expect((await second).status, IapPurchaseResultStatus.canceled);
  });

  test('times out the UI wait while allowing a later retry', () async {
    final client = ApiClient(
      client: MockClient((request) async => http.Response('{}', 200)),
      baseUrl: 'https://example.com',
    );
    final store = _FakeStoreGateway();
    final service = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (_) async => _package,
      () async {},
      purchaseTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(() async {
      await service.dispose();
      await store.close();
      client.close();
    });

    final first = await service.purchase(package: _package, product: _product);
    expect(first.status, IapPurchaseResultStatus.pending);

    final second = service.purchase(package: _package, product: _product);
    await Future<void>.delayed(Duration.zero);
    expect(store.startedProductIds, [_package.productId, _package.productId]);
    store.emit([_purchase(PurchaseStatus.canceled)]);
    expect((await second).status, IapPurchaseResultStatus.canceled);
  });

  test(
    'resumes the unfinished upgrade instead of starting a second purchase',
    () async {
      final annualPackage = _subscriptionPackage('subscription.year');
      final annualProduct = _subscriptionProduct(annualPackage.productId);
      var verificationCalls = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          verificationCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'subscription': {
                  'productId': verificationCalls == 1
                      ? 'subscription.week'
                      : annualPackage.productId,
                },
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
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => annualPackage,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(
        package: annualPackage,
        product: annualProduct,
        previousSubscriptionProductId: 'subscription.week',
      );
      await Future<void>.delayed(Duration.zero);
      final purchase = _purchaseFor(
        annualPackage.productId,
        PurchaseStatus.purchased,
      );
      store.emit([purchase]);

      final result = await resultFuture;
      expect(result.status, IapPurchaseResultStatus.pending);
      expect(store.completedPurchases, isEmpty);

      store.unfinishedPurchaseDetails = [purchase];
      final resumedResult = await service.purchase(
        package: annualPackage,
        product: annualProduct,
        previousSubscriptionProductId: 'subscription.week',
      );

      expect(resumedResult.status, IapPurchaseResultStatus.verified);
      expect(verificationCalls, 2);
      expect(store.startedProductIds, [annualPackage.productId]);
      expect(store.completedPurchases, [purchase]);
    },
  );

  test(
    'confirms an upgrade only when the target product is returned',
    () async {
      final annualPackage = _subscriptionPackage('subscription.year');
      final annualProduct = _subscriptionProduct(annualPackage.productId);
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'subscription': {'productId': annualPackage.productId},
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
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => annualPackage,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(
        package: annualPackage,
        product: annualProduct,
        previousSubscriptionProductId: 'subscription.week',
      );
      await Future<void>.delayed(Duration.zero);
      store.emit([
        _purchaseFor(annualPackage.productId, PurchaseStatus.purchased),
      ]);

      expect((await resultFuture).status, IapPurchaseResultStatus.verified);
      expect(store.completedPurchases, hasLength(1));
    },
  );

  test(
    'validates only the target when StoreKit also emits the source plan',
    () async {
      const weeklyProductId = 'subscription.week';
      final annualPackage = _subscriptionPackage('subscription.year');
      final annualProduct = _subscriptionProduct(annualPackage.productId);
      final verifiedProductIds = <String>[];
      final client = ApiClient(
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final receipt = body['receipt'] as Map<String, dynamic>;
          verifiedProductIds.add(receipt['productId'] as String);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isPremium': true,
                'subscription': {'productId': annualPackage.productId},
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
      final service = IapPurchaseService(
        store,
        IapTransactionApiService(client),
        (_) async => annualPackage,
        () async {},
      );
      addTearDown(() async {
        await service.dispose();
        await store.close();
        client.close();
      });

      final resultFuture = service.purchase(
        package: annualPackage,
        product: annualProduct,
        previousSubscriptionProductId: weeklyProductId,
      );
      await Future<void>.delayed(Duration.zero);
      final sourcePurchase = _purchaseFor(
        weeklyProductId,
        PurchaseStatus.purchased,
        purchaseId: 'weekly-source-transaction',
      );
      final targetPurchase = _purchaseFor(
        annualPackage.productId,
        PurchaseStatus.purchased,
        purchaseId: 'yearly-target-transaction',
      );
      store.emit([sourcePurchase]);
      await Future<void>.delayed(Duration.zero);
      expect(verifiedProductIds, isEmpty);

      store.emit([targetPurchase]);

      expect((await resultFuture).status, IapPurchaseResultStatus.verified);
      await Future<void>.delayed(Duration.zero);

      expect(verifiedProductIds, [annualPackage.productId]);
      expect(store.completedPurchases, [targetPurchase, sourcePurchase]);

      final lateSourcePurchase = _purchaseFor(
        weeklyProductId,
        PurchaseStatus.purchased,
        purchaseId: 'late-weekly-source-transaction',
      );
      store.emit([lateSourcePurchase]);
      await Future<void>.delayed(Duration.zero);

      expect(verifiedProductIds, [annualPackage.productId]);
      expect(store.completedPurchases, [
        targetPurchase,
        sourcePurchase,
        lateSourcePurchase,
      ]);
    },
  );

  test('restore purchases forwards the request to the store', () async {
    final client = ApiClient(
      client: MockClient((request) async => http.Response('{}', 200)),
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

    await service.restorePurchases();

    expect(store.restoreCalls, 1);
  });
}

class _FakeStoreGateway implements IapStoreGateway {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  bool startsPurchase = true;
  Object? purchaseError;
  bool purchaseErrorOnce = false;
  bool returnUnfinishedAfterFirstLookup = false;
  int completePurchaseRemovalDelayLookups = 0;
  Future<void>? completePurchaseGate;
  var unfinishedPurchaseLookups = 0;
  final Map<String, int> _completedVisibilityLookups = {};
  List<PurchaseDetails> unfinishedPurchaseDetails = [];
  final List<String> startedProductIds = [];
  final List<String> startedConsumableProductIds = [];
  final List<PurchaseDetails> completedPurchases = [];
  var restoreCalls = 0;

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
    final result = unfinishedPurchaseDetails
        .where((purchase) => purchase.productID == productId)
        .toList(growable: false);
    final completedIds = _completedVisibilityLookups.keys.toList();
    for (final purchaseId in completedIds) {
      final remaining = _completedVisibilityLookups[purchaseId]! - 1;
      if (remaining <= 0) {
        _completedVisibilityLookups.remove(purchaseId);
        unfinishedPurchaseDetails.removeWhere(
          (purchase) => purchase.purchaseID == purchaseId,
        );
      } else {
        _completedVisibilityLookups[purchaseId] = remaining;
      }
    }
    return result;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
    await completePurchaseGate;
    if (completePurchaseRemovalDelayLookups > 0 &&
        purchase.purchaseID != null) {
      _completedVisibilityLookups[purchase.purchaseID!] =
          completePurchaseRemovalDelayLookups;
      return;
    }
    unfinishedPurchaseDetails.removeWhere(
      (item) => item.purchaseID == purchase.purchaseID,
    );
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }

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
  String? environment,
  int? expiresDate,
  String? localVerificationData,
  String serverVerificationData = 'storekit-jws',
  String transactionDate = '1786880400000',
}) {
  final purchase = PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData:
          localVerificationData ??
          (environment == null && expiresDate == null
              ? 'local-storekit-transaction'
              : jsonEncode({
                  'environment': ?environment,
                  'expiresDate': ?expiresDate,
                })),
      serverVerificationData: serverVerificationData,
      source: 'app_store',
    ),
    transactionDate: transactionDate,
    status: status,
  );
  purchase.pendingCompletePurchase = status == PurchaseStatus.purchased;
  return purchase;
}

String _signedTransaction(Map<String, Object?> payload) {
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return 'header.$encodedPayload.signature';
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
