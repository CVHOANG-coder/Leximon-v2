import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../local/app_database.dart';

enum PracticeSessionSkill {
  listening,
  grammar,
  pronunciation,
  reading,
  speaking,
}

class PracticeSessionService {
  const PracticeSessionService(this._database);

  final AppDatabase _database;

  Future<void> recordCompleted({
    required PracticeSessionSkill skill,
    required String contentId,
    String? parentId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final completed = completedAt ?? DateTime.now();
    await _database
        .into(_database.practiceSessionHistoryModels)
        .insert(
          PracticeSessionHistoryModelsCompanion.insert(
            skill: skill.name,
            contentId: contentId,
            parentId: Value(parentId),
            startedAt: (startedAt ?? completed).millisecondsSinceEpoch,
            completedAt: completed.millisecondsSinceEpoch,
          ),
        );
  }

  /// Repairs rows affected by the old open/completion race. Session history is
  /// append-only, so a completed session is reliable evidence that its content
  /// progress must also be marked complete.
  Future<void> reconcileIpaAndReadingProgress() {
    return _database.transaction(() async {
      final sessions = await (_database.select(
        _database.practiceSessionHistoryModels,
      )..where((row) => row.status.equals('completed'))).get();

      for (final session in sessions) {
        if (session.skill == PracticeSessionSkill.pronunciation.name) {
          final existing =
              await (_database.select(_database.ipaSoundProgressModels)
                    ..where((row) => row.symbol.equals(session.contentId)))
                  .getSingleOrNull();
          if (existing?.completedAt != null) continue;
          await _database
              .into(_database.ipaSoundProgressModels)
              .insertOnConflictUpdate(
                IpaSoundProgressModelsCompanion.insert(
                  symbol: session.contentId,
                  startedAt: existing?.startedAt ?? session.startedAt,
                  updatedAt: existing == null
                      ? session.completedAt
                      : math.max(existing.updatedAt, session.completedAt),
                  completedAt: Value(
                    existing?.completedAt ?? session.completedAt,
                  ),
                  practiceCount: Value(
                    math.max(existing?.practiceCount ?? 0, 1),
                  ),
                ),
              );
        }

        if (session.skill == PracticeSessionSkill.reading.name) {
          final storyId = int.tryParse(session.contentId);
          if (storyId == null) continue;
          final existing = await (_database.select(
            _database.readingStoryProgressModels,
          )..where((row) => row.storyId.equals(storyId))).getSingleOrNull();
          if (existing?.completedAt != null) continue;
          await _database
              .into(_database.readingStoryProgressModels)
              .insertOnConflictUpdate(
                ReadingStoryProgressModelsCompanion.insert(
                  storyId: Value(storyId),
                  startedAt: existing?.startedAt ?? session.startedAt,
                  updatedAt: existing == null
                      ? session.completedAt
                      : math.max(existing.updatedAt, session.completedAt),
                  completedAt: Value(
                    existing?.completedAt ?? session.completedAt,
                  ),
                  viewCount: Value(math.max(existing?.viewCount ?? 0, 1)),
                  maxScrollPercent: Value(
                    math.max(existing?.maxScrollPercent ?? 0, 80),
                  ),
                ),
              );
        }
      }
    });
  }
}
