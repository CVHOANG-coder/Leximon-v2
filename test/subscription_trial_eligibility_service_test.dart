import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/services/subscription_trial_eligibility_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'local purchase history hides the trial without querying StoreKit',
    () async {
      SharedPreferences.setMockInitialValues({
        SubscriptionTrialEligibilityService.hasPurchasedSubscriptionKey: true,
      });
      final preferences = await SharedPreferences.getInstance();
      var storeKitCalls = 0;
      final service = SubscriptionTrialEligibilityService(
        preferences: preferences,
        platformProvider: () => TargetPlatform.iOS,
        eligibilityChecker: (_) async {
          storeKitCalls++;
          return true;
        },
      );

      expect(await service.isEligible(const ['weekly', 'yearly']), isFalse);
      expect(storeKitCalls, 0);
    },
  );

  test('StoreKit ineligibility is persisted locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = SubscriptionTrialEligibilityService(
      preferences: preferences,
      platformProvider: () => TargetPlatform.iOS,
      eligibilityChecker: (productId) async => productId != 'yearly',
    );

    expect(await service.isEligible(const ['weekly', 'yearly']), isFalse);
    expect(
      preferences.getBool(
        SubscriptionTrialEligibilityService.hasPurchasedSubscriptionKey,
      ),
      isTrue,
    );
  });

  test('shows the trial only when StoreKit confirms every product', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = SubscriptionTrialEligibilityService(
      preferences: preferences,
      platformProvider: () => TargetPlatform.iOS,
      eligibilityChecker: (_) async => true,
    );

    expect(await service.isEligible(const ['weekly', 'yearly']), isTrue);
  });

  test(
    'hides the trial when StoreKit eligibility cannot be confirmed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = SubscriptionTrialEligibilityService(
        preferences: preferences,
        platformProvider: () => TargetPlatform.iOS,
        eligibilityChecker: (_) => Future<bool>.error(StateError('StoreKit')),
      );

      expect(await service.isEligible(const ['weekly', 'yearly']), isFalse);
    },
  );
}
