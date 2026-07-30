enum LearningLanguageLevel {
  beginner('Sơ cấp', {1, 2}),
  intermediate('Trung bình', {3}),
  advanced('Nâng cao', {4, 5});

  const LearningLanguageLevel(this.label, this.wordLevels);

  final String label;
  final Set<int> wordLevels;

  static LearningLanguageLevel fromLabel(String label) {
    return values.firstWhere(
      (level) => level.label == label,
      orElse: () => beginner,
    );
  }
}
