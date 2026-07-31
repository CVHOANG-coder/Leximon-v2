import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/presentation/screens/onboarding/assessment_level_screen.dart';
import 'package:leximon/presentation/screens/onboarding/level_assessment_intro_screen.dart';
import 'package:leximon/presentation/screens/onboarding/level_selection_screen.dart';
import 'package:leximon/presentation/screens/onboarding/survey_carousel_screen.dart';
import 'package:leximon/presentation/screens/onboarding/survey_intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('known-level path saves the level and opens the survey', (
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
          routes: [
            GoRoute(
              path: 'level',
              builder: (context, state) => const LevelSelectionScreen(),
            ),
            GoRoute(
              path: 'assessment-level',
              builder: (context, state) => const AssessmentLevelScreen(),
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
        GoRoute(
          path: '/onboarding/language',
          builder: (context, state) =>
              const Scaffold(body: Text('Language onboarding')),
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

    expect(find.text('Hãy làm một khảo sát\nngắn nhé!'), findsOneWidget);
    expect(find.text('Tiếp'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppLanguageService.selectedLearningLevelKey),
      'Trung bình',
    );
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isNot(true),
    );

    await tester.tap(find.byKey(const ValueKey('survey-intro-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn bao nhiêu tuổi?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-age-1')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Tại sao bạn lại học tiếng Anh?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-goal-1')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn dùng tiếng Anh thường xuyên\nnhư thế nào?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-frequency-3')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã từng học tiếng Anh\nbao giờ chưa?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-learning-method-0')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần bao lâu\nđể có kết quả?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-result-timeline-1')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bạn sẵn sàng dành bao nhiêu\n'
        'thời gian mỗi ngày để\n'
        'học tiếng Anh?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-daily-study-time-3')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bạn đã sẵn sàng dành bao\n'
        'nhiêu thời gian mỗi ngày để\n'
        'học tiếng Anh?',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('survey-habit-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('survey-habit-back')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Bạn sẵn sàng dành bao nhiêu\n'
        'thời gian mỗi ngày để\n'
        'học tiếng Anh?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Với bạn, giờ nào là thuận tiện\nđể học tiếng Anh?'),
      findsOneWidget,
    );
    expect(find.text('19:50'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('survey-preferred-time-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('survey-preferred-time-back')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Leximon sẽ nhắc nhở bạn về các buổi học\n'
        'để bạn không bỏ lỡ ngày nào.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('4,6 lần!'), findsOneWidget);
    expect(find.text('Tuyệt vời!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Đối với bạn, khó khăn lớn nhất\ntrong tiếng Anh là gì?'),
      findsOneWidget,
    );
    expect(find.text('Học và ghi nhớ từ mới'), findsOneWidget);
    expect(find.text('Học và hiểu ngữ pháp'), findsOneWidget);
    expect(find.text('Nói bằng tiếng Anh'), findsOneWidget);
    expect(find.text('Nghe hiểu tiếng Anh'), findsOneWidget);
    expect(find.text('Hiểu và dịch các văn bản'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-challenge-1')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Điều gì khiến bạn không thể\n'
        'học tiếng Anh một cách\n'
        'nhanh chóng?',
      ),
      findsOneWidget,
    );
    expect(find.text('Thiếu thời gian'), findsOneWidget);
    expect(find.text('Thiếu học liệu tốt'), findsOneWidget);
    expect(
      find.text('Tôi không biết cách học\ntiếng Anh đúng đắn'),
      findsOneWidget,
    );
    expect(find.text('Học điều mới thật là khó'), findsOneWidget);
    expect(find.text('Thiếu thực hành và giao tiếp'), findsOneWidget);
    expect(find.text('Không có điều gì'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-barrier-0')));
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bright đã giúp 2.000.000 người dùng'),
      findsOneWidget,
    );
    expect(find.text('4.5'), findsOneWidget);
    expect(find.byKey(const ValueKey('survey-social-reviews')), findsOneWidget);
    expect(find.text('Bắt đầu học nào!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tiếng Anh là chìa khóa'), findsOneWidget);
    expect(find.text('Tiếp tục hành trình'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Anh giúp bạn tiến xa hơn'), findsOneWidget);
    expect(find.text('Tiếp tục cùng Leximon'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('App ready'), findsOneWidget);
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isTrue,
    );
  });

  testWidgets('test path opens the current-level assessment screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/onboarding/assessment-intro',
      routes: [
        GoRoute(
          path: '/onboarding/assessment-intro',
          builder: (context, state) => const LevelAssessmentIntroScreen(),
          routes: [
            GoRoute(
              path: 'assessment-level',
              builder: (context, state) => const AssessmentLevelScreen(),
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byKey(const ValueKey('assessment-start')));
    await tester.pumpAndSettle();

    expect(
      find.text('Đánh giá trình độ\ntiếng Anh hiện tại\ncủa bạn'),
      findsOneWidget,
    );
    expect(find.textContaining('Vừa mới bắt đầu học'), findsOneWidget);
    expect(find.textContaining('Tôi biết một chút ngữ pháp'), findsOneWidget);
    expect(find.textContaining('Tôi có thể trò chuyện'), findsOneWidget);
    expect(find.textContaining('Tôi nói trôi chảy'), findsOneWidget);
    expect(find.text('Bắt đầu bài kiểm tra'), findsOneWidget);

    await tester.tap(find.textContaining('Tôi biết một chút ngữ pháp'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('assessment-level-start')));
    await tester.pumpAndSettle();

    expect(find.text('Hãy làm một khảo sát\nngắn nhé!'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(
      find.text('Đánh giá trình độ\ntiếng Anh hiện tại\ncủa bạn'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Làm bài kiểm tra ngắn'), findsNWidgets(2));
  });
}
