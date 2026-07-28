class TopicAssetPayload {
  const TopicAssetPayload({required this.version, required this.topics});

  factory TopicAssetPayload.fromJson(Map<String, dynamic> json) {
    return TopicAssetPayload(
      version: _readInt(json['version']),
      topics: (json['topics'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(TopicAssetItem.fromJson)
          .toList(growable: false),
    );
  }

  final int version;
  final List<TopicAssetItem> topics;
}

class TopicAssetItem {
  const TopicAssetItem({
    required this.id,
    required this.order,
    required this.original,
    required this.translated,
    required this.isEnabled,
    required this.words,
  });

  factory TopicAssetItem.fromJson(Map<String, dynamic> json) {
    final topicId = _readInt(json['id']);
    return TopicAssetItem(
      id: topicId,
      order: _readInt(json['order'], fallback: topicId),
      original: json['original'] as String?,
      translated: json['translated'] as String?,
      isEnabled: json['enabled'] as bool? ?? false,
      words: (json['words'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(WordAssetItem.fromJson)
          .toList(growable: false),
    );
  }

  final int id;
  final int order;
  final String? original;
  final String? translated;
  final bool isEnabled;
  final List<WordAssetItem> words;
}

class WordAssetItem {
  const WordAssetItem({
    required this.id,
    required this.writing,
    required this.translation,
    required this.transcription,
    required this.transliteration,
    required this.isEnabled,
    required this.priority,
    required this.level,
  });

  factory WordAssetItem.fromJson(Map<String, dynamic> json) {
    return WordAssetItem(
      id: _readInt(json['id']),
      writing: json['writing'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      transcription: json['transcription'] as String?,
      transliteration: json['transliteration'] as String?,
      isEnabled: json['enabled'] as bool? ?? false,
      priority: _readInt(json['priority']),
      level: _readInt(json['level']),
    );
  }

  final int id;
  final String writing;
  final String translation;
  final String? transcription;
  final String? transliteration;
  final bool isEnabled;
  final int priority;
  final int level;
}

int _readInt(Object? value, {int fallback = 0}) {
  return switch (value) {
    int intValue => intValue,
    num numberValue => numberValue.toInt(),
    String stringValue => int.tryParse(stringValue) ?? fallback,
    _ => fallback,
  };
}
