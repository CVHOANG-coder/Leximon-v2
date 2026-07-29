import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/app_usage_service.dart';

void main() {
  late AppDatabase database;
  late AppUsageService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = AppUsageService(
      database,
      checkpointInterval: const Duration(days: 1),
    );
  });

  tearDown(() async {
    service.dispose();
    await database.close();
  });

  test('splits foreground time at local midnight', () async {
    final firstDay = DateTime(2026, 7, 28, 23, 59, 30);
    final secondDay = DateTime(2026, 7, 29, 0, 1);

    await service.recordInterval(startedAt: firstDay, endedAt: secondDay);

    final rows = await database.select(database.appUsageDays).get();
    rows.sort((left, right) => left.date.compareTo(right.date));
    expect(rows, hasLength(2));
    expect(rows[0].date, DateTime(2026, 7, 28).millisecondsSinceEpoch);
    expect(rows[0].foregroundMilliseconds, 30 * 1000);
    expect(rows[1].date, DateTime(2026, 7, 29).millisecondsSinceEpoch);
    expect(rows[1].foregroundMilliseconds, 60 * 1000);
  });

  test(
    'checkpoints and pause do not double-count an active interval',
    () async {
      final start = DateTime(2026, 7, 29, 8);

      await service.resume(at: start);
      await service.checkpoint(at: start.add(const Duration(seconds: 10)));
      await service.pause(at: start.add(const Duration(seconds: 15)));

      final row = await database.select(database.appUsageDays).getSingle();
      expect(row.foregroundMilliseconds, 15 * 1000);
      expect(service.isTracking, isFalse);
    },
  );
}
