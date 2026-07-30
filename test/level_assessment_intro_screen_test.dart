import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/presentation/screens/onboarding/level_assessment_intro_screen.dart';
import 'package:leximon/presentation/screens/onboarding/level_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('known-level path selects a level and finishes onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'vi',
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/onboarding/assessment-intro',
      routes: [
        GoRoute(
          path: '/onboarding/assessment-intro',
          builder: (context, state) => const LevelAssessmentIntroScreen(),
        ),
        GoRoute(
          path: '/onboarding/language',
          builder: (context, state) =>
              const Scaffold(body: Text('Language onboarding')),
        ),
        GoRoute(
          path: '/onboarding/level',
          builder: (context, state) => const LevelSelectionScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('App ready')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    expect(find.text('Làm bài kiểm tra ngắn'), findsNWidgets(2));
    expect(find.text('Bạn sẽ biết được trình độ của mình'), findsOneWidget);
    expect(find.text('Kiểm tra vốn từ vựng của bạn'), findsOneWidget);
    expect(
      find.text('Ứng dụng sẽ phù hợp với trình độ của bạn'),
      findsOneWidget,
    );
    expect(find.text('Tôi biết trình độ của mình'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assessment-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Chọn trình độ\nAnh ngữ của bạn'), findsOneWidget);
    expect(find.text('Sơ cấp'), findsOneWidget);
    expect(find.text('Trung bình'), findsOneWidget);
    expect(find.text('Nâng cao'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('level-option-intermediate')));
    await tester.tap(find.byKey(const ValueKey('level-selection-continue')));
    await tester.pumpAndSettle();

    expect(find.text('App ready'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppLanguageService.selectedLearningLevelKey),
      'Trung bình',
    );
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isTrue,
    );
  });
}
