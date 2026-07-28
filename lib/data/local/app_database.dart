import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/topic_asset_payload.dart';

part 'app_database.g.dart';

@DataClassName('TopicRow')
@TableIndex(
  name: 'topic_model_enabled_order',
  columns: {#isEnabled, #sortOrder},
)
class TopicModels extends Table {
  @override
  String get tableName => 'TopicModel';

  IntColumn get id => integer()();

  TextColumn get originalName => text().nullable()();

  TextColumn get translatedName => text().nullable()();

  BoolColumn get isEnabled => boolean()();

  IntColumn get sortOrder => integer().named('order')();

  BoolColumn get isSelected => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WordRow')
@TableIndex(name: 'word_model_topic_enabled', columns: {#topicId, #isEnabled})
class WordModels extends Table {
  @override
  String get tableName => 'WordModel';

  IntColumn get id => integer()();

  IntColumn get topicId => integer()();

  TextColumn get writing => text()();

  TextColumn get translation => text()();

  TextColumn get transcription => text().nullable()();

  TextColumn get transliteration => text().nullable()();

  BoolColumn get isEnabled => boolean()();

  IntColumn get priority => integer()();

  IntColumn get level => integer()();

  IntColumn get showCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id, topicId};
}

@DataClassName('LearningProgressRow')
@TableIndex(
  name: 'learning_progress_repetition_date',
  columns: {#repetitionDate},
)
class LearningProgressModels extends Table {
  @override
  String get tableName => 'LearningProgressModel';

  IntColumn get id => integer()();

  IntColumn get creationDate => integer()();

  IntColumn get trainingProgress => integer().withDefault(const Constant(0))();

  IntColumn get trainingError => integer().withDefault(const Constant(0))();

  IntColumn get repetitionStep => integer().withDefault(const Constant(0))();

  IntColumn get repetitionDate => integer().nullable()();

  IntColumn get learnedDate => integer().nullable()();

  BoolColumn get onFastBrain => boolean().withDefault(const Constant(false))();

  IntColumn get repetitionFastBrainStep =>
      integer().withDefault(const Constant(0))();

  IntColumn get repetitionFastBrainDate => integer().nullable()();

  BoolColumn get markedAsKnown =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get deletedByUser =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SimilarWordRow')
class SimilarWordModels extends Table {
  @override
  String get tableName => 'SimilarWordModel';

  IntColumn get id => integer()();

  TextColumn get options => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SttMisspellingRow')
class SttMisspellingModels extends Table {
  @override
  String get tableName => 'SttMisspellingModel';

  IntColumn get id => integer()();

  TextColumn get misspellings => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LetterRow')
class LetterModels extends Table {
  @override
  String get tableName => 'LetterModel';

  IntColumn get id => integer()();

  TextColumn get writing => text().nullable()();

  TextColumn get transcription => text().nullable()();

  IntColumn get alphabetOrder => integer().nullable()();

  IntColumn get educationOrder => integer().nullable()();

  TextColumn get audioFilename => text().nullable()();

  TextColumn get digitValue => text().nullable()();

  TextColumn get type => text()();

  TextColumn get variations => text()();

  TextColumn get vowels => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VisitRow')
class VisitModels extends Table {
  @override
  String get tableName => 'VisitModel';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get date => integer()();

  BoolColumn get areDailyTasksFinished =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get atLeastOneTaskFinished =>
      boolean().withDefault(const Constant(false))();

  IntColumn get repeatWordsGoal => integer().withDefault(const Constant(0))();

  IntColumn get learnWordsGoal => integer().withDefault(const Constant(0))();

  IntColumn get trainWordsGoal => integer().withDefault(const Constant(0))();

  IntColumn get difficultWordsGoal =>
      integer().withDefault(const Constant(0))();

  IntColumn get repeatedWordsCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get learnedWordsCount => integer().withDefault(const Constant(0))();

  IntColumn get trainedWordsCount => integer().withDefault(const Constant(0))();

  IntColumn get difficultWordsTrainedCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get problemWordsHealedCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get learningsWithoutMistakes =>
      integer().withDefault(const Constant(0))();

  IntColumn get learnedWordsWithoutMistakes =>
      integer().withDefault(const Constant(0))();
}

@DataClassName('OnboardingTestAnswerRow')
class OnboardingTestAnswerModels extends Table {
  @override
  String get tableName => 'OnboardingTestAnswerModel';

  TextColumn get questionId => text()();

  BoolColumn get isCorrectAnswered => boolean().nullable()();

  TextColumn get answerId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {questionId};
}

@DataClassName('ContentRevisionRow')
class ContentRevisions extends Table {
  TextColumn get source => text()();

  IntColumn get revision => integer()();

  IntColumn get syncedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source};
}

@DriftDatabase(
  tables: [
    TopicModels,
    WordModels,
    LearningProgressModels,
    SimilarWordModels,
    SttMisspellingModels,
    LetterModels,
    VisitModels,
    OnboardingTestAnswerModels,
    ContentRevisions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'bright-db'));

  AppDatabase.forTesting(super.e);

  static const topicAssetSource = 'bundled_topic_word_params';

  @override
  int get schemaVersion => 1;

  Future<int?> topicContentRevision() async {
    final query = select(contentRevisions)
      ..where((row) => row.source.equals(topicAssetSource));
    return (await query.getSingleOrNull())?.revision;
  }

  Future<bool> hasTopicContent() async {
    final topic = await (select(topicModels)..limit(1)).getSingleOrNull();
    return topic != null;
  }

  Future<List<TopicRow>> enabledTopics() {
    final query = select(topicModels)
      ..where((row) => row.isEnabled.equals(true))
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortOrder),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.get();
  }

  Future<List<WordRow>> enabledWords() {
    final query = select(wordModels)
      ..where((row) => row.isEnabled.equals(true))
      ..orderBy([
        (row) => OrderingTerm.asc(row.topicId),
        (row) => OrderingTerm.desc(row.priority),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.get();
  }

  Future<Map<int, List<int>>> similarWordIdsFor(Iterable<int> wordIds) async {
    final ids = wordIds.toSet();
    if (ids.isEmpty) return const {};

    final query = select(similarWordModels)..where((row) => row.id.isIn(ids));
    final rows = await query.get();
    return {
      for (final row in rows)
        row.id: (jsonDecode(row.options) as List<dynamic>)
            .whereType<num>()
            .map((id) => id.toInt())
            .toList(growable: false),
    };
  }

  Future<void> upsertTopicContent(TopicAssetPayload payload) {
    return transaction(() async {
      final existingTopics = await select(topicModels).get();
      final topicSelections = {
        for (final topic in existingTopics) topic.id: topic.isSelected,
      };

      final existingWords = await select(wordModels).get();
      final wordShowCounts = {
        for (final word in existingWords)
          (word.id, word.topicId): word.showCount,
      };

      final topicRows = <TopicModelsCompanion>[];
      final wordRows = <WordModelsCompanion>[];
      for (final topic in payload.topics) {
        topicRows.add(
          TopicModelsCompanion(
            id: Value(topic.id),
            originalName: Value(topic.original),
            translatedName: Value(topic.translated),
            isEnabled: Value(topic.isEnabled),
            sortOrder: Value(topic.order),
            isSelected: Value(topicSelections[topic.id] ?? false),
          ),
        );

        for (final word in topic.words) {
          wordRows.add(
            WordModelsCompanion(
              id: Value(word.id),
              topicId: Value(topic.id),
              writing: Value(word.writing),
              translation: Value(word.translation),
              transcription: Value(word.transcription),
              transliteration: Value(word.transliteration),
              isEnabled: Value(word.isEnabled && topic.isEnabled),
              priority: Value(word.priority),
              level: Value(word.level),
              showCount: Value(wordShowCounts[(word.id, topic.id)] ?? 0),
            ),
          );
        }
      }

      await batch((batch) {
        batch.insertAll(
          topicModels,
          topicRows,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(wordModels, wordRows, mode: InsertMode.insertOrReplace);
      });

      await into(contentRevisions).insertOnConflictUpdate(
        ContentRevisionsCompanion.insert(
          source: topicAssetSource,
          revision: payload.version,
          syncedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }
}
