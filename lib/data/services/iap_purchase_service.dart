import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../models/iap_packages_response.dart';
import 'iap_transaction_api_service.dart';

typedef IapPackageResolver = Future<IapPackage?> Function(String productId);
typedef IapAuthenticationEnsurer = Future<void> Function();

abstract class IapStoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<bool> buyNonConsumable(ProductDetails productDetails);

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<void> restorePurchases();
}

class FlutterIapStoreGateway implements IapStoreGateway {
  FlutterIapStoreGateway({
    InAppPurchase? inAppPurchase,
    TargetPlatform Function()? platformProvider,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
       _platformProvider = platformProvider ?? _defaultPlatform;

  final InAppPurchase _inAppPurchase;
  final TargetPlatform Function() _platformProvider;

  static TargetPlatform _defaultPlatform() => defaultTargetPlatform;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _inAppPurchase.purchaseStream;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<bool> buyNonConsumable(ProductDetails productDetails) {
    final purchaseParam = _platformProvider() == TargetPlatform.iOS
        ? Sk2PurchaseParam(productDetails: productDetails)
        : PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _inAppPurchase.completePurchase(purchase);

  @override
  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();
}

enum IapPurchaseResultStatus {
  verified,
  canceled,
  storeUnavailable,
  productUnavailable,
  failed,
  verificationFailed,
  busy,
}

class IapPurchaseResult {
  const IapPurchaseResult(this.status, {this.message});

  final IapPurchaseResultStatus status;
  final String? message;

  bool get isSuccess => status == IapPurchaseResultStatus.verified;
}

class IapPurchaseService {
  IapPurchaseService(
    this._store,
    this._transactionApiService,
    this._packageResolver,
    this._ensureAuthenticated,
  ) {
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handlePurchaseStreamError,
    );
  }

  final IapStoreGateway _store;
  final IapTransactionApiService _transactionApiService;
  final IapPackageResolver _packageResolver;
  final IapAuthenticationEnsurer _ensureAuthenticated;
  final Set<String> _verificationsInFlight = {};
  final Map<String, PurchaseDetails> _pendingPurchases = {};

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  Completer<IapPurchaseResult>? _activePurchase;
  String? _activeProductId;

  Future<IapPurchaseResult> purchase({
    required IapPackage package,
    required ProductDetails? product,
  }) async {
    if (_activePurchase != null) {
      return const IapPurchaseResult(IapPurchaseResultStatus.busy);
    }
    if (product == null || product.id != package.productId) {
      return const IapPurchaseResult(
        IapPurchaseResultStatus.productUnavailable,
      );
    }

    // A store transaction whose backend verification failed must stay
    // unfinished so it can be retried. Starting another transaction for the
    // same product makes StoreKit reject it as a duplicate purchase.
    final pendingPurchase = _pendingPurchases[package.productId];
    if (pendingPurchase != null) {
      final completer = Completer<IapPurchaseResult>();
      _activePurchase = completer;
      _activeProductId = package.productId;

      final verificationKey = _verificationKey(pendingPurchase);
      if (!_verificationsInFlight.contains(verificationKey)) {
        unawaited(_verifyAndComplete(pendingPurchase));
      }
      return completer.future;
    }

    bool available;
    try {
      available = await _store.isAvailable();
    } on Object catch (error) {
      return IapPurchaseResult(
        IapPurchaseResultStatus.storeUnavailable,
        message: '$error',
      );
    }
    if (!available) {
      return const IapPurchaseResult(IapPurchaseResultStatus.storeUnavailable);
    }

    final completer = Completer<IapPurchaseResult>();
    _activePurchase = completer;
    _activeProductId = package.productId;
    try {
      final started = await _store.buyNonConsumable(product);
      if (!started) {
        _finishActive(const IapPurchaseResult(IapPurchaseResultStatus.failed));
      }
    } on Object catch (error) {
      _finishActive(
        IapPurchaseResult(IapPurchaseResultStatus.failed, message: '$error'),
      );
    }
    return completer.future;
  }

  Future<void> restorePurchases() => _store.restorePurchases();

  Future<void> dispose() => _purchaseSubscription.cancel();

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
        case PurchaseStatus.error:
          _finishForProduct(
            purchase.productID,
            IapPurchaseResult(
              IapPurchaseResultStatus.failed,
              message: purchase.error?.message,
            ),
          );
        case PurchaseStatus.canceled:
          _finishForProduct(
            purchase.productID,
            const IapPurchaseResult(IapPurchaseResultStatus.canceled),
          );
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final verificationKey = _verificationKey(purchase);
    if (!_verificationsInFlight.add(verificationKey)) return;
    _pendingPurchases[purchase.productID] = purchase;

    try {
      final package = await _packageResolver(purchase.productID);
      if (package == null) {
        _finishForProduct(
          purchase.productID,
          const IapPurchaseResult(IapPurchaseResultStatus.verificationFailed),
        );
        return;
      }

      final receiptData = purchase.verificationData.serverVerificationData;
      if (receiptData.trim().isEmpty) {
        _finishForProduct(
          purchase.productID,
          const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message: 'The store did not return server verification data.',
          ),
        );
        return;
      }

      await _ensureAuthenticated();
      await _transactionApiService.verifyPurchase(
        IapTransactionBuyRequest(
          platform: _platformFor(package, purchase),
          productId: purchase.productID,
          signedTransaction: receiptData,
        ),
      );

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _pendingPurchases.remove(purchase.productID);
      _finishForProduct(
        purchase.productID,
        const IapPurchaseResult(IapPurchaseResultStatus.verified),
      );
    } on Object catch (error) {
      // Do not complete the store transaction when backend verification fails.
      // StoreKit/Google Play can redeliver it and the app can safely retry.
      _finishForProduct(
        purchase.productID,
        IapPurchaseResult(
          IapPurchaseResultStatus.verificationFailed,
          message: '$error',
        ),
      );
    } finally {
      _verificationsInFlight.remove(verificationKey);
    }
  }

  String _verificationKey(PurchaseDetails purchase) =>
      purchase.purchaseID ??
      '${purchase.productID}:${purchase.transactionDate ?? ''}';

  String _platformFor(IapPackage package, PurchaseDetails purchase) {
    final packagePlatform = package.platform.trim().toUpperCase();
    if (packagePlatform.isNotEmpty) return packagePlatform;
    return purchase.verificationData.source.toLowerCase().contains('app_store')
        ? 'IOS'
        : 'ANDROID';
  }

  void _handlePurchaseStreamError(Object error, StackTrace stackTrace) {
    _finishActive(
      IapPurchaseResult(IapPurchaseResultStatus.failed, message: '$error'),
    );
  }

  void _finishForProduct(String productId, IapPurchaseResult result) {
    if (_activeProductId == productId) _finishActive(result);
  }

  void _finishActive(IapPurchaseResult result) {
    final completer = _activePurchase;
    _activePurchase = null;
    _activeProductId = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }
}
