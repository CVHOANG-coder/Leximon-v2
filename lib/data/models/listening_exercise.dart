class ListeningExercise {
  const ListeningExercise({
    required this.id,
    required this.name,
    required this.levelName,
    required this.audioUrl,
    required this.challenges,
    required this.translations,
  });

  final int id;
  final String name;
  final String levelName;
  final String audioUrl;
  final List<ListeningChallenge> challenges;
  final Map<int, String> translations;
}

class ListeningChallenge {
  const ListeningChallenge({
    required this.id,
    required this.position,
    required this.content,
    required this.defaultInput,
    required this.solutions,
    required this.audioUrl,
  });

  final int id;
  final int position;
  final String content;
  final String defaultInput;
  final List<List<String>> solutions;
  final String audioUrl;
}
