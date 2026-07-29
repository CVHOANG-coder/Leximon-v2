import 'package:drift/drift.dart';

import '../local/app_database.dart';
import 'exercise_error_mask.dart';

enum DailyTaskType { repeat, learn, train, difficult }

bool areDailyTaskGoalsFinished({
  required int repeatWordsGoal,
  required int repeatedWordsCount,
  required int learnWordsGoal,
  required int learnedWordsCount,
  required int trainWordsGoal,
  required int trainedWordsCount,
  required int difficultWordsGoal,
  required int difficultWordsTrainedCount,
}) {
  final hasInitializedGoal =
      repeatWordsGoal > 0 ||
      learnWordsGoal > 0 ||
      trainWordsGoal > 0 ||
      difficultWordsGoal > 0;
  return hasInitializedGoal &&
      (repeatWordsGoal == 0 || repeatedWordsCount >= repeatWordsGoal) &&
      (learnWordsGoal == 0 || learnedWordsCount >= learnWordsGoal) &&
      (trainWordsGoal == 0 || trainedWordsCount >= trainWordsGoal) &&
      (difficultWordsGoal == 0 ||
          difficultWordsTrainedCount >= difficultWordsGoal);
}

class DailyTaskSnapshot {
  const DailyTaskSnapshot({
    required this.type,
    required this.completed,
    required this.count,
  });

  final DailyTaskType type;
  final int completed;
  final int count;

  bool get isDone => count > 0 && completed >= count;
}

class DailyCardSnapshot {
  const DailyCardSnapshot({
    required this.tasks,
    required this.additionalTasks,
    required this.isFirstLearningDay,
  });

  final List<DailyTaskSnapshot> tasks;
  final List<DailyTaskType> additionalTasks;
  final bool isFirstLearningDay;

  bool get isComplete => tasks.isNotEmpty && tasks.every((task) => task.isDone);
}

/// Reads the small, day-scoped model used by the Home Daily Card.
///
/// The app does not have a settings use case yet, so the learn goal falls back
/// to the same 8-word starting goal used by the onboarding UI.
class DailyCardService {
  DailyCardService(this._database);

  static const defaultLearnWordsGoal = 8;
  static const maxRepeatWordsGoal = 60;
  static const supportedDifficultExerciseMask =
      supportedStoredExerciseErrorMask;

  final AppDatabase _database;

  Future<DailyCardSnapshot> load({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final today = _dayStart(currentTime);
    final tomorrow = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day + 1,
    ).millisecondsSinceEpoch;
    final enabledWordIds = (await _database.enabledWords())
        .map((word) => word.id)
        .toSet();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();

    final repeatableCount = progressRows.where((row) {
      return enabledWordIds.contains(row.id) &&
          row.repetitionStep > 0 &&
          !row.markedAsKnown &&
          !row.deletedByUser &&
          row.repetitionDate != null &&
          row.repetitionDate! <= currentTime.millisecondsSinceEpoch;
    }).length;
    final difficultCount = progressRows
        .where(
          (row) =>
              enabledWordIds.contains(row.id) &&
              normalizeExerciseErrorMask(row.trainingError) != 0 &&
              !row.markedAsKnown &&
              !row.deletedByUser,
        )
        .length;
    final fastBrainCount = progressRows.where((row) {
      return enabledWordIds.contains(row.id) &&
          row.onFastBrain &&
          !row.markedAsKnown &&
          !row.deletedByUser &&
          row.repetitionFastBrainDate != null &&
          row.repetitionFastBrainDate! <= currentTime.millisecondsSinceEpoch;
    }).length;
    final learnedTodayCount = progressRows
        .where(
          (row) =>
              enabledWordIds.contains(row.id) &&
              row.creationDate >= today &&
              row.creationDate < tomorrow &&
              !row.markedAsKnown &&
              !row.deletedByUser,
        )
        .length;
    final visit = await _ensureVisit(
      today: today,
      repeatableCount: repeatableCount,
      fastBrainCount: fastBrainCount,
      difficultCount: difficultCount,
    );

    final tasks = <DailyTaskSnapshot>[
      if (visit.repeatWordsGoal != 0)
        DailyTaskSnapshot(
          type: DailyTaskType.repeat,
          completed: visit.repeatedWordsCount,
          count: visit.repeatWordsGoal,
        ),
      DailyTaskSnapshot(
        type: DailyTaskType.learn,
        completed: visit.learnedWordsCount,
        count: visit.learnWordsGoal,
      ),
      if (visit.trainWordsGoal != 0)
        DailyTaskSnapshot(
          type: DailyTaskType.train,
          completed: visit.trainedWordsCount,
          count: visit.trainWordsGoal,
        ),
      if (visit.difficultWordsGoal != 0)
        DailyTaskSnapshot(
          type: DailyTaskType.difficult,
          completed: visit.difficultWordsTrainedCount,
          count: visit.difficultWordsGoal,
        ),
    ];

    final finishedVisitCount = await (_database.select(
      _database.visitModels,
    )..where((row) => row.atLeastOneTaskFinished.equals(true))).get();
    final isFirstLearningDay =
        finishedVisitCount.isEmpty ||
        (finishedVisitCount.length == 1 &&
            finishedVisitCount.single.date == today);

    return DailyCardSnapshot(
      tasks: tasks,
      additionalTasks: _additionalTasks(
        learnedTodayCount: learnedTodayCount,
        fastBrainCount: fastBrainCount,
        difficultCount: difficultCount,
      ),
      isFirstLearningDay: isFirstLearningDay,
    );
  }

