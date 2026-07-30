import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/learning_language_level.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/services/recommended_words_service.dart';

void main() {
  const service = RecommendedWordsService();

  test('sorts by showCount and mixes up to three words per topic', () {
    final words = service.build(
      topics: [
        _topic(
          id: 10,
          order: 1,
          words: [
            _word(1, showCount: 4),
            _word(2, showCount: 1),
            _word(3, showCount: 3),
            _word(4, showCount: 2),
            _word(99, showCount: 0, level: 4),
          ],
        ),
        _topic(
          id: 20,
          order: 2,
          words: [
            _word(5, showCount: 0),
            _word(6, showCount: 4),
            _word(7, showCount: 2),
            _word(8, showCount: 1),
          ],
        ),
      ],
      selectedTopicOrders: {1, 2},
      selectedLevels: const [LearningLanguageLevel.beginner],
      progressedWordIds: {7},
    );

    expect(words.map((word) => word['id']), [2, 4, 3, 5, 8, 6, 1]);
    expect(words.map((word) => word['topicId']), [10, 10, 10, 20, 20, 20, 10]);
  });

  test('falls back to all levels only when the level result is empty', () {
    final words = service.build(
      topics: [
        _topic(
          id: 10,
          order: 1,
          words: [
            _word(1, showCount: 3, level: 4),
            _word(2, showCount: 1, level: 5),
            _word(3, showCount: 0, level: 4, enabled: false),
          ],
        ),
        _topic(
          id: 20,
          order: 2,
          words: [
            _word(4, showCount: 0, level: 3),
            _word(5, showCount: 2, level: 4),
          ],
        ),
      ],
      selectedTopicOrders: {1, 2},
      selectedLevels: const [LearningLanguageLevel.beginner],
      progressedWordIds: {4},
    );

    expect(words.map((word) => word['id']), [2, 1, 5]);
  });
}

Topic _topic({
  required int id,
  required int order,
  required List<Map<String, dynamic>> words,
}) {
  return Topic(
    id: id,
    order: order,
    original: 'Topic $order',
    translated: 'Chủ đề $order',
    words: words,
  );
}

Map<String, dynamic> _word(
  int id, {
  required int showCount,
  int level = 1,
  bool enabled = true,
}) {
  return {
    'id': id,
    'writing': 'word $id',
    'translation': 'nghĩa $id',
    'level': level,
    'showCount': showCount,
    'enabled': enabled,
  };
}
