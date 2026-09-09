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
        overrides: [
          iapCatalogProvider.overrideWith((ref) async => _catalog),
          reviewModeProvider.overrideWith((ref) async => false),
          subscriptionTrialEligibilityProvider.overrideWith(
            (ref) async => true,
          ),
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
    expect(
      find.byKey(const ValueKey('subscription-weekly-price')),
      findsNothing,
    );
    _expectFunctionalLegalLinks(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the legal footer on the onboarding subscription screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapCatalogProvider.overrideWith((ref) async => _catalog),
          reviewModeProvider.overrideWith((ref) async => false),
          subscriptionTrialEligibilityProvider.overrideWith(
            (ref) async => true,
          ),
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
    _expectFunctionalLegalLinks(tester);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Chính sách về Quyền riêng tư'), findsOneWidget);
    expect(find.text('PHỔ BIẾN'), findsOneWidget);
    expect(find.text('129.000 ₫'), findsOneWidget);
    expect(find.textContaining('₫'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('subscription-weekly-price')),
      findsNothing,
    );
    expect(find.textContaining(r'$'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides trial messaging for a previous subscriber', (
    tester,
  ) async {
    Widget app(Widget home) => ProviderScope(
      overrides: [
        iapCatalogProvider.overrideWith((ref) async => _catalog),
        reviewModeProvider.overrideWith((ref) async => false),
        subscriptionTrialEligibilityProvider.overrideWith((ref) async => false),
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
        home: home,
      ),
    );

    await tester.pumpWidget(app(const SubscriptionPlanScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký ngay'), findsOneWidget);
    expect(find.text('Dùng thử miễn phí và đăng ký'), findsNothing);
    expect(
      find.text('Chọn gói đăng ký sau 7 ngày dùng thử miễn phí'),
      findsNothing,
    );

    await tester.pumpWidget(
      app(const onboarding_subscription.SubscriptionPlanScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký ngay'), findsOneWidget);
    expect(find.text('Dùng thử 7 ngày miễn phí'), findsNothing);
    expect(find.text('Dùng thử miễn phí và đăng ký'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the singular week label for normalized prices', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapCatalogProvider.overrideWith((ref) async => _catalog),
          reviewModeProvider.overrideWith((ref) async => true),
          subscriptionTrialEligibilityProvider.overrideWith(
            (ref) async => true,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
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

    expect(find.textContaining('/ week'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('subscription-weekly-price')),
      findsOneWidget,
    );
    expect(find.textContaining('weeks'), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iapCatalogProvider.overrideWith((ref) async => _catalog),
          reviewModeProvider.overrideWith((ref) async => true),
          subscriptionTrialEligibilityProvider.overrideWith(
            (ref) async => true,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
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

    expect(find.textContaining('/ week'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('subscription-weekly-price')),
      findsOneWidget,
    );
    expect(find.textContaining('weeks'), findsNothing);
  });
}

void _expectFunctionalLegalLinks(WidgetTester tester) {
  final terms = find.byKey(const ValueKey('subscription-terms'));
  final privacy = find.byKey(const ValueKey('subscription-privacy'));
  expect(terms, findsOneWidget);
  expect(privacy, findsOneWidget);
  expect(
    tester
        .widget<TextButton>(
          find.descendant(of: terms, matching: find.byType(TextButton)),
        )
        .onPressed,
    isNotNull,
  );
  expect(
    tester
        .widget<TextButton>(
          find.descendant(of: privacy, matching: find.byType(TextButton)),
        )
        .onPressed,
    isNotNull,
  );
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
