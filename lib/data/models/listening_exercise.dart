class ListeningExercise {
  const ListeningExercise({
    required this.id,
    required this.name,
    required this.levelName,
    required this.audioUrl,
    required this.challenges,
    required this.translations,
    this.youtubeVideoId,
  });

  final int id;
  final String name;
  final String levelName;
  final String audioUrl;
  final List<ListeningChallenge> challenges;
  final Map<int, String> translations;
  final String? youtubeVideoId;

  bool get isYoutubeLesson => youtubeVideoId?.isNotEmpty == true;
  bool get isSelectionLesson =>
      challenges.isNotEmpty && challenges.every((item) => item.isSelection);
}

class ListeningChallenge {
  const ListeningChallenge({
    required this.id,
    required this.position,
    required this.content,
    required this.defaultInput,
    required this.solutions,
    required this.audioUrl,
    this.timeStart,
    this.timeEnd,
    this.selectionOptions = const [],
    this.correctSelectionIndex,
  });

  final int id;
  final int position;
  final String content;
  final String defaultInput;
  final List<List<String>> solutions;
  final String audioUrl;
  final double? timeStart;
  final double? timeEnd;
  final List<ListeningSelectionOption> selectionOptions;
  final int? correctSelectionIndex;

  bool get isSelection =>
      selectionOptions.isNotEmpty && correctSelectionIndex != null;
}

class ListeningSelectionOption {
  const ListeningSelectionOption({
    required this.text,
    required this.phonetic,
    required this.audioUrl,
  });

  final String text;
  final String phonetic;
  final String audioUrl;
}
