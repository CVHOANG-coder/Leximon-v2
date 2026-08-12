enum IpaSoundGroup { vowel, rControlledVowel, consonant }

class IpaSound {
  const IpaSound({
    required this.symbol,
    required this.name,
    required this.example,
    required this.audioAsset,
    required this.group,
  });

  final String symbol;
  final String name;
  final String example;
  final String audioAsset;
  final IpaSoundGroup group;
}
