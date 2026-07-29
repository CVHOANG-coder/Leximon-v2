import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/practice_exercise.dart';

class TopicRepetitionData {
  const TopicRepetitionData({
    required this.words,
    required this.distractorWords,
  });

  final List<ExerciseWord> words;
  final List<ExerciseWord> distractorWords;

  bool get canStart => words.length >= TopicRepetitionService.minimumWordCount;
}

class TopicRepetitionService {
  TopicRepetitionService(this._database);

  static const minimumWordCount = 8;

  final AppDatabase _database;

  Future<TopicRepetitionData> load(int topicId) async {
    final wordRows =
        await (_database.select(_database.wordModels)
              ..where(
                (row) =>
                    row.topicId.equals(topicId) & row.isEnabled.equals(true),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.priority),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    final wordIds = wordRows.map((word) => word.id).toSet();
    final progressRows = wordIds.isEmpty
        ? const <LearningProgressRow>[]
        : await (_database.select(
            _database.learningProgressModels,
          )..where((row) => row.id.isIn(wordIds))).get();
    final progressByWordId = {
      for (final progress in progressRows) progress.id: progress,
    };
    final distractorWords = wordRows
        .map(_toExerciseWord)
        .where(_hasUsableContent)
        .toList(growable: false);
    final repeatableWords = wordRows
        .where((word) {
          final progress = progressByWordId[word.id];
          if (progress == null || !_hasLearningActivity(progress)) return false;
          final target = _toExerciseWord(word);
          return _hasUsableContent(target) &&
              distractorWords.any(
                (candidate) =>
                    candidate.id != target.id &&
                    _normalizedTranslation(candidate.translation) !=
                        _normalizedTranslation(target.translation),
              );
        })
        .map(_toExerciseWord)
        .toList(growable: false);

    return TopicRepetitionData(
      words: List.unmodifiable(repeatableWords),
      distractorWords: List.unmodifiable(distractorWords),
    );
  }

  bool _hasLearningActivity(LearningProgressRow progress) {
    if (progress.deletedByUser) return false;
    return progress.trainingProgress > 0 ||
        progress.trainingError > 0 ||
        progress.learnedDate != null ||
        progress.markedAsKnown ||
        progress.repetitionStep > 0 ||
        progress.onFastBrain;
  }

  ExerciseWord _toExerciseWord(WordRow word) {
    return ExerciseWord(
      id: word.id,
      topicId: word.topicId,
      writing: word.writing,
      translation: word.translation,
      transliteration: word.transliteration ?? word.transcription ?? '',
    );
  }

  bool _hasUsableContent(ExerciseWord word) {
    return word.writing.trim().isNotEmpty && word.translation.trim().isNotEmpty;
  }

  String _normalizedTranslation(String value) {
    return value.trim().toLowerCase();
  }
}
