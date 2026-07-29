import '../local/app_database.dart';
import 'exercise_error_mask.dart';

class DifficultWordsTrainingBatch {
  const DifficultWordsTrainingBatch({
    required this.words,
    required this.distractorWords,
    required this.similarWordIds,
    required this.exerciseMasksByWordId,
    required this.remainingWordCount,
  });

  final List<WordRow> words;
  final List<WordRow> distractorWords;
  final Map<int, List<int>> similarWordIds;
  final Map<int, int> exerciseMasksByWordId;
  final int remainingWordCount;

  bool get isEmpty => words.isEmpty;
}

/// Builds the global "difficult words" batch opened from Progress.
///
/// Search and topic state deliberately do not participate in this query. Each
/// launch reads current local progress again and takes at most four valid words.
class DifficultWordsTrainingService {
  DifficultWordsTrainingService(this._database);

  static const batchSize = 4;

  final AppDatabase _database;

  Future<DifficultWordsTrainingBatch> prepareBatch() async {
    final enabledWords = await _database.enabledWords();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressById = {for (final row in progressRows) row.id: row};

    final difficultWords = enabledWords
        .where((word) {
          final progress = progressById[word.id];
          return progress != null &&
              !progress.deletedByUser &&
              !progress.markedAsKnown &&
              normalizeExerciseErrorMask(progress.trainingError) != 0;
        })
        .toList(growable: false);
    final words = difficultWords.take(batchSize).toList(growable: false);

    return DifficultWordsTrainingBatch(
      words: words,
      distractorWords: enabledWords,
      similarWordIds: await _database.similarWordIdsFor(
        words.map((word) => word.id),
      ),
      exerciseMasksByWordId: {
        for (final word in words)
          word.id: normalizeExerciseErrorMask(
            progressById[word.id]!.trainingError,
          ),
      },
      remainingWordCount: difficultWords.length,
    );
  }
}
