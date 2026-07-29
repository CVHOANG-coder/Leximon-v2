import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/profile_statistics_service.dart';

void main() {
  late AppDatabase database;
  late ProfileStatisticsService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = ProfileStatisticsService(database);
  });

  tearDown(() => database.close());

  test(
    'calculates current-week accuracy and seven-day usage average',
    () async {
      final now = DateTime(2026, 7, 29, 12);
      final monday = DateTime(2026, 7, 27, 9);
      final previousWeek = DateTime(2026, 7, 26, 23, 59);

      await database.batch((batch) {
        batch.insertAll(database.sessionExercises, [
          _answer(id: 1, answer: ExerciseAnswerState.correct, at: monday),
          _answer(
            id: 2,
            answer: ExerciseAnswerState.wrong,
            at: monday.add(const Duration(minutes: 1)),
          ),
          _answer(
            id: 3,
            answer: ExerciseAnswerState.skipped,
            at: monday.add(const Duration(minutes: 2)),
          ),
          _answer(id: 4, answer: ExerciseAnswerState.correct, at: previousWeek),
        ]);
        batch.insertAll(database.appUsageDays, [
          AppUsageDaysCompanion.insert(
            date: Value(DateTime(2026, 7, 29).millisecondsSinceEpoch),
            foregroundMilliseconds: const Value(20 * 60 * 1000),
          ),
          AppUsageDaysCompanion.insert(
            date: Value(DateTime(2026, 7, 28).millisecondsSinceEpoch),
            foregroundMilliseconds: const Value(40 * 60 * 1000),
          ),
          AppUsageDaysCompanion.insert(
            date: Value(DateTime(2026, 7, 21).millisecondsSinceEpoch),
            foregroundMilliseconds: const Value(90 * 60 * 1000),
          ),
        ]);
      });

      final snapshot = await service.load(trackedTopicCount: 4, now: now);

      expect(snapshot.trackedTopicCount, 4);
      expect(snapshot.weekCorrectAnswerCount, 1);
      expect(snapshot.weekAnswerCount, 3);
      expect(snapshot.weekAccuracy, closeTo(1 / 3, .0001));
      expect(snapshot.usageDayCount, 7);
      expect(
        snapshot.averageDailyUsage.inMilliseconds,
        const Duration(minutes: 60).inMilliseconds ~/ 7,
      );
    },
  );

  test('returns no accuracy when the week has no answered exercise', () async {
    final snapshot = await service.load(
      trackedTopicCount: 0,
      now: DateTime(2026, 7, 29),
    );

    expect(snapshot.weekAccuracy, isNull);
    expect(snapshot.averageDailyUsage, Duration.zero);
  });

  test('includes days without usage in the daily average', () async {
    await database
        .into(database.appUsageDays)
        .insert(
          AppUsageDaysCompanion.insert(
            date: Value(DateTime(2026, 7, 27).millisecondsSinceEpoch),
            foregroundMilliseconds: const Value(30 * 60 * 1000),
          ),
        );

    final snapshot = await service.load(
      trackedTopicCount: 0,
      now: DateTime(2026, 7, 29),
    );

    expect(snapshot.usageDayCount, 3);
    expect(snapshot.averageDailyUsage, const Duration(minutes: 10));
  });
}

SessionExercisesCompanion _answer({
  required int id,
  required ExerciseAnswerState answer,
  required DateTime at,
}) {
  return SessionExercisesCompanion.insert(
    id: Value(id),
    sessionId: 'session-$id',
    wordId: id,
    exerciseType: 0,
    orderIndex: 0,
    answer: Value(answer.index),
    answeredAt: Value(at.millisecondsSinceEpoch),
  );
}
