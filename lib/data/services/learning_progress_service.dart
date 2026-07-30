import 'dart:math';

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/practice_exercise.dart';
import 'daily_card_service.dart';
import 'exercise_error_mask.dart';

enum LearningSessionStatus { active, completed, abandoned }

class SessionCompletionResult {
  const SessionCompletionResult({
    required this.sessionId,
    required this.successfulWordCount,
    required this.unresolvedWrongWordCount,
    required this.completedWordCount,
    required this.newlyLearnedWordCount,
  });

  final String sessionId;
  final int successfulWordCount;
  final int unresolvedWrongWordCount;
  final int completedWordCount;
  final int newlyLearnedWordCount;
}

class LearningProgressService {
  LearningProgressService(this._database);

  static const int _activeStatus = 0;
  static const int _completedStatus = 1;
  static const int _abandonedStatus = 2;

  final AppDatabase _database;

  static int maskForTypes(Iterable<TrainingExerciseType> types) {
    return types.fold<int>(0, (mask, type) => mask | bitForType(type));
  }

  static int bitForType(TrainingExerciseType type) {
    switch (type) {
      case TrainingExerciseType.choiceOfFourToEng:
        return 1 << 1;
      case TrainingExerciseType.choiceOfFourFromEng:
        return 1 << 2;
      case TrainingExerciseType.constructor:
        return 1 << 3;
      case TrainingExerciseType.choiceOfFourListening:
        return 1 << 4;
      case TrainingExerciseType.choiceOfThreeListening:
        return 1 << 5;
      case TrainingExerciseType.speaking:
        return 1 << 6;
      case TrainingExerciseType.choiceOfTwo:
        return 1;
    }
  }

