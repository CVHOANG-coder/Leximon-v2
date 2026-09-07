import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/data/models/iap_packages_response.dart';
import 'package:leximon/data/services/iap_catalog_service.dart';
import 'package:leximon/presentation/screens/listening_practice/skill_pack_purchase_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('shows functional legal links for every skill pack', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final skill in SkillPackType.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            iapCatalogProvider.overrideWith((ref) async => _catalogFor(skill)),
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
            home: SkillPackPurchaseScreen(skill: skill),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final legalLinks = find.byKey(const ValueKey('purchase-legal-links'));
      final terms = find.byKey(const ValueKey('subscription-terms'));
      final privacy = find.byKey(const ValueKey('subscription-privacy'));
      expect(
        legalLinks,
        findsOneWidget,
        reason: '$skill must show legal links',
      );
      expect(terms, findsOneWidget);
      expect(privacy, findsOneWidget);
      expect(tester.getRect(legalLinks).bottom, lessThanOrEqualTo(932));
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
      expect(tester.takeException(), isNull);
    }
  });
}

IapCatalog _catalogFor(SkillPackType skill) {
  final package = IapPackage(
    id: skill.index + 1,
    productId: skill.productId,
    productType: 'NON_CONSUMABLE',
    name: '${skill.name} package',
    description: 'Buy once, use forever',
    price: 99000,
    currency: 'VND',
    platform: 'IOS',
    packDurationDay: 0,
    trialDays: 0,
    isEnabled: true,
    sortOrder: skill.index,
    adjustEventToken: '',
    createdAt: null,
    updatedAt: null,
    group: 'SKILL_PACK',
  );

  return IapCatalog(
    apiResponse: IapPackagesResponse(
      success: true,
      message: 'Packages retrieved',
      packages: {
        'SKILL_PACK': [package],
      },
      total: 1,
    ),
    storeProducts: {
      package.productId: ProductDetails(
        id: package.productId,
        title: package.name,
        description: package.description,
        price: '99.000₫',
        rawPrice: 99000,
        currencyCode: 'VND',
        currencySymbol: '₫',
      ),
    },
  );
}
