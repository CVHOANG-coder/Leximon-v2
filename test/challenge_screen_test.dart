import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/services/progress_dashboard_service.dart';
import 'package:leximon/data/services/challenge_dashboard_service.dart';
import 'package:leximon/presentation/screens/messages/messages_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('shows weekly goal and all five practice modes', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildChallengeScreen());
    await tester.pump();

    expect(find.text('Luyện nghe', findRichText: true), findsOneWidget);
    expect(find.text('Luyện nói', findRichText: true), findsOneWidget);
    expect(find.text('Ngữ pháp', findRichText: true), findsOneWidget);
    expect(find.text('IPA & phát âm', findRichText: true), findsOneWidget);
    expect(find.text('Luyện đọc', findRichText: true), findsOneWidget);
    expect(find.text('MỤC TIÊU TUẦN NÀY'), findsOneWidget);
    expect(
      find.text('Còn 20 phiên để hoàn thành mục tiêu tuần này'),
      findsOneWidget,
    );
    expect(find.text('MỤC TIÊU HÔM NAY'), findsNothing);
    expect(find.text('3 / 10 bài'), findsOneWidget);
    expect(find.text('Bài nghe phù hợp'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-owl')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('challenge-scroll')),
      const Offset(0, -800),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('weekly-activity-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-history')), findsOneWidget);
    expect(find.text('Bài nghe đã hoàn thành'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('challenge dashboard does not overflow on supported widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [430.0, 375.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(_buildChallengeScreen());
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('challenge-scroll')),
        const Offset(0, -500),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Challenge dashboard overflowed at ${width.toInt()}px',
      );
    }
  });

  testWidgets('speaking mode card opens the speaking catalog', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildChallengeScreen());
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('speaking-mode-card-action')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('speaking-mode-card-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('speaking-practice-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _buildChallengeScreen() {
  return ProviderScope(
    overrides: [
      topicsProvider.overrideWith((ref) async => []),
      progressDashboardProvider.overrideWith(
        (ref) async => ProgressDashboardSnapshot.empty(),
      ),
      challengeDashboardProvider.overrideWith(
        (ref) async => ChallengeDashboardSnapshot(
          modes: const [
            PracticeModeProgress(
              skill: PracticeSkill.listening,
              completed: 3,
              total: 10,
              weekSessions: 2,
            ),
            PracticeModeProgress(
              skill: PracticeSkill.grammar,
              completed: 2,
              total: 8,
              weekSessions: 1,
            ),
            PracticeModeProgress(
              skill: PracticeSkill.speaking,
              completed: 1,
              total: 10,
              weekSessions: 0,
            ),
            PracticeModeProgress(
              skill: PracticeSkill.pronunciation,
              completed: 4,
              total: 43,
              weekSessions: 1,
            ),
            PracticeModeProgress(
              skill: PracticeSkill.reading,
              completed: 1,
              total: 30,
              weekSessions: 0,
            ),
          ],
          recommendation: const PracticeRecommendation(
            skill: PracticeSkill.listening,
            title: 'Bài nghe phù hợp',
            contextLabel: 'Luyện nghe • Hội thoại',
            reason: 'Còn 4 phiên để cân bằng mục tiêu tuần',
            durationMinutes: 5,
          ),
          weekCompleted: 4,
          weekGoal: 24,
          knownWordCount: 120,
          levelLabel: 'A2',
          weeklyActivity: [
            for (var index = 0; index < 7; index++)
              WeeklyPracticeActivity(
                date: DateTime(2026, 8, 10 + index),
                sessions: const [0, 1, 0, 2, 1, 0, 0][index],
              ),
          ],
          recentHistory: [
            PracticeHistoryEntry(
              skill: PracticeSkill.listening,
              title: 'Bài nghe đã hoàn thành',
              contextLabel: 'Luyện nghe • Hội thoại',
              completedAt: DateTime(2026, 8, 13, 9, 30),
            ),
          ],
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(body: MessagesScreen()),
    ),
  );
}
