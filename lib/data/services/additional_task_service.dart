import '../local/app_database.dart';
import 'daily_card_service.dart';
import 'exercise_error_mask.dart';

class AdditionalTasksLockedException implements Exception {
  const AdditionalTasksLockedException();
}

class AdditionalTaskUnavailableException implements Exception {
  const AdditionalTaskUnavailableException(this.type);

  final DailyTaskType type;
}

class AdditionalTaskLaunchData {
  const AdditionalTaskLaunchData({
    required this.type,
    required this.words,
    required this.distractorWords,
    required this.similarWordIds,
    required this.exerciseMasksByWordId,
  });

  final DailyTaskType type;
  final List<WordRow> words;
  final List<WordRow> distractorWords;
  final Map<int, List<int>> similarWordIds;
  final Map<int, int> exerciseMasksByWordId;
}

class AdditionalTaskService {
  AdditionalTaskService({
    required AppDatabase database,
    required DailyCardService dailyCardService,
  }) : _database = database,
       _dailyCardService = dailyCardService;

  static const supportedDifficultMask =
      DailyCardService.supportedDifficultExerciseMask;
  static const maxRepeatWords = 20;

  final AppDatabase _database;
  final DailyCardService _dailyCardService;

  Future<List<DailyTaskType>> loadAvailableTasks({DateTime? now}) async {
    final card = await _dailyCardService.load(now: now);
    if (!card.isComplete) throw const AdditionalTasksLockedException();
    return card.additionalTasks;
  }

  Future<AdditionalTaskLaunchData> prepareTask(
    DailyTaskType type, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final availableTasks = await loadAvailableTasks(now: currentTime);
    if (!availableTasks.contains(type)) {
      throw AdditionalTaskUnavailableException(type);
    }

    final enabledWords = await _database.enabledWords();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressById = {for (final row in progressRows) row.id: row};
    final currentTimestamp = currentTime.millisecondsSinceEpoch;

    final words = switch (type) {
      DailyTaskType.learn => const <WordRow>[],
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
      DailyTaskType.sentences => const <WordRow>[],
    };

    if (type != DailyTaskType.learn &&
        type != DailyTaskType.sentences &&
        words.isEmpty) {
      throw AdditionalTaskUnavailableException(type);
    }
    if ((type == DailyTaskType.train || type == DailyTaskType.difficult) &&
        words.length != 4) {
      throw AdditionalTaskUnavailableException(type);
    }

    final wordIds = words.map((word) => word.id);
    return AdditionalTaskLaunchData(
      type: type,
      words: words,
      distractorWords: enabledWords,
      similarWordIds: await _database.similarWordIdsFor(wordIds),
      exerciseMasksByWordId: {
        if (type == DailyTaskType.difficult)
          for (final word in words)
            word.id: normalizeExerciseErrorMask(
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
    final result = enabledWords.where((word) {
      final progress = progressById[word.id];
      return progress != null &&
          !progress.deletedByUser &&
          !progress.markedAsKnown &&
          progress.repetitionStep > 0 &&
          progress.repetitionDate != null &&
          progress.repetitionDate! <= currentTimestamp;
    }).toList();
    result.sort((a, b) {
      final aDate = progressById[a.id]!.repetitionDate ?? 1 << 62;
      final bDate = progressById[b.id]!.repetitionDate ?? 1 << 62;
      final byDate = aDate.compareTo(bDate);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return result.take(maxRepeatWords).toList(growable: false);
  }

  List<WordRow> _fastBrainWords(
    List<WordRow> enabledWords,
    Map<int, LearningProgressRow> progressById,
    int currentTimestamp,
  ) {
    final result = enabledWords.where((word) {
      final progress = progressById[word.id];
      return progress != null &&
          !progress.deletedByUser &&
          !progress.markedAsKnown &&
          progress.onFastBrain &&
          progress.repetitionFastBrainDate != null &&
          progress.repetitionFastBrainDate! <= currentTimestamp;
    }).toList();
    result.sort((a, b) {
      final aProgress = progressById[a.id]!;
      final bProgress = progressById[b.id]!;
      final byDate = aProgress.repetitionFastBrainDate!.compareTo(
        bProgress.repetitionFastBrainDate!,
      );
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return result.take(4).toList(growable: false);
  }

  List<WordRow> _difficultWords(
    List<WordRow> enabledWords,
    Map<int, LearningProgressRow> progressById,
  ) {
    final result = enabledWords.where((word) {
      final progress = progressById[word.id];
      return progress != null &&
          !progress.deletedByUser &&
          !progress.markedAsKnown &&
          normalizeExerciseErrorMask(progress.trainingError) != 0;
    }).toList();
    result.sort((a, b) {
      final aError = progressById[a.id]!.trainingError;
      final bError = progressById[b.id]!.trainingError;
      final byError = bError.compareTo(aError);
      return byError != 0 ? byError : a.id.compareTo(b.id);
    });
    return result.take(4).toList(growable: false);
  }
}
