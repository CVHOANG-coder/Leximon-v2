import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/daily_card_service.dart';

void main() {
  late AppDatabase database;
  late DailyCardService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = DailyCardService(database);
  });

  tearDown(() => database.close());

  test('creates the current-day visit with Learn as the only task', () async {
    final card = await service.load();

    expect(card.tasks, hasLength(1));
    expect(card.tasks.single.type, DailyTaskType.learn);
    expect(card.tasks.single.completed, 0);
    expect(card.tasks.single.count, DailyCardService.defaultLearnWordsGoal);
    expect(card.isComplete, isFalse);

    final visit = await database.select(database.visitModels).getSingle();
    expect(visit.learnWordsGoal, DailyCardService.defaultLearnWordsGoal);
    expect(visit.repeatWordsGoal, 0);
  });

  test(
    'keeps completed tasks disabled when the counter exceeds the goal',
    () async {
      final today = DateTime.now();
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).millisecondsSinceEpoch;
      await database
          .into(database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: date,
              atLeastOneTaskFinished: const Value(true),
              areDailyTasksFinished: const Value(true),
              learnWordsGoal: const Value(8),
              learnedWordsCount: const Value(9),
            ),
          );

      final card = await service.load();

      expect(card.isComplete, isTrue);
      expect(card.tasks.single.isDone, isTrue);
      expect(card.additionalTasks, contains(DailyTaskType.learn));
    },
  );
}
