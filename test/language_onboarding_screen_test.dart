import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/presentation/screens/onboarding/language_onboarding_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'startup requires language onboarding only when no language is saved',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstLaunchContainer = ProviderContainer(
        overrides: [
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(firstLaunchContainer.dispose);

      expect(
        await firstLaunchContainer.read(
          applicationInitializationProvider.future,
        ),
        AppStartupDestination.languageOnboarding,
      );

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(AppLanguageService.selectedLanguageKey, 'vi');
      final assessmentContainer = ProviderContainer(
        overrides: [
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(assessmentContainer.dispose);

      expect(
        await assessmentContainer.read(
          applicationInitializationProvider.future,
        ),
        AppStartupDestination.assessmentIntro,
      );

      await preferences.setBool(
        AppLanguageService.onboardingCompletedKey,
        true,
      );
      final returningUserContainer = ProviderContainer(
        overrides: [
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(returningUserContainer.dispose);

      expect(
        await returningUserContainer.read(
          applicationInitializationProvider.future,
        ),
        AppStartupDestination.home,
      );
      expect(returningUserContainer.read(selectedAppLanguageProvider), 'vi');
    },
  );

  testWidgets('selects and persists the app language before continuing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/onboarding/language',
      routes: [
        GoRoute(
          path: '/onboarding/language',
          builder: (context, state) => const LanguageOnboardingScreen(),
        ),
        GoRoute(
          path: '/onboarding/assessment-intro',
          builder: (context, state) =>
              const Scaffold(body: Text('Assessment intro')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('Chọn ngôn ngữ\nmẹ đẻ của bạn'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Tiếp'), findsOneWidget);

    final german = find.byKey(const ValueKey('app-language-de'));
    await tester.ensureVisible(german);
    await tester.tap(german);
    await tester.tap(
      find.byKey(const ValueKey('language-onboarding-continue')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assessment intro'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppLanguageService.selectedLanguageKey), 'de');
    expect(container.read(selectedAppLanguageProvider), 'de');
  });
}
