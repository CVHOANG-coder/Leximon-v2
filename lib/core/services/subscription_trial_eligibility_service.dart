import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef IntroductoryOfferEligibilityChecker =
    Future<bool> Function(String productId);

class SubscriptionTrialEligibilityService {
  SubscriptionTrialEligibilityService({
    SharedPreferences? preferences,
    IntroductoryOfferEligibilityChecker? eligibilityChecker,
    TargetPlatform Function()? platformProvider,
  }) : _preferences = preferences,
       _eligibilityChecker =
           eligibilityChecker ?? SK2Product.isIntroductoryOfferEligible,
       _platformProvider = platformProvider ?? _defaultPlatform;

  static const hasPurchasedSubscriptionKey = 'iap.has_purchased_subscription';

  final SharedPreferences? _preferences;
  final IntroductoryOfferEligibilityChecker _eligibilityChecker;
  final TargetPlatform Function() _platformProvider;

  static TargetPlatform _defaultPlatform() => defaultTargetPlatform;

  Future<bool> isEligible(Iterable<String> productIds) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    if (preferences.getBool(hasPurchasedSubscriptionKey) == true) return false;

    final ids = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return false;
    if (_platformProvider() != TargetPlatform.iOS) return true;
    if (!InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) return false;

    try {
      for (final productId in ids) {
        if (!await _eligibilityChecker(productId)) {
          await preferences.setBool(hasPurchasedSubscriptionKey, true);
          return false;
        }
      }
      return true;
    } on Object catch (error) {
      debugPrint('Could not read subscription trial eligibility: $error');
      // Never advertise a free trial when StoreKit cannot confirm eligibility.
      return false;
    }
  }

  Future<void> markSubscriptionPurchased() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final saved = await preferences.setBool(hasPurchasedSubscriptionKey, true);
    if (!saved) {
      throw StateError('Could not persist subscription purchase history.');
    }
  }
}
