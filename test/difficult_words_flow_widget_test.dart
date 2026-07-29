import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/models/vocabulary_collection.dart';
import 'package:leximon/data/services/learning_progress_service.dart';
import 'package:leximon/presentation/screens/vocabulary_collection/vocabulary_collection_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('search does not change the difficult-word training batch', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final constructorMask = LearningProgressService.bitForType(
      TrainingExerciseType.constructor,
    );
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        WordModelsCompanion.insert(
          id: 1,
          topicId: 1,
          writing: 'airport',
          translation: 'sân bay',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
        WordModelsCompanion.insert(
          id: 2,
          topicId: 1,
          writing: 'passport',
          translation: 'hộ chiếu',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
      ]);
      batch.insertAll(database.learningProgressModels, [
        for (final id in [1, 2])
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: 1,
            trainingError: Value(constructorMask),
          ),
      ]);
    });

    final topic = Topic(
      id: 1,
      order: 1,
      original: 'Travel',
      translated: 'Du lịch',
      words: const [],
    );
    final words = await database.enabledWords();
    final progress = await database
        .select(database.learningProgressModels)
        .get();
    final progressById = {for (final row in progress) row.id: row};
    final snapshot = VocabularyCollectionSnapshot(
      entries: [
        for (final word in words)
          VocabularyCollectionEntry(
            word: word,
            topic: topic,
            progress: progressById[word.id]!,
            status: VocabularyCollectionStatus.needsPractice,
          ),
      ],
      totalWordCount: words.length,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          vocabularyCollectionProvider.overrideWith((ref) async => snapshot),
        ],
        child: const MaterialApp(
          home: VocabularyCollectionScreen(
            status: VocabularyCollectionStatus.needsPractice,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Các từ khó'), findsOneWidget);
    expect(find.text('Luyện từ'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'không có kết quả');
    await tester.pump();
    expect(find.text('Chưa có từ nào trong nhóm này'), findsOneWidget);

    await tester.tap(find.text('Luyện từ'));
    await tester.pumpAndSettle();

    expect(find.text('DIFFICULT WORDS'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('airport'), findsOneWidget);
    expect(find.text('passport'), findsOneWidget);
  });
}
