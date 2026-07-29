import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/practice_exercise.dart';

class ProfileStatisticsSnapshot {
  const ProfileStatisticsSnapshot({
    required this.trackedTopicCount,
    required this.weekCorrectAnswerCount,
    required this.weekAnswerCount,
    required this.averageDailyUsage,
    required this.usageDayCount,
  });

  final int trackedTopicCount;
  final int weekCorrectAnswerCount;
  final int weekAnswerCount;
  final Duration averageDailyUsage;
  final int usageDayCount;

  double? get weekAccuracy {
    if (weekAnswerCount == 0) return null;
    return (weekCorrectAnswerCount / weekAnswerCount).clamp(0, 1).toDouble();
  }
}

class ProfileStatisticsService {
  ProfileStatisticsService(this._database);

  final AppDatabase _database;

  Future<ProfileStatisticsSnapshot> load({
    required int trackedTopicCount,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final weekStart = today.subtract(Duration(days: currentTime.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final answerRows =
        await (_database.select(_database.sessionExercises)..where(
              (row) =>
                  row.answeredAt.isBiggerOrEqualValue(
                    weekStart.millisecondsSinceEpoch,
                  ) &
                  row.answeredAt.isSmallerThanValue(
                    weekEnd.millisecondsSinceEpoch,
                  ),
            ))
            .get();
    final answered = answerRows.where(
      (row) => row.answer != ExerciseAnswerState.notAnswered.index,
    );
    final weekAnswerCount = answered.length;
    final weekCorrectAnswerCount = answered
        .where((row) => row.answer == ExerciseAnswerState.correct.index)
        .length;

    final usageWindowStart = today.subtract(const Duration(days: 6));
    final usageWindowEnd = today.add(const Duration(days: 1));
    final allUsageRows = await _database.select(_database.appUsageDays).get();
    final usageRows = allUsageRows.where(
      (row) =>
          row.date >= usageWindowStart.millisecondsSinceEpoch &&
          row.date < usageWindowEnd.millisecondsSinceEpoch,
    );
    final totalUsageMilliseconds = usageRows.fold<int>(
      0,
      (sum, row) => sum + row.foregroundMilliseconds,
    );
    final firstRecordedDate = allUsageRows.isEmpty
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            allUsageRows
                .map((row) => row.date)
                .reduce((first, date) => date < first ? date : first),
          );
    final usageDayCount = firstRecordedDate == null
        ? 0
        : (_calendarDayDifference(firstRecordedDate, today) + 1)
              .clamp(1, 7)
              .toInt();

    return ProfileStatisticsSnapshot(
      trackedTopicCount: trackedTopicCount,
      weekCorrectAnswerCount: weekCorrectAnswerCount,
      weekAnswerCount: weekAnswerCount,
      averageDailyUsage: Duration(
        milliseconds: usageDayCount == 0
            ? 0
            : totalUsageMilliseconds ~/ usageDayCount,
      ),
      usageDayCount: usageDayCount,
    );
  }

  int _calendarDayDifference(DateTime from, DateTime to) {
    final utcFrom = DateTime.utc(from.year, from.month, from.day);
    final utcTo = DateTime.utc(to.year, to.month, to.day);
    return utcTo.difference(utcFrom).inDays;
  }
}
