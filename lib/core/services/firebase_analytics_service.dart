import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/models/iap_packages_response.dart';

/// Sends analytics events without allowing an unavailable Firebase
/// configuration to interrupt the purchase flow.
class FirebaseAnalyticsService {
  FirebaseAnalytics? _analytics;

  Future<void> logPurchase({
    required IapPackage package,
    required PurchaseDetails purchase,
  }) async {
    final analytics = await _loadAnalytics();
    if (analytics == null) return;

    final currency = package.currency.trim().toUpperCase();
    final value = package.price.isFinite && package.price > 0
        ? package.price
        : null;

    try {
      await analytics.logPurchase(
        currency: currency.isEmpty ? null : currency,
        value: currency.isEmpty ? null : value,
        transactionId: purchase.purchaseID,
        items: [
          AnalyticsEventItem(
            itemId: purchase.productID,
            itemName: package.name.trim().isEmpty
                ? package.productId
                : package.name,
            price: value,
            quantity: 1,
            currency: currency.isEmpty ? null : currency,
          ),
        ],
        parameters: {
          'package_group': package.group,
          'product_type': package.productType,
          'platform': package.platform,
        },
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Could not log Firebase purchase event: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<FirebaseAnalytics?> _loadAnalytics() async {
    if (_analytics != null) return _analytics;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _analytics = FirebaseAnalytics.instance;
      return _analytics;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase Analytics is unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
