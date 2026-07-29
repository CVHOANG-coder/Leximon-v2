import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  test('nextLocalMidnight keeps the device-local calendar date', () {
    final currentLocalTime = DateTime(2026, 7, 29, 23, 59, 58, 500);

    final nextMidnight = nextLocalMidnight(currentLocalTime);

    expect(nextMidnight, DateTime(2026, 7, 30));
    expect(
      nextMidnight.difference(currentLocalTime),
      const Duration(milliseconds: 1500),
    );
    expect(nextMidnight.isUtc, isFalse);
  });

  test('nextLocalMidnight rolls over month and year boundaries', () {
    expect(
      nextLocalMidnight(DateTime(2026, 12, 31, 23, 59, 59)),
      DateTime(2027),
    );
  });
}
