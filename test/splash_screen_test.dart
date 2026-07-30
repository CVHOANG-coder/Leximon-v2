import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/presentation/screens/splash/splash_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('waits on the splash image until app initialization completes', (
    tester,
  ) async {
    final initialization = Completer<void>();
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('App ready')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationInitializationProvider.overrideWith((ref) async {
            await initialization.future;
            return AppStartupDestination.home;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    final splashImage = tester.widget<Image>(find.byType(Image));
    expect(
      (splashImage.image as AssetImage).assetName,
      'assets/images/splash.png',
    );
    expect(splashImage.fit, BoxFit.cover);
    expect(find.text('App ready'), findsNothing);

    initialization.complete();
    await tester.pump(const Duration(milliseconds: 799));
    expect(find.text('App ready'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('App ready'), findsOneWidget);
  });
}
