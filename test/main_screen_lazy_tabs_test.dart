import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/localization/app_localizations.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/presentation/screens/discover/discover_screen.dart';
import 'package:leximon/presentation/screens/home/home_screen.dart';
import 'package:leximon/presentation/screens/main/main_screen.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/presentation/screens/profile/profile_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('only builds the selected main tab on first entry', (
    tester,
  ) async {
    final pendingDailyCard = Completer<DailyCardSnapshot>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => []),
          topicProgressProvider.overrideWith((ref) async => {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
          dailyCardProvider.overrideWith((ref) => pendingDailyCard.future),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: MainScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(DiscoverScreen, skipOffstage: false), findsNothing);
    expect(find.byType(MessagesScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
  });
}
