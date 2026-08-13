import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/services/reading_vocabulary_service.dart';

void main() {
  late AppDatabase database;
  late ReadingVocabularyService service;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = ReadingVocabularyService(database);
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        for (var id = 1; id <= 6; id++)
          WordModelsCompanion.insert(
            id: id,
            topicId: 10,
            writing: id == 1 ? 'Winter' : 'word$id',
            translation: id == 1 ? 'mùa đông' : 'nghĩa $id',
            transcription: Value(id == 1 ? '/ˈwɪn.tər/' : null),
            isEnabled: true,
            priority: 10 - id,
            level: 1,
          ),
      ]);
    });
  });

  tearDown(() => database.close());

  test('finds a tapped word without case or surrounding punctuation', () async {
    final word = await service.findWord('“WINTER,”');

    expect(word?.writing, 'Winter');
    expect(word?.translation, 'mùa đông');
    expect(await service.findWord('not-in-database'), isNull);
  });

  test('saves once and exposes pending words in groups of four', () async {
    for (var id = 1; id <= 3; id++) {
      final word = await service.findWord(id == 1 ? 'winter' : 'word$id');
      await service.saveWord(word: word!, storyId: 7);
    }
    expect((await service.loadTask()).isAvailable, isFalse);

    final fourth = await service.findWord('word4');
    await service.saveWord(word: fourth!, storyId: 7);
    await service.saveWord(word: fourth, storyId: 8);

    final firstTask = await service.loadTask();
    expect(firstTask.isAvailable, isTrue);
    expect(firstTask.pendingCount, 4);
    expect(firstTask.words.map((word) => word.id), [1, 2, 3, 4]);
    expect(
      await database.select(database.readingSavedWordModels).get(),
      hasLength(4),
    );

    final fifth = await service.findWord('word5');
    await service.saveWord(word: fifth!, storyId: 9);
    await service.completeBatch(firstTask.words);

    final nextTask = await service.loadTask();
    expect(nextTask.pendingCount, 1);
    expect(nextTask.isAvailable, isFalse);
    expect(nextTask.words.single.id, 5);
  });
}
