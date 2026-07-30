import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';
import 'package:leximon/data/services/topic_progress_service.dart';

void main() {
  late AppDatabase database;
  late LearningProgressService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = LearningProgressService(database);
  });

  tearDown(() => database.close());

  test('learning only increases the learned counter once', () async {
    final exercises = [
      _exercise(TrainingExerciseType.choiceOfFourToEng),
      _exercise(TrainingExerciseType.choiceOfFourFromEng),
    ];
    final sessionId = await service.startSession(
      exercises: exercises,
      requiredMask: LearningProgressService.maskForTypes(
        exercises.map((exercise) => exercise.trainingExercise),
      ),
      topicId: 7,
    );

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.correct,
    );
    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 1,
      answer: ExerciseAnswerState.correct,
    );

    final first = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.learn,
    );
    final second = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.learn,
    );
    final progress = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(1))).getSingle();
    final visit = await database.select(database.visitModels).getSingle();

    expect(first.newlyLearnedWordCount, 1);
    expect(second.newlyLearnedWordCount, 1);
    expect(first.completedWordCount, 1);
    expect(second.completedWordCount, 1);
    expect(progress.trainingProgress, 6);
    expect(progress.trainingError, 0);
    expect(progress.learnedDate, isNotNull);
    expect(progress.onFastBrain, isTrue);
    expect(progress.repetitionFastBrainDate, isNotNull);
    expect(visit.learnedWordsCount, 1);
    expect(visit.trainedWordsCount, 0);
  });

  test(
    'learning completion and topic progress count an unresolved word',
    () async {
      await database.batch((batch) {
        batch.insertAll(database.wordModels, [
          for (var wordId = 1; wordId <= 4; wordId++)
            WordModelsCompanion.insert(
              id: wordId,
              topicId: 7,
              writing: 'word$wordId',
              translation: 'nghĩa $wordId',
              isEnabled: true,
              priority: 1,
              level: 1,
            ),
        ]);
      });
      final exercises = [
        for (var wordId = 1; wordId <= 4; wordId++)
          _exerciseFor(wordId, TrainingExerciseType.choiceOfFourToEng),
      ];
      final sessionId = await service.startSession(
        exercises: exercises,
        requiredMask: LearningProgressService.maskForTypes(
          exercises.map((exercise) => exercise.trainingExercise),
        ),
        topicId: 7,
      );
      for (var index = 0; index < 3; index++) {
        await service.submitAnswer(
          sessionId: sessionId,
          orderIndex: index,
          answer: ExerciseAnswerState.correct,
        );
      }
      await service.submitAnswer(
        sessionId: sessionId,
        orderIndex: 3,
        answer: ExerciseAnswerState.wrong,
      );
      await service.submitAnswer(
        sessionId: sessionId,
        orderIndex: 4,
        answer: ExerciseAnswerState.wrong,
      );

      final result = await service.completeSession(
        sessionId,
        dailyTaskType: DailyTaskType.learn,
      );
      final visit = await database.select(database.visitModels).getSingle();
      final progress = await TopicProgressService(database).load();
      final problemProgress = await (database.select(
        database.learningProgressModels,
      )..where((row) => row.id.equals(4))).getSingle();

      expect(result.completedWordCount, 4);
      expect(result.newlyLearnedWordCount, 3);
      expect(result.unresolvedWrongWordCount, 1);
      expect(visit.learnedWordsCount, 4);
      expect(progress[7], 1);
      expect(problemProgress.trainingError, isNonZero);
      expect(problemProgress.learnedDate, isNull);
    },
  );

  test(
    'does not finish the daily plan before Home initializes its goals',
    () async {
      for (var wordId = 1; wordId <= 2; wordId++) {
        final exercise = _exerciseFor(
          wordId,
          TrainingExerciseType.choiceOfFourToEng,
        );
        final sessionId = await service.startSession(
          exercises: [exercise],
          requiredMask: LearningProgressService.maskForTypes([
            exercise.trainingExercise,
          ]),
          topicId: 7,
        );
        await service.submitAnswer(
          sessionId: sessionId,
          orderIndex: 0,
          answer: ExerciseAnswerState.correct,
        );
        await service.completeSession(
          sessionId,
          dailyTaskType: DailyTaskType.learn,
        );
      }

      final visit = await database.select(database.visitModels).getSingle();

      expect(visit.learnWordsGoal, 0);
      expect(visit.learnedWordsCount, 2);
      expect(visit.areDailyTasksFinished, isFalse);
    },
  );

  test('clears an error when the generated retry is correct', () async {
    final exercise = _exercise(TrainingExerciseType.choiceOfFourToEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.wrong,
    );
    final retry =
        await (database.select(database.sessionExercises)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)]))
            .get();
    expect(retry, hasLength(2));
    expect(retry.last.isRetry, isTrue);

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: retry.last.orderIndex,
      answer: ExerciseAnswerState.correct,
    );
    final result = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.learn,
    );
    final progress = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(1))).getSingle();

    expect(result.successfulWordCount, 1);
    expect(result.unresolvedWrongWordCount, 0);
    expect(progress.trainingProgress, 2);
    expect(progress.trainingError, 0);
  });

  test('keeps an unresolved error when retry is wrong', () async {
    final exercise = _exercise(TrainingExerciseType.choiceOfFourToEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.wrong,
    );
    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 1,
      answer: ExerciseAnswerState.wrong,
    );
    expect(
      await (database.select(
        database.sessionExercises,
      )..where((row) => row.sessionId.equals(sessionId))).get(),
      hasLength(2),
    );
    final result = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.learn,
    );
    final progress = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(1))).getSingle();

    expect(result.successfulWordCount, 0);
    expect(result.unresolvedWrongWordCount, 1);
    expect(progress.trainingProgress, 0);
    expect(progress.trainingError, 2);
    expect(progress.learnedDate, isNull);
  });

  test('skipped required exercise does not mark a word as learned', () async {
    final exercise = _exercise(TrainingExerciseType.speaking);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.skipped,
    );
    final result = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.learn,
    );

    expect(result.successfulWordCount, 0);
    final progress = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(1))).getSingle();
    expect(progress.trainingProgress, 0);
    expect(progress.trainingError, 0);
    expect(progress.learnedDate, isNull);
  });

  test('supports repetition answers without adding retry exercises', () async {
    final exercise = _exercise(TrainingExerciseType.choiceOfFourFromEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );

    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.wrong,
      createRetryOnWrong: false,
    );
    final sessionExercises = await (database.select(
      database.sessionExercises,
    )..where((row) => row.sessionId.equals(sessionId))).get();

    expect(sessionExercises, hasLength(1));
    final result = await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.repeat,
    );
    expect(result.successfulWordCount, 0);
    expect(result.unresolvedWrongWordCount, 1);
    final visit = await database.select(database.visitModels).getSingle();
    expect(visit.repeatedWordsCount, 1);
  });

  test('advances a successful repetition to its next local schedule', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: now - const Duration(days: 2).inMilliseconds,
            trainingProgress: const Value(4),
            repetitionStep: const Value(1),
            repetitionDate: Value(now - 1),
            learnedDate: Value(now - const Duration(days: 1).inMilliseconds),
          ),
        );
    final exercise = _exercise(TrainingExerciseType.choiceOfFourFromEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );
    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.correct,
      createRetryOnWrong: false,
    );

    await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.repeat,
    );
    final progress = await database
        .select(database.learningProgressModels)
        .getSingle();

    expect(progress.repetitionStep, 2);
    expect(
      progress.repetitionDate!,
      greaterThanOrEqualTo(now + const Duration(days: 5).inMilliseconds),
    );
  });

  test('Fast Brain only increases the trained counter', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: now - const Duration(days: 3).inMilliseconds,
            trainingProgress: const Value(2),
            learnedDate: Value(now - const Duration(days: 3).inMilliseconds),
            onFastBrain: const Value(true),
            repetitionFastBrainStep: const Value(1),
            repetitionFastBrainDate: Value(now - 1),
          ),
        );
    final exercise = _exercise(TrainingExerciseType.choiceOfFourToEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );
    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.correct,
    );

    await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.train,
    );
    final visit = await database.select(database.visitModels).getSingle();
    final progress = await database
        .select(database.learningProgressModels)
        .getSingle();

    expect(visit.learnedWordsCount, 0);
    expect(visit.trainedWordsCount, 1);
    expect(progress.repetitionFastBrainStep, 2);
    expect(
      progress.repetitionFastBrainDate!,
      greaterThanOrEqualTo(now + const Duration(days: 2).inMilliseconds),
    );
  });

  test(
    'counts difficult words independently when their error types differ',
    () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final firstType = TrainingExerciseType.choiceOfFourToEng;
      final secondType = TrainingExerciseType.constructor;
      await database.batch((batch) {
        batch.insertAll(database.learningProgressModels, [
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: now,
            trainingError: Value(LearningProgressService.bitForType(firstType)),
            learnedDate: Value(now),
          ),
          LearningProgressModelsCompanion.insert(
            id: const Value(2),
            creationDate: now,
            trainingError: Value(
              LearningProgressService.bitForType(secondType),
            ),
            learnedDate: Value(now),
          ),
        ]);
      });
      final exercises = [
        _exerciseFor(1, firstType),
        _exerciseFor(2, secondType),
      ];
      final sessionId = await service.startSession(
        exercises: exercises,
        requiredMask: LearningProgressService.maskForTypes([
          firstType,
          secondType,
        ]),
      );
      for (var index = 0; index < exercises.length; index++) {
        await service.submitAnswer(
          sessionId: sessionId,
          orderIndex: index,
          answer: ExerciseAnswerState.correct,
        );
      }

      final result = await service.completeSession(
        sessionId,
        dailyTaskType: DailyTaskType.difficult,
      );
      final progressRows = await database
          .select(database.learningProgressModels)
          .get();
      final visit = await database.select(database.visitModels).getSingle();

      expect(result.successfulWordCount, 2);
      expect(progressRows, everyElement(isA<LearningProgressRow>()));
      expect(progressRows.map((row) => row.trainingError), everyElement(0));
      expect(visit.problemWordsHealedCount, 2);
    },
  );

  test('heals legacy choice-of-two error through choice-to-English', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: now,
            trainingError: const Value(1),
            learnedDate: Value(now),
          ),
        );
    final exercise = _exercise(TrainingExerciseType.choiceOfFourToEng);
    final sessionId = await service.startSession(
      exercises: [exercise],
      requiredMask: LearningProgressService.maskForTypes([
        exercise.trainingExercise,
      ]),
    );
    await service.submitAnswer(
      sessionId: sessionId,
      orderIndex: 0,
      answer: ExerciseAnswerState.correct,
    );

    await service.completeSession(
      sessionId,
      dailyTaskType: DailyTaskType.difficult,
    );
    final progress = await database
        .select(database.learningProgressModels)
        .getSingle();
    final visit = await database.select(database.visitModels).getSingle();

    expect(progress.trainingError, 0);
    expect(visit.problemWordsHealedCount, 1);
  });
}

PracticeExercise _exercise(TrainingExerciseType type) {
  return _exerciseFor(1, type);
}

PracticeExercise _exerciseFor(int wordId, TrainingExerciseType type) {
  final word = ExerciseWord(
    id: wordId,
    topicId: 7,
    writing: 'word$wordId',
    translation: 'nghĩa $wordId',
    transliteration: '',
  );
  return PracticeExercise(word: word, variants: [word], trainingExercise: type);
}
