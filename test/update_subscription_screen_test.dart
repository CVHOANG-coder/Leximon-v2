import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/models/user_profile_response.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/data/services/iap_purchase_service.dart';
import 'package:leximon/data/services/iap_transaction_api_service.dart';
import 'package:leximon/presentation/screens/update_subscription/update_subscription_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('updates the current plan from transaction-buy response', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _SuccessfulStoreGateway();
    final client = ApiClient(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Transaction processed',
            'data': _profileJson(
              subscriptionProductId: _monthlyPackage.productId,
            ),
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'https://example.com',
      authToken: 'token',
    );
    final purchaseService = IapPurchaseService(
      store,
      IapTransactionApiService(client),
      (productId) async =>
          _packages.firstWhere((package) => package.productId == productId),
      () async {},
    );
    addTearDown(() async {
      await purchaseService.dispose();
      await store.close();
      client.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapCatalogProvider.overrideWith((ref) async => _catalog),
          remoteUserProfileProvider.overrideWith(
            (ref) async => UserProfile.fromJson(
              _profileJson(subscriptionProductId: _weeklyPackage.productId),
            ),
          ),
          iapPurchaseServiceProvider.overrideWithValue(purchaseService),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const UpdateSubscriptionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription-current')),
        matching: find.text('Weekly'),
      ),
      findsOneWidget,
    );

    final buyButton = find.byKey(const ValueKey('subscription-start'));
    await tester.ensureVisible(buyButton);
    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('subscription-current')),
        matching: find.text('Monthly'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('subscription-plan-${_monthlyPackage.productId}')),
      findsNothing,
    );
    expect(find.text('Nâng cấp lên gói năm'), findsWidgets);
  });
}

class _SuccessfulStoreGateway implements IapStoreGateway {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> buyNonConsumable(ProductDetails productDetails) async {
    scheduleMicrotask(() {
      final purchase = PurchaseDetails(
        purchaseID: '2000000123456789',
        productID: productDetails.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local-storekit-transaction',
          serverVerificationData: 'storekit-jws',
          source: 'app_store',
        ),
        transactionDate: '1786880400000',
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true;
      _controller.add([purchase]);
    });
    return true;
  }

  @override
  Future<bool> buyConsumable(ProductDetails productDetails) async => false;

  @override
  Future<List<PurchaseDetails>> unfinishedPurchases(String productId) async =>
      const [];

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases() async {}

  Future<void> close() => _controller.close();
}

Map<String, dynamic> _profileJson({required String subscriptionProductId}) => {
  'id': 1,
  'userCode': 'test',
  'email': 'test@example.com',
  'username': null,
  'avatar': '',
  'platform': 'IOS',
  'country': 'VN',
  'isPremium': true,
  'createdAt': '2026-08-21T09:30:21.914Z',
  'language': 'vi',
  'appVersion': '1.0.0',
  'databaseVersion': 1,
  'notificationEnabled': true,
  'subscription': {'productId': subscriptionProductId},
  'ownedProducts': [],
  'ownedProductIds': [],
};

final _weeklyPackage = _package('subscription.week', 'Weekly', 7, 1);
final _monthlyPackage = _package('subscription.month', 'Monthly', 30, 2);
final _yearlyPackage = _package('subscription.year', 'Yearly', 365, 3);
final _packages = [_weeklyPackage, _monthlyPackage, _yearlyPackage];

final _catalog = IapCatalog(
  apiResponse: IapPackagesResponse(
    success: true,
    message: 'Packages retrieved',
    packages: {'SUBSCRIPTION': _packages},
    total: _packages.length,
  ),
  storeProducts: {
    for (final package in _packages)
      package.productId: ProductDetails(
        id: package.productId,
        title: package.name,
        description: '',
        price: r'$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
        currencySymbol: r'$',
      ),
  },
);

IapPackage _package(
  String productId,
  String name,
  int duration,
  int sortOrder,
) => IapPackage(
  id: sortOrder,
  productId: productId,
  productType: 'SUBSCRIPTION',
  name: name,
  description: '',
  price: 4.99,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: duration,
  trialDays: 0,
  isEnabled: true,
  sortOrder: sortOrder,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'SUBSCRIPTION',
);
