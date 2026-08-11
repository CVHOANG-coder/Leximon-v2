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

/// Exposure counters for Words in Sentences are kept separate from the core
/// learning row so bundled sentence content can evolve without rewriting it.
@DataClassName('WordSentenceProgressRow')
class WordSentenceProgressModels extends Table {
  IntColumn get wordId => integer()();

  IntColumn get finishedCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {wordId};
}

@DataClassName('SentenceExposureRow')
@TableIndex(name: 'sentence_exposure_word', columns: {#wordId})
class SentenceExposureModels extends Table {
  IntColumn get sentenceId => integer()();

  IntColumn get wordId => integer()();

  IntColumn get finishedCount => integer().withDefault(const Constant(0))();

  IntColumn get insertWordTask => integer().withDefault(const Constant(0))();

  IntColumn get constructorTask => integer().withDefault(const Constant(1))();

  IntColumn get constructorAudioTask =>
      integer().withDefault(const Constant(0))();

  IntColumn get constructorInverseTask =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {sentenceId};
}

@TableIndex(
  name: 'learning_session_status_started_at',
  columns: {#status, #startedAt},
)
class LearningSessions extends Table {
  @override
  String get tableName => 'LearningSession';

  TextColumn get id => text()();

  IntColumn get topicId => integer().nullable()();

  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get requiredMask => integer()();

  IntColumn get originalExerciseCount => integer()();

  IntColumn get currentIndex => integer().withDefault(const Constant(0))();

  IntColumn get startedAt => integer()();

  IntColumn get completedAt => integer().nullable()();

  IntColumn get completionAppliedAt => integer().nullable()();

  IntColumn get successfulWordCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get unresolvedWrongWordCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get completedWordCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get newlyLearnedWordCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'session_exercise_session_order',
  columns: {#sessionId, #orderIndex},
  unique: true,
)
class SessionExercises extends Table {
  @override
  String get tableName => 'SessionExercise';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get sessionId => text()();

  IntColumn get wordId => integer()();

  IntColumn get exerciseType => integer()();

  IntColumn get orderIndex => integer()();

  BoolColumn get isRetry => boolean().withDefault(const Constant(false))();

  IntColumn get parentExerciseId => integer().nullable()();

  IntColumn get answer => integer().withDefault(const Constant(0))();

  IntColumn get answeredAt => integer().nullable()();
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

  IntColumn get wordsInSentencesGoal =>
      integer().withDefault(const Constant(0))();

  IntColumn get repeatedWordsCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get learnedWordsCount => integer().withDefault(const Constant(0))();

  IntColumn get trainedWordsCount => integer().withDefault(const Constant(0))();

  IntColumn get difficultWordsTrainedCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get wordsInSentencesCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get sentencesTrainedCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get sentencesTrainedExtraCount =>
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

@DataClassName('AppUsageDayRow')
class AppUsageDays extends Table {
  /// Local midnight, stored as milliseconds since epoch.
  IntColumn get date => integer()();

  IntColumn get foregroundMilliseconds =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  @override
  String get tableName => 'UserProfile';

  IntColumn get id => integer()();

  TextColumn get name => text()();

  TextColumn get email => text()();

  TextColumn get avatarPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local-only progress for a listening lesson. Status values are managed by
/// [ListeningProgressService]: 0 = not started, 1 = in progress, 2 = complete.
@DataClassName('ListeningLessonProgressRow')
@TableIndex(
  name: 'listening_lesson_progress_status_updated',
  columns: {#status, #updatedAt},
)
class ListeningLessonProgressModels extends Table {
  IntColumn get courseId => integer()();

  IntColumn get lessonId => integer()();

  IntColumn get currentChallengePosition =>
      integer().withDefault(const Constant(1))();

  IntColumn get completedChallenges =>
      integer().withDefault(const Constant(0))();

  IntColumn get totalChallenges => integer()();

  IntColumn get status => integer().withDefault(const Constant(0))();

  IntColumn get startedAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get completedAt => integer().nullable()();

  IntColumn get activeMilliseconds =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {courseId, lessonId};
}

/// Per-challenge attempts are retained locally so an interrupted lesson can
/// resume without relying on a server progress endpoint.
@DataClassName('ListeningChallengeProgressRow')
@TableIndex(
  name: 'listening_challenge_progress_lesson_position',
  columns: {#courseId, #lessonId, #position},
  unique: true,
)
class ListeningChallengeProgressModels extends Table {
  IntColumn get courseId => integer()();

  IntColumn get lessonId => integer()();

  IntColumn get challengeId => integer()();

  IntColumn get position => integer()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  TextColumn get lastAnswer => text().nullable()();

  IntColumn get updatedAt => integer()();

  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {courseId, lessonId, challengeId};
}

/// Listening time is tracked separately from general app foreground time.
@DataClassName('ListeningPracticeDayRow')
class ListeningPracticeDays extends Table {
  /// Local midnight, stored as milliseconds since epoch.
  IntColumn get date => integer()();

  IntColumn get activeMilliseconds =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

@DriftDatabase(
  tables: [
    TopicModels,
    WordModels,
    LearningProgressModels,
    WordSentenceProgressModels,
    SentenceExposureModels,
    LearningSessions,
    SessionExercises,
    SimilarWordModels,
    SttMisspellingModels,
    LetterModels,
    VisitModels,
    OnboardingTestAnswerModels,
    ContentRevisions,
    AppUsageDays,
    UserProfiles,
    ListeningLessonProgressModels,
    ListeningChallengeProgressModels,
    ListeningPracticeDays,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'bright-db'));

  AppDatabase.forTesting(super.e);

  static String topicAssetSource(String languageCode) =>
      'bundled_topics_$languageCode';

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(learningSessions);
        await m.createTable(sessionExercises);
      }
      if (from >= 2 && from < 3) {
        await m.addColumn(
          learningSessions,
          learningSessions.completedWordCount,
        );
      }
      if (from < 4) {
        await m.createTable(appUsageDays);
      }
      if (from < 5) {
        await m.createTable(userProfiles);
      }
      if (from < 6) {
        await m.createTable(wordSentenceProgressModels);
        await m.createTable(sentenceExposureModels);
        await m.addColumn(visitModels, visitModels.wordsInSentencesGoal);
        await m.addColumn(visitModels, visitModels.wordsInSentencesCount);
        await m.addColumn(visitModels, visitModels.sentencesTrainedCount);
        await m.addColumn(visitModels, visitModels.sentencesTrainedExtraCount);
      }
      if (from < 7) {
        await m.createTable(listeningLessonProgressModels);
        await m.createTable(listeningChallengeProgressModels);
        await m.createTable(listeningPracticeDays);
      }
    },
  );

  Future<UserProfileRow?> loadUserProfile() {
    return (select(
      userProfiles,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
  }

  Future<void> saveUserProfile({
    required String name,
    required String email,
    String? avatarPath,
  }) {
    return into(userProfiles).insertOnConflictUpdate(
      UserProfilesCompanion.insert(
        id: const Value(1),
        name: name,
        email: email,
        avatarPath: Value(avatarPath),
      ),
    );
  }

  Future<int?> topicContentRevision([String languageCode = 'vi']) async {
    final query = select(contentRevisions)
      ..where((row) => row.source.equals(topicAssetSource(languageCode)));
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

  Future<void> incrementWordShowCount({
    required int wordId,
    required int topicId,
  }) async {
    await customUpdate(
      'UPDATE "WordModel" '
      'SET show_count = show_count + 1 '
      'WHERE id = ? AND topic_id = ?',
      variables: [Variable.withInt(wordId), Variable.withInt(topicId)],
      updates: {wordModels},
    );
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

  Future<void> upsertTopicContent(
    TopicAssetPayload payload, {
    String languageCode = 'vi',
  }) {
    return transaction(() async {
      final source = topicAssetSource(languageCode);
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
      final topicIds = payload.topics.map((topic) => topic.id).toSet();
      final wordIdsByTopic = {
        for (final topic in payload.topics)
          topic.id: topic.words.map((word) => word.id).toSet(),
      };

      if (topicIds.isNotEmpty) {
        await (delete(
          topicModels,
        )..where((row) => row.id.isNotIn(topicIds))).go();
      }
      if (topicIds.isNotEmpty) {
        await (delete(
          wordModels,
        )..where((row) => row.topicId.isNotIn(topicIds))).go();
      }
      for (final topicId in topicIds) {
        final wordIds = wordIdsByTopic[topicId]!;
        if (wordIds.isEmpty) {
          await (delete(
            wordModels,
          )..where((row) => row.topicId.equals(topicId))).go();
        } else {
          await (delete(wordModels)..where(
                (row) => row.topicId.equals(topicId) & row.id.isNotIn(wordIds),
              ))
              .go();
        }
      }
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
          source: source,
          revision: payload.version,
          syncedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }
}
