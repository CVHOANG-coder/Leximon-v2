import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('switches the app locale without restarting', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedAppLanguageProvider.notifier).state = 'en';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp(
              locale: AppLocalizations.localeForCode(
                ref.watch(selectedAppLanguageProvider),
              ),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) =>
                    Scaffold(body: Text(context.l10n.navStudy)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsOneWidget);

    container.read(selectedAppLanguageProvider.notifier).state = 'de';
    await tester.pumpAndSettle();

    expect(find.text('Lernen'), findsOneWidget);
  });
}
