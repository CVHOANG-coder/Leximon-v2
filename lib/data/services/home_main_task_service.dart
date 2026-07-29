import '../local/app_database.dart';
import 'daily_card_service.dart';
import 'exercise_error_mask.dart';

class HomeMainTaskUnavailableException implements Exception {
  const HomeMainTaskUnavailableException(this.type);

  final DailyTaskType type;
}

class HomeMainTaskLaunchData {
  const HomeMainTaskLaunchData({
    required this.type,
    required this.words,
    required this.distractorWords,
    required this.exerciseMasksByWordId,
  });

  final DailyTaskType type;
  final List<WordRow> words;
  final List<WordRow> distractorWords;
  final Map<int, int> exerciseMasksByWordId;
}

/// Re-queries the database when a main Home task is opened.
///
/// Daily goals are fixed when [VisitModel] is created, while the words in a
/// lesson must reflect their current repetition/error state.
class HomeMainTaskService {
  HomeMainTaskService(this._database);

  static const maxRepeatWords = 20;
  static const maxPracticeWords = 4;

  final AppDatabase _database;

  Future<HomeMainTaskLaunchData> prepareTask(
    DailyTaskType type, {
    DateTime? now,
  }) async {
    if (type == DailyTaskType.learn) {
      throw HomeMainTaskUnavailableException(type);
    }

    final currentTimestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final enabledWords = await _database.enabledWords();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressById = {for (final row in progressRows) row.id: row};

    final words = switch (type) {
      DailyTaskType.repeat => _repeatWords(
        enabledWords,
        progressById,
        currentTimestamp,
      ),
      DailyTaskType.train => _fastBrainWords(
        enabledWords,
        progressById,
        currentTimestamp,
      ),
      DailyTaskType.difficult => _difficultWords(enabledWords, progressById),
      DailyTaskType.learn => const <WordRow>[],
    };

    final requiredCount = type == DailyTaskType.repeat ? 1 : maxPracticeWords;
    if (words.length < requiredCount) {
      throw HomeMainTaskUnavailableException(type);
    }

    return HomeMainTaskLaunchData(
      type: type,
      words: List.unmodifiable(words),
      distractorWords: List.unmodifiable(enabledWords),
      exerciseMasksByWordId: {
        if (type == DailyTaskType.difficult)
          for (final word in words)
            word.id: _normalizedDifficultMask(
              progressById[word.id]!.trainingError,
            ),
      },
    );
  }

  List<WordRow> _repeatWords(
    List<WordRow> enabledWords,
    Map<int, LearningProgressRow> progressById,
    int currentTimestamp,
  ) {
    return enabledWords
        .where((word) {
          final progress = progressById[word.id];
          return _isAvailable(progress) &&
              progress!.repetitionStep > 0 &&
              progress.repetitionDate != null &&
              progress.repetitionDate! <= currentTimestamp;
        })
        .take(maxRepeatWords)
        .toList(growable: false);
  }

  List<WordRow> _fastBrainWords(
    List<WordRow> enabledWords,
    Map<int, LearningProgressRow> progressById,
    int currentTimestamp,
  ) {
    return enabledWords
        .where((word) {
          final progress = progressById[word.id];
          return _isAvailable(progress) &&
              progress!.onFastBrain &&
              progress.repetitionFastBrainDate != null &&
              progress.repetitionFastBrainDate! <= currentTimestamp;
        })
        .take(maxPracticeWords)
        .toList(growable: false);
  }

  List<WordRow> _difficultWords(
    List<WordRow> enabledWords,
    Map<int, LearningProgressRow> progressById,
  ) {
    return enabledWords
        .where((word) {
          final progress = progressById[word.id];
          return _isAvailable(progress) &&
              _normalizedDifficultMask(progress!.trainingError) != 0;
        })
        .take(maxPracticeWords)
        .toList(growable: false);
  }

  bool _isAvailable(LearningProgressRow? progress) {
    return progress != null &&
        !progress.deletedByUser &&
        !progress.markedAsKnown;
  }

  int _normalizedDifficultMask(int storedMask) {
    return normalizeExerciseErrorMask(storedMask);
  }
}
