import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/presentation/screens/home/home_screen.dart';
import 'package:leximon/presentation/screens/sale_package/sale_package_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('renders the SALE package returned by the IAP catalog', (
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
          home: const SalePackageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sale-package-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-package-hero')), findsOneWidget);
    expect(find.text('Gói Pro năm'), findsOneWidget);
    expect(find.text(r'$29.99'), findsOneWidget);
    expect(find.text(r'$49.99'), findsOneWidget);
    expect(find.text('7 ngày dùng thử miễn phí'), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-package-back')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not open subscription from the Home notification button', (
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
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    final notificationButton = tester.widget<InkWell>(
      find.byKey(const ValueKey('home-notification-button')),
    );
    expect(notificationButton.onTap, isNull);
    final vipButton = tester.widget<InkWell>(
      find.byKey(const ValueKey('home-vip-button')),
    );
    expect(vipButton.onTap, isNotNull);
    expect(find.byKey(const ValueKey('home-vip-icon')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-vip-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('update-subscription-screen')),
      findsOneWidget,
    );
  });
}

final _salePackage = _package(
  id: 2,
  productId: 'com.wordisland.learnenglish.premium.annuallysale',
  price: 29.99,
  group: 'SALE',
  sortOrder: 2,
  trialDays: 7,
);

final _regularPackage = _package(
  id: 3,
  productId: 'com.wordisland.learnenglish.premium.annually',
  price: 49.99,
  group: 'SUBSCRIPTION',
  sortOrder: 3,
  trialDays: 7,
);

final _catalog = IapCatalog(
  apiResponse: IapPackagesResponse(
    success: true,
    message: 'Packages retrieved',
    packages: {
      'SALE': [_salePackage],
      'SUBSCRIPTION': [_regularPackage],
    },
    total: 2,
  ),
  storeProducts: {
    _salePackage.productId: ProductDetails(
      id: _salePackage.productId,
      title: 'Annual sale',
      description: '',
      price: r'$29.99',
      rawPrice: 29.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    ),
    _regularPackage.productId: ProductDetails(
      id: _regularPackage.productId,
      title: 'Annual',
      description: '',
      price: r'$49.99',
      rawPrice: 49.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    ),
  },
);

IapPackage _package({
  required int id,
  required String productId,
  required double price,
  required String group,
  required int sortOrder,
  required int trialDays,
}) => IapPackage(
  id: id,
  productId: productId,
  productType: 'SUBSCRIPTION',
  name: 'Premium - 1 năm',
  description: 'Mở khoá toàn bộ bài học, không quảng cáo',
  price: price,
  currency: 'USD',
  platform: 'IOS',
  packDurationDay: 365,
  trialDays: trialDays,
  isEnabled: true,
  sortOrder: sortOrder,
  adjustEventToken: '',
  createdAt: null,
  updatedAt: null,
  group: group,
);
