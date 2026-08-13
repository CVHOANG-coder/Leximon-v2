import 'package:drift/drift.dart';

import '../local/app_database.dart';
import 'practice_session_service.dart';

class IpaProgressService {
  const IpaProgressService(this._database);

  final AppDatabase _database;

  Future<Map<String, IpaSoundProgressRow>> loadAll() async {
    await PracticeSessionService(_database).reconcileIpaAndReadingProgress();
    final rows = await _database.select(_database.ipaSoundProgressModels).get();
    return {for (final row in rows) row.symbol: row};
  }

  Future<void> recordOpened(String symbol, {DateTime? now}) {
    return _database.transaction(() async {
      final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
      final existing = await (_database.select(
        _database.ipaSoundProgressModels,
      )..where((row) => row.symbol.equals(symbol))).getSingleOrNull();
      await _database
          .into(_database.ipaSoundProgressModels)
          .insertOnConflictUpdate(
            IpaSoundProgressModelsCompanion.insert(
              symbol: symbol,
              startedAt: existing?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(existing?.completedAt),
              practiceCount: Value(existing?.practiceCount ?? 0),
            ),
          );
    });
  }

  Future<void> recordPracticed(String symbol, {DateTime? now}) {
    return _database.transaction(() async {
      final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
      final existing = await (_database.select(
        _database.ipaSoundProgressModels,
      )..where((row) => row.symbol.equals(symbol))).getSingleOrNull();
      await _database
          .into(_database.ipaSoundProgressModels)
          .insertOnConflictUpdate(
            IpaSoundProgressModelsCompanion.insert(
              symbol: symbol,
              startedAt: existing?.startedAt ?? timestamp,
              updatedAt: timestamp,
              completedAt: Value(existing?.completedAt ?? timestamp),
              practiceCount: Value((existing?.practiceCount ?? 0) + 1),
            ),
          );
      if (existing?.completedAt == null) {
        await PracticeSessionService(_database).recordCompleted(
          skill: PracticeSessionSkill.pronunciation,
          contentId: symbol,
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            existing?.startedAt ?? timestamp,
          ),
          completedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        );
      }
    });
  }
}
