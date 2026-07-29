import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/services/profile_statistics_service.dart';
import 'package:leximon/presentation/screens/profile/profile_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('shows calculated profile statistics and tracked topics', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => [topic]),
          selectedTopicOrdersProvider.overrideWith((ref) => {1}),
          topicProgressProvider.overrideWith((ref) async => {10: .4}),
          profileStatisticsProvider.overrideWith((ref) async => statistics),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 chủ đề'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1 giờ 15 phút / ngày'), findsOneWidget);
    expect(find.text('Trung bình trong 7 ngày gần nhất'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Chủ đề đang theo dõi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Du lịch'), findsOneWidget);
    expect(find.text('2 / 5 từ • 40%'), findsOneWidget);
  });
}
