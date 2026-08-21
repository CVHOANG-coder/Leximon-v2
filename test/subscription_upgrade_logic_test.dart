import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/models/user_profile_response.dart';
import 'package:leximon/data/services/iap_purchase_service.dart';
import 'package:leximon/data/services/iap_transaction_api_service.dart';
import 'package:leximon/presentation/screens/update_subscription/update_subscription_screen.dart';

void main() {
  test('a weekly subscriber sees the monthly and annual upgrades', () {
    final current = resolveCurrentSubscriptionPackage(
      profile: _profile(subscription: {'productId': 'subscription.week'}),
      packages: _packages,
    );

    expect(current?.productId, 'subscription.week');
    expect(
      visibleSubscriptionPackages(
        packages: _packages,
        current: current,
      ).map((package) => package.productId),
      ['subscription.week', 'subscription.month', 'subscription.year'],
    );
  });

  test('a monthly subscriber only sees the annual upgrade', () {
    final current = resolveCurrentSubscriptionPackage(
      profile: _profile(subscription: {'packDurationDay': 30}),
      packages: _packages,
    );

    expect(current?.productId, 'subscription.month');
    expect(
      visibleSubscriptionPackages(
        packages: _packages,
        current: current,
      ).map((package) => package.productId),
      ['subscription.month', 'subscription.year'],
    );
  });

  test('an annual subscriber does not see shorter plans', () {
    final current = resolveCurrentSubscriptionPackage(
      profile: _profile(subscription: {'productId': 'subscription.year'}),
      packages: _packages,
    );

    expect(current?.productId, 'subscription.year');
    expect(
      visibleSubscriptionPackages(
        packages: _packages,
        current: current,
      ).map((package) => package.productId),
      ['subscription.year'],
    );
  });

  test('premium status alone does not confirm a package upgrade', () {
    final profile = _profile(subscription: {'productId': 'subscription.week'});

    expect(
      isSubscriptionPackageActive(profile: profile, package: _packages[1]),
      isFalse,
    );
  });

  test('the target package in subscription confirms the upgrade', () {
    final profile = _profile(
      subscription: {
        'latestTransaction': {'productId': 'subscription.month'},
      },
    );

    expect(
      isSubscriptionPackageActive(profile: profile, package: _packages[1]),
      isTrue,
    );
  });

  test('reads the upgraded subscription from transaction-buy response', () {
    final profile = profileFromIapPurchaseResult(
      const IapPurchaseResult(
        IapPurchaseResultStatus.verified,
        verificationResponse: IapTransactionBuyResponse(
          success: true,
          message: 'Transaction processed',
          data: {
            'isPremium': true,
            'subscription': {'productId': 'subscription.month'},
            'ownedProducts': [],
            'ownedProductIds': [],
          },
        ),
      ),
    );

    expect(profile, isNotNull);
    expect(
      isSubscriptionPackageActive(profile: profile!, package: _packages[1]),
      isTrue,
    );
  });

  test('stale selected package is ignored after it becomes current', () {
    final current = _packages[1];
    final visible = visibleSubscriptionPackages(
      packages: _packages,
      current: current,
    );

    final selected = selectSubscriptionUpgradePackage(
      packages: visible,
      current: current,
      recommended: _packages[2],
      selectedProductId: current.productId,
    );

    expect(selected?.productId, 'subscription.year');
  });

  test('no package is selected when the annual plan is current', () {
    final current = _packages[2];
    final visible = visibleSubscriptionPackages(
      packages: _packages,
      current: current,
    );

    final selected = selectSubscriptionUpgradePackage(
      packages: visible,
      current: current,
      recommended: null,
      selectedProductId: current.productId,
    );

    expect(selected, isNull);
  });
}

final _packages = [
  _package('subscription.week', 7),
  _package('subscription.month', 30),
  _package('subscription.year', 365),
];

IapPackage _package(String productId, int duration) => IapPackage(
  id: duration,
  productId: productId,
  productType: 'SUBSCRIPTION',
  name: productId,
  description: '',
  price: 1,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: duration,
  trialDays: 0,
  isEnabled: true,
  sortOrder: duration,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'SUBSCRIPTION',
);

UserProfile _profile({required Map<String, dynamic> subscription}) =>
    UserProfile(
      id: 1,
      userCode: 'test',
      email: 'test@example.com',
      username: null,
      avatar: '',
      platform: 'IOS',
      country: 'VN',
      isPremium: true,
      createdAt: null,
      language: 'vi',
      appVersion: '1.0.0',
      databaseVersion: 1,
      notificationEnabled: true,
      subscription: subscription,
      ownedProducts: const [],
      ownedProductIds: const [],
    );
