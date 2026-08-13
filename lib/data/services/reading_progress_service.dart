import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import 'practice_session_service.dart';

class ReadingProgressService {
  const ReadingProgressService(this._database);

  static const completionThreshold = 80;

  final AppDatabase _database;

  Future<Map<int, ReadingStoryProgressRow>> loadAll() async {
    await PracticeSessionService(_database).reconcileIpaAndReadingProgress();
    final rows = await _database
        .select(_database.readingStoryProgressModels)
        .get();
    return {for (final row in rows) row.storyId: row};
  }

  Future<void> recordOpened(int storyId, {DateTime? now}) {
    return _database.transaction(() async {
      final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
      final existing = await (_database.select(
        _database.readingStoryProgressModels,
      )..where((row) => row.storyId.equals(storyId))).getSingleOrNull();
      await _database
          .into(_database.readingStoryProgressModels)
          .insertOnConflictUpdate(
            ReadingStoryProgressModelsCompanion.insert(
              storyId: Value(storyId),
              startedAt: existing?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(existing?.completedAt),
              viewCount: Value((existing?.viewCount ?? 0) + 1),
              maxScrollPercent: Value(existing?.maxScrollPercent ?? 0),
            ),
          );
    });
  }

  Future<void> recordScrollProgress(int storyId, int percent, {DateTime? now}) {
    return _database.transaction(() async {
      final normalized = percent.clamp(0, 100);
      final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
      final existing = await (_database.select(
        _database.readingStoryProgressModels,
      )..where((row) => row.storyId.equals(storyId))).getSingleOrNull();
      final maxPercent = math.max(existing?.maxScrollPercent ?? 0, normalized);
      final completedAt =
          existing?.completedAt ??
          (maxPercent >= completionThreshold ? timestamp : null);
      await _database
          .into(_database.readingStoryProgressModels)
          .insertOnConflictUpdate(
            ReadingStoryProgressModelsCompanion.insert(
              storyId: Value(storyId),
              startedAt: existing?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(completedAt),
              viewCount: Value(existing?.viewCount ?? 1),
              maxScrollPercent: Value(maxPercent),
            ),
          );
      if (existing?.completedAt == null && completedAt != null) {
        await PracticeSessionService(_database).recordCompleted(
          skill: PracticeSessionSkill.reading,
          contentId: storyId.toString(),
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            existing?.startedAt ?? timestamp,
          ),
          completedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
      }
    });
  }
}
