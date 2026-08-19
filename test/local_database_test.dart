import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/sentence_exercise.dart';
import 'package:leximon/data/repositories/topic_repository.dart';

import 'remote_content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('seeds server topics and words into Drift', () async {
    final dataSource = testTopicDataSource();
    final repository = TopicRepository(
      database: database,
      assetDataSource: dataSource,
    );

    final topics = await repository.loadTopics();

    expect(await database.topicContentRevision(), 36);
    expect(topics, hasLength(3));
    expect(topics.fold<int>(0, (total, topic) => total + topic.wordCount), 4);
  });

  test('keeps local fields when server content is upserted again', () async {
    final dataSource = testTopicDataSource();
    final payload = await dataSource.load();
    await database.upsertTopicContent(payload);

    final firstTopic = payload.topics.first;
    final firstWord = firstTopic.words.first;
    await (database.update(database.topicModels)
          ..where((row) => row.id.equals(firstTopic.id)))
        .write(const TopicModelsCompanion(isSelected: Value(true)));
    await (database.update(database.wordModels)..where(
          (row) =>
              row.id.equals(firstWord.id) & row.topicId.equals(firstTopic.id),
        ))
        .write(const WordModelsCompanion(showCount: Value(7)));

    await database.upsertTopicContent(payload);

    final topic = await (database.select(
      database.topicModels,
    )..where((row) => row.id.equals(firstTopic.id))).getSingle();
    final word =
        await (database.select(database.wordModels)..where(
              (row) =>
                  row.id.equals(firstWord.id) &
                  row.topicId.equals(firstTopic.id),
            ))
            .getSingle();
    expect(topic.isSelected, isTrue);
    expect(word.showCount, 7);
  });

  test('content synchronization preserves learning progress', () async {
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(4),
            creationDate: 123,
            trainingProgress: const Value(8),
          ),
        );
    await database
        .into(database.sentenceExposureModels)
        .insert(
          SentenceExposureModelsCompanion.insert(
            sentenceId: const Value(19499),
            wordId: 4,
            finishedCount: const Value(3),
          ),
        );

    final payload = await testTopicDataSource().load();
    await database.upsertTopicContent(payload);
    await database.replaceSentenceContent(
      languageCode: 'vi',
      sentences: const [
        SentenceRecord(
          translationId: 1,
          wordId: 4,
          sentenceId: 19499,
          spelling: 'She likes tea',
          translation: 'Cô ấy thích trà',
          difficulty: 1,
          wrongSpellings: [],
          taskSpellings: ['likes'],
          task: 'She |likes| tea',
          soundUrl: '',
          alternativeTranslations: [],
        ),
      ],
    );

    final learningProgress = await database
        .select(database.learningProgressModels)
        .getSingle();
    final sentenceProgress = await database
        .select(database.sentenceExposureModels)
        .getSingle();
    expect(learningProgress.trainingProgress, 8);
    expect(sentenceProgress.finishedCount, 3);
  });

  test('loads words from the selected language topic package', () async {
    final repository = TopicRepository(
      database: database,
      assetDataSource: testTopicDataSource(),
    );

    final germanTopics = await repository.loadTopics(languageCode: 'de');

    expect(await database.topicContentRevision('de'), 36);
    expect(germanTopics.first.translated, 'Reisen');
    expect(
      germanTopics.fold<int>(0, (total, topic) => total + topic.wordCount),
      4,
    );

    final vietnameseTopics = await repository.loadTopics(languageCode: 'vi');

    expect(vietnameseTopics.first.translated, 'Du lịch');
    expect(await database.topicContentRevision('vi'), 36);
  });

  test('reads similar word IDs for lesson generation', () async {
    await database
        .into(database.similarWordModels)
        .insert(
          SimilarWordModelsCompanion.insert(
            id: const Value(7058),
            options: jsonEncode([1536, 5731, 7523]),
          ),
        );

    expect(await database.similarWordIdsFor([7058, 9999]), {
      7058: [1536, 5731, 7523],
    });
  });

  test('increments a word show count atomically', () async {
    await database
        .into(database.wordModels)
        .insert(
          WordModelsCompanion.insert(
            id: 10,
            topicId: 20,
            writing: 'airport',
            translation: 'sân bay',
            isEnabled: true,
            priority: 1,
            level: 1,
            showCount: const Value(7),
          ),
        );

    await database.incrementWordShowCount(wordId: 10, topicId: 20);

    final word = await database.select(database.wordModels).getSingle();
    expect(word.showCount, 8);
  });

  test('stores and reads the local user profile', () async {
    await database.saveUserProfile(
      name: 'Nguyễn An',
      email: 'an@example.com',
      avatarPath: '/app/documents/profile/avatar.jpg',
    );

    final profile = await database.loadUserProfile();

    expect(profile?.name, 'Nguyễn An');
    expect(profile?.email, 'an@example.com');
    expect(profile?.avatarPath, '/app/documents/profile/avatar.jpg');
  });

  test('clears learner data while retaining bundled content', () async {
    final payload = await TopicAssetDataSource(bundle: rootBundle).load();
    await database.upsertTopicContent(payload);
    await database.saveUserProfile(name: 'Nguyễn An', email: 'an@example.com');
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(999999),
            creationDate: 123,
            trainingProgress: const Value(8),
          ),
        );
    await (database.update(database.topicModels)
          ..where((row) => row.id.equals(payload.topics.first.id)))
        .write(const TopicModelsCompanion(isSelected: Value(true)));

    await database.clearUserData();

    expect(await database.loadUserProfile(), null);
    expect(
      await database.select(database.learningProgressModels).get(),
      isEmpty,
    );
    final topic = await (database.select(
      database.topicModels,
    )..where((row) => row.id.equals(payload.topics.first.id))).getSingle();
    expect(topic.isSelected, isFalse);
    expect(await database.hasTopicContent(), isTrue);
  });

  test('stores and reads sentence content for the selected language', () async {
    const sentence = SentenceRecord(
      translationId: 101,
      wordId: 7,
      sentenceId: 1001,
      spelling: 'She learns quickly',
      translation: 'Cô ấy học nhanh',
      difficulty: 1,
      wrongSpellings: ['She learn quickly'],
      taskSpellings: ['learns'],
      task: 'She |learns| quickly',
      soundUrl: 'https://example.com/sentence.mp3',
      alternativeTranslations: ['Cô ấy tiếp thu nhanh'],
    );

    await database.replaceSentenceContent(
      languageCode: 'vi',
      sentences: const [sentence],
    );

    final sentences = await database.loadSentenceContent(languageCode: 'vi');
    expect(sentences, hasLength(1));
    expect(sentences.single.translationId, sentence.translationId);
    expect(sentences.single.spelling, sentence.spelling);
    expect(sentences.single.translation, sentence.translation);
    expect(sentences.single.wrongSpellings, sentence.wrongSpellings);
    expect(sentences.single.taskSpellings, sentence.taskSpellings);
    expect(
      sentences.single.alternativeTranslations,
      sentence.alternativeTranslations,
    );
    expect(await database.loadSentenceContent(languageCode: 'de'), isEmpty);
  });
}
