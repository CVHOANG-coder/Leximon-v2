import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../models/iap_packages_response.dart';
import 'iap_transaction_api_service.dart';

typedef IapPackageResolver = Future<IapPackage?> Function(String productId);
typedef IapAuthenticationEnsurer = Future<void> Function();
typedef IapPurchaseEventLogger =
    Future<void> Function(IapPackage package, PurchaseDetails purchase);

abstract class IapStoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<bool> buyNonConsumable(ProductDetails productDetails);

  Future<bool> buyConsumable(ProductDetails productDetails);

  Future<List<PurchaseDetails>> unfinishedPurchases(String productId);

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
  Future<bool> buyConsumable(ProductDetails productDetails) {
    final purchaseParam = _platformProvider() == TargetPlatform.iOS
        ? Sk2PurchaseParam(productDetails: productDetails)
        : PurchaseParam(productDetails: productDetails);
    return _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<List<PurchaseDetails>> unfinishedPurchases(String productId) async {
    if (_platformProvider() != TargetPlatform.iOS ||
        !InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
      return const [];
    }

    final transactions = await SK2Transaction.unfinishedTransactions();
    final purchases = <PurchaseDetails>[];
    for (final transaction in transactions) {
      if (transaction.productId != productId) continue;
      final receipt = transaction.receiptData?.trim() ?? '';

      purchases.add(
        SK2PurchaseDetails(
          productID: transaction.productId,
          purchaseID: transaction.id,
          verificationData: PurchaseVerificationData(
            localVerificationData: transaction.jsonRepresentation ?? receipt,
            serverVerificationData: receipt,
            source: 'app_store',
          ),
          transactionDate: transaction.purchaseDate,
          status: PurchaseStatus.purchased,
          appAccountToken: transaction.appAccountToken,
        ),
      );
    }
    return purchases;
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
  networkUnavailable,
  storeUnavailable,
  productUnavailable,
  failed,
  verificationFailed,
  busy,
}

class IapPurchaseResult {
  const IapPurchaseResult(
    this.status, {
    this.message,
    this.verificationResponse,
  });

  final IapPurchaseResultStatus status;
  final String? message;
  final IapTransactionBuyResponse? verificationResponse;

  bool get isSuccess => status == IapPurchaseResultStatus.verified;
}

class IapPurchaseService {
  IapPurchaseService(
    this._store,
    this._transactionApiService,
    this._packageResolver,
    this._ensureAuthenticated, {
    IapPurchaseEventLogger? purchaseEventLogger,
  }) : _purchaseEventLogger = purchaseEventLogger {
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handlePurchaseStreamError,
    );
  }

  final IapStoreGateway _store;
  final IapTransactionApiService _transactionApiService;
  final IapPackageResolver _packageResolver;
  final IapAuthenticationEnsurer _ensureAuthenticated;
  final IapPurchaseEventLogger? _purchaseEventLogger;
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

    final completer = Completer<IapPurchaseResult>();
    _activePurchase = completer;
    _activeProductId = package.productId;

    // A skill pack is an independent one-time product. Always ask the store to
    // purchase it first so buying one pack can never short-circuit a later Buy
    // action for another pack. If StoreKit reports a duplicate transaction for
    // this exact product, _startStorePurchase recovers that transaction.
    if (!_isSkillPack(package)) {
      // Finish transactions left in StoreKit by an earlier purchase before
      // asking Apple to create another transaction for the same product. An
      // expired subscription is cleanup work, not a successful new Buy action.
      final recoveryResult = await _recoverUnfinishedBeforePurchase(package);
      if (recoveryResult != null) {
        _finishActive(recoveryResult);
        return completer.future;
      }
    }

    bool available;
    try {
      available = await _store.isAvailable();
    } on Object catch (error) {
      _finishActive(
        _safeFailureResult(
          error,
          fallbackStatus: IapPurchaseResultStatus.storeUnavailable,
        ),
      );
      return completer.future;
    }
    if (!available) {
      _finishActive(
        const IapPurchaseResult(IapPurchaseResultStatus.storeUnavailable),
      );
      return completer.future;
    }

    await _startStorePurchase(package, product);
    return completer.future;
  }

  Future<void> _startStorePurchase(
    IapPackage package,
    ProductDetails product, {
    bool recoverDuplicate = true,
  }) async {
    try {
      final started = _isConsumable(package)
          ? await _store.buyConsumable(product)
          : await _store.buyNonConsumable(product);
      if (!started) {
        _finishActive(const IapPurchaseResult(IapPurchaseResultStatus.failed));
      }
    } on Object catch (error) {
      if (recoverDuplicate && _isDuplicateProductError(error)) {
        final recoveryResult = await _recoverUnfinishedBeforePurchase(package);
        if (recoveryResult != null) {
          _finishActive(recoveryResult);
          return;
        }

        // StoreKit may publish the unfinished transaction at the same moment
        // the first buy call fails. Retry only once after it has been finished.
        await _startStorePurchase(package, product, recoverDuplicate: false);
        return;
      }
      _finishActive(_safeFailureResult(error));
    }
  }

  Future<IapPurchaseResult?> _recoverUnfinishedBeforePurchase(
    IapPackage package,
  ) async {
    final purchasesByKey = <String, PurchaseDetails>{};
    final memoryPending = _pendingPurchases[package.productId];
    if (memoryPending != null) {
      purchasesByKey[_verificationKey(memoryPending)] = memoryPending;
    }

    try {
      final storePurchases = await _store.unfinishedPurchases(
        package.productId,
      );
      for (final purchase in storePurchases) {
        purchasesByKey[_verificationKey(purchase)] = purchase;
      }
    } on Object catch (error) {
      return _safeFailureResult(
        error,
        fallbackStatus: IapPurchaseResultStatus.storeUnavailable,
      );
    }

    IapTransactionBuyResponse? activeEntitlementResponse;
    for (final purchase in purchasesByKey.values) {
      final verificationKey = _verificationKey(purchase);
      if (!_verificationsInFlight.add(verificationKey)) {
        return const IapPurchaseResult(IapPurchaseResultStatus.busy);
      }
      _pendingPurchases[purchase.productID] = purchase;

      try {
        final receiptData = purchase.verificationData.serverVerificationData;
        if (receiptData.trim().isEmpty) {
          return const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message: 'The store did not return server verification data.',
          );
        }

        await _ensureAuthenticated();
        final response = await _transactionApiService.verifyPurchase(
          IapTransactionBuyRequest(
            platform: _platformFor(package, purchase),
            productId: purchase.productID,
            signedTransaction: receiptData,
          ),
        );
        final grantsEntitlement = _grantsEntitlement(package, response);
        if (grantsEntitlement == null) {
          return const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message:
                'The backend did not return the subscription entitlement state.',
          );
        }
        if (_isSkillPack(package) && !grantsEntitlement) {
          return const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message:
                'The backend did not grant the purchased skill-pack product.',
          );
        }

        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        _removePendingPurchase(purchase);
        if (grantsEntitlement) activeEntitlementResponse = response;
      } on Object catch (error) {
        // Keep an unverified transaction unfinished. Starting another StoreKit
        // transaction here would recreate the duplicate-product error.
        return _safeFailureResult(
          error,
          fallbackStatus: IapPurchaseResultStatus.verificationFailed,
          classifyNetwork: false,
        );
      } finally {
        _verificationsInFlight.remove(verificationKey);
      }
    }

    return activeEntitlementResponse == null
        ? null
        : IapPurchaseResult(
            IapPurchaseResultStatus.verified,
            verificationResponse: activeEntitlementResponse,
          );
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
          // A transaction redelivered by StoreKit/Play is an existing store
          // transaction, not a new Buy request. Verify and finish it here;
          // never route it through purchase(), which must start a new store
          // purchase when the user taps Buy.
          await _verifyAndComplete(purchase);
        case PurchaseStatus.error:
          _finishForProduct(
            purchase.productID,
            _safeFailureResult(purchase.error),
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
      final verificationResponse = await _transactionApiService.verifyPurchase(
        IapTransactionBuyRequest(
          platform: _platformFor(package, purchase),
          productId: purchase.productID,
          signedTransaction: receiptData,
        ),
      );
      if (_isSkillPack(package) &&
          _grantsEntitlement(package, verificationResponse) != true) {
        _finishForProduct(
          purchase.productID,
          const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message:
                'The backend did not grant the purchased skill-pack product.',
          ),
        );
        return;
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _removePendingPurchase(purchase);
      if (purchase.status == PurchaseStatus.purchased) {
        unawaited(_logVerifiedPurchase(package, purchase));
      }
      _finishForProduct(
        purchase.productID,
        IapPurchaseResult(
          IapPurchaseResultStatus.verified,
          verificationResponse: verificationResponse,
        ),
      );
    } on Object catch (error) {
      // Do not complete the store transaction when backend verification fails.
      // StoreKit/Google Play can redeliver it and the app can safely retry.
      _finishForProduct(
        purchase.productID,
        _safeFailureResult(
          error,
          fallbackStatus: IapPurchaseResultStatus.verificationFailed,
          classifyNetwork: false,
        ),
      );
    } finally {
      _verificationsInFlight.remove(verificationKey);
    }
  }

  Future<void> _logVerifiedPurchase(
    IapPackage package,
    PurchaseDetails purchase,
  ) async {
    final logger = _purchaseEventLogger;
    if (logger == null) return;

    try {
      await logger(package, purchase);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not log verified purchase event: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _isConsumable(IapPackage package) =>
      package.productType.trim().toUpperCase() == 'CONSUMABLE';

  bool _isSubscription(IapPackage package) =>
      package.productType.trim().toUpperCase().contains('SUBSCRIPTION');

  bool _isSkillPack(IapPackage package) =>
      package.group.trim().toUpperCase() == 'SKILL_PACK';

  bool? _grantsEntitlement(
    IapPackage package,
    IapTransactionBuyResponse response,
  ) {
    if (_isConsumable(package)) return false;
    if (_isSubscription(package)) return response.isPremium;

    final ownsProduct =
        response.lifetimeProductId == package.productId ||
        response.ownedProductIds.contains(package.productId);
    if (_isSkillPack(package)) {
      final hasOwnershipState =
          response.data.containsKey('lifetimeProductId') ||
          response.data.containsKey('ownedProductIds') ||
          response.data.containsKey('ownedProducts');
      return hasOwnershipState ? ownsProduct : null;
    }
    if (ownsProduct || response.isPremium == true) return true;

    final hasOwnershipState =
        response.data.containsKey('lifetimeProductId') ||
        response.data.containsKey('ownedProductIds') ||
        response.data.containsKey('ownedProducts') ||
        response.isPremium != null;
    return hasOwnershipState ? false : true;
  }

  void _removePendingPurchase(PurchaseDetails purchase) {
    final pending = _pendingPurchases[purchase.productID];
    if (pending != null &&
        _verificationKey(pending) == _verificationKey(purchase)) {
      _pendingPurchases.remove(purchase.productID);
    }
  }

  bool _isDuplicateProductError(Object error) {
    final message = '$error'.toLowerCase();
    return message.contains('storekit_duplicate_product_object') ||
        message.contains('pending transaction for the same product');
  }

  IapPurchaseResult _safeFailureResult(
    Object? error, {
    IapPurchaseResultStatus fallbackStatus = IapPurchaseResultStatus.failed,
    bool classifyNetwork = true,
  }) {
    if (kDebugMode && error != null) {
      debugPrint('IAP error: $error');
    }
    return IapPurchaseResult(
      classifyNetwork && _isNetworkError(error)
          ? IapPurchaseResultStatus.networkUnavailable
          : fallbackStatus,
    );
  }

  bool _isNetworkError(Object? error) {
    final message = '${error ?? ''}'.toLowerCase();
    return message.contains('networkerror') ||
        message.contains('code=-1001') ||
        message.contains('code=-1005') ||
        message.contains('code=-1009') ||
        message.contains('network connection was lost') ||
        message.contains('not connected to the internet') ||
        message.contains('connection timed out') ||
        message.contains('socketexception') ||
        message.contains('failed host lookup');
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
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    _finishActive(_safeFailureResult(error));
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
