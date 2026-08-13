import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/speaking_progress_service.dart';

void main() {
  late AppDatabase database;
  late SpeakingProgressService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = SpeakingProgressService(database);
  });

  tearDown(() => database.close());

  test(
    'counts one speaking session only after every sentence is checked',
    () async {
      final now = DateTime(2026, 8, 13, 10);
      await service.startLesson(
        courseId: 6,
        lessonId: 470,
        totalSentences: 2,
        now: now,
      );
      await service.saveAssessment(
        courseId: 6,
        lessonId: 470,
        challengeId: 1,
        position: 1,
        totalSentences: 2,
        transcript: 'good morning',
        accuracyPercent: 100,
        isCorrect: true,
        now: now,
      );

      expect(
        await database.select(database.practiceSessionHistoryModels).get(),
        isEmpty,
      );

      await service.saveAssessment(
        courseId: 6,
        lessonId: 470,
        challengeId: 2,
        position: 2,
        totalSentences: 2,
        transcript: 'may I help you',
        accuracyPercent: 75,
        isCorrect: false,
        now: now.add(const Duration(minutes: 2)),
      );

      final lesson = await service.loadLesson(courseId: 6, lessonId: 470);
      final sentences = await service.loadSentences(courseId: 6, lessonId: 470);
      final sessions = await database
          .select(database.practiceSessionHistoryModels)
          .get();
      expect(lesson?.status, SpeakingLessonStatus.completed.index);
      expect(lesson?.completedSentences, 2);
      expect(sentences, hasLength(2));
      expect(sessions, hasLength(1));
      expect(sessions.single.skill, 'speaking');
      expect(sessions.single.contentId, '470');

      await service.saveAssessment(
        courseId: 6,
        lessonId: 470,
        challengeId: 2,
        position: 2,
        totalSentences: 2,
        transcript: 'may I help you please',
        accuracyPercent: 100,
        isCorrect: true,
        now: now.add(const Duration(minutes: 3)),
      );
      expect(
        await database.select(database.practiceSessionHistoryModels).get(),
        hasLength(1),
        reason:
            'Rechecking a completed lesson must not duplicate weekly sessions.',
      );
    },
  );
}
