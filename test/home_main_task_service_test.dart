import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/home_main_task_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';

void main() {
  late AppDatabase database;
  late HomeMainTaskService service;
  final now = DateTime(2026, 7, 29, 12);

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = HomeMainTaskService(database);
  });

  tearDown(() => database.close());

  test('selects at most twenty due repetition words', () async {
    await _insertWords(database, 29);
    for (var id = 1; id <= 25; id++) {
      await _insertProgress(
        database,
        id: id,
        now: now,
        repetitionStep: 1,
        repetitionDate: now.millisecondsSinceEpoch - id,
      );
    }
    await _insertProgress(
      database,
      id: 26,
      now: now,
      repetitionStep: 1,
      repetitionDate: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    await _insertProgress(
      database,
      id: 27,
      now: now,
      repetitionStep: 1,
      repetitionDate: now.millisecondsSinceEpoch - 1,
      markedAsKnown: true,
    );
    await _insertProgress(
      database,
      id: 28,
      now: now,
      repetitionStep: 1,
      repetitionDate: now.millisecondsSinceEpoch - 1,
      deletedByUser: true,
    );
    await _insertProgress(
      database,
      id: 29,
      now: now,
      repetitionStep: 0,
      repetitionDate: now.millisecondsSinceEpoch - 1,
    );

    final data = await service.prepareTask(DailyTaskType.repeat, now: now);

    expect(data.words, hasLength(HomeMainTaskService.maxRepeatWords));
    expect(
      data.words.map((word) => word.id),
      List.generate(20, (index) => index + 1),
    );
    expect(data.exerciseMasksByWordId, isEmpty);
  });

  test('selects four due Fast Brain words across all topics', () async {
    await _insertWords(database, 7, splitTopics: true);
    for (var id = 1; id <= 5; id++) {
      await _insertProgress(
        database,
        id: id,
        now: now,
        onFastBrain: true,
        repetitionFastBrainDate: now.millisecondsSinceEpoch - id,
      );
    }
    await _insertProgress(
      database,
      id: 6,
      now: now,
      onFastBrain: true,
      repetitionFastBrainDate: now
          .add(const Duration(days: 1))
          .millisecondsSinceEpoch,
    );
    await _insertProgress(
      database,
      id: 7,
      now: now,
      onFastBrain: true,
      repetitionFastBrainDate: now.millisecondsSinceEpoch - 1,
      markedAsKnown: true,
    );

    final data = await service.prepareTask(DailyTaskType.train, now: now);

    expect(data.words, hasLength(HomeMainTaskService.maxPracticeWords));
    expect(data.words.map((word) => word.topicId).toSet(), {1, 2});
    expect(
      data.words,
      everyElement(
        isA<WordRow>().having((word) => word.isEnabled, 'isEnabled', true),
      ),
    );
  });

  test(
    'selects four difficult words and normalizes legacy error bit zero',
    () async {
      await _insertWords(database, 8);
      final choiceToEnglishBit = LearningProgressService.bitForType(
        TrainingExerciseType.choiceOfFourToEng,
      );
      final constructorBit = LearningProgressService.bitForType(
        TrainingExerciseType.constructor,
      );
      final speakingBit = LearningProgressService.bitForType(
        TrainingExerciseType.speaking,
      );
      await _insertProgress(database, id: 1, now: now, trainingError: 1);
      await _insertProgress(
        database,
        id: 2,
        now: now,
        trainingError: constructorBit | speakingBit,
      );
      await _insertProgress(
        database,
        id: 3,
        now: now,
        trainingError: choiceToEnglishBit,
        markedAsKnown: true,
      );
      await _insertProgress(
        database,
        id: 4,
        now: now,
        trainingError: choiceToEnglishBit,
        deletedByUser: true,
      );
      await _insertProgress(database, id: 5, now: now);
      for (var id = 6; id <= 8; id++) {
        await _insertProgress(
          database,
          id: id,
          now: now,
          trainingError: choiceToEnglishBit,
        );
      }

      final data = await service.prepareTask(DailyTaskType.difficult, now: now);

      expect(data.words.map((word) => word.id), [1, 2, 6, 7]);
      expect(data.exerciseMasksByWordId[1], choiceToEnglishBit);
      expect(data.exerciseMasksByWordId[2], constructorBit | speakingBit);
    },
  );

  test('rejects a practice task when fewer than four words remain', () async {
    await _insertWords(database, 3);
    for (var id = 1; id <= 3; id++) {
      await _insertProgress(
        database,
        id: id,
        now: now,
        onFastBrain: true,
        repetitionFastBrainDate: now.millisecondsSinceEpoch - 1,
      );
    }

    await expectLater(
      service.prepareTask(DailyTaskType.train, now: now),
      throwsA(isA<HomeMainTaskUnavailableException>()),
    );
  });
}

Future<void> _insertWords(
  AppDatabase database,
  int count, {
  bool splitTopics = false,
}) {
  return database.batch((batch) {
    batch.insertAll(database.wordModels, [
      for (var id = 1; id <= count; id++)
        WordModelsCompanion.insert(
          id: id,
          topicId: splitTopics && id.isEven ? 2 : 1,
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
  required DateTime now,
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
          creationDate: now.millisecondsSinceEpoch,
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
