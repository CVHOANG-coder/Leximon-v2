class ReadingStory {
  const ReadingStory({
    required this.id,
    required this.title,
    required this.content,
    required this.imageAsset,
    this.englishTitle,
    this.englishContent,
  });

  final int id;
  final String title;
  final String content;
  final String imageAsset;
  final String? englishTitle;
  final String? englishContent;

  String get originalTitle => englishTitle ?? title;
  String get originalContent => englishContent ?? content;

  bool get hasTranslation =>
      title != originalTitle || content != originalContent;

  ReadingStory withEnglishVersion(ReadingStory englishStory) {
    return ReadingStory(
      id: id,
      title: title,
      content: content,
      imageAsset: imageAsset,
      englishTitle: englishStory.title,
      englishContent: englishStory.content,
    );
  }

  factory ReadingStory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final content = json['content'];
    if (id is! num || title is! String || content is! String) {
      throw const FormatException('Reading story has invalid fields.');
    }

    return ReadingStory(
      id: id.toInt(),
      title: _cleanTitle(title),
      content: _cleanContent(content),
      imageAsset: 'assets/images/reading/${id.toInt()}.jpg',
    );
  }
}

String _cleanTitle(String value) {
  return value.trim().replaceAll(RegExp(r'^[\s"]+|[\s".]+$'), '');
}

String _cleanContent(String value) {
  return value.trim().replaceAllMapped(
    RegExp(r'([a-z”’])\.([A-Z])'),
    (match) => '${match.group(1)}. ${match.group(2)}',
  );
}
