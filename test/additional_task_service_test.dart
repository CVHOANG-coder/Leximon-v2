import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/additional_task_service.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';

void main() {
  late AppDatabase database;
  late AdditionalTaskService service;
  final now = DateTime(2026, 7, 29, 12);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = AdditionalTaskService(
      database: database,
      dailyCardService: DailyCardService(database),
    );
  });

  tearDown(() => database.close());

  test('keeps additional tasks locked until every main task is done', () async {
    await expectLater(
      service.loadAvailableTasks(now: now),
      throwsA(isA<AdditionalTasksLockedException>()),
    );
  });

  test('builds the live additional list from today progress', () async {
    await _insertCompletedVisit(database, now);
    await _insertWords(database, 9);

    await _insertProgress(
      database,
      id: 1,
      creationDate: now.millisecondsSinceEpoch,
      repetitionStep: 1,
      repetitionDate: now.millisecondsSinceEpoch - 1000,
    );
    for (var id = 2; id <= 5; id++) {
      await _insertProgress(
        database,
        id: id,
        creationDate: now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
        onFastBrain: true,
        repetitionFastBrainDate: now.millisecondsSinceEpoch - (6 - id) * 1000,
      );
    }
    for (var id = 6; id <= 9; id++) {
      await _insertProgress(
        database,
        id: id,
        creationDate: now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
        trainingError: LearningProgressService.bitForType(
          TrainingExerciseType.choiceOfFourToEng,
        ),
      );
    }

    expect(await service.loadAvailableTasks(now: now), [
      DailyTaskType.learn,
      DailyTaskType.repeat,
      DailyTaskType.train,
      DailyTaskType.difficult,
    ]);

    final repeat = await service.prepareTask(DailyTaskType.repeat, now: now);
    final fastBrain = await service.prepareTask(DailyTaskType.train, now: now);
    final difficult = await service.prepareTask(
      DailyTaskType.difficult,
      now: now,
    );

    expect(repeat.words.map((word) => word.id), [1]);
    expect(fastBrain.words.map((word) => word.id), [2, 3, 4, 5]);
    expect(difficult.words.map((word) => word.id), [6, 7, 8, 9]);
    expect(
      difficult.exerciseMasksByWordId.values,
      everyElement(
        LearningProgressService.bitForType(
          TrainingExerciseType.choiceOfFourToEng,
        ),
      ),
    );
  });

  test('rechecks availability immediately before starting a task', () async {
    await _insertCompletedVisit(database, now);
    await _insertWords(database, 4);
    for (var id = 1; id <= 4; id++) {
      await _insertProgress(
        database,
        id: id,
        creationDate: now.millisecondsSinceEpoch,
        onFastBrain: true,
        repetitionFastBrainDate: now.millisecondsSinceEpoch - 1000,
      );
    }
    expect(
      await service.loadAvailableTasks(now: now),
      contains(DailyTaskType.train),
    );

    await (database.update(
      database.learningProgressModels,
    )..where((row) => row.id.equals(4))).write(
      const LearningProgressModelsCompanion(markedAsKnown: Value(true)),
    );

    await expectLater(
      service.prepareTask(DailyTaskType.train, now: now),
      throwsA(isA<AdditionalTaskUnavailableException>()),
    );
  });

  test(
    'additional Repeat selects only twenty due regular-repeat words',
    () async {
      await _insertCompletedVisit(database, now);
      await _insertWords(database, 27);
      for (var id = 1; id <= 22; id++) {
        await _insertProgress(
          database,
          id: id,
          creationDate: id == 1
              ? now.millisecondsSinceEpoch
              : now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          repetitionStep: 1,
          repetitionDate: now.millisecondsSinceEpoch - id * 1000,
        );
      }
      await _insertProgress(
        database,
        id: 23,
        creationDate: now.millisecondsSinceEpoch,
        repetitionStep: 1,
        repetitionDate: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      await _insertProgress(
        database,
        id: 24,
        creationDate: now.millisecondsSinceEpoch,
        onFastBrain: true,
        repetitionFastBrainDate: now.millisecondsSinceEpoch - 1,
      );
      await _insertProgress(
        database,
        id: 25,
        creationDate: now.millisecondsSinceEpoch,
        repetitionStep: 1,
        repetitionDate: now.millisecondsSinceEpoch - 1,
        markedAsKnown: true,
      );
      await _insertProgress(
        database,
        id: 26,
        creationDate: now.millisecondsSinceEpoch,
        repetitionStep: 1,
        repetitionDate: now.millisecondsSinceEpoch - 1,
        deletedByUser: true,
      );
      await _insertProgress(
        database,
        id: 27,
        creationDate: now.millisecondsSinceEpoch,
        repetitionStep: 1,
        repetitionDate: now.millisecondsSinceEpoch - 1,
      );
      await (database.update(database.wordModels)
            ..where((row) => row.id.equals(27)))
          .write(const WordModelsCompanion(isEnabled: Value(false)));

      final repeat = await service.prepareTask(DailyTaskType.repeat, now: now);

      expect(repeat.words, hasLength(AdditionalTaskService.maxRepeatWords));
      expect(
        repeat.words.map((word) => word.id),
        List<int>.generate(20, (index) => 22 - index),
      );
      final selectedIds = repeat.words.map((word) => word.id);
      for (final excludedId in [23, 24, 25, 26, 27]) {
        expect(selectedIds, isNot(contains(excludedId)));
      }
    },
  );
}

Future<void> _insertCompletedVisit(AppDatabase database, DateTime now) async {
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
}

Future<void> _insertWords(AppDatabase database, int count) {
  return database.batch((batch) {
    batch.insertAll(database.wordModels, [
      for (var id = 1; id <= count; id++)
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
  });
}

Future<void> _insertProgress(
  AppDatabase database, {
  required int id,
  required int creationDate,
  int trainingError = 0,
  int repetitionStep = 0,
  int? repetitionDate,
  bool onFastBrain = false,
  int? repetitionFastBrainDate,
  bool markedAsKnown = false,
  bool deletedByUser = false,
}) {
  return database
      .into(database.learningProgressModels)
      .insert(
        LearningProgressModelsCompanion.insert(
          id: Value(id),
          creationDate: creationDate,
          trainingError: Value(trainingError),
          repetitionStep: Value(repetitionStep),
          repetitionDate: Value(repetitionDate),
          onFastBrain: Value(onFastBrain),
          repetitionFastBrainDate: Value(repetitionFastBrainDate),
          markedAsKnown: Value(markedAsKnown),
          deletedByUser: Value(deletedByUser),
        ),
      );
}