  Future<String> startSession({
    required List<PracticeExercise> exercises,
    required int requiredMask,
    int? topicId,
  }) async {
    if (exercises.isEmpty) {
      throw ArgumentError.value(exercises, 'exercises', 'Cannot be empty.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionId =
        'learning-$now-${Random().nextInt(1 << 32).toRadixString(16)}';

    await _database.transaction(() async {
      await _database
          .into(_database.learningSessions)
          .insert(
            LearningSessionsCompanion.insert(
              id: sessionId,
              topicId: Value(topicId),
              requiredMask: requiredMask,
              originalExerciseCount: exercises.length,
              startedAt: now,
            ),
          );

      await _database.batch((batch) {
        batch.insertAll(_database.sessionExercises, [
          for (var index = 0; index < exercises.length; index++)
            SessionExercisesCompanion.insert(
              sessionId: sessionId,
              wordId: exercises[index].word.id,
              exerciseType: exercises[index].trainingExercise.index,
              orderIndex: index,
            ),
        ]);
      });
    });

    return sessionId;
  }

  Future<void> submitAnswer({
    required String sessionId,
    required int orderIndex,
    required ExerciseAnswerState answer,
    bool createRetryOnWrong = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.transaction(() async {
      final exercise =
          await (_database.select(_database.sessionExercises)..where(
                (row) =>
                    row.sessionId.equals(sessionId) &
                    row.orderIndex.equals(orderIndex),
              ))
              .getSingleOrNull();
      if (exercise == null) {
        throw StateError('Unknown exercise $sessionId/$orderIndex');
      }
      if (exercise.answer != ExerciseAnswerState.notAnswered.index) return;

      await (_database.update(
        _database.sessionExercises,
      )..where((row) => row.id.equals(exercise.id))).write(
        SessionExercisesCompanion(
          answer: Value(answer.index),
          answeredAt: Value(now),
        ),
      );

      if (answer == ExerciseAnswerState.wrong &&
          !exercise.isRetry &&
          createRetryOnWrong) {
        final existingRetry =
            await (_database.select(_database.sessionExercises)..where(
                  (row) =>
                      row.sessionId.equals(sessionId) &
                      row.parentExerciseId.equals(exercise.id),
                ))
                .getSingleOrNull();
        if (existingRetry == null) {
          final sessionExercises = await (_database.select(
            _database.sessionExercises,
          )..where((row) => row.sessionId.equals(sessionId))).get();
          final nextOrderIndex =
              sessionExercises.map((row) => row.orderIndex).fold<int>(-1, max) +
              1;
          await _database
              .into(_database.sessionExercises)
              .insert(
                SessionExercisesCompanion.insert(
                  sessionId: sessionId,
                  wordId: exercise.wordId,
                  exerciseType: exercise.exerciseType,
                  orderIndex: nextOrderIndex,
                  isRetry: const Value(true),
                  parentExerciseId: Value(exercise.id),
                ),
              );
        }
      }

      final remaining =
          await (_database.select(_database.sessionExercises)..where(
                (row) =>
                    row.sessionId.equals(sessionId) &
                    row.answer.equals(ExerciseAnswerState.notAnswered.index),
              ))
              .get();
      final nextIndex = remaining.isEmpty
          ? (await (_database.select(
                      _database.sessionExercises,
                    )..where((row) => row.sessionId.equals(sessionId))).get())
                    .map((row) => row.orderIndex)
                    .fold<int>(-1, max) +
                1
          : remaining.map((row) => row.orderIndex).reduce(min);
      await (_database.update(_database.learningSessions)
            ..where((row) => row.id.equals(sessionId)))
          .write(LearningSessionsCompanion(currentIndex: Value(nextIndex)));
    });
  }

  Future<SessionCompletionResult> completeSession(
    String sessionId, {
    required DailyTaskType dailyTaskType,
  }) {
    return _database.transaction(() async {
      final session = await (_database.select(
        _database.learningSessions,
      )..where((row) => row.id.equals(sessionId))).getSingle();

      if (session.completionAppliedAt != null) {
        return _resultFrom(session);
      }
      if (session.status == _abandonedStatus) {
        throw StateError('Cannot complete an abandoned session.');
      }

      final exercises = await (_database.select(
        _database.sessionExercises,
      )..where((row) => row.sessionId.equals(sessionId))).get();
      if (exercises.any(
        (exercise) => exercise.answer == ExerciseAnswerState.notAnswered.index,
      )) {
        throw StateError('Session still has unanswered exercises.');
      }

      final aggregates = <int, _WordAggregate>{};
      for (final exercise in exercises) {
        final aggregate = aggregates[exercise.wordId] ??= _WordAggregate();
        final type = exercise.exerciseType;
        if (!exercise.isRetry) aggregate.originalTypes.add(type);
        if (exercise.isRetry) {
          if (exercise.answer == ExerciseAnswerState.correct.index) {
            aggregate.retryCorrect[type] =
                (aggregate.retryCorrect[type] ?? 0) + 1;
          }
        } else if (exercise.answer == ExerciseAnswerState.correct.index) {
          aggregate.originalCorrect[type] =
              (aggregate.originalCorrect[type] ?? 0) + 1;
        } else if (exercise.answer == ExerciseAnswerState.wrong.index) {
          aggregate.originalWrong[type] =
              (aggregate.originalWrong[type] ?? 0) + 1;
        }
      }

      var successfulWordCount = 0;
      var unresolvedWrongWordCount = 0;
      var newlyLearnedWordCount = 0;
      var healedProblemWordCount = 0;
      final completedWordCount = aggregates.length;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in aggregates.entries) {
        final aggregate = entry.value;
        var solvedMask = 0;
        var unresolvedMask = 0;
        for (final type in {
          ...aggregate.originalCorrect.keys,
          ...aggregate.originalWrong.keys,
          ...aggregate.retryCorrect.keys,
        }) {
          final originalCorrect = aggregate.originalCorrect[type] ?? 0;
          final originalWrong = aggregate.originalWrong[type] ?? 0;
          final retryCorrect = aggregate.retryCorrect[type] ?? 0;
          if (originalCorrect > 0 || retryCorrect > 0) {
            solvedMask |= _bitForStoredType(type);
          }
          if (originalWrong > retryCorrect) {
            unresolvedMask |= _bitForStoredType(type);
          }
        }

        final progress = await (_database.select(
          _database.learningProgressModels,
        )..where((row) => row.id.equals(entry.key))).getSingleOrNull();
        final oldProgress =
            progress ??
            LearningProgressRow(
              id: entry.key,
              creationDate: now,
              trainingProgress: 0,
              trainingError: 0,
              repetitionStep: 0,
              repetitionDate: null,
              learnedDate: null,
              onFastBrain: false,
              repetitionFastBrainStep: 0,
              repetitionFastBrainDate: null,
              markedAsKnown: false,
              deletedByUser: false,
            );
        final progressMask = oldProgress.trainingProgress | solvedMask;
        final errorMask =
            (oldProgress.trainingError | unresolvedMask) &
            ~storedErrorClearMask(solvedMask);
        final wordRequiredMask = aggregate.originalTypes.fold<int>(
          0,
          (mask, type) => mask | _bitForStoredType(type),
        );
        final isLearned =
            (progressMask & session.requiredMask) == session.requiredMask &&
            (errorMask & session.requiredMask) == 0;
        final canBecomeLearned = dailyTaskType == DailyTaskType.learn;
        final becameLearned =
            canBecomeLearned && oldProgress.learnedDate == null && isLearned;
        final learnedDate =
            oldProgress.learnedDate ?? (becameLearned ? now : null);
        final isSuccessful =
            wordRequiredMask != 0 &&
            (solvedMask & wordRequiredMask) == wordRequiredMask &&
            (unresolvedMask & wordRequiredMask) == 0;
        var repetitionStep = becameLearned ? 1 : oldProgress.repetitionStep;
        var repetitionDate = becameLearned
            ? now + const Duration(days: 1).inMilliseconds
            : oldProgress.repetitionDate;
        var fastBrainStep = becameLearned
            ? 1
            : oldProgress.repetitionFastBrainStep;
        var fastBrainDate = becameLearned
            ? now + const Duration(days: 2).inMilliseconds
            : oldProgress.repetitionFastBrainDate;
        final onFastBrain = becameLearned || oldProgress.onFastBrain;

        if (isSuccessful &&
            dailyTaskType == DailyTaskType.repeat &&
            oldProgress.repetitionStep > 0) {
          repetitionStep = oldProgress.repetitionStep + 1;
          repetitionDate =
              now + _repetitionDelay(repetitionStep).inMilliseconds;
        }
        if (isSuccessful && dailyTaskType == DailyTaskType.train) {
          fastBrainStep = oldProgress.repetitionFastBrainStep + 1;
          fastBrainDate = now + const Duration(days: 2).inMilliseconds;
        }

        if (isSuccessful) {
          successfulWordCount++;
        }
        if ((unresolvedMask & wordRequiredMask) != 0) {
          unresolvedWrongWordCount++;
        }
        if (becameLearned) newlyLearnedWordCount++;
        if (dailyTaskType == DailyTaskType.difficult &&
            oldProgress.trainingError != 0 &&
            errorMask == 0) {
          healedProblemWordCount++;
        }

        await _database
            .into(_database.learningProgressModels)
            .insertOnConflictUpdate(
              LearningProgressModelsCompanion(
                id: Value(oldProgress.id),
                creationDate: Value(oldProgress.creationDate),
                trainingProgress: Value(progressMask),
                trainingError: Value(errorMask),
                repetitionStep: Value(repetitionStep),
                repetitionDate: Value(repetitionDate),
                learnedDate: Value(learnedDate),
                onFastBrain: Value(onFastBrain),
                repetitionFastBrainStep: Value(fastBrainStep),
                repetitionFastBrainDate: Value(fastBrainDate),
                markedAsKnown: Value(oldProgress.markedAsKnown),
                deletedByUser: Value(oldProgress.deletedByUser),
              ),
            );
      }

      await _updateVisit(
        now: now,
        completedWordCount: completedWordCount,
        successfulWordCount: successfulWordCount,
        processedWordCount: session.originalExerciseCount,
        healedProblemWordCount: healedProblemWordCount,
        dailyTaskType: dailyTaskType,
      );

      await (_database.update(
        _database.learningSessions,
      )..where((row) => row.id.equals(sessionId))).write(
        LearningSessionsCompanion(
          status: const Value(_completedStatus),
          completedAt: Value(now),
          completionAppliedAt: Value(now),
          successfulWordCount: Value(successfulWordCount),
          unresolvedWrongWordCount: Value(unresolvedWrongWordCount),
          completedWordCount: Value(completedWordCount),
          newlyLearnedWordCount: Value(newlyLearnedWordCount),
        ),
      );

      return SessionCompletionResult(
        sessionId: sessionId,
        successfulWordCount: successfulWordCount,
        unresolvedWrongWordCount: unresolvedWrongWordCount,
        completedWordCount: completedWordCount,
        newlyLearnedWordCount: newlyLearnedWordCount,
      );
    });
  }

  Future<void> abandonSession(String sessionId) async {
    await (_database.update(_database.learningSessions)..where(
          (row) => row.id.equals(sessionId) & row.status.equals(_activeStatus),
        ))
        .write(
          const LearningSessionsCompanion(status: Value(_abandonedStatus)),
        );
  }

  Future<void> _updateVisit({
    required int now,
    required int completedWordCount,
    required int successfulWordCount,
    required int processedWordCount,
    required int healedProblemWordCount,
    required DailyTaskType dailyTaskType,
  }) async {
    final learnedCountDelta = dailyTaskType == DailyTaskType.learn
        ? completedWordCount
        : 0;
    final trainedCountDelta = dailyTaskType == DailyTaskType.train
        ? successfulWordCount
        : 0;
    final repeatedCountDelta = dailyTaskType == DailyTaskType.repeat
        ? processedWordCount
        : 0;
    final difficultCountDelta = dailyTaskType == DailyTaskType.difficult
        ? successfulWordCount
        : 0;
    final date = _dayStart(now);
    final existing = await (_database.select(
      _database.visitModels,
    )..where((row) => row.date.equals(date))).getSingleOrNull();
    if (existing == null) {
      final areGoalsFinished = areDailyTaskGoalsFinished(
        repeatWordsGoal: 0,
        repeatedWordsCount: repeatedCountDelta,
        learnWordsGoal: 0,
        learnedWordsCount: learnedCountDelta,
        trainWordsGoal: 0,
        trainedWordsCount: trainedCountDelta,
        difficultWordsGoal: 0,
        difficultWordsTrainedCount: difficultCountDelta,
      );
      await _database
          .into(_database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: date,
              atLeastOneTaskFinished: const Value(true),
              areDailyTasksFinished: Value(areGoalsFinished),
              repeatedWordsCount: Value(repeatedCountDelta),
              learnedWordsCount: Value(learnedCountDelta),
              trainedWordsCount: Value(trainedCountDelta),
              difficultWordsTrainedCount: Value(difficultCountDelta),
              problemWordsHealedCount: Value(healedProblemWordCount),
            ),
          );
      return;
    }

    final repeatedCount = existing.repeatedWordsCount + repeatedCountDelta;
    final learnedCount = existing.learnedWordsCount + learnedCountDelta;
    final trainedCount = existing.trainedWordsCount + trainedCountDelta;
    final difficultCount =
        existing.difficultWordsTrainedCount + difficultCountDelta;
    final problemWordsHealedCount =
        existing.problemWordsHealedCount + healedProblemWordCount;
    final allGoalsFinished = areDailyTaskGoalsFinished(
      repeatWordsGoal: existing.repeatWordsGoal,
      repeatedWordsCount: repeatedCount,
      learnWordsGoal: existing.learnWordsGoal,
      learnedWordsCount: learnedCount,
      trainWordsGoal: existing.trainWordsGoal,
      trainedWordsCount: trainedCount,
      difficultWordsGoal: existing.difficultWordsGoal,
      difficultWordsTrainedCount: difficultCount,
    );
    await (_database.update(
      _database.visitModels,
    )..where((row) => row.id.equals(existing.id))).write(
      VisitModelsCompanion(
        atLeastOneTaskFinished: const Value(true),
        areDailyTasksFinished: Value(allGoalsFinished),
        repeatedWordsCount: Value(repeatedCount),
        learnedWordsCount: Value(learnedCount),
        trainedWordsCount: Value(trainedCount),
        difficultWordsTrainedCount: Value(difficultCount),
        problemWordsHealedCount: Value(problemWordsHealedCount),
      ),
    );
  }

  SessionCompletionResult _resultFrom(LearningSession session) {
    return SessionCompletionResult(
      sessionId: session.id,
      successfulWordCount: session.successfulWordCount,
      unresolvedWrongWordCount: session.unresolvedWrongWordCount,
      completedWordCount: session.completedWordCount,
      newlyLearnedWordCount: session.newlyLearnedWordCount,
    );
  }

  static int _bitForStoredType(int typeIndex) {
    switch (typeIndex) {
      case 0:
        return 1 << 1;
      case 1:
        return 1 << 2;
      case 2:
        return 1 << 5;
      case 3:
        return 1 << 3;
      case 4:
        return 1 << 4;
      case 5:
        return 1 << 6;
      case 6:
        return 1;
      default:
        throw StateError('Unknown exercise type index: $typeIndex');
    }
  }

  static Duration _repetitionDelay(int step) {
    return Duration(
      days: switch (step) {
        1 => 1,
        2 => 5,
        3 => 14,
        4 => 60,
        5 => 180,
        _ => 365,
      },
    );
  }

  static int _dayStart(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }
}

class _WordAggregate {
  final originalTypes = <int>{};
  final originalCorrect = <int, int>{};
  final originalWrong = <int, int>{};
  final retryCorrect = <int, int>{};
}
