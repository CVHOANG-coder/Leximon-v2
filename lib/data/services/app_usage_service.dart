import 'dart:async';

import 'package:drift/drift.dart';

import '../local/app_database.dart';

/// Records only the time the app spends in the foreground.
///
/// A periodic checkpoint limits data loss if the process is terminated without
/// receiving a lifecycle callback. Intervals crossing midnight are split into
/// the corresponding local calendar days.
class AppUsageService {
  AppUsageService(
    this._database, {
    Duration checkpointInterval = const Duration(seconds: 30),
  }) : _checkpointInterval = checkpointInterval;

  final AppDatabase _database;
  final Duration _checkpointInterval;

  DateTime? _activeSince;
  Timer? _checkpointTimer;
  Future<void> _pendingWrite = Future<void>.value();

  bool get isTracking => _activeSince != null;

  Future<void> resume({DateTime? at}) async {
    if (_activeSince != null) return;
    _activeSince = at ?? DateTime.now();
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer.periodic(
      _checkpointInterval,
      (_) => unawaited(checkpoint()),
    );
  }

  Future<void> pause({DateTime? at}) {
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    final startedAt = _activeSince;
    if (startedAt == null) return _pendingWrite;

    final endedAt = at ?? DateTime.now();
    _activeSince = null;
    return _queueInterval(startedAt, endedAt);
  }

  Future<void> checkpoint({DateTime? at}) {
    final startedAt = _activeSince;
    if (startedAt == null) return _pendingWrite;

    final endedAt = at ?? DateTime.now();
    _activeSince = endedAt;
    return _queueInterval(startedAt, endedAt);
  }

  Future<void> recordInterval({
    required DateTime startedAt,
    required DateTime endedAt,
  }) {
    return _queueInterval(startedAt, endedAt);
  }

  Future<void> _queueInterval(DateTime startedAt, DateTime endedAt) {
    if (!endedAt.isAfter(startedAt)) return _pendingWrite;
    _pendingWrite = _pendingWrite.then(
      (_) => _persistInterval(startedAt, endedAt),
    );
    return _pendingWrite;
  }

  Future<void> _persistInterval(DateTime startedAt, DateTime endedAt) async {
    var cursor = startedAt;
    while (cursor.isBefore(endedAt)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = endedAt.isBefore(nextMidnight)
          ? endedAt
          : nextMidnight;
      final duration = segmentEnd.difference(cursor).inMilliseconds;
      if (duration > 0) {
        await _addDuration(
          date: DateTime(cursor.year, cursor.month, cursor.day),
          milliseconds: duration,
        );
      }
      cursor = segmentEnd;
    }
  }

  Future<void> _addDuration({
    required DateTime date,
    required int milliseconds,
  }) {
    final day = date.millisecondsSinceEpoch;
    return _database.transaction(() async {
      final existing = await (_database.select(
        _database.appUsageDays,
      )..where((row) => row.date.equals(day))).getSingleOrNull();
      if (existing == null) {
        await _database
            .into(_database.appUsageDays)
            .insert(
              AppUsageDaysCompanion.insert(
                date: Value(day),
                foregroundMilliseconds: Value(milliseconds),
              ),
            );
        return;
      }

      await (_database.update(
        _database.appUsageDays,
      )..where((row) => row.date.equals(day))).write(
        AppUsageDaysCompanion(
          foregroundMilliseconds: Value(
            existing.foregroundMilliseconds + milliseconds,
          ),
        ),
      );
    });
  }

  void dispose() {
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    unawaited(pause());
  }
}
