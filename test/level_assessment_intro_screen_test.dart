import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/data/models/onboarding_vocabulary_test.dart';
import 'package:leximon/data/services/onboarding_vocabulary_test_service.dart';
import 'package:leximon/data/models/user_profile_response.dart';
import 'package:leximon/presentation/screens/onboarding/assessment_level_screen.dart';
import 'package:leximon/presentation/screens/onboarding/free_trial_offer_screen.dart';
import 'package:leximon/presentation/screens/onboarding/level_assessment_intro_screen.dart';
import 'package:leximon/presentation/screens/onboarding/level_selection_screen.dart';
import 'package:leximon/presentation/screens/onboarding/survey_carousel_screen.dart';
import 'package:leximon/presentation/screens/onboarding/survey_intro_screen.dart';
import 'package:leximon/presentation/screens/onboarding/subscription_plan_screen.dart';
import 'package:leximon/presentation/screens/onboarding/trial_reminder_screen.dart';
import 'package:leximon/presentation/screens/onboarding/vocabulary_test_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('survey onboarding advances by horizontal swipe', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SurveyCarouselScreen()));
    await tester.pump();

    expect(find.text('Bạn bao nhiêu tuổi?'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('survey-age-1')));
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('survey-carousel')),
      const Offset(-300, 0),
      kind: PointerDeviceKind.touch,
    );
    await tester.pumpAndSettle();

    expect(find.text('Tại sao bạn lại học tiếng Anh?'), findsOneWidget);
  });

  testWidgets('learning history requires at least one selected method', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SurveyCarouselScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('survey-age-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-goal-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-frequency-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã từng học tiếng Anh\nbao giờ chưa?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNull,
    );
    expect(
      find.text('Bạn đã từng học tiếng Anh\nbao giờ chưa?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('survey-learning-method-0')));
    await tester.pump();
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('knowledge-journey-text')),
      findsOneWidget,
    );
  });

  testWidgets('preferred study time defaults to 19:30 and can continue', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SurveyCarouselScreen()));
    await tester.pump();

    Future<void> continueSurvey() async {
      await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('survey-age-0')));
    await tester.pump();
    await continueSurvey();
    await tester.tap(find.byKey(const ValueKey('survey-goal-0')));
    await tester.pump();
    await continueSurvey();
    await continueSurvey();
    await tester.tap(find.byKey(const ValueKey('survey-frequency-0')));
    await tester.pump();
    await continueSurvey();
    await tester.tap(find.byKey(const ValueKey('survey-learning-method-0')));
    await tester.pump();
    await continueSurvey();
    await continueSurvey();
    await tester.tap(find.byKey(const ValueKey('survey-result-timeline-0')));
    await tester.pump();
    await continueSurvey();
    await tester.tap(find.byKey(const ValueKey('survey-daily-study-time-0')));
    await tester.pump();
    await continueSurvey();
    await continueSurvey();

    expect(find.text('19:30'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNotNull,
    );
  });

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
              path: 'vocabulary-test',
              builder: (context, state) => VocabularyTestScreen(
                startingBand: VocabularyStartingBand.fromQuery(
                  state.uri.queryParameters['band'],
                ),
                service: _AssessmentFakeVocabularyTestService(),
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
                  builder: (context, state) => const SubscriptionPlanScreen(),
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
      ProviderScope(
        overrides: [
          remoteUserProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 1,
              userCode: 'test-user',
              email: 'test@example.com',
              username: 'Test User',
              avatar: '',
              platform: 'IOS',
              country: 'VN',
              isPremium: false,
              createdAt: null,
              language: 'vi',
              appVersion: '1.0.0',
              databaseVersion: 1,
              notificationEnabled: false,
              subscription: null,
              ownedProducts: [],
              ownedProductIds: [],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Tại sao bạn lại học tiếng Anh?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-goal-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tiếng Anh giúp bạn tiến'), findsOneWidget);
    expect(find.text('Tiếp tục cùng Leximon'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn dùng tiếng Anh thường xuyên như thế nào?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-frequency-3')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã từng học tiếng Anh\nbao giờ chưa?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('survey-learning-method-0')));
    await tester.pump();
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('knowledge-journey-text')),
      findsOneWidget,
    );
    expect(find.text('Tiếp tục hành trình'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần bao lâu\nđể có kết quả?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-result-timeline-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bạn sẵn sàng dành bao nhiêu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-daily-study-time-3')));
    await tester.pump();
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
    expect(find.textContaining('Bạn sẵn sàng dành bao nhiêu'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Với bạn, giờ nào là thuận tiện'),
      findsOneWidget,
    );
    expect(find.text('19:30'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('survey-preferred-time-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('survey-preferred-time-back')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('survey-carousel-continue')),
          )
          .onTap,
      isNotNull,
    );
    await tester.drag(
      find.byKey(const ValueKey('survey-preferred-time-slider')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();
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
      find.textContaining('Đối với bạn, khó khăn lớn nhất'),
      findsOneWidget,
    );
    expect(find.text('Học và ghi nhớ từ mới'), findsOneWidget);
    expect(find.text('Học và hiểu ngữ pháp'), findsOneWidget);
    expect(find.text('Nói bằng tiếng Anh'), findsOneWidget);
    expect(find.text('Nghe hiểu tiếng Anh'), findsOneWidget);
    expect(find.text('Hiểu và dịch các văn bản'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-challenge-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Điều gì khiến bạn không thể'), findsOneWidget);
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
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('survey-carousel-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Chọn các chủ đề\nmà bạn muốn học'), findsOneWidget);
    expect(find.text('Chọn tất cả'), findsOneWidget);
    expect(find.text('Du lịch'), findsOneWidget);
    expect(find.text('Mua sắm'), findsOneWidget);
    expect(find.text('Khi đi phỏng vấn xin việc'), findsOneWidget);
    expect(find.text('Kinh doanh và Tài chính'), findsOneWidget);
    expect(find.text('Gia đình và Bạn bè'), findsOneWidget);
    expect(find.text('Giao tiếp'), findsOneWidget);
    expect(find.text('Trường học và Đại học'), findsOneWidget);
    expect(find.text('Lao động và Việc làm'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('survey-topic-select-all')));
    await tester.pump();
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Đang phân tích câu trả\nlời của bạn'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('survey-analysis-lottie')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('survey-carousel-continue')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('7 ngày miễn phí'), findsOneWidget);
    expect(find.text('Dùng thử miễn phí'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('free-trial-illustration')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('survey-carousel')), findsNothing);
    expect(
      preferences.getBool(AppLanguageService.carouselCompletedKey),
      isTrue,
    );
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isNot(true),
    );

    await tester.tap(find.byKey(const ValueKey('free-trial-start')));
    await tester.pumpAndSettle();

    expect(find.text('2 ngày trước khi'), findsOneWidget);
    expect(find.text('kết thúc thời gian dùng thử'), findsOneWidget);
    expect(
      find.textContaining('Thông báo đẩy sẽ được gửi vào ngày'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trial-reminder-illustration')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('trial-reminder-back')), findsOneWidget);
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isNot(true),
    );

    await tester.tap(find.byKey(const ValueKey('trial-reminder-start')));
    await tester.pumpAndSettle();

    expect(find.text('Trong '), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('2 tháng'), findsOneWidget);
    expect(find.text('12 tháng'), findsOneWidget);
    expect(find.text('PHỔ BIẾN'), findsOneWidget);
    expect(find.text('2.099.000 đ'), findsOneWidget);
    expect(find.text('174.917 đ / thg'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('subscription-illustration')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('subscription-back')), findsOneWidget);
    expect(
      preferences.getBool(AppLanguageService.onboardingCompletedKey),
      isNot(true),
    );

    await tester.tap(find.byKey(const ValueKey('subscription-plan-2-month')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('subscription-start')),
    );
    await tester.tap(find.byKey(const ValueKey('subscription-start')));
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
              path: 'vocabulary-test',
              builder: (context, state) => VocabularyTestScreen(
                startingBand: VocabularyStartingBand.fromQuery(
                  state.uri.queryParameters['band'],
                ),
                service: _AssessmentFakeVocabularyTestService(),
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
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Từ này có nghĩa là gì?'), findsOneWidget);
    expect(find.text('love'), findsOneWidget);

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

class _AssessmentFakeVocabularyTestService
    extends OnboardingVocabularyTestService {
  @override
  Future<List<VocabularyTestQuestion>> loadQuestions(BrightLevel level) async {
    return List.generate(
      5,
      (index) => VocabularyTestQuestion(
        definition: VocabularyTestDefinition(
          id: index,
          task: index == 0 ? 'love' : 'word-$index',
          frequency: 100 - index,
          type: VocabularyTaskType.text,
          level: level,
        ),
        writing: index == 0 ? 'love' : 'word-$index',
        translation: index == 0 ? 'tình yêu' : 'nghĩa-$index',
        transcription: '',
        choices: const [
          VocabularyTestChoice(text: 'Đúng', isCorrect: true),
          VocabularyTestChoice(text: 'Sai 1', isCorrect: false),
          VocabularyTestChoice(text: 'Sai 2', isCorrect: false),
          VocabularyTestChoice(text: 'Sai 3', isCorrect: false),
        ],
      ),
    );
  }
}
