import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/presentation/screens/onboarding/subscription_plan_screen.dart'
    as onboarding_subscription;
import 'package:leximon/presentation/screens/subscription_plan/subscription_plan_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('renders the subscription offer with the StoreKit price', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [iapCatalogProvider.overrideWith((ref) async => _catalog)],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const SubscriptionPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('subscription-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('subscription-hero')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('subscription-plan-com.example.subscription.annual'),
      ),
      findsOneWidget,
    );
    expect(find.text('129.000 ₫'), findsOneWidget);
    expect(find.text('Gói Pro năm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the legal footer on the onboarding subscription screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [iapCatalogProvider.overrideWith((ref) async => _catalog)],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const onboarding_subscription.SubscriptionPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('subscription-legal-footer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('subscription-restore')), findsOneWidget);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Chính sách về Quyền riêng tư'), findsOneWidget);
    expect(find.text('PHỔ BIẾN'), findsOneWidget);
    expect(find.text('129.000 ₫'), findsOneWidget);
    expect(find.textContaining('₫'), findsNWidgets(3));
    expect(find.textContaining(r'$'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _package = IapPackage(
  id: 10,
  productId: 'com.example.subscription.annual',
  productType: 'SUBSCRIPTION',
  name: 'Gói Pro năm',
  description: 'Mở khoá toàn bộ bài học, không quảng cáo',
  price: 129000,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 365,
  trialDays: 7,
  isEnabled: true,
  sortOrder: 1,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: 'SUBSCRIPTION',
);

final _catalog = IapCatalog(
  apiResponse: IapPackagesResponse(
    success: true,
    message: 'Packages retrieved',
    packages: {
      'SUBSCRIPTION': [_package],
    },
    total: 1,
  ),
  storeProducts: {
    _package.productId: ProductDetails(
      id: _package.productId,
      title: 'Annual subscription',
      description: '',
      price: '129.000 ₫',
      rawPrice: 129000,
      currencyCode: 'VND',
      currencySymbol: '₫',
    ),
  },
);
