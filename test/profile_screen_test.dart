import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/services/progress_dashboard_service.dart';
import 'package:leximon/data/services/profile_statistics_service.dart';
import 'package:leximon/presentation/screens/profile/profile_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows database-backed hero and calculated profile statistics', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    const topic = Topic(
      id: 10,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: [{}, {}, {}, {}, {}],
    );
    const statistics = ProfileStatisticsSnapshot(
      trackedTopicCount: 1,
      weekCorrectAnswerCount: 3,
      weekAnswerCount: 4,
      averageDailyUsage: Duration(minutes: 75),
      usageDayCount: 7,
    );
    const dashboard = ProgressDashboardSnapshot(
      totalWords: 120,
      progressedWords: 18,
      masteredWords: 12,
      currentStreak: 6,
      weekActivity: [1, 2, 3, 2, 1, 0, 0],
      weekSessionCount: 4,
      activeDaysThisMonth: 5,
      elapsedDaysThisMonth: 10,
      monthActivityLevels: [1, 2, 3],
      monthLabel: 'Tháng này',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => [topic]),
          selectedTopicOrdersProvider.overrideWith((ref) => {1}),
          topicProgressProvider.overrideWith((ref) async => {10: .4}),
          profileStatisticsProvider.overrideWith((ref) async => statistics),
          progressDashboardProvider.overrideWith((ref) async => dashboard),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfileRow(
              id: 1,
              name: 'Nguyễn An',
              email: 'an@example.com',
              avatarPath: null,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 chủ đề'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1 giờ 15 phút / ngày'), findsOneWidget);
    expect(find.text('Trung bình trong 7 ngày gần nhất'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
  });

  testWidgets('quick setting toggle rebuilds inside a visible Material', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'profile.pronunciation_enabled': false,
      'profile.listening_enabled': true,
      'profile.daily_reminder_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => const <Topic>[]),
          selectedTopicOrdersProvider.overrideWith((ref) => <int>{}),
          topicProgressProvider.overrideWith((ref) async => const {}),
          profileStatisticsProvider.overrideWith(
            (ref) async => const ProfileStatisticsSnapshot(
              trackedTopicCount: 0,
              weekCorrectAnswerCount: 0,
              weekAnswerCount: 0,
              averageDailyUsage: Duration.zero,
              usageDayCount: 0,
            ),
          ),
          progressDashboardProvider.overrideWith(
            (ref) async => const ProgressDashboardSnapshot(
              totalWords: 0,
              progressedWords: 0,
              masteredWords: 0,
              currentStreak: 0,
              weekActivity: [0, 0, 0, 0, 0, 0, 0],
              weekSessionCount: 0,
              activeDaysThisMonth: 0,
              elapsedDaysThisMonth: 1,
              monthActivityLevels: [],
              monthLabel: 'Tháng này',
            ),
          ),
          userProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-setting-toggle-Luyện nghe')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final listeningToggle = tester.widget<Switch>(
      find.byKey(const ValueKey('profile-setting-toggle-Luyện nghe')),
    );
    expect(listeningToggle.value, isTrue);
    listeningToggle.onChanged!(false);
    await tester.pumpAndSettle();

    expect(find.text('Loa đang tắt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
