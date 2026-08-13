import '../local/app_database.dart';

class ProgressDashboardSnapshot {
  const ProgressDashboardSnapshot({
    required this.totalWords,
    required this.progressedWords,
    required this.masteredWords,
    required this.currentStreak,
    required this.weekActivity,
    required this.weekSessionCount,
    required this.activeDaysThisMonth,
    required this.elapsedDaysThisMonth,
    required this.monthActivityLevels,
    required this.monthLabel,
  });

  factory ProgressDashboardSnapshot.empty() {
    return const ProgressDashboardSnapshot(
      totalWords: 0,
      progressedWords: 0,
      masteredWords: 0,
      currentStreak: 0,
      weekActivity: [0, 0, 0, 0, 0, 0, 0],
      weekSessionCount: 0,
      activeDaysThisMonth: 0,
      elapsedDaysThisMonth: 0,
      monthActivityLevels: [],
      monthLabel: 'Tháng này',
    );
  }

  final int totalWords;
  final int progressedWords;
  final int masteredWords;
  final int currentStreak;
  final List<int> weekActivity;
  final int weekSessionCount;
  final int activeDaysThisMonth;
  final int elapsedDaysThisMonth;
  final List<int> monthActivityLevels;
  final String monthLabel;

  double get overallProgress => totalWords == 0
      ? 0
      : (progressedWords / totalWords).clamp(0, 1).toDouble();

  int get weekActivityTotal =>
      weekActivity.fold(0, (sum, value) => sum + value);

  int get missedDaysThisMonth => (elapsedDaysThisMonth - activeDaysThisMonth)
      .clamp(0, elapsedDaysThisMonth)
      .toInt();

  List<double> get weekActivityRatios {
    final maxActivity = weekActivity.fold<int>(
      0,
      (maxValue, value) => value > maxValue ? value : maxValue,
    );
    if (maxActivity == 0) return List<double>.filled(7, 0);
    return [
      for (final value in weekActivity)
        (value / maxActivity).clamp(0, 1).toDouble(),
    ];
  }
}

class ProgressDashboardService {
  ProgressDashboardService(this._database);

  final AppDatabase _database;

  Future<ProgressDashboardSnapshot> load() async {
    final now = DateTime.now();
    final today = _dayStart(now);
    final words = await _database.enabledWords();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressByWordId = {for (final row in progressRows) row.id: row};

    var progressedWords = 0;
    var masteredWords = 0;
    for (final word in words) {
      final progress = progressByWordId[word.id];
      if (progress == null || progress.deletedByUser) continue;
      if (progress.trainingProgress > 0 ||
          progress.learnedDate != null ||
          progress.markedAsKnown) {
        progressedWords++;
      }
      if (progress.learnedDate != null || progress.markedAsKnown) {
        masteredWords++;
      }
    }

    final visits = await _database.select(_database.visitModels).get();
    final visitByDate = {for (final visit in visits) visit.date: visit};
    final practiceSessions = await _database
        .select(_database.practiceSessionHistoryModels)
        .get();
    final activeDayStarts = <int>{
      for (final visit in visits)
        if (visit.atLeastOneTaskFinished) visit.date,
      for (final session in practiceSessions)
        if (session.status == 'completed')
          _dayStart(DateTime.fromMillisecondsSinceEpoch(session.completedAt)),
    };
    final weekStart = today - (now.weekday - 1) * _dayMilliseconds;
    final weekActivity = [
      for (var index = 0; index < 7; index++)
        _activityFor(visitByDate[weekStart + index * _dayMilliseconds]),
    ];

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthDays = monthEnd.day;
    final monthActivityCounts = [
      for (var day = 1; day <= monthDays; day++)
        _activityFor(
          visitByDate[_dayStart(DateTime(now.year, now.month, day))],
        ),
    ];
    final monthMax = monthActivityCounts.fold<int>(
      0,
      (maxValue, value) => value > maxValue ? value : maxValue,
    );
    final monthActivityLevels = [
      for (final count in monthActivityCounts)
        count == 0 || monthMax == 0
            ? 0
            : (count / monthMax * 3).ceil().clamp(1, 3).toInt(),
    ];
    final activeDaysThisMonth = activeDayStarts
        .where(
          (date) => date >= monthStart.millisecondsSinceEpoch && date <= today,
        )
        .length;

    var currentStreak = 0;
    var streakDay = today;
    while (activeDayStarts.contains(streakDay)) {
      currentStreak++;
      streakDay -= _dayMilliseconds;
    }
    if (currentStreak == 0) {
      streakDay = today - _dayMilliseconds;
      while (activeDayStarts.contains(streakDay)) {
        currentStreak++;
        streakDay -= _dayMilliseconds;
      }
    }

    final weekEnd = weekStart + 7 * _dayMilliseconds;
    final sessions = await _database.select(_database.learningSessions).get();
    final weekSessionCount = sessions.where((session) {
      final completedAt = session.completedAt;
      return session.status == 1 &&
          completedAt != null &&
          completedAt >= weekStart &&
          completedAt < weekEnd;
    }).length;

    return ProgressDashboardSnapshot(
      totalWords: words.length,
      progressedWords: progressedWords,
      masteredWords: masteredWords,
      currentStreak: currentStreak,
      weekActivity: weekActivity,
      weekSessionCount: weekSessionCount,
      activeDaysThisMonth: activeDaysThisMonth,
      elapsedDaysThisMonth: now.day,
      monthActivityLevels: monthActivityLevels,
      monthLabel: 'Tháng ${now.month}',
    );
  }

  int _activityFor(VisitRow? visit) {
    if (visit == null) return 0;
    return visit.repeatedWordsCount +
        visit.learnedWordsCount +
        visit.trainedWordsCount +
        visit.difficultWordsTrainedCount;
  }

  int _dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  static const _dayMilliseconds = Duration.millisecondsPerDay;
}
