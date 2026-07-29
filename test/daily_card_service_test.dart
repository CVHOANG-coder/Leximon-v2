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

  test(
    'recalculates an incomplete flag when Home initializes lesson goals',
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
              learnedWordsCount: const Value(4),
            ),
          );

      final card = await service.load(now: today);
      final visit = await database.select(database.visitModels).getSingle();

      expect(card.isComplete, isFalse);
      expect(visit.learnWordsGoal, DailyCardService.defaultLearnWordsGoal);
      expect(visit.learnedWordsCount, 4);
      expect(visit.areDailyTasksFinished, isFalse);
    },
  );

  test(
    'recalculates a completed flag when Home initializes lesson goals',
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
              learnedWordsCount: const Value(8),
            ),
          );

      final card = await service.load(now: today);
      final visit = await database.select(database.visitModels).getSingle();

      expect(card.isComplete, isTrue);
      expect(visit.learnWordsGoal, DailyCardService.defaultLearnWordsGoal);
      expect(visit.learnedWordsCount, 8);
      expect(visit.areDailyTasksFinished, isTrue);
    },
  );

  final combinations =
      <
        ({
          bool repeat,
          bool train,
          bool difficult,
          List<DailyTaskType> expected,
        })
      >[
        (
          repeat: false,
          train: false,
          difficult: false,
          expected: [DailyTaskType.learn],
        ),
        (
          repeat: true,
          train: false,
          difficult: false,
          expected: [DailyTaskType.repeat, DailyTaskType.learn],
        ),
        (
          repeat: false,
          train: true,
          difficult: false,
          expected: [DailyTaskType.learn, DailyTaskType.train],
        ),
        (
          repeat: false,
          train: false,
          difficult: true,
          expected: [DailyTaskType.learn, DailyTaskType.difficult],
        ),
        (
          repeat: true,
          train: true,
          difficult: false,
          expected: [
            DailyTaskType.repeat,
            DailyTaskType.learn,
            DailyTaskType.train,
          ],
        ),
        (
          repeat: true,
          train: false,
          difficult: true,
          expected: [
            DailyTaskType.repeat,
            DailyTaskType.learn,
            DailyTaskType.difficult,
          ],
        ),
        (
          repeat: false,
          train: true,
          difficult: true,
          expected: [
            DailyTaskType.learn,
            DailyTaskType.train,
            DailyTaskType.difficult,
          ],
        ),
        (
          repeat: true,
          train: true,
          difficult: true,
          expected: DailyTaskType.values,
        ),
      ];

  for (final combination in combinations) {
    test('builds main task combination '
        'R:${combination.repeat} T:${combination.train} '
        'D:${combination.difficult}', () async {
      final now = DateTime(2026, 7, 29, 12);
      await database.batch((batch) {
        batch.insertAll(database.wordModels, [
          for (var id = 1; id <= 8; id++)
            WordModelsCompanion.insert(
              id: id,
              topicId: 1,
              writing: 'word$id',
              translation: 'nghĩa $id',
              isEnabled: true,
              priority: 1,
              level: 1,
            ),
        ]);
        batch.insertAll(database.learningProgressModels, [
          for (var id = 1; id <= 8; id++)
            LearningProgressModelsCompanion.insert(
              id: Value(id),
              creationDate: now
                  .subtract(const Duration(days: 2))
                  .millisecondsSinceEpoch,
              repetitionStep: Value(combination.repeat ? 1 : 0),
              repetitionDate: combination.repeat
                  ? Value(now.millisecondsSinceEpoch - 1)
                  : const Value.absent(),
              onFastBrain: Value(combination.train),
              repetitionFastBrainDate: combination.train
                  ? Value(now.millisecondsSinceEpoch - 1)
                  : const Value.absent(),
              trainingError: Value(combination.difficult ? 2 : 0),
            ),
        ]);
      });

      final card = await service.load(now: now);

      expect(card.tasks.map((task) => task.type), combination.expected);
    });
  }
}
