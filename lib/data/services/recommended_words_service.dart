import '../models/learning_language_level.dart';
import '../models/topic.dart';

class RecommendedWordsService {
  const RecommendedWordsService();

  List<Map<String, dynamic>> build({
    required List<Topic> topics,
    required Set<int> selectedTopicOrders,
    required Iterable<LearningLanguageLevel> selectedLevels,
    required Set<int> progressedWordIds,
  }) {
    final selectedTopics = topics
        .where((topic) => selectedTopicOrders.contains(topic.order))
        .toList(growable: false);
    final recommended = <Map<String, dynamic>>[];

    for (final languageLevel in selectedLevels) {
      final topicLists = selectedTopics
          .map(
            (topic) => _eligibleWords(
              topic,
              progressedWordIds: progressedWordIds,
              levels: languageLevel.wordLevels,
            ),
          )
          .toList(growable: false);

      var hasWords = true;
      var offset = 0;
      while (hasWords) {
        hasWords = false;
        for (final words in topicLists) {
          if (offset >= words.length) continue;
          hasWords = true;
          final end = (offset + 3).clamp(0, words.length);
          recommended.addAll(words.getRange(offset, end));
        }
        offset += 3;
      }
    }

    if (recommended.isNotEmpty) return recommended;

    for (final topic in selectedTopics) {
      recommended.addAll(
        _eligibleWords(topic, progressedWordIds: progressedWordIds),
      );
    }
    return recommended;
  }

  List<Map<String, dynamic>> _eligibleWords(
    Topic topic, {
    required Set<int> progressedWordIds,
    Set<int>? levels,
  }) {
    final words = topic.words
        .where((word) {
          final wordId = _intValue(word['id']);
          final level = _intValue(word['level']);
          return wordId != null &&
              !progressedWordIds.contains(wordId) &&
              word['enabled'] != false &&
              (levels == null || (level != null && levels.contains(level)));
        })
        .map(
          (word) => <String, dynamic>{
            ...word,
            'topicId': _intValue(word['topicId']) ?? topic.id,
          },
        )
        .toList(growable: true);

    words.sort((left, right) {
      final leftCount = _intValue(left['showCount']) ?? 0;
      final rightCount = _intValue(right['showCount']) ?? 0;
      return leftCount.compareTo(rightCount);
    });
    return words;
  }

  int? _intValue(Object? value) {
    return value is num ? value.toInt() : null;
  }
}
