import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/progress_dashboard_service.dart';

void main() {
  late AppDatabase database;
  late ProgressDashboardService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = ProgressDashboardService(database);
  });

  tearDown(() => database.close());

  test(
    'loads dashboard metrics from local progress, visits, and sessions',
    () async {
      final now = DateTime.now();
      final nowMillis = now.millisecondsSinceEpoch;
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day - 1,
      ).millisecondsSinceEpoch;

      await database.batch((batch) {
        batch.insertAll(database.wordModels, [
          WordModelsCompanion.insert(
            id: 1,
            topicId: 10,
            writing: 'one',
            translation: 'một',
            isEnabled: true,
            priority: 1,
            level: 1,
          ),
          WordModelsCompanion.insert(
            id: 2,
            topicId: 10,
            writing: 'two',
            translation: 'hai',
            isEnabled: true,
            priority: 1,
            level: 1,
          ),
        ]);
      });
      await database.batch((batch) {
        batch.insertAll(database.learningProgressModels, [
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: nowMillis,
            learnedDate: Value(nowMillis),
          ),
          LearningProgressModelsCompanion.insert(
            id: const Value(2),
            creationDate: nowMillis,
            trainingProgress: const Value(2),
          ),
        ]);
      });
      await database
          .into(database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: today,
              atLeastOneTaskFinished: const Value(true),
              learnedWordsCount: const Value(2),
              trainedWordsCount: const Value(1),
            ),
          );
      await database
          .into(database.learningSessions)
          .insert(
            LearningSessionsCompanion.insert(
              id: 'session-1',
              requiredMask: 1,
              originalExerciseCount: 1,
              startedAt: nowMillis,
              status: const Value(1),
              completedAt: Value(nowMillis),
            ),
          );
      await database
          .into(database.practiceSessionHistoryModels)
          .insert(
            PracticeSessionHistoryModelsCompanion.insert(
              skill: 'listening',
              contentId: '10',
              startedAt: yesterday,
              completedAt: yesterday,
            ),
          );

      final snapshot = await service.load();

      expect(snapshot.totalWords, 2);
      expect(snapshot.progressedWords, 2);
      expect(snapshot.masteredWords, 1);
      expect(snapshot.currentStreak, 2);
      expect(snapshot.weekSessionCount, 1);
      expect(snapshot.weekActivity[now.weekday - 1], 3);
      expect(snapshot.activeDaysThisMonth, now.day == 1 ? 1 : 2);
      expect(snapshot.monthActivityLevels[now.day - 1], 3);
    },
  );
}
