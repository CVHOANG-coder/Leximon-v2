import 'package:drift/drift.dart';

import '../local/app_database.dart';

enum ListeningLessonStatus { notStarted, inProgress, completed }

class ListeningProgressService {
  const ListeningProgressService(this._database);

  final AppDatabase _database;

  Future<ListeningLessonProgressRow> startLesson({
    required int courseId,
    required int lessonId,
    required int totalChallenges,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final existing = await loadLesson(courseId: courseId, lessonId: lessonId);
    if (existing == null) {
      final row = ListeningLessonProgressModelsCompanion.insert(
        courseId: courseId,
        lessonId: lessonId,
        totalChallenges: totalChallenges,
        status: Value(ListeningLessonStatus.inProgress.index),
        startedAt: timestamp,
        updatedAt: timestamp,
      );
      await _database.into(_database.listeningLessonProgressModels).insert(row);
    } else {
      await (_database.update(_database.listeningLessonProgressModels)..where(
            (row) =>
                row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
          ))
          .write(
            ListeningLessonProgressModelsCompanion(
              totalChallenges: Value(totalChallenges),
              status: Value(
                existing.status == ListeningLessonStatus.notStarted.index
                    ? ListeningLessonStatus.inProgress.index
                    : existing.status,
              ),
              updatedAt: Value(timestamp),
            ),
          );
    }
    return (await loadLesson(courseId: courseId, lessonId: lessonId))!;
  }

  Future<ListeningLessonProgressRow?> loadLesson({
    required int courseId,
    required int lessonId,
  }) {
    return (_database.select(_database.listeningLessonProgressModels)..where(
          (row) =>
              row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
        ))
        .getSingleOrNull();
  }

  Future<Map<int, ListeningLessonProgressRow>> loadCourseLessons(
    int courseId,
  ) async {
    final rows = await (_database.select(
      _database.listeningLessonProgressModels,
    )..where((row) => row.courseId.equals(courseId))).get();
    return {for (final row in rows) row.lessonId: row};
  }

  Future<List<ListeningChallengeProgressRow>> loadChallenges({
    required int courseId,
    required int lessonId,
  }) {
    final query = _database.select(_database.listeningChallengeProgressModels)
      ..where(
        (row) => row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
      );
    query.orderBy([(row) => OrderingTerm.asc(row.position)]);
    return query.get();
  }

  Future<void> saveAttempt({
    required int courseId,
    required int lessonId,
    required int challengeId,
    required int position,
    required int totalChallenges,
    required String answer,
    required bool isCorrect,
    bool isSkipped = false,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await _database.transaction(() async {
      final challengeTable = _database.listeningChallengeProgressModels;
      final existingChallenge =
          await (_database.select(challengeTable)..where(
                (row) =>
                    row.courseId.equals(courseId) &
                    row.lessonId.equals(lessonId) &
                    row.challengeId.equals(challengeId),
              ))
              .getSingleOrNull();
      final completed = existingChallenge?.isCompleted == true || isCorrect;
      await _database
          .into(challengeTable)
          .insertOnConflictUpdate(
            ListeningChallengeProgressModelsCompanion.insert(
              courseId: courseId,
              lessonId: lessonId,
              challengeId: challengeId,
              position: position,
              isCompleted: Value(completed),
              isSkipped: Value(isSkipped && !completed),
              attemptCount: Value((existingChallenge?.attemptCount ?? 0) + 1),
              lastAnswer: Value(answer),
              updatedAt: timestamp,
              completedAt: Value(
                completed ? existingChallenge?.completedAt ?? timestamp : null,
              ),
            ),
          );

      final completedRows =
          await (_database.select(challengeTable)..where(
                (row) =>
                    row.courseId.equals(courseId) &
                    row.lessonId.equals(lessonId) &
                    row.isCompleted.equals(true),
              ))
              .get();
      final completedCount = completedRows.length;
      final lessonCompleted = completedCount >= totalChallenges;
      final nextPosition = position >= totalChallenges
          ? position
          : position + 1;
      final lessonTable = _database.listeningLessonProgressModels;
      final existingLesson =
          await (_database.select(lessonTable)..where(
                (row) =>
                    row.courseId.equals(courseId) &
                    row.lessonId.equals(lessonId),
              ))
              .getSingleOrNull();
      await _database
          .into(lessonTable)
          .insertOnConflictUpdate(
            ListeningLessonProgressModelsCompanion.insert(
              courseId: courseId,
              lessonId: lessonId,
              currentChallengePosition: Value(
                isCorrect || isSkipped
                    ? nextPosition
                    : existingLesson?.currentChallengePosition ?? position,
              ),
              completedChallenges: Value(completedCount),
              totalChallenges: totalChallenges,
              status: Value(
                lessonCompleted
                    ? ListeningLessonStatus.completed.index
                    : ListeningLessonStatus.inProgress.index,
              ),
              startedAt: existingLesson?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(
                lessonCompleted
                    ? existingLesson?.completedAt ?? timestamp
                    : null,
              ),
              activeMilliseconds: Value(
                existingLesson?.activeMilliseconds ?? 0,
              ),
            ),
          );
    });
  }

  Future<void> updateCurrentPosition({
    required int courseId,
    required int lessonId,
    required int position,
    DateTime? now,
  }) {
    return (_database.update(_database.listeningLessonProgressModels)..where(
          (row) =>
              row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
        ))
        .write(
          ListeningLessonProgressModelsCompanion(
            currentChallengePosition: Value(position),
            updatedAt: Value((now ?? DateTime.now()).millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> addActiveTime({
    required int courseId,
    required int lessonId,
    required Duration duration,
    DateTime? now,
  }) async {
    if (duration <= Duration.zero) return;
    final current = now ?? DateTime.now();
    final milliseconds = duration.inMilliseconds;
    final localMidnight = DateTime(
      current.year,
      current.month,
      current.day,
    ).millisecondsSinceEpoch;
    await _database.transaction(() async {
      final lesson = await loadLesson(courseId: courseId, lessonId: lessonId);
      if (lesson != null) {
        await (_database.update(_database.listeningLessonProgressModels)..where(
              (row) =>
                  row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
            ))
            .write(
              ListeningLessonProgressModelsCompanion(
                activeMilliseconds: Value(
                  lesson.activeMilliseconds + milliseconds,
                ),
                updatedAt: Value(current.millisecondsSinceEpoch),
              ),
            );
      }

      final dayTable = _database.listeningPracticeDays;
      final day = await (_database.select(
        dayTable,
      )..where((row) => row.date.equals(localMidnight))).getSingleOrNull();
      await _database
          .into(dayTable)
          .insertOnConflictUpdate(
            ListeningPracticeDaysCompanion.insert(
              date: Value(localMidnight),
              activeMilliseconds: Value(
                (day?.activeMilliseconds ?? 0) + milliseconds,
              ),
            ),
          );
    });
  }

  Future<Duration> activeTimeToday({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final localMidnight = DateTime(
      current.year,
      current.month,
      current.day,
    ).millisecondsSinceEpoch;
    final row = await (_database.select(
      _database.listeningPracticeDays,
    )..where((row) => row.date.equals(localMidnight))).getSingleOrNull();
    return Duration(milliseconds: row?.activeMilliseconds ?? 0);
  }
}
