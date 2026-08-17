import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/presentation/screens/onboarding/language_onboarding_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('startup resumes onboarding from the correct checkpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final firstLaunchContainer = ProviderContainer(
      overrides: [
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(firstLaunchContainer.dispose);

    expect(
      await firstLaunchContainer.read(applicationInitializationProvider.future),
      AppStartupDestination.languageOnboarding,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppLanguageService.selectedLanguageKey, 'vi');
    final incompleteOnboardingContainer = ProviderContainer(
      overrides: [
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(incompleteOnboardingContainer.dispose);

    expect(
      await incompleteOnboardingContainer.read(
        applicationInitializationProvider.future,
      ),
      AppStartupDestination.languageOnboarding,
    );

    await preferences.setBool(AppLanguageService.carouselCompletedKey, true);
    final freeTrialContainer = ProviderContainer(
      overrides: [
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(freeTrialContainer.dispose);

    expect(
      await freeTrialContainer.read(applicationInitializationProvider.future),
      AppStartupDestination.freeTrialOffer,
    );

    await preferences.setBool(AppLanguageService.onboardingCompletedKey, true);
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
  });

  test('carousel checkpoint can be completed and reset', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppLanguageService();

    expect(await service.isCarouselCompleted(), isFalse);
    await service.completeCarousel();
    expect(await service.isCarouselCompleted(), isTrue);
    await service.resetCarousel();
    expect(await service.isCarouselCompleted(), isFalse);
  });

  testWidgets('selects and persists the app language before continuing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.carouselCompletedKey: true,
    });
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
    expect(
      preferences.getBool(AppLanguageService.carouselCompletedKey),
      isFalse,
    );
    expect(container.read(selectedAppLanguageProvider), 'de');

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Tiếp'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
