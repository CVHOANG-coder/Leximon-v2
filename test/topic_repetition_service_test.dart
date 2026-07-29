import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/topic_repetition_service.dart';

void main() {
  late AppDatabase database;
  late TopicRepetitionService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = TopicRepetitionService(database);
  });

  tearDown(() => database.close());

  test('selects only learned enabled words from the requested topic', () async {
    await _insertWords(database, count: 11);
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.batch((batch) {
      batch.insertAll(database.learningProgressModels, [
        for (var id = 1; id <= 8; id++)
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: now,
            trainingProgress: const Value(2),
          ),
        LearningProgressModelsCompanion.insert(
          id: const Value(9),
          creationDate: now,
          learnedDate: Value(now),
          deletedByUser: const Value(true),
        ),
        LearningProgressModelsCompanion.insert(
          id: const Value(10),
          creationDate: now,
          markedAsKnown: const Value(true),
        ),
        LearningProgressModelsCompanion.insert(
          id: const Value(100),
          creationDate: now,
          trainingProgress: const Value(2),
        ),
      ]);
    });

    final data = await service.load(7);

    expect(data.words.map((word) => word.id), [1, 2, 3, 4, 5, 6, 7, 8, 10]);
    expect(data.canStart, isTrue);
    expect(data.distractorWords, hasLength(10));
    expect(data.words.every((word) => word.topicId == 7), isTrue);
  });

  test('does not create progress rows while preparing repetition', () async {
    await _insertWords(database, count: 8);

    final data = await service.load(7);
    final progressRows = await database
        .select(database.learningProgressModels)
        .get();

    expect(data.words, isEmpty);
    expect(data.canStart, isFalse);
    expect(progressRows, isEmpty);
  });

  test('requires a distinct translation for every repeatable word', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        WordModelsCompanion.insert(
          id: 1,
          topicId: 7,
          writing: 'first',
          translation: 'giống nhau',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
        WordModelsCompanion.insert(
          id: 2,
          topicId: 7,
          writing: 'second',
          translation: ' GIỐNG NHAU ',
          isEnabled: true,
          priority: 2,
          level: 1,
        ),
      ]);
      batch.insertAll(database.learningProgressModels, [
        for (final id in [1, 2])
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: now,
            trainingProgress: const Value(1),
          ),
      ]);
    });

    final data = await service.load(7);

    expect(data.words, isEmpty);
  });
}

Future<void> _insertWords(AppDatabase database, {required int count}) async {
  await database.batch((batch) {
    batch.insertAll(database.wordModels, [
      for (var id = 1; id <= count; id++)
        WordModelsCompanion.insert(
          id: id,
          topicId: 7,
          writing: 'word $id',
          translation: 'nghĩa $id',
          isEnabled: id != 11,
          priority: id,
          level: 1,
        ),
      WordModelsCompanion.insert(
        id: 100,
        topicId: 99,
        writing: 'other topic',
        translation: 'chủ đề khác',
        isEnabled: true,
        priority: 1,
        level: 1,
      ),
    ]);
  });
}
