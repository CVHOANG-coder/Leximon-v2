import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/models/vocabulary_collection.dart';
import 'package:leximon/data/services/progress_dashboard_service.dart';
import 'package:leximon/presentation/screens/discover/discover_screen.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('keeps the vocabulary progress ring circular on narrow screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final ringSize = tester.getSize(
      find.byKey(const Key('vocabulary-progress-ring')),
    );

    expect(ringSize.width, lessThan(150));
    expect(ringSize.width, greaterThan(0));
    expect(ringSize.height, closeTo(ringSize.width, .001));
  });

  testWidgets('uses bundled assets for vocabulary tracking stats', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('assets/svgs/streak.svg')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('assets/svgs/book.svg')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assets/svgs/thunder.svg')),
      findsOneWidget,
    );
    expect(find.text('🔥'), findsNothing);
    expect(find.text('📘'), findsNothing);
    expect(find.text('⚡'), findsNothing);
  });

  testWidgets('shows vocabulary progress with two decimal places', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('50.00%'), findsOneWidget);
    expect(
      find.byKey(const Key('vocabulary-progress-percentage')),
      findsOneWidget,
    );
  });

  testWidgets('opens word study from the vocabulary library entry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-vocabulary-library')));
    await tester.pumpAndSettle();

    expect(find.byType(WordStudyScreen), findsOneWidget);
  });
}

Widget _testApp() {
  const dashboard = ProgressDashboardSnapshot(
    totalWords: 32,
    progressedWords: 16,
    masteredWords: 8,
    currentStreak: 3,
    weekActivity: [1, 2, 3, 2, 1, 0, 0],
    weekSessionCount: 4,
    activeDaysThisMonth: 5,
    elapsedDaysThisMonth: 10,
    monthActivityLevels: [1, 2, 3],
    monthLabel: 'Tháng này',
  );
  const topic = Topic(
    id: 1,
    order: 1,
    original: 'Basics',
    translated: 'Cơ bản',
    words: [],
  );

  return ProviderScope(
    overrides: [
      topicsProvider.overrideWith((ref) async => [topic]),
      topicProgressProvider.overrideWith((ref) async => const <int, double>{}),
      progressDashboardProvider.overrideWith((ref) async => dashboard),
      vocabularyCollectionProvider.overrideWith(
        (ref) async =>
            const VocabularyCollectionSnapshot(entries: [], totalWordCount: 0),
      ),
    ],
    child: const MaterialApp(home: DiscoverScreen()),
  );
}
