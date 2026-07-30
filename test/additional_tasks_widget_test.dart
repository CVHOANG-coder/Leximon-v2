import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/home/home_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('shows and opens additional tasks after main tasks are done', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await database
        .into(database.visitModels)
        .insert(
          VisitModelsCompanion.insert(
            date: today,
            atLeastOneTaskFinished: const Value(true),
            areDailyTasksFinished: const Value(true),
            learnWordsGoal: const Value(8),
            learnedWordsCount: const Value(8),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          localDataInitializationProvider.overrideWith((ref) async {}),
          selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
          topicsProvider.overrideWith((ref) async => const <Topic>[]),
          topicProgressProvider.overrideWith(
            (ref) async => const <int, double>{},
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tất cả các nhiệm vụ đã hoàn thành'), findsOneWidget);
    expect(find.text('8 từ đã học'), findsOneWidget);
    expect(
      find.text('Những nhiệm vụ mới đang chờ bạn vào ngày mai.'),
      findsOneWidget,
    );
    expect(find.text('Muốn thực hành nhiều hơn?'), findsOneWidget);
    expect(find.text('Chúng tôi có một vài nhiệm vụ bổ sung.'), findsOneWidget);
    expect(find.text('Tôi muốn thực hành nhiều hơn'), findsOneWidget);
    final button = find.text('Tôi muốn thực hành nhiều hơn');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Chọn một cách để tiếp tục luyện tập.'), findsOneWidget);
    expect(find.text('Học từ mới'), findsWidgets);
  });
}
