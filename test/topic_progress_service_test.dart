import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/topic_progress_service.dart';

void main() {
  late AppDatabase database;
  late TopicProgressService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = TopicProgressService(database);
  });

  tearDown(() => database.close());

  test(
    'calculates topic progress from local words and learning rows',
    () async {
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
      await database
          .into(database.learningProgressModels)
          .insert(
            LearningProgressModelsCompanion.insert(
              id: const Value(1),
              creationDate: DateTime.now().millisecondsSinceEpoch,
              trainingProgress: const Value(2),
            ),
          );

      final progress = await service.load();

      expect(progress[10], .5);
    },
  );

  test('loads detail counters from the selected topic rows', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        WordModelsCompanion.insert(
          id: 11,
          topicId: 20,
          writing: 'known',
          translation: 'đã biết',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
        WordModelsCompanion.insert(
          id: 12,
          topicId: 20,
          writing: 'learning',
          translation: 'đang học',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
      ]);
    });
    await database.batch((batch) {
      batch.insertAll(database.learningProgressModels, [
        LearningProgressModelsCompanion.insert(
          id: const Value(11),
          creationDate: now,
          learnedDate: Value(now),
          repetitionStep: const Value(1),
          repetitionDate: Value(now - 1),
        ),
        LearningProgressModelsCompanion.insert(
          id: const Value(12),
          creationDate: now,
          trainingError: const Value(1),
        ),
      ]);
    });

    final details = await service.loadDetails(20);

    expect(details.totalWords, 2);
    expect(details.learnedWords, 1);
    expect(details.reviewWords, 1);
    expect(details.activeWords, 1);
    expect(details.difficultWords, 1);
    expect(details.progressedWords, 2);
    expect(details.progress, 1);
  });
}
