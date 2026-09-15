import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../models/iap_packages_response.dart';
import 'iap_transaction_api_service.dart';

typedef IapPackageResolver = Future<IapPackage?> Function(String productId);
typedef IapAuthenticationEnsurer = Future<void> Function();
typedef IapSubscriptionPurchaseRecorder = Future<void> Function();
typedef IapPurchaseEventLogger =
    Future<void> Function(IapPackage package, PurchaseDetails purchase);
typedef IapPurchaseErrorLogger =
    Future<void> Function({
      required String productId,
      required String phase,
      required String code,
    });
typedef IapEntitlementChanged = void Function();

abstract class IapStoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<bool> buyNonConsumable(
    ProductDetails productDetails, {
    PurchaseDetails? oldSubscription,
  });

  Future<bool> buyConsumable(ProductDetails productDetails);

  Future<PurchaseDetails?> pastPurchase(String productId);

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
  Future<bool> buyNonConsumable(
    ProductDetails productDetails, {
    PurchaseDetails? oldSubscription,
  }) {
    final platform = _platformProvider();
    final PurchaseParam purchaseParam;
    if (platform == TargetPlatform.iOS) {
      purchaseParam = Sk2PurchaseParam(productDetails: productDetails);
    } else if (platform == TargetPlatform.android) {
      if (oldSubscription != null &&
          oldSubscription is! GooglePlayPurchaseDetails) {
        throw StateError('The previous subscription is not from Google Play.');
      }
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: productDetails,
        changeSubscriptionParam: oldSubscription == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails:
                    oldSubscription as GooglePlayPurchaseDetails,
                replacementMode: ReplacementMode.withTimeProration,
              ),
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: productDetails);
    }
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
  Future<PurchaseDetails?> pastPurchase(String productId) async {
    if (_platformProvider() != TargetPlatform.android) return null;

    final addition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    for (final purchase in response.pastPurchases) {
      if (purchase.productID == productId) return purchase;
    }
    return null;
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
  pending,
  canceled,
  networkUnavailable,
  storeUnavailable,
  productUnavailable,
  purchaseNotAllowed,
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
  static const _defaultPurchaseTimeout = Duration(seconds: 90);
  static const _defaultVerificationUiTimeout = Duration(seconds: 12);
  static const _defaultStoreQueuePollDelay = Duration(milliseconds: 200);
  static const _defaultStoreQueueClearTimeout = Duration(seconds: 3);

  factory IapPurchaseService(
    IapStoreGateway store,
    IapTransactionApiService transactionApiService,
    IapPackageResolver packageResolver,
    IapAuthenticationEnsurer ensureAuthenticated, {
    IapSubscriptionPurchaseRecorder? subscriptionPurchaseRecorder,
    IapPurchaseEventLogger? purchaseEventLogger,
    IapPurchaseErrorLogger? purchaseErrorLogger,
    IapEntitlementChanged? entitlementChanged,
    Duration purchaseTimeout = _defaultPurchaseTimeout,
    Duration verificationUiTimeout = _defaultVerificationUiTimeout,
    Duration storeQueuePollDelay = _defaultStoreQueuePollDelay,
    Duration storeQueueClearTimeout = _defaultStoreQueueClearTimeout,
  }) => IapPurchaseService._(
    store,
    transactionApiService,
    packageResolver,
    ensureAuthenticated,
    subscriptionPurchaseRecorder,
    purchaseEventLogger,
    purchaseErrorLogger,
    entitlementChanged,
    purchaseTimeout,
    verificationUiTimeout,
    storeQueuePollDelay,
    storeQueueClearTimeout,
  );

  IapPurchaseService._(
    this._store,
    this._transactionApiService,
    this._packageResolver,
    this._ensureAuthenticated,
    this._subscriptionPurchaseRecorder,
    this._purchaseEventLogger,
    this._purchaseErrorLogger,
    this._entitlementChanged,
    this._purchaseTimeout,
    this._verificationUiTimeout,
    this._storeQueuePollDelay,
    this._storeQueueClearTimeout,
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
  final IapSubscriptionPurchaseRecorder? _subscriptionPurchaseRecorder;
  final IapPurchaseEventLogger? _purchaseEventLogger;
  final IapPurchaseErrorLogger? _purchaseErrorLogger;
  final IapEntitlementChanged? _entitlementChanged;
  final Duration _purchaseTimeout;
  final Duration _verificationUiTimeout;
  final Duration _storeQueuePollDelay;
  final Duration _storeQueueClearTimeout;
  final Set<String> _verificationsInFlight = {};
  final Set<String> _completionsInFlight = {};
  final Set<String> _locallyCompletedPurchaseKeys = {};
  final Set<String> _storePendingProductIds = {};
  final Set<String> _nativePurchasesInFlight = {};
  final Set<String> _supersededUpgradeSourceProductIds = {};
  final Map<String, PurchaseDetails> _pendingPurchases = {};
  final Map<String, PurchaseDetails> _deferredUpgradeSourcePurchases = {};
  final Map<String, String> _subscriptionUpgradeSources = {};

  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  Completer<IapPurchaseResult>? _activePurchase;
  String? _activeProductId;
  int? _activePurchaseStartedAtMs;
  IapPackage? _activePackage;
  ProductDetails? _activeProduct;
  Timer? _activePurchaseTimer;
  bool _skillPackRetryScheduled = false;

  Future<IapPurchaseResult> purchase({
    required IapPackage package,
    required ProductDetails? product,
    String? previousSubscriptionProductId,
  }) async {
    if (product == null || product.id != package.productId) {
      return const IapPurchaseResult(
        IapPurchaseResultStatus.productUnavailable,
      );
    }
    if (_nativePurchasesInFlight.contains(package.productId)) {
      return const IapPurchaseResult(IapPurchaseResultStatus.pending);
    }
    final activePurchase = _activePurchase;
    if (activePurchase != null) {
      if (_activeProductId == package.productId) {
        return activePurchase.future;
      }
      return const IapPurchaseResult(IapPurchaseResultStatus.pending);
    }
    if (_storePendingProductIds.contains(package.productId)) {
      return const IapPurchaseResult(IapPurchaseResultStatus.pending);
    }

    final completer = Completer<IapPurchaseResult>();
    _activePurchase = completer;
    _activeProductId = package.productId;
    _activePurchaseStartedAtMs = DateTime.now().millisecondsSinceEpoch;
    _activePackage = package;
    _activeProduct = product;
    final previousProductId = previousSubscriptionProductId?.trim();
    if (_isSubscription(package) &&
        previousProductId?.isNotEmpty == true &&
        previousProductId != package.productId) {
      _subscriptionUpgradeSources[package.productId] = previousProductId!;
    } else {
      _subscriptionUpgradeSources.remove(package.productId);
    }
    _startActivePurchaseTimeout(package.productId);

    // A skill pack is an independent one-time product. Always ask the store to
    // purchase it first so buying one pack can never short-circuit a later Buy
    // action for another pack. If StoreKit reports a duplicate transaction for
    // this exact product, _startStorePurchase recovers that transaction.
    if (!_isSkillPack(package)) {
      // Finish transactions left in StoreKit by an earlier purchase before
      // asking Apple to create another transaction for the same product. An
      // expired subscription is cleanup work, not a successful new Buy action.
      var completedRecoveredTransaction = false;
      final recoveryResult = await _recoverUnfinishedBeforePurchase(
        package,
        onTransactionCompleted: () => completedRecoveredTransaction = true,
      );
      if (!identical(_activePurchase, completer)) return completer.future;
      if (recoveryResult != null) {
        _finishActive(recoveryResult);
        return completer.future;
      }
      if (completedRecoveredTransaction) {
        final storeQueueReady = await _waitForStoreQueueToClear(
          package.productId,
        );
        if (!identical(_activePurchase, completer)) return completer.future;
        if (!storeQueueReady) {
          _finishActive(
            const IapPurchaseResult(IapPurchaseResultStatus.pending),
          );
          return completer.future;
        }
      }
    }

    bool available;
    try {
      available = await _store.isAvailable();
    } on Object catch (error) {
      _reportPurchaseError(
        productId: package.productId,
        phase: 'store_availability',
        error: error,
      );
      _finishActive(
        _safeFailureResult(
          error,
          fallbackStatus: IapPurchaseResultStatus.storeUnavailable,
        ),
      );
      return completer.future;
    }
    if (!identical(_activePurchase, completer)) return completer.future;
    if (!available) {
      _finishActive(
        const IapPurchaseResult(IapPurchaseResultStatus.storeUnavailable),
      );
      return completer.future;
    }

    if (_isSkillPack(package)) {
      final finishedTransactions =
          await _finishUnfinishedSandboxSkillPackPurchases(package.productId);
      if (!identical(_activePurchase, completer)) return completer.future;
      if (finishedTransactions > 0) {
        debugPrint(
          '[IAP][SkillPack][Sandbox] Cleanup completed: '
          'finishedTransactions=$finishedTransactions. '
          'Starting a new StoreKit purchase for productID=${package.productId}',
        );
      }
    }
    await _startStorePurchase(
      package,
      product,
      previousSubscriptionProductId: previousSubscriptionProductId,
    );
    return completer.future;
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
    String? previousSubscriptionProductId,
  }) async {
    _nativePurchasesInFlight.add(package.productId);
    try {
      PurchaseDetails? oldSubscription;
      if (_isAndroidSubscriptionChange(
        package,
        previousSubscriptionProductId,
      )) {
        oldSubscription = await _store.pastPurchase(
          previousSubscriptionProductId!,
        );
        if (oldSubscription == null) {
          _finishActive(
            const IapPurchaseResult(IapPurchaseResultStatus.failed),
          );
          return;
        }
      }
      final started = _isConsumable(package)
          ? await _store.buyConsumable(product)
          : await _store.buyNonConsumable(
              product,
              oldSubscription: oldSubscription,
            );
      if (!started) {
        _reportPurchaseError(
          productId: package.productId,
          phase: 'purchase_request',
          code: 'purchase_request_not_started',
        );
        _finishForProduct(
          package.productId,
          const IapPurchaseResult(IapPurchaseResultStatus.failed),
        );
      }
    } on Object catch (error) {
      _reportPurchaseError(
        productId: package.productId,
        phase: 'purchase_request',
        error: error,
      );
      if (_isDuplicateProductError(error)) {
        if (!recoverDuplicate) {
          _finishForProduct(
            package.productId,
            const IapPurchaseResult(IapPurchaseResultStatus.pending),
          );
          return;
        }
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

        // StoreKit can surface the duplicate before Transaction.unfinished is
        // visible to Dart. Give the queue one short turn before recovery.
        await Future<void>.delayed(_storeQueuePollDelay);
        final recoveryResult = await _recoverUnfinishedBeforePurchase(package);
        if (recoveryResult != null) {
          _finishForProduct(package.productId, recoveryResult);
          return;
        }

        final storeQueueReady = await _waitForStoreQueueToClear(
          package.productId,
        );
        if (!storeQueueReady) {
          _finishForProduct(
            package.productId,
            const IapPurchaseResult(IapPurchaseResultStatus.pending),
          );
          return;
        }

        // Retry only after StoreKit confirms the old transaction disappeared.
        await _startStorePurchase(
          package,
          product,
          recoverDuplicate: false,
          previousSubscriptionProductId: previousSubscriptionProductId,
        );
        return;
      }
      _finishForProduct(package.productId, _safeFailureResult(error));
    } finally {
      _nativePurchasesInFlight.remove(package.productId);
    }
  }

  Future<bool> _waitForStoreQueueToClear(String productId) async {
    final deadline = DateTime.now().add(_storeQueueClearTimeout);
    while (true) {
      try {
        final unfinished = await _store.unfinishedPurchases(productId);
        if (unfinished.isEmpty) return true;
      } on Object catch (error) {
        _reportPurchaseError(
          productId: productId,
          phase: 'unfinished_queue_check',
          error: error,
        );
        return false;
      }

      if (!DateTime.now().isBefore(deadline)) return false;
      await Future<void>.delayed(_storeQueuePollDelay);
    }
  }

  Future<IapPurchaseResult?> _recoverUnfinishedBeforePurchase(
    IapPackage package, {
    VoidCallback? onTransactionCompleted,
  }) async {
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
        return const IapPurchaseResult(IapPurchaseResultStatus.pending);
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
        _logSkillPackValidationBill(package, purchase);
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
        if (_isSubscription(package) && !grantsEntitlement) {
          final expiresAtMs = _storeKitExpirationDateMs(purchase);
          final isExpired =
              expiresAtMs != null &&
              expiresAtMs <= DateTime.now().millisecondsSinceEpoch;
          if (!isExpired) {
            return IapPurchaseResult(
              IapPurchaseResultStatus.pending,
              verificationResponse: response,
            );
          }
        }

        if (grantsEntitlement) {
          if (_subscriptionEntitlementIsStillProcessing(package, response)) {
            final expiresAtMs = _storeKitExpirationDateMs(purchase);
            final isExpired =
                expiresAtMs != null &&
                expiresAtMs <= DateTime.now().millisecondsSinceEpoch;
            if (!isExpired) {
              return IapPurchaseResult(
                IapPurchaseResultStatus.pending,
                verificationResponse: response,
              );
            }
          } else {
            activeEntitlementResponse = response;
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
          onTransactionCompleted?.call();
        }
        _removePendingPurchase(purchase);
      } on Object catch (error) {
        // Keep an unverified transaction unfinished. Starting another StoreKit
        // transaction here would recreate the duplicate-product error.
        _reportPurchaseError(
          productId: package.productId,
          phase: 'unfinished_verification',
          error: error,
        );
        return _safeFailureResult(
          error,
          fallbackStatus: IapPurchaseResultStatus.verificationFailed,
          classifyNetwork: false,
        );
      } finally {
        _verificationsInFlight.remove(verificationKey);
      }
    }

    if (activeEntitlementResponse == null) return null;
    unawaited(_recordSubscriptionPurchase(package));
    _subscriptionUpgradeSources.remove(package.productId);
    _notifyEntitlementChanged();
    return IapPurchaseResult(
      IapPurchaseResultStatus.verified,
      verificationResponse: activeEntitlementResponse,
    );
  }

  Future<void> restorePurchases() => _store.restorePurchases();

  /// Finishes a transaction after a refreshed profile confirms that the
  /// backend has applied the exact subscription product.
  Future<void> completePendingPurchase(String productId) async {
    final purchase = _pendingPurchases[productId];
    if (purchase == null) return;
    final verificationKey = _verificationKey(purchase);
    if (!_completionsInFlight.add(verificationKey)) return;
    final upgradeSourceProductId = _subscriptionUpgradeSources[productId];
    if (upgradeSourceProductId != null) {
      _supersededUpgradeSourceProductIds.add(upgradeSourceProductId);
    }

    try {
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _removePendingPurchase(purchase);
      _subscriptionUpgradeSources.remove(productId);

      if (purchase.status == PurchaseStatus.purchased) {
        final package = await _packageResolver(productId);
        if (package != null) {
          unawaited(_logVerifiedPurchase(package, purchase));
          unawaited(_recordSubscriptionPurchase(package));
        }
      }
    } on Object catch (error, stackTrace) {
      // StoreKit will redeliver an unfinished transaction on a later launch.
      debugPrint('[IAP] Could not finish confirmed transaction: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    } finally {
      _completionsInFlight.remove(verificationKey);
    }
    if (upgradeSourceProductId != null) {
      await _completeSupersededUpgradeSourcePurchases(upgradeSourceProductId);
    }
  }

  Future<void> dispose() async {
    _activePurchaseTimer?.cancel();
    await _purchaseSubscription.cancel();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final activeProductId = _activeProductId;
    final deferredUpgradeKeys = <String>{};
    if (activeProductId != null) {
      for (final purchase in purchases) {
        if (purchase.status != PurchaseStatus.purchased &&
            purchase.status != PurchaseStatus.restored) {
          continue;
        }
        if (_deferUpgradeSourcePurchase(activeProductId, purchase)) {
          deferredUpgradeKeys.add(_verificationKey(purchase));
        }
      }
    }
    final orderedPurchases = activeProductId == null
        ? purchases
        : [
            ...purchases.where(
              (purchase) => purchase.productID == activeProductId,
            ),
            ...purchases.where(
              (purchase) => purchase.productID != activeProductId,
            ),
          ];

    for (final purchase in orderedPurchases) {
      if (deferredUpgradeKeys.contains(_verificationKey(purchase))) continue;
      if ((purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) &&
          _supersededUpgradeSourceProductIds.contains(purchase.productID)) {
        await _completeSupersededUpgradeSourcePurchase(purchase);
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _storePendingProductIds.add(purchase.productID);
          _finishForProduct(
            purchase.productID,
            const IapPurchaseResult(IapPurchaseResultStatus.pending),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _storePendingProductIds.remove(purchase.productID);
          if (_activeProductId == purchase.productID) {
            // Apple has finished its purchase UI. From this point onward the
            // user must not remain blocked by a slow backend or StoreKit
            // finish call; verification continues after this bounded wait.
            _startActivePurchaseTimeout(
              purchase.productID,
              timeout: _verificationUiTimeout,
            );
          }
          // A transaction redelivered by StoreKit/Play is an existing store
          // transaction, not a new Buy request. Verify and finish it here;
          // never route it through purchase(), which must start a new store
          // purchase when the user taps Buy.
          await _verifyAndComplete(purchase);
        case PurchaseStatus.error:
          _storePendingProductIds.remove(purchase.productID);
          _subscriptionUpgradeSources.remove(purchase.productID);
          _reportPurchaseError(
            productId: purchase.productID,
            phase: 'purchase_update',
            error: purchase.error,
          );
          _finishForProduct(
            purchase.productID,
            _safeFailureResult(purchase.error),
          );
        case PurchaseStatus.canceled:
          _storePendingProductIds.remove(purchase.productID);
          _subscriptionUpgradeSources.remove(purchase.productID);
          _finishForProduct(
            purchase.productID,
            const IapPurchaseResult(IapPurchaseResultStatus.canceled),
          );
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final verificationKey = _verificationKey(purchase);
    // A StoreKit update may already be queued when a stale sandbox skill-pack
    // transaction is completed locally. Ignore that delayed update so only the
    // fresh purchase is sent to the backend.
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
      _logSkillPackValidationBill(package, purchase);
      final verificationResponse = await _transactionApiService.verifyPurchase(
        request,
      );
      final grantsEntitlement = _grantsEntitlement(
        package,
        verificationResponse,
      );
      if (_isSkillPack(package) && grantsEntitlement != true) {
        _finishForProduct(
          purchase.productID,
          IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message: _isSkillPack(package)
                ? 'The backend did not grant the purchased skill-pack product.'
                : 'The backend did not grant the purchased subscription.',
          ),
        );
        return;
      }
      if (_isSubscription(package) &&
          _activeProductId == purchase.productID &&
          grantsEntitlement != true) {
        _finishForProduct(
          purchase.productID,
          const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message:
                'The backend did not grant the purchased subscription product.',
          ),
        );
        return;
      }

      if (_hasMismatchedSubscriptionEntitlement(
            package,
            verificationResponse,
          ) &&
          !_requiresExactSubscriptionProduct(package)) {
        _finishForProduct(
          purchase.productID,
          const IapPurchaseResult(
            IapPurchaseResultStatus.verificationFailed,
            message:
                'The backend did not grant the purchased subscription product.',
          ),
        );
        return;
      }

      final upgradeStillProcessing = _subscriptionEntitlementIsStillProcessing(
        package,
        verificationResponse,
      );
      if (upgradeStillProcessing) {
        final expiresAtMs = _storeKitExpirationDateMs(purchase);
        final isExpired =
            expiresAtMs != null &&
            expiresAtMs <= DateTime.now().millisecondsSinceEpoch;
        if (!isExpired) {
          _finishForProduct(
            purchase.productID,
            IapPurchaseResult(
              IapPurchaseResultStatus.pending,
              verificationResponse: verificationResponse,
            ),
          );
          return;
        }

        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        _removePendingPurchase(purchase);
        return;
      }

      final upgradeSourceProductId =
          _subscriptionUpgradeSources[purchase.productID];
      unawaited(_recordSubscriptionPurchase(package));
      if (upgradeSourceProductId != null) {
        _supersededUpgradeSourceProductIds.add(upgradeSourceProductId);
      }
      _subscriptionUpgradeSources.remove(purchase.productID);
      if (grantsEntitlement == true) _notifyEntitlementChanged();
      _finishForProduct(
        purchase.productID,
        IapPurchaseResult(
          IapPurchaseResultStatus.verified,
          verificationResponse: verificationResponse,
        ),
      );
      await _completeVerifiedPurchase(
        package,
        purchase,
        upgradeSourceProductId: upgradeSourceProductId,
      );
    } on Object catch (error) {
      // Do not complete the store transaction when backend verification fails.
      // StoreKit/Google Play can redeliver it and the app can safely retry.
      _reportPurchaseError(
        productId: purchase.productID,
        phase: 'purchase_verification',
        error: error,
      );
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

  Future<void> _recordSubscriptionPurchase(IapPackage package) async {
    final recorder = _subscriptionPurchaseRecorder;
    if (recorder == null || !_isSubscription(package)) return;
    try {
      await recorder();
    } on Object catch (error, stackTrace) {
      debugPrint('Could not persist subscription purchase history: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _notifyEntitlementChanged() {
    try {
      _entitlementChanged?.call();
    } on Object catch (error, stackTrace) {
      debugPrint('Could not refresh IAP entitlement state: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _completeVerifiedPurchase(
    IapPackage package,
    PurchaseDetails purchase, {
    String? upgradeSourceProductId,
  }) async {
    final verificationKey = _verificationKey(purchase);
    if (!_completionsInFlight.add(verificationKey)) return;

    try {
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _removePendingPurchase(purchase);
      if (purchase.status == PurchaseStatus.purchased) {
        unawaited(_logVerifiedPurchase(package, purchase));
      }
    } on Object catch (error) {
      // The entitlement is already confirmed and the UI has been released.
      // StoreKit will redeliver an unfinished transaction on a later launch.
      _reportPurchaseError(
        productId: purchase.productID,
        phase: 'purchase_completion',
        error: error,
      );
    } finally {
      _completionsInFlight.remove(verificationKey);
    }
    if (upgradeSourceProductId != null) {
      await _completeSupersededUpgradeSourcePurchases(upgradeSourceProductId);
    }
  }

  bool _deferUpgradeSourcePurchase(
    String activeProductId,
    PurchaseDetails purchase,
  ) {
    if (purchase.productID == activeProductId) {
      return false;
    }
    final sourceProductId = _subscriptionUpgradeSources[activeProductId];
    if (sourceProductId == null || purchase.productID != sourceProductId) {
      return false;
    }

    final verificationKey = _verificationKey(purchase);
    _deferredUpgradeSourcePurchases[verificationKey] = purchase;
    debugPrint(
      '[IAP][Subscription] Deferred source transaction during upgrade: '
      'sourceProductID=${purchase.productID}, '
      'targetProductID=$activeProductId, '
      'purchaseID=${purchase.purchaseID}',
    );
    return true;
  }

  Future<void> _completeSupersededUpgradeSourcePurchases(
    String sourceProductId,
  ) async {
    final deferredEntries = _deferredUpgradeSourcePurchases.entries
        .where((entry) => entry.value.productID == sourceProductId)
        .toList(growable: false);
    for (final entry in deferredEntries) {
      await _completeSupersededUpgradeSourcePurchase(entry.value);
    }
  }

  Future<void> _completeSupersededUpgradeSourcePurchase(
    PurchaseDetails purchase,
  ) async {
    final verificationKey = _verificationKey(purchase);
    if (!_completionsInFlight.add(verificationKey)) return;
    try {
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      _locallyCompletedPurchaseKeys.add(verificationKey);
      _deferredUpgradeSourcePurchases.remove(verificationKey);
    } on Object catch (error) {
      _reportPurchaseError(
        productId: purchase.productID,
        phase: 'superseded_upgrade_source_completion',
        error: error,
      );
    } finally {
      _completionsInFlight.remove(verificationKey);
    }
  }

  void _logSkillPackValidationBill(
    IapPackage package,
    PurchaseDetails purchase,
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
  }

  bool _isConsumable(IapPackage package) =>
      package.productType.trim().toUpperCase() == 'CONSUMABLE';

  bool _isSubscription(IapPackage package) =>
      package.productType.trim().toUpperCase().contains('SUBSCRIPTION');

  bool _isAndroidSubscriptionChange(
    IapPackage package,
    String? previousSubscriptionProductId,
  ) =>
      _isSubscription(package) &&
      package.platform.trim().toUpperCase() == 'ANDROID' &&
      previousSubscriptionProductId != null &&
      previousSubscriptionProductId.isNotEmpty &&
      previousSubscriptionProductId != package.productId;

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

  bool _requiresExactSubscriptionProduct(IapPackage package) {
    final previousProductId = _subscriptionUpgradeSources[package.productId];
    return _isSubscription(package) &&
        previousProductId?.isNotEmpty == true &&
        previousProductId != package.productId;
  }

  bool _subscriptionEntitlementIsStillProcessing(
    IapPackage package,
    IapTransactionBuyResponse response,
  ) {
    return _requiresExactSubscriptionProduct(package) &&
        !_subscriptionEntitlementMatches(package, response);
  }

  bool _hasMismatchedSubscriptionEntitlement(
    IapPackage package,
    IapTransactionBuyResponse response,
  ) {
    if (!_isSubscription(package)) return false;
    final subscription = response.data['subscription'];
    return subscription is Map &&
        subscription.isNotEmpty &&
        !_subscriptionEntitlementMatches(package, response);
  }

  bool _subscriptionEntitlementMatches(
    IapPackage package,
    IapTransactionBuyResponse response,
  ) {
    final subscription = response.data['subscription'];
    return subscription is Map &&
        _subscriptionDataMatchesPackage(subscription, package);
  }

  bool _subscriptionDataMatchesPackage(Map subscription, IapPackage package) {
    final productId = package.productId.trim();
    bool containsProductId(Object? value) {
      if (value is Map) return value.values.any(containsProductId);
      if (value is Iterable) return value.any(containsProductId);
      return productId.isNotEmpty && value?.toString().trim() == productId;
    }

    if (containsProductId(subscription)) return true;
    const durationKeys = {
      'packDurationDay',
      'packDurationDays',
      'durationDay',
      'durationDays',
      'duration',
    };
    bool containsDuration(Map value) {
      for (final entry in value.entries) {
        if (durationKeys.contains(entry.key) &&
            int.tryParse('${entry.value}') == package.packDurationDay) {
          return true;
        }
        if (entry.value is Map && containsDuration(entry.value as Map)) {
          return true;
        }
      }
      return false;
    }

    return containsDuration(subscription);
  }

  void _removePendingPurchase(PurchaseDetails purchase) {
    final pending = _pendingPurchases[purchase.productID];
    if (pending != null &&
        _verificationKey(pending) == _verificationKey(purchase)) {
      _pendingPurchases.remove(purchase.productID);
    }
  }

  bool _isDuplicateProductError(Object? error) {
    final message = '$error'.toLowerCase();
    return message.contains('storekit_duplicate_product_object') ||
        message.contains('pending transaction for the same product');
  }

  IapPurchaseResult _safeFailureResult(
    Object? error, {
    IapPurchaseResultStatus fallbackStatus = IapPurchaseResultStatus.failed,
    bool classifyNetwork = true,
  }) {
    if (_isDuplicateProductError(error)) {
      return const IapPurchaseResult(IapPurchaseResultStatus.pending);
    }
    if (_isCancellationError(error)) {
      return const IapPurchaseResult(IapPurchaseResultStatus.canceled);
    }
    if (_isProductUnavailableError(error)) {
      return const IapPurchaseResult(
        IapPurchaseResultStatus.productUnavailable,
      );
    }
    if (_isPurchaseNotAllowedError(error)) {
      return const IapPurchaseResult(
        IapPurchaseResultStatus.purchaseNotAllowed,
      );
    }
    debugPrint('IAP error: ${_errorCode(error)}');
    return IapPurchaseResult(
      classifyNetwork && _isNetworkError(error)
          ? IapPurchaseResultStatus.networkUnavailable
          : fallbackStatus,
    );
  }

  bool _isCancellationError(Object? error) {
    final message = _normalizedError(error);
    return message.contains('payment_cancelled') ||
        message.contains('payment_canceled') ||
        message.contains('user_cancelled') ||
        message.contains('user_canceled');
  }

  bool _isProductUnavailableError(Object? error) {
    final message = _normalizedError(error);
    return message.contains('storekit2_failed_to_fetch_product') ||
        message.contains('product_not_available') ||
        message.contains('productnotavailable') ||
        message.contains('item_unavailable') ||
        message.contains('itemunavailable');
  }

  bool _isPurchaseNotAllowedError(Object? error) {
    final message = _normalizedError(error);
    return message.contains('payment_not_allowed') ||
        message.contains('paymentnotallowed') ||
        message.contains('client_invalid') ||
        message.contains('clientinvalid') ||
        message.contains('not allowed to make payments') ||
        message.contains('cannot make payments') ||
        message.contains('privacy_acknowledgement_required') ||
        message.contains('cloud_service_permission_denied');
  }

  String _normalizedError(Object? error) => switch (error) {
    PlatformException value =>
      '${value.code} ${value.message ?? ''} ${value.details ?? ''}'
          .toLowerCase(),
    IAPError value =>
      '${value.code} ${value.message} ${value.details ?? ''}'.toLowerCase(),
    InAppPurchaseException value =>
      '${value.code} ${value.message ?? ''}'.toLowerCase(),
    _ => '${error ?? ''}'.toLowerCase(),
  };

  String _errorCode(Object? error) {
    final typedCode = switch (error) {
      PlatformException value => value.code,
      IAPError value => value.code,
      InAppPurchaseException value => value.code,
      null => 'unknown',
      _ => '',
    };
    if (typedCode.trim().isNotEmpty) return typedCode.trim();

    final normalized = _normalizedError(error);
    const knownCodes = <String>[
      'storekit_duplicate_product_object',
      'storekit2_failed_to_fetch_product',
      'payment_not_allowed',
      'payment_cancelled',
      'payment_canceled',
      'user_cancelled',
      'user_canceled',
      'product_not_available',
      'item_unavailable',
      'network_error',
      'networkerror',
    ];
    for (final code in knownCodes) {
      if (normalized.contains(code)) return code;
    }

    return error?.runtimeType.toString() ?? 'unknown';
  }

  void _reportPurchaseError({
    required String productId,
    required String phase,
    Object? error,
    String? code,
  }) {
    final logger = _purchaseErrorLogger;
    if (logger == null) return;
    unawaited(
      _sendPurchaseError(
        logger,
        productId: productId,
        phase: phase,
        code: code ?? _errorCode(error),
      ),
    );
  }

  Future<void> _sendPurchaseError(
    IapPurchaseErrorLogger logger, {
    required String productId,
    required String phase,
    required String code,
  }) async {
    try {
      await logger(productId: productId, phase: phase, code: code);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not log IAP error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    }
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
    _reportPurchaseError(
      productId: _activeProductId ?? 'unknown',
      phase: 'purchase_stream',
      error: error,
    );
    _finishActive(_safeFailureResult(error));
  }

  void _startActivePurchaseTimeout(String productId, {Duration? timeout}) {
    _activePurchaseTimer?.cancel();
    _activePurchaseTimer = Timer(timeout ?? _purchaseTimeout, () {
      if (_activeProductId != productId) return;
      _finishActive(const IapPurchaseResult(IapPurchaseResultStatus.pending));
    });
  }

  void _finishForProduct(String productId, IapPurchaseResult result) {
    if (_activeProductId == productId) _finishActive(result);
  }

  void _finishActive(IapPurchaseResult result) {
    final completer = _activePurchase;
    final productId = _activeProductId;
    if (result.status != IapPurchaseResultStatus.pending && productId != null) {
      _subscriptionUpgradeSources.remove(productId);
    }
    _activePurchaseTimer?.cancel();
    _activePurchaseTimer = null;
    _activePurchase = null;
    _activeProductId = null;
    _activePurchaseStartedAtMs = null;
    _activePackage = null;
    _activeProduct = null;
    _skillPackRetryScheduled = false;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }
}
