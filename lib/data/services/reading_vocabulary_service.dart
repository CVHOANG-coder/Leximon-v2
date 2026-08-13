import 'package:drift/drift.dart';

import '../local/app_database.dart';

class ReadingVocabularyTaskSnapshot {
  const ReadingVocabularyTaskSnapshot({
    required this.pendingCount,
    required this.words,
    required this.distractorWords,
    required this.similarWordIds,
  });

  static const batchSize = 4;

  final int pendingCount;
  final List<WordRow> words;
  final List<WordRow> distractorWords;
  final Map<int, List<int>> similarWordIds;

  bool get isAvailable =>
      pendingCount >= batchSize && words.length == batchSize;
}

/// Looks up vocabulary tapped in Reading and owns the queue of saved words.
class ReadingVocabularyService {
  ReadingVocabularyService(this._database);

  final AppDatabase _database;
  Future<Map<String, WordRow>>? _wordLookup;

  Future<WordRow?> findWord(String text) async {
    final normalized = normalizeReadingWord(text);
    if (normalized.isEmpty) return null;
    final lookup = await (_wordLookup ??= _buildWordLookup());
    return lookup[normalized];
  }

  Future<bool> isSaved(WordRow word) async {
    final row =
        await (_database.select(_database.readingSavedWordModels)..where(
              (saved) =>
                  saved.wordId.equals(word.id) &
                  saved.topicId.equals(word.topicId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> saveWord({required WordRow word, required int storyId}) {
    return _database
        .into(_database.readingSavedWordModels)
        .insert(
          ReadingSavedWordModelsCompanion.insert(
            wordId: word.id,
            topicId: word.topicId,
            storyId: storyId,
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<ReadingVocabularyTaskSnapshot> loadTask() async {
    final savedRows =
        await (_database.select(_database.readingSavedWordModels)
              ..where((row) => row.completedAt.isNull())
              ..orderBy([(row) => OrderingTerm.asc(row.savedAt)]))
            .get();
    final enabledWords = await _database.enabledWords();
    final wordsByKey = {
      for (final word in enabledWords) (word.id, word.topicId): word,
    };
    final pendingWords = savedRows
        .map((saved) => wordsByKey[(saved.wordId, saved.topicId)])
        .whereType<WordRow>()
        .toList(growable: false);
    final words = pendingWords
        .take(ReadingVocabularyTaskSnapshot.batchSize)
        .toList(growable: false);

    return ReadingVocabularyTaskSnapshot(
      pendingCount: pendingWords.length,
      words: words,
      distractorWords: enabledWords,
      similarWordIds: await _database.similarWordIdsFor(
        words.map((word) => word.id),
      ),
    );
  }

  Future<void> completeBatch(Iterable<WordRow> words) {
    final completedAt = DateTime.now().millisecondsSinceEpoch;
    return _database.transaction(() async {
      for (final word in words) {
        await (_database.update(_database.readingSavedWordModels)..where(
              (saved) =>
                  saved.wordId.equals(word.id) &
                  saved.topicId.equals(word.topicId),
            ))
            .write(
              ReadingSavedWordModelsCompanion(completedAt: Value(completedAt)),
            );
      }
    });
  }

  Future<Map<String, WordRow>> _buildWordLookup() async {
    final lookup = <String, WordRow>{};
    for (final word in await _database.enabledWords()) {
      final normalized = normalizeReadingWord(word.writing);
      if (normalized.isNotEmpty) lookup.putIfAbsent(normalized, () => word);
    }
    return lookup;
  }
}

String normalizeReadingWord(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"^[^a-z0-9]+|[^a-z0-9]+$"), '');
}
