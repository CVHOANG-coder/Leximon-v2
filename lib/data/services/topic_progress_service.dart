import 'package:drift/drift.dart';

import '../local/app_database.dart';

class TopicProgressDetails {
  const TopicProgressDetails({
    required this.totalWords,
    required this.learnedWords,
    required this.reviewWords,
    required this.activeWords,
    required this.difficultWords,
  });

  factory TopicProgressDetails.empty(int totalWords) {
    return TopicProgressDetails(
      totalWords: totalWords,
      learnedWords: 0,
      reviewWords: 0,
      activeWords: 0,
      difficultWords: 0,
    );
  }

  final int totalWords;
  final int learnedWords;
  final int reviewWords;
  final int activeWords;
  final int difficultWords;

  int get progressedWords => learnedWords + activeWords;

  double get progress => totalWords == 0
      ? 0
      : (progressedWords / totalWords).clamp(0, 1).toDouble();
}

class TopicProgressService {
  TopicProgressService(this._database);

  final AppDatabase _database;

  Future<TopicProgressDetails> loadDetails(int topicId) async {
    final words =
        await (_database.select(_database.wordModels)..where(
              (row) => row.topicId.equals(topicId) & row.isEnabled.equals(true),
            ))
            .get();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressByWordId = {for (final row in progressRows) row.id: row};
    final now = DateTime.now().millisecondsSinceEpoch;
    var learnedWords = 0;
    var reviewWords = 0;
    var activeWords = 0;
    var difficultWords = 0;

    for (final word in words) {
      final progress = progressByWordId[word.id];
      if (progress == null || progress.deletedByUser) continue;
      final isLearned = progress.learnedDate != null || progress.markedAsKnown;
      final isDue =
          progress.repetitionStep > 0 &&
          progress.repetitionDate != null &&
          progress.repetitionDate! <= now;
      if (isLearned) {
        learnedWords++;
      } else if (_hasLearningActivity(progress)) {
        activeWords++;
      }
      if (isDue) reviewWords++;
      if (progress.trainingError > 0) difficultWords++;
    }

    return TopicProgressDetails(
      totalWords: words.length,
      learnedWords: learnedWords,
      reviewWords: reviewWords,
      activeWords: activeWords,
      difficultWords: difficultWords,
    );
  }

  Future<Map<int, double>> load() async {
    final words = await _database.enabledWords();
    final progressRows = await _database
        .select(_database.learningProgressModels)
        .get();
    final progressByWordId = {for (final row in progressRows) row.id: row};
    final totalByTopic = <int, int>{};
    final progressedByTopic = <int, int>{};

    for (final word in words) {
      totalByTopic[word.topicId] = (totalByTopic[word.topicId] ?? 0) + 1;
      final progress = progressByWordId[word.id];
      if (progress == null || progress.deletedByUser) continue;
      if (_hasLearningActivity(progress)) {
        progressedByTopic[word.topicId] =
            (progressedByTopic[word.topicId] ?? 0) + 1;
      }
    }

    return {
      for (final entry in totalByTopic.entries)
        entry.key: ((progressedByTopic[entry.key] ?? 0) / entry.value).clamp(
          0,
          1,
        ),
    };
  }
}

bool _hasLearningActivity(LearningProgressRow progress) {
  return progress.trainingProgress > 0 ||
      progress.trainingError > 0 ||
      progress.learnedDate != null ||
      progress.markedAsKnown ||
      progress.repetitionStep > 0 ||
      progress.onFastBrain;
}