  Future<VisitRow> _ensureVisit({
    required int today,
    required int repeatableCount,
    required int fastBrainCount,
    required int difficultCount,
  }) {
    final learnGoal = defaultLearnWordsGoal;
    final repeatGoal = repeatableCount == 0
        ? 0
        : repeatableCount.clamp(1, maxRepeatWordsGoal).toInt();
    final trainGoal = fastBrainCount >= learnGoal ? learnGoal : 0;
    final difficultGoal = difficultCount >= learnGoal ? learnGoal : 0;

    return _database.transaction(() async {
      final existing = await (_database.select(
        _database.visitModels,
      )..where((row) => row.date.equals(today))).getSingleOrNull();
      if (existing == null) {
        final areGoalsFinished = areDailyTaskGoalsFinished(
          repeatWordsGoal: repeatGoal,
          repeatedWordsCount: 0,
          learnWordsGoal: learnGoal,
          learnedWordsCount: 0,
          trainWordsGoal: trainGoal,
          trainedWordsCount: 0,
          difficultWordsGoal: difficultGoal,
          difficultWordsTrainedCount: 0,
        );
        final id = await _database
            .into(_database.visitModels)
            .insert(
              VisitModelsCompanion.insert(
                date: today,
                repeatWordsGoal: Value(repeatGoal),
                learnWordsGoal: Value(learnGoal),
                trainWordsGoal: Value(trainGoal),
                difficultWordsGoal: Value(difficultGoal),
                areDailyTasksFinished: Value(areGoalsFinished),
              ),
            );
        return (_database.select(
          _database.visitModels,
        )..where((row) => row.id.equals(id))).getSingle();
      }

      if (existing.learnWordsGoal != 0) {
        final areGoalsFinished = areDailyTaskGoalsFinished(
          repeatWordsGoal: existing.repeatWordsGoal,
          repeatedWordsCount: existing.repeatedWordsCount,
          learnWordsGoal: existing.learnWordsGoal,
          learnedWordsCount: existing.learnedWordsCount,
          trainWordsGoal: existing.trainWordsGoal,
          trainedWordsCount: existing.trainedWordsCount,
          difficultWordsGoal: existing.difficultWordsGoal,
          difficultWordsTrainedCount: existing.difficultWordsTrainedCount,
        );
        if (existing.areDailyTasksFinished == areGoalsFinished) {
          return existing;
        }
        await (_database.update(
          _database.visitModels,
        )..where((row) => row.id.equals(existing.id))).write(
          VisitModelsCompanion(areDailyTasksFinished: Value(areGoalsFinished)),
        );
        return (_database.select(
          _database.visitModels,
        )..where((row) => row.id.equals(existing.id))).getSingle();
      }

      final areGoalsFinished = areDailyTaskGoalsFinished(
        repeatWordsGoal: repeatGoal,
        repeatedWordsCount: existing.repeatedWordsCount,
        learnWordsGoal: learnGoal,
        learnedWordsCount: existing.learnedWordsCount,
        trainWordsGoal: trainGoal,
        trainedWordsCount: existing.trainedWordsCount,
        difficultWordsGoal: difficultGoal,
        difficultWordsTrainedCount: existing.difficultWordsTrainedCount,
      );
      await (_database.update(
        _database.visitModels,
      )..where((row) => row.id.equals(existing.id))).write(
        VisitModelsCompanion(
          repeatWordsGoal: Value(repeatGoal),
          learnWordsGoal: Value(learnGoal),
          trainWordsGoal: Value(trainGoal),
          difficultWordsGoal: Value(difficultGoal),
          areDailyTasksFinished: Value(areGoalsFinished),
        ),
      );
      return (_database.select(
        _database.visitModels,
      )..where((row) => row.id.equals(existing.id))).getSingle();
    });
  }

  List<DailyTaskType> _additionalTasks({
    required int learnedTodayCount,
    required int fastBrainCount,
    required int difficultCount,
  }) {
    return [
      DailyTaskType.learn,
      if (learnedTodayCount > 0) DailyTaskType.repeat,
      if (fastBrainCount >= 4) DailyTaskType.train,
      if (difficultCount >= 4) DailyTaskType.difficult,
    ];
  }

  static int _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}
