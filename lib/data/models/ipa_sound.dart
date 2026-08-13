enum IpaSoundGroup { vowel, rControlledVowel, consonant }

class IpaWord {
  const IpaWord({
    required this.name,
    required this.audioAsset,
    this.transcription = '',
  });

  final String name;
  final String transcription;
  final String audioAsset;
}

class IpaSound {
  const IpaSound({
    required this.symbol,
    required this.name,
    required this.example,
    required this.audioAsset,
    required this.group,
    this.description = '',
    this.photoAsset = '',
    this.spellingWords = const [],
    this.beginningWords = const [],
    this.middleWords = const [],
    this.endWords = const [],
    this.youtubeVideoId = '',
    this.youtubeStartSeconds = 0,
  });

  final String symbol;
  final String name;
  final String example;
  final String audioAsset;
  final IpaSoundGroup group;
  final String description;
  final String photoAsset;
  final List<IpaWord> spellingWords;
  final List<IpaWord> beginningWords;
  final List<IpaWord> middleWords;
  final List<IpaWord> endWords;
  final String youtubeVideoId;
  final double youtubeStartSeconds;

  String get typeLabel => switch (group) {
    IpaSoundGroup.vowel => 'vowel sound',
    IpaSoundGroup.rControlledVowel => 'r-controlled vowel',
    IpaSoundGroup.consonant => 'consonant sound',
  };
}
