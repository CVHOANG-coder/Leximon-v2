import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/data/models/user_profile_response.dart';
import 'package:leximon/data/services/reading_word_translation_service.dart';
import 'package:leximon/presentation/screens/onboarding/language_onboarding_screen.dart';
import 'package:leximon/presentation/screens/onboarding/language_package_loading_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  UserProfile profile({required int databaseVersion, bool isPremium = true}) =>
      UserProfile(
        id: 2,
        userCode: 'test-user',
        email: '',
        username: null,
        avatar: '',
        platform: 'ANDROID',
        country: 'VN',
        isPremium: isPremium,
        createdAt: null,
        language: 'vi',
        appVersion: '1.0.0',
        databaseVersion: databaseVersion,
        notificationEnabled: true,
        subscription: null,
        ownedProducts: const [],
        ownedProductIds: const [],
      );

  test('synchronizes content metadata before entering the app', () async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'de',
      AppLanguageService.onboardingCompletedKey: true,
    });
    var packageLoads = 0;
    final container = ProviderContainer(
      overrides: [
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7),
        ),
        authLoginInitializationProvider.overrideWith(
          (ref) => ref.watch(remoteUserProfileProvider.future).then((_) {}),
        ),
        languagePackageInitializationProvider.overrideWith((ref) async {
          packageLoads++;
        }),
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(applicationInitializationProvider.future),
      AppStartupDestination.home,
    );
    expect(packageLoads, 1);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(AppLanguageService.nativeLanguageKey), 'de');
    expect(preferences.getInt(AppLanguageService.databaseVersionKey), 7);
  });

  test('skips content synchronization for non-premium users', () async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'vi',
      AppLanguageService.nativeLanguageKey: 'vi',
      AppLanguageService.databaseVersionKey: 2,
      AppLanguageService.onboardingCompletedKey: true,
    });
    var packageLoads = 0;
    final container = ProviderContainer(
      overrides: [
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7, isPremium: false),
        ),
        authLoginInitializationProvider.overrideWith(
          (ref) => ref.watch(remoteUserProfileProvider.future).then((_) {}),
        ),
        languagePackageInitializationProvider.overrideWith((ref) async {
          packageLoads++;
        }),
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(applicationInitializationProvider.future),
      AppStartupDestination.subscriptionPlan,
    );
    expect(packageLoads, 0);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt(AppLanguageService.databaseVersionKey), 2);
  });

  test(
    'startup waits for authentication before choosing a destination',
    () async {
      SharedPreferences.setMockInitialValues({});
      final authentication = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          authLoginInitializationProvider.overrideWith(
            (ref) => authentication.future,
          ),
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      var startupCompleted = false;
      final startup = container.read(applicationInitializationProvider.future);
      unawaited(startup.then((_) => startupCompleted = true));
      await Future<void>.delayed(Duration.zero);

      expect(startupCompleted, isFalse);

      authentication.complete();
      expect(await startup, AppStartupDestination.languageOnboarding);
      expect(startupCompleted, isTrue);
    },
  );

  test('startup resumes onboarding from the correct checkpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final firstLaunchContainer = ProviderContainer(
      overrides: [
        authLoginInitializationProvider.overrideWith((ref) async {}),
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
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7),
        ),
        authLoginInitializationProvider.overrideWith((ref) async {}),
        languagePackageInitializationProvider.overrideWith((ref) async {}),
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
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7),
        ),
        authLoginInitializationProvider.overrideWith((ref) async {}),
        languagePackageInitializationProvider.overrideWith((ref) async {}),
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(freeTrialContainer.dispose);

    expect(
      await freeTrialContainer.read(applicationInitializationProvider.future),
      AppStartupDestination.home,
    );
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isTrue,
    );

    await preferences.setBool(AppLanguageService.onboardingCompletedKey, true);
    final returningUserContainer = ProviderContainer(
      overrides: [
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7),
        ),
        authLoginInitializationProvider.overrideWith((ref) async {}),
        languagePackageInitializationProvider.overrideWith((ref) async {}),
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

  test('keeps non-premium users on the post-carousel offer flow', () async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'vi',
      AppLanguageService.carouselCompletedKey: true,
    });
    final container = ProviderContainer(
      overrides: [
        remoteUserProfileProvider.overrideWith(
          (ref) async => profile(databaseVersion: 7, isPremium: false),
        ),
        authLoginInitializationProvider.overrideWith((ref) async {}),
        languagePackageInitializationProvider.overrideWith((ref) async {}),
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(applicationInitializationProvider.future),
      AppStartupDestination.freeTrialOffer,
    );
  });

  test(
    'returns a former customer to subscription plans when not premium',
    () async {
      SharedPreferences.setMockInitialValues({
        AppLanguageService.selectedLanguageKey: 'vi',
        AppLanguageService.onboardingCompletedKey: true,
      });
      final container = ProviderContainer(
        overrides: [
          remoteUserProfileProvider.overrideWith(
            (ref) async => profile(databaseVersion: 7, isPremium: false),
          ),
          authLoginInitializationProvider.overrideWith((ref) async {}),
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(applicationInitializationProvider.future),
        AppStartupDestination.subscriptionPlan,
      );
    },
  );

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

    final container = ProviderContainer(
      overrides: [
        languagePackageInitializationProvider.overrideWith((ref) async {}),
        languageModelDownloaderProvider.overrideWithValue(
          _ImmediateLanguageModelDownloader(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/onboarding/language',
      routes: [
        GoRoute(
          path: '/onboarding/language',
          builder: (context, state) => const LanguageOnboardingScreen(),
        ),
        GoRoute(
          path: '/onboarding/language-loading',
          builder: (context, state) => const LanguagePackageLoadingScreen(),
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
    expect(find.text('Español (España)'), findsOneWidget);
    expect(find.text('Español (Latinoamérica)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('language-locale-code-es-ES')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('language-locale-code-es-US')),
      findsOneWidget,
    );

    final languageList = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('app-language-zh-TW')),
      500,
      scrollable: languageList,
    );
    expect(
      find.byKey(const ValueKey('language-locale-code-zh')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('language-locale-code-zh-TW')),
      findsOneWidget,
    );

    final german = find.byKey(const ValueKey('app-language-de'));
    await tester.scrollUntilVisible(german, -500, scrollable: languageList);
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

  testWidgets('waits for language packages before continuing', (tester) async {
    final packageLoading = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        languagePackageInitializationProvider.overrideWith(
          (ref) => packageLoading.future,
        ),
        languageModelDownloaderProvider.overrideWithValue(
          _ImmediateLanguageModelDownloader(),
        ),
      ],
    );
    // Keep progress alive before mounting the loading screen. This reproduces
    // the real navigation case where a synchronous initState write used to
    // notify Riverpod while the widget tree was still building.
    final progressSubscription = container.listen(
      languagePackageLoadingProgressProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() {
      progressSubscription.close();
      container.dispose();
    });
    final router = GoRouter(
      initialLocation: '/onboarding/language-loading',
      routes: [
        GoRoute(
          path: '/onboarding/language-loading',
          builder: (context, state) => const LanguagePackageLoadingScreen(),
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

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('language-package-loading-progress')),
      findsOneWidget,
    );
    expect(find.text('Assessment intro'), findsNothing);

    await tester.pump(const Duration(seconds: 8));
    expect(find.text('8%'), findsOneWidget);
    expect(find.text('Assessment intro'), findsNothing);

    packageLoading.complete();
    await tester.pumpAndSettle();
    expect(find.text('Assessment intro'), findsOneWidget);
  });

  testWidgets('shows an error and retries failed language package loads', (
    tester,
  ) async {
    var attempts = 0;
    final router = GoRouter(
      initialLocation: '/onboarding/language-loading',
      routes: [
        GoRoute(
          path: '/onboarding/language-loading',
          builder: (context, state) => const LanguagePackageLoadingScreen(),
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
      ProviderScope(
        overrides: [
          languagePackageInitializationProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw StateError('network unavailable');
          }),
          languageModelDownloaderProvider.overrideWithValue(
            _ImmediateLanguageModelDownloader(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('language-package-loading-retry')),
      findsOneWidget,
    );
    expect(find.text('Assessment intro'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('language-package-loading-retry')),
    );
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Assessment intro'), findsOneWidget);
  });
}

class _ImmediateLanguageModelDownloader implements LanguageModelDownloader {
  @override
  Future<void> downloadRequiredModels({
    required String targetLanguageCode,
    LanguageModelProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const LanguageModelDownloadProgress(
        phase: LanguageModelDownloadPhase.complete,
        progress: 1,
        completedModels: 2,
        totalModels: 2,
      ),
    );
  }
}
