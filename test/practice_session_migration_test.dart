import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';

void main() {
  test(
    'schema 12 backfills sessions and creates newer progress tables',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'leximon-session-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/database.sqlite');
      final beforeUpgrade = AppDatabase.forTesting(NativeDatabase(file));
      final completedAt = DateTime(2026, 8, 13, 10).millisecondsSinceEpoch;

      await beforeUpgrade
          .into(beforeUpgrade.listeningLessonProgressModels)
          .insert(
            ListeningLessonProgressModelsCompanion.insert(
              courseId: 1,
              lessonId: 10,
              totalChallenges: 1,
              status: const Value(2),
              startedAt: completedAt - 60000,
              updatedAt: completedAt,
              completedAt: Value(completedAt),
            ),
          );
      await beforeUpgrade
          .into(beforeUpgrade.listeningLessonProgressModels)
          .insert(
            ListeningLessonProgressModelsCompanion.insert(
              courseId: 1,
              lessonId: 11,
              totalChallenges: 3,
              status: const Value(1),
              startedAt: completedAt,
              updatedAt: completedAt,
            ),
          );
      await beforeUpgrade.customStatement(
        'DROP TABLE practice_session_history_models',
      );
      await beforeUpgrade.customStatement('PRAGMA user_version = 9');
      await beforeUpgrade.close();

      final afterUpgrade = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(afterUpgrade.close);
      final sessions = await afterUpgrade
          .select(afterUpgrade.practiceSessionHistoryModels)
          .get();

      expect(sessions, hasLength(1));
      expect(sessions.single.skill, 'listening');
      expect(sessions.single.contentId, '10');
      expect(sessions.single.completedAt, completedAt);
      expect(
        await afterUpgrade
            .select(afterUpgrade.speakingLessonProgressModels)
            .get(),
        isEmpty,
      );
      expect(
        await afterUpgrade
            .select(afterUpgrade.speakingSentenceProgressModels)
            .get(),
        isEmpty,
      );
      expect(
        await afterUpgrade.select(afterUpgrade.readingSavedWordModels).get(),
        isEmpty,
      );
    },
  );
}
