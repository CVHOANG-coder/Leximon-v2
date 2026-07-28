class Topic {
  const Topic({
    required this.id,
    required this.order,
    required this.original,
    required this.translated,
    required this.words,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as int,
      order: json['order'] as int,
      original: json['original'] as String? ?? '',
      translated: json['translated'] as String? ?? '',
      words: (json['words'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .where((word) => word['enabled'] == true)
          .toList(growable: false),
    );
  }

  final int id;
  final int order;
  final String original;
  final String translated;
  final List<Map<String, dynamic>> words;

  int get wordCount => words.length;
}
