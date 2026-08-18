class ListeningCourseSummary {
  const ListeningCourseSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.levelName,
    required this.indexAsset,
    required this.lessons,
    this.totalLessons = 0,
  });

  final int id;
  final String name;
  final String type;
  final String levelName;
  final String indexAsset;
  final List<ListeningLessonSummary> lessons;
  final int totalLessons;
}

class ListeningLessonSummary {
  const ListeningLessonSummary({
    required this.id,
    required this.courseId,
    required this.name,
    required this.levelName,
    required this.totalChallenges,
    required this.courseIndexAsset,
  });

  final int id;
  final int courseId;
  final String name;
  final String levelName;
  final int totalChallenges;
  final String courseIndexAsset;
}
