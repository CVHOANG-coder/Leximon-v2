import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';

void main() {
  late AppDatabase database;
  late LearningProgressService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = LearningProgressService(database);
  });

  tearDown(() => database.close());

  test('sets progress bits and counts a completed session once', () async {
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

    final first = await service.completeSession(sessionId);
    final second = await service.completeSession(sessionId);
    final progress = await (database.select(
      database.learningProgressModels,
    )..where((row) => row.id.equals(1))).getSingle();
    final visit = await database.select(database.visitModels).getSingle();

    expect(first.newlyLearnedWordCount, 1);
    expect(second.newlyLearnedWordCount, 1);
    expect(progress.trainingProgress, 6);
    expect(progress.trainingError, 0);
    expect(progress.learnedDate, isNotNull);
    expect(visit.learnedWordsCount, 1);
    expect(visit.trainedWordsCount, 1);
  });

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
    final result = await service.completeSession(sessionId);
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
    final result = await service.completeSession(sessionId);
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
    final result = await service.completeSession(sessionId);

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
  });
}

PracticeExercise _exercise(TrainingExerciseType type) {
  const word = ExerciseWord(
    id: 1,
    topicId: 7,
    writing: 'trip',
    translation: 'chuyến đi',
    transliteration: '',
  );
  return PracticeExercise(word: word, variants: [word], trainingExercise: type);
}
