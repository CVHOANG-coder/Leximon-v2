import 'package:drift/drift.dart';

import '../local/app_database.dart';

enum DailyTaskType { repeat, learn, train, difficult }

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

  final AppDatabase _database;

  Future<DailyCardSnapshot> load() async {
    final now = DateTime.now();
    final today = _dayStart(now);
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();

    final repeatableCount = progressRows.where((row) {
      return row.repetitionStep > 0 &&
          !row.markedAsKnown &&
          !row.deletedByUser &&
          row.repetitionDate != null &&
          row.repetitionDate! <= now.millisecondsSinceEpoch;
    }).length;
    final difficultCount = progressRows
        .where(
          (row) =>
              row.trainingError > 0 && !row.markedAsKnown && !row.deletedByUser,
        )
        .length;
    final fastBrainCount = progressRows.where((row) {
      return row.onFastBrain &&
          !row.deletedByUser &&
          row.repetitionFastBrainDate != null &&
          row.repetitionFastBrainDate! <= now.millisecondsSinceEpoch;
    }).length;
    final learnedWordCount = progressRows
        .where(
          (row) =>
              row.learnedDate != null &&
              !row.markedAsKnown &&
              !row.deletedByUser,
        )
        .length;
    final existing = await (_database.select(
      _database.visitModels,
    )..where((row) => row.date.equals(today))).getSingleOrNull();
    final visit = await _ensureVisit(
      today: today,
      existing: existing,
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
        learnedWordCount: learnedWordCount,
        fastBrainCount: fastBrainCount,
        difficultCount: difficultCount,
      ),
      isFirstLearningDay: isFirstLearningDay,
    );
  }

  Future<VisitRow> _ensureVisit({
    required int today,
    required VisitRow? existing,
    required int repeatableCount,
    required int fastBrainCount,
    required int difficultCount,
  }) async {
    final learnGoal = defaultLearnWordsGoal;
    final repeatGoal = repeatableCount == 0
        ? 0
        : repeatableCount.clamp(1, maxRepeatWordsGoal).toInt();
    final trainGoal = fastBrainCount >= learnGoal ? learnGoal : 0;
    final difficultGoal = difficultCount >= learnGoal ? learnGoal : 0;

    if (existing == null) {
      final id = await _database
          .into(_database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: today,
              repeatWordsGoal: Value(repeatGoal),
              learnWordsGoal: Value(learnGoal),
              trainWordsGoal: Value(trainGoal),
              difficultWordsGoal: Value(difficultGoal),
            ),
          );
      return (_database.select(
        _database.visitModels,
      )..where((row) => row.id.equals(id))).getSingle();
    }

    if (existing.learnWordsGoal != 0) return existing;

    await (_database.update(
      _database.visitModels,
    )..where((row) => row.id.equals(existing.id))).write(
      VisitModelsCompanion(
        repeatWordsGoal: Value(repeatGoal),
        learnWordsGoal: Value(learnGoal),
        trainWordsGoal: Value(trainGoal),
        difficultWordsGoal: Value(difficultGoal),
      ),
    );
    return (_database.select(
      _database.visitModels,
    )..where((row) => row.id.equals(existing.id))).getSingle();
  }

  List<DailyTaskType> _additionalTasks({
    required int learnedWordCount,
    required int fastBrainCount,
    required int difficultCount,
  }) {
    return [
      DailyTaskType.learn,
      if (learnedWordCount > 0) DailyTaskType.repeat,
      if (fastBrainCount >= 4) DailyTaskType.train,
      if (difficultCount >= 4) DailyTaskType.difficult,
    ];
  }

  static int _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}
