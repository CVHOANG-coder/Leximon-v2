import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/daily_notification_service.dart';
import 'data/services/app_usage_service.dart';
import 'data/models/onboarding_vocabulary_test.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/onboarding/assessment_level_screen.dart';
import 'presentation/screens/onboarding/free_trial_offer_screen.dart';
import 'presentation/screens/onboarding/level_assessment_intro_screen.dart';
import 'presentation/screens/onboarding/level_selection_screen.dart';
import 'presentation/screens/onboarding/language_onboarding_screen.dart';
import 'presentation/screens/onboarding/language_package_loading_screen.dart';
import 'presentation/screens/onboarding/survey_carousel_screen.dart';
import 'presentation/screens/onboarding/survey_intro_screen.dart';
import 'presentation/screens/onboarding/subscription_plan_screen.dart'
    as onboarding_subscription;
import 'presentation/screens/subscription_plan/subscription_plan_screen.dart'
    as subscription_plan;
import 'presentation/screens/onboarding/trial_reminder_screen.dart';
import 'presentation/screens/onboarding/vocabulary_test_screen.dart';
import 'presentation/screens/profile/language_selection_screen.dart';
import 'presentation/screens/sale_package/sale_package_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'shared/providers/app_providers.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
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
      builder: (context, state) => const LevelAssessmentIntroScreen(),
      routes: [
        GoRoute(
          path: 'assessment-level',
          builder: (context, state) => const AssessmentLevelScreen(),
        ),
        GoRoute(
          path: 'level',
          builder: (context, state) => const LevelSelectionScreen(),
        ),
        GoRoute(
          path: 'vocabulary-test',
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => VocabularyTestScreen(
              database: ref.watch(appDatabaseProvider),
              languageCode: ref.watch(selectedAppLanguageProvider),
              startingBand: VocabularyStartingBand.fromQuery(
                state.uri.queryParameters['band'],
              ),
            ),
          ),
        ),
        GoRoute(
          path: 'survey',
          builder: (context, state) => const SurveyIntroScreen(),
          routes: [
            GoRoute(
              path: 'questions',
              builder: (context, state) => const SurveyCarouselScreen(),
            ),
            GoRoute(
              path: 'free-trial',
              builder: (context, state) => const FreeTrialOfferScreen(),
            ),
            GoRoute(
              path: 'trial-reminder',
              builder: (context, state) => const TrialReminderScreen(),
            ),
            GoRoute(
              path: 'subscription',
              builder: (context, state) =>
                  const onboarding_subscription.SubscriptionPlanScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/subscription_plan',
      builder: (context, state) =>
          const subscription_plan.SubscriptionPlanScreen(),
    ),
    GoRoute(
      path: '/sale_package',
      builder: (context, state) => const SalePackageScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
  ],
);

class LeximonApp extends ConsumerWidget {
  const LeximonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe before feature screens open so unfinished StoreKit/Play
    // transactions from an earlier session are never missed.
    ref.watch(iapPurchaseServiceProvider);
    return _AppUsageLifecycle(
      child: MaterialApp.router(
        title: 'Leximon',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
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
        routerConfig: _router,
      ),
    );
  }
}

class _AppUsageLifecycle extends ConsumerStatefulWidget {
  const _AppUsageLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppUsageLifecycle> createState() => _AppUsageLifecycleState();
}

class _AppUsageLifecycleState extends ConsumerState<_AppUsageLifecycle>
    with WidgetsBindingObserver {
  late final AppUsageService _appUsageService;
  bool _saleNavigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _appUsageService = ref.read(appUsageServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_appUsageService.resume());
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await DailyNotificationService.instance.initialize(
        onSaleNotificationTap: _openSalePackage,
      );
    } on Object {
      // Notification support is optional and must not block app startup.
    }
  }

  void _openSalePackage() {
    if (!mounted) return;
    final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/splash') {
      // SplashScreen will consume the pending notification tap and choose the
      // sale route after startup finishes.
      return;
    }
    if (_saleNavigationScheduled || currentPath == '/sale_package') return;
    _saleNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saleNavigationScheduled = false;
      if (!mounted) return;
      DailyNotificationService.instance.takePendingSaleNotificationTap();
      _router.go('/sale_package');
    });
  }

  void _notifyAnnualSaleIfNeeded() {
    DailyNotificationService.instance.notifyAnnualSaleIfNeeded();
  }

  Future<void> _handleAppResumed() async {
    try {
      await DailyNotificationService.instance.initialize(
        onSaleNotificationTap: _openSalePackage,
      );
    } on Object {
      return;
    }
    if (!mounted) return;
    final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/splash') return;
    if (DailyNotificationService.instance.takePendingSaleNotificationTap()) {
      _openSalePackage();
      return;
    }
    final localizations = AppLocalizations(
      AppLocalizations.localeForCode(ref.read(selectedAppLanguageProvider)),
    );
    try {
      await DailyNotificationService.instance.resumeAnnualSaleNotification(
        localizations: localizations,
      );
    } on Object {
      // Notification support is optional and must not block app resume.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_appUsageService.resume());
        unawaited(_handleAppResumed());
      case AppLifecycleState.inactive:
        unawaited(_appUsageService.pause());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _notifyAnnualSaleIfNeeded();
        unawaited(_appUsageService.pause());
      case AppLifecycleState.detached:
        _notifyAnnualSaleIfNeeded();
        unawaited(_appUsageService.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_appUsageService.pause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
