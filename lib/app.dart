import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/services/app_usage_service.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/onboarding/assessment_level_screen.dart';
import 'presentation/screens/onboarding/level_assessment_intro_screen.dart';
import 'presentation/screens/onboarding/level_selection_screen.dart';
import 'presentation/screens/onboarding/language_onboarding_screen.dart';
import 'presentation/screens/onboarding/survey_carousel_screen.dart';
import 'presentation/screens/onboarding/survey_intro_screen.dart';
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
          path: 'survey',
          builder: (context, state) => const SurveyIntroScreen(),
          routes: [
            GoRoute(
              path: 'questions',
              builder: (context, state) => const SurveyCarouselScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
  ],
);

class LeximonApp extends ConsumerWidget {
  const LeximonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AppUsageLifecycle(
      child: MaterialApp.router(
        title: 'Leximon',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
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

  @override
  void initState() {
    super.initState();
    _appUsageService = ref.read(appUsageServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_appUsageService.resume());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_appUsageService.resume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
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
