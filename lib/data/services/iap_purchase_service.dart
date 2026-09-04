import 'dart:async';
import 'dart:convert';

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
  static const _skillPackRetryDelay = Duration(milliseconds: 500);
  static const _skillPackRetryTimeout = Duration(seconds: 20);

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
  final Set<String> _locallyCompletedPurchaseKeys = {};
  final Map<String, PurchaseDetails> _pendingPurchases = {};

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  Completer<IapPurchaseResult>? _activePurchase;
  String? _activeProductId;
  int? _activePurchaseStartedAtMs;
  IapPackage? _activePackage;
  ProductDetails? _activeProduct;
  bool _skillPackRetryScheduled = false;

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
    _activePurchaseStartedAtMs = DateTime.now().millisecondsSinceEpoch;
    _activePackage = package;
    _activeProduct = product;

    // StoreKit 2 refuses to start another purchase while the same product has
    // an unfinished transaction. Expired subscription renewals no longer grant
    // access, so acknowledge them locally before recovery and let the user's
    // Buy action create a fresh transaction without depending on the backend.
    if (_isSubscription(package)) {
      await _finishExpiredUnfinishedSubscriptions(package.productId);
    }

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

    if (_isSkillPack(package)) {
      final finishedTransactions =
          await _finishUnfinishedSandboxSkillPackPurchases(package.productId);
      if (finishedTransactions > 0) {
        debugPrint(
          '[IAP][SkillPack][Sandbox] Cleanup completed: '
          'finishedTransactions=$finishedTransactions. '
          'Starting a new StoreKit purchase for productID=${package.productId}',
        );
      }
    }
    await _startStorePurchase(package, product);
    return completer.future;
  }

  Future<int> _finishExpiredUnfinishedSubscriptions(String productId) async {
    var finishedTransactions = 0;
    try {
      final purchases = await _store.unfinishedPurchases(productId);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final purchase in purchases) {
        final expiresAtMs = _storeKitExpirationDateMs(purchase);
        if (expiresAtMs == null || expiresAtMs > nowMs) continue;

        debugPrint(
          '[IAP][Subscription] Finishing expired unfinished transaction: '
          'purchaseID=${purchase.purchaseID}, '
          'productID=${purchase.productID}, expiresAtMs=$expiresAtMs',
        );
        await _store.completePurchase(purchase);
        _locallyCompletedPurchaseKeys.add(_verificationKey(purchase));
        _removePendingPurchase(purchase);
        finishedTransactions++;
      }
    } on Object catch (error, stackTrace) {
      // If StoreKit cleanup fails, keep the transaction untouched and let the
      // normal recovery path handle it instead of risking a duplicate buy.
      debugPrint(
        '[IAP][Subscription] Could not finish expired transaction: $error',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    }
    return finishedTransactions;
  }

  Future<int> _finishUnfinishedSandboxSkillPackPurchases(
    String productId,
  ) async {
    var finishedTransactions = 0;
    try {
      final purchases = await _store.unfinishedPurchases(productId);
      for (final purchase in purchases) {
        final environment = _storeKitEnvironment(purchase) ?? 'Unknown';
        debugPrint(
          '[IAP][SkillPack] Found unfinished StoreKit transaction: '
          'environment=$environment, purchaseID=${purchase.purchaseID}, '
          'productID=${purchase.productID}',
        );
        if (environment.toUpperCase() != 'SANDBOX') continue;

        debugPrint(
          '[IAP][SkillPack][Sandbox] Finishing old unfinished transaction: '
          'purchaseID=${purchase.purchaseID}, '
          'productID=${purchase.productID}',
        );
        await _store.completePurchase(purchase);
        _locallyCompletedPurchaseKeys.add(_verificationKey(purchase));
        _removePendingPurchase(purchase);
        finishedTransactions++;
        debugPrint(
          '[IAP][SkillPack][Sandbox] Finished old transaction successfully: '
          'purchaseID=${purchase.purchaseID}, '
          'productID=${purchase.productID}',
        );
      }
    } on Object catch (error, stackTrace) {
      // Cleanup is best-effort. The normal purchase path still handles a
      // duplicate StoreKit transaction if finishing the sandbox item fails.
      debugPrint(
        '[IAP][SkillPack][Sandbox] Could not finish unfinished transaction: '
        '$error',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    }
    return finishedTransactions;
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
        if (_isSkillPack(package)) {
          final finishedTransactions =
              await _finishUnfinishedSandboxSkillPackPurchases(
                package.productId,
              );
          if (finishedTransactions > 0) {
            // The first lookup can race StoreKit's own unfinished-transaction
            // check. Once the stale item is finished, retry the actual Buy
            // request and never send that stale receipt to the backend.
            _scheduleActiveSkillPackPurchaseRetry();
            return;
          }

          // The purchase stream can finish the stale transaction concurrently
          // with this duplicate callback. Let its scheduled retry own the next
          // StoreKit call instead of recovering the old receipt through API.
          await Future<void>.delayed(Duration.zero);
          if (_skillPackRetryScheduled) return;
        }

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
        final request = IapTransactionBuyRequest(
          platform: _platformFor(package, purchase),
          productId: purchase.productID,
          signedTransaction: receiptData,
        );
        _logSkillPackValidationBill(package, purchase, request);
        final response = await _transactionApiService.verifyPurchase(request);
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
    // A StoreKit update may already be queued when an expired subscription or
    // stale sandbox skill-pack transaction is completed locally. Ignore that
    // delayed update so only the fresh purchase is sent to the backend.
    if (_locallyCompletedPurchaseKeys.contains(verificationKey)) return;
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

      if (_isOldSandboxSkillPackDuringBuy(package, purchase)) {
        await _store.completePurchase(purchase);
        _locallyCompletedPurchaseKeys.add(verificationKey);
        _removePendingPurchase(purchase);
        debugPrint(
          '[IAP][SkillPack][Sandbox] Ignored delayed old transaction update: '
          'purchaseID=${purchase.purchaseID}, '
          'productID=${purchase.productID}',
        );
        _scheduleActiveSkillPackPurchaseRetry();
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
      final request = IapTransactionBuyRequest(
        platform: _platformFor(package, purchase),
        productId: purchase.productID,
        signedTransaction: receiptData,
      );
      _logSkillPackValidationBill(package, purchase, request);
      final verificationResponse = await _transactionApiService.verifyPurchase(
        request,
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

  void _logSkillPackValidationBill(
    IapPackage package,
    PurchaseDetails purchase,
    IapTransactionBuyRequest request,
  ) {
    if (!_isSkillPack(package)) return;

    final environment = _storeKitEnvironment(purchase) ?? 'Unknown';
    final billClassification = _classifyBill(purchase);
    debugPrint(
      '[IAP][SkillPack] Bill classification before validation: '
      'billSource=${billClassification.source}, '
      'isOldUnfinished=${billClassification.isOldUnfinished}, '
      'environment=$environment, purchaseID=${purchase.purchaseID}, '
      'productID=${purchase.productID}, '
      'transactionDate=${purchase.transactionDate}, '
      'activePurchaseStartedAtMs=$_activePurchaseStartedAtMs, '
      'activeProductID=$_activeProductId',
    );
    final bill = <String, Object?>{
      'billSource': billClassification.source,
      'isOldUnfinished': billClassification.isOldUnfinished,
      'environment': environment,
      'purchaseID': purchase.purchaseID,
      'productID': purchase.productID,
      'transactionDate': purchase.transactionDate,
      'verificationSource': purchase.verificationData.source,
      'localVerificationData': purchase.verificationData.localVerificationData,
      'serverVerificationData':
          purchase.verificationData.serverVerificationData,
      'validateRequest': request.toJson(),
    };
    debugPrint(
      '[IAP][SkillPack] StoreKit bill before validate: ${jsonEncode(bill)}',
    );
  }

  bool _isConsumable(IapPackage package) =>
      package.productType.trim().toUpperCase() == 'CONSUMABLE';

  bool _isSubscription(IapPackage package) =>
      package.productType.trim().toUpperCase().contains('SUBSCRIPTION');

  bool _isSkillPack(IapPackage package) =>
      package.group.trim().toUpperCase() == 'SKILL_PACK';

  bool _isOldSandboxSkillPackDuringBuy(
    IapPackage package,
    PurchaseDetails purchase,
  ) {
    if (!_isSkillPack(package) || _activeProductId != purchase.productID) {
      return false;
    }
    if ((_storeKitEnvironment(purchase) ?? '').toUpperCase() != 'SANDBOX') {
      return false;
    }
    return _classifyBill(purchase).isOldUnfinished;
  }

  void _scheduleActiveSkillPackPurchaseRetry() {
    if (_skillPackRetryScheduled) return;
    final package = _activePackage;
    final product = _activeProduct;
    if (package == null ||
        product == null ||
        !_isSkillPack(package) ||
        _activeProductId != product.id) {
      return;
    }

    _skillPackRetryScheduled = true;
    unawaited(
      Future<void>(() async {
        // Leave the purchase-stream callback completely and give StoreKit time
        // to persist transaction.finish() before requesting the same product.
        await Future<void>.delayed(_skillPackRetryDelay);
        try {
          if (_activePurchase == null || _activeProductId != product.id) return;

          final queueReady = await _waitForSandboxSkillPackQueueToClear(
            product.id,
          );
          if (!queueReady) {
            _finishActive(
              const IapPurchaseResult(IapPurchaseResultStatus.failed),
            );
            return;
          }

          debugPrint(
            '[IAP][SkillPack][Sandbox] Retrying StoreKit purchase after '
            'finishing stale transaction: productID=${product.id}',
          );
          try {
            await _startStorePurchase(
              package,
              product,
              recoverDuplicate: false,
            ).timeout(_skillPackRetryTimeout);
          } on TimeoutException {
            // Sandbox can wait forever when the account still caches ownership
            // of a non-consumable. Never leave the Buy screen spinning forever.
            debugPrint(
              '[IAP][SkillPack][Sandbox] StoreKit retry timed out: '
              'productID=${product.id}',
            );
            _finishActive(
              const IapPurchaseResult(IapPurchaseResultStatus.failed),
            );
          }
        } finally {
          _skillPackRetryScheduled = false;
        }
      }),
    );
  }

  Future<bool> _waitForSandboxSkillPackQueueToClear(String productId) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final remaining = await _store.unfinishedPurchases(productId);
        final sandboxRemaining = remaining.any(
          (purchase) =>
              (_storeKitEnvironment(purchase) ?? '').toUpperCase() == 'SANDBOX',
        );
        if (!sandboxRemaining) return true;
        await _finishUnfinishedSandboxSkillPackPurchases(productId);
      } on Object catch (error, stackTrace) {
        debugPrint(
          '[IAP][SkillPack][Sandbox] Could not confirm queue cleanup: $error',
        );
        if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  String? _storeKitEnvironment(PurchaseDetails purchase) {
    return _storeKitField(purchase, const ['environment'])?.toString().trim();
  }

  int? _storeKitExpirationDateMs(PurchaseDetails purchase) {
    final value = _storeKitField(purchase, const [
      'expiresDate',
      'expirationDate',
    ]);
    if (value is num) return _normalizeEpochMilliseconds(value.toInt());
    if (value is! String || value.trim().isEmpty) return null;

    final epoch = int.tryParse(value.trim());
    if (epoch != null) return _normalizeEpochMilliseconds(epoch);
    return DateTime.tryParse(value.trim())?.millisecondsSinceEpoch;
  }

  int _normalizeEpochMilliseconds(int value) {
    // StoreKit's transaction JSON may use seconds while the signed JWS uses
    // milliseconds. Current epoch milliseconds are well above this boundary.
    return value.abs() < 100000000000 ? value * 1000 : value;
  }

  Object? _storeKitField(PurchaseDetails purchase, List<String> keys) {
    final localPayload = _jsonObject(
      purchase.verificationData.localVerificationData.trim(),
    );
    for (final key in keys) {
      if (localPayload?.containsKey(key) == true) return localPayload![key];
    }

    final signedTransaction = purchase.verificationData.serverVerificationData
        .trim();
    final segments = signedTransaction.split('.');
    if (segments.length != 3) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final signedPayload = _jsonObject(payload);
      for (final key in keys) {
        if (signedPayload?.containsKey(key) == true) return signedPayload![key];
      }
      return null;
    } on Object {
      return null;
    }
  }

  Map<String, dynamic>? _jsonObject(String value) {
    if (value.isEmpty) return null;
    try {
      final json = jsonDecode(value);
      return json is Map<String, dynamic> ? json : null;
    } on Object {
      return null;
    }
  }

  ({String source, bool isOldUnfinished}) _classifyBill(
    PurchaseDetails purchase,
  ) {
    final activeStartedAtMs = _activePurchaseStartedAtMs;
    final transactionDateMs = int.tryParse(purchase.transactionDate ?? '');
    final hasMatchingActivePurchase =
        _activeProductId == purchase.productID && activeStartedAtMs != null;
    final predatesActivePurchase =
        transactionDateMs != null &&
        activeStartedAtMs != null &&
        transactionDateMs <
            activeStartedAtMs - const Duration(minutes: 1).inMilliseconds;
    final isOldUnfinished =
        purchase.status == PurchaseStatus.restored ||
        !hasMatchingActivePurchase ||
        predatesActivePurchase;

    return (
      source: isOldUnfinished ? 'UNFINISHED_REDELIVERED' : 'NEW_PURCHASE',
      isOldUnfinished: isOldUnfinished,
    );
  }

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
    _activePurchaseStartedAtMs = null;
    _activePackage = null;
    _activeProduct = null;
    _skillPackRetryScheduled = false;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }
}
