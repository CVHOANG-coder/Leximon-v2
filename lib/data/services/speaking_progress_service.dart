import 'package:drift/drift.dart';

import '../local/app_database.dart';
import 'practice_session_service.dart';

enum SpeakingLessonStatus { notStarted, inProgress, completed }

class SpeakingProgressService {
  const SpeakingProgressService(this._database);

  final AppDatabase _database;

  Future<SpeakingLessonProgressRow> startLesson({
    required int courseId,
    required int lessonId,
    required int totalSentences,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final existing = await loadLesson(courseId: courseId, lessonId: lessonId);
    await _database
        .into(_database.speakingLessonProgressModels)
        .insertOnConflictUpdate(
          SpeakingLessonProgressModelsCompanion.insert(
            courseId: courseId,
            lessonId: lessonId,
            currentSentencePosition: Value(
              existing?.currentSentencePosition ?? 1,
            ),
            completedSentences: Value(existing?.completedSentences ?? 0),
            totalSentences: totalSentences,
            status: Value(
              existing?.status ?? SpeakingLessonStatus.inProgress.index,
            ),
            startedAt: existing?.startedAt ?? timestamp,
            updatedAt: timestamp,
            completedAt: Value(existing?.completedAt),
          ),
        );
    return (await loadLesson(courseId: courseId, lessonId: lessonId))!;
  }

  Future<SpeakingLessonProgressRow?> loadLesson({
    required int courseId,
    required int lessonId,
  }) {
    return (_database.select(_database.speakingLessonProgressModels)..where(
          (row) =>
              row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
        ))
        .getSingleOrNull();
  }

  Future<Map<int, SpeakingLessonProgressRow>> loadCourseLessons(
    int courseId,
  ) async {
    final rows = await (_database.select(
      _database.speakingLessonProgressModels,
    )..where((row) => row.courseId.equals(courseId))).get();
    return {for (final row in rows) row.lessonId: row};
  }

  Future<List<SpeakingSentenceProgressRow>> loadSentences({
    required int courseId,
    required int lessonId,
  }) {
    final query = _database.select(_database.speakingSentenceProgressModels)
      ..where(
        (row) => row.courseId.equals(courseId) & row.lessonId.equals(lessonId),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.position)]);
    return query.get();
  }

  Future<void> saveAssessment({
    required int courseId,
    required int lessonId,
    required int challengeId,
    required int position,
    required int totalSentences,
    required String transcript,
    required int accuracyPercent,
    required bool isCorrect,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await _database.transaction(() async {
      final sentenceTable = _database.speakingSentenceProgressModels;
      final existingSentence =
          await (_database.select(sentenceTable)..where(
                (row) =>
                    row.courseId.equals(courseId) &
                    row.lessonId.equals(lessonId) &
                    row.challengeId.equals(challengeId),
              ))
              .getSingleOrNull();
      await _database
          .into(sentenceTable)
          .insertOnConflictUpdate(
            SpeakingSentenceProgressModelsCompanion.insert(
              courseId: courseId,
              lessonId: lessonId,
              challengeId: challengeId,
              position: position,
              isCompleted: const Value(true),
              isCorrect: Value(isCorrect),
              attemptCount: Value((existingSentence?.attemptCount ?? 0) + 1),
              lastTranscript: Value(transcript),
              accuracyPercent: Value(accuracyPercent.clamp(0, 100)),
              updatedAt: timestamp,
              completedAt: Value(existingSentence?.completedAt ?? timestamp),
            ),
          );

      final completedRows =
          await (_database.select(sentenceTable)..where(
                (row) =>
                    row.courseId.equals(courseId) &
                    row.lessonId.equals(lessonId) &
                    row.isCompleted.equals(true),
              ))
              .get();
      final completedCount = completedRows.length;
      final lessonCompleted = completedCount >= totalSentences;
      final lessonTable = _database.speakingLessonProgressModels;
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
            SpeakingLessonProgressModelsCompanion.insert(
              courseId: courseId,
              lessonId: lessonId,
              currentSentencePosition: Value(
                position >= totalSentences ? position : position + 1,
              ),
              completedSentences: Value(completedCount),
              totalSentences: totalSentences,
              status: Value(
                lessonCompleted
                    ? SpeakingLessonStatus.completed.index
                    : SpeakingLessonStatus.inProgress.index,
              ),
              startedAt: existingLesson?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(
                lessonCompleted
                    ? existingLesson?.completedAt ?? timestamp
                    : null,
              ),
            ),
          );

      final wasCompleted =
          existingLesson?.status == SpeakingLessonStatus.completed.index;
      if (lessonCompleted && !wasCompleted) {
        await PracticeSessionService(_database).recordCompleted(
          skill: PracticeSessionSkill.speaking,
          contentId: lessonId.toString(),
          parentId: courseId.toString(),
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            existingLesson?.startedAt ?? timestamp,
          ),
          completedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
      }
    });
  }
}
