import '../local/app_database.dart';
import 'topic.dart';

enum VocabularyCollectionStatus { mastered, reviewing, needsPractice }

class VocabularyCollectionEntry {
  const VocabularyCollectionEntry({
    required this.word,
    required this.topic,
    required this.progress,
    required this.status,
  });

  final WordRow word;
  final Topic topic;
  final LearningProgressRow progress;
  final VocabularyCollectionStatus status;
}

class VocabularyCollectionSnapshot {
  const VocabularyCollectionSnapshot({
    required this.entries,
    required this.totalWordCount,
  });

  final List<VocabularyCollectionEntry> entries;
  final int totalWordCount;

  int countFor(VocabularyCollectionStatus status) =>
      entries.where((entry) => entry.status == status).length;

  List<VocabularyCollectionEntry> entriesFor(
    VocabularyCollectionStatus status,
  ) => entries.where((entry) => entry.status == status).toList(growable: false);
}
