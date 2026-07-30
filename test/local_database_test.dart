import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/topic_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('seeds bundled topics and words into Drift', () async {
    final dataSource = TopicAssetDataSource();
    final repository = TopicRepository(
      database: database,
      assetDataSource: dataSource,
    );

    final topics = await repository.loadTopics();

    expect(await database.topicContentRevision(), 36);
    expect(topics, hasLength(47));
    expect(
      topics.fold<int>(0, (total, topic) => total + topic.wordCount),
      5995,
    );
  });

  test('keeps local fields when bundled content is upserted again', () async {
    final dataSource = TopicAssetDataSource();
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
}
