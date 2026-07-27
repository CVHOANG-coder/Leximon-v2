class DemoCharacter {
  const DemoCharacter({
    required this.name,
    required this.role,
    required this.description,
    required this.emoji,
    required this.colors,
    this.isNew = false,
  });

  final String name;
  final String role;
  final String description;
  final String emoji;
  final List<int> colors;
  final bool isNew;
}
