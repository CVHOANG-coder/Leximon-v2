import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets(
    'refreshes Home topic progress when study closes after marking known',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database
          .into(database.wordModels)
          .insert(
            WordModelsCompanion.insert(
              id: 7058,
              topicId: 57,
              writing: 'affect',
              translation: 'ảnh hưởng đến',
              isEnabled: true,
              priority: 1,
              level: 1,
            ),
          );
      const topic = Topic(
        id: 57,
        order: 1,
        original: 'Traveling',
        translated: 'Du lịch',
        words: [
          {'id': 7058, 'writing': 'affect', 'translation': 'ảnh hưởng đến'},
        ],
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          localDataInitializationProvider.overrideWith((ref) async {}),
          topicsProvider.overrideWith((ref) async => [topic]),
        ],
      );
      addTearDown(container.dispose);

      final initialProgress = await container.read(
        topicProgressProvider.future,
      );
      expect(initialProgress[57], 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WordStudyScreen(topic: topic)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã biết').hitTestable().first);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 50; attempt++) {
          final progress = await (database.select(
            database.learningProgressModels,
          )..where((row) => row.id.equals(7058))).getSingleOrNull();
          if (progress?.markedAsKnown ?? false) return;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('markedAsKnown was not persisted.');
      });

      final refreshedProgress = await container.read(
        topicProgressProvider.future,
      );
      expect(refreshedProgress[57], 1);
    },
  );

  testWidgets('loads only unclassified database words on entry', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(113),
            creationDate: DateTime.now().millisecondsSinceEpoch,
            markedAsKnown: const Value(true),
          ),
        );

    const staleTopic = Topic(
      id: 57,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {'id': 113, 'writing': 'stale word', 'translation': 'stale'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          localDataInitializationProvider.overrideWith((ref) async {}),
          topicsProvider.overrideWith(
            (ref) async => [
              const Topic(
                id: 57,
                order: 1,
                original: 'Traveling',
                translated: 'Du lịch',
                words: [
                  {
                    'id': 113,
                    'writing': 'half board',
                    'translation': 'ăn uống bán phần',
                  },
                  {
                    'id': 7058,
                    'writing': 'affect',
                    'translation': 'ảnh hưởng đến',
                  },
                ],
              ),
            ],
          ),
        ],
        child: MaterialApp(home: WordStudyScreen(topic: staleTopic)),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('affect'), findsWidgets);
    expect(find.text('half board'), findsNothing);
    expect(find.text('stale word'), findsNothing);

    await tester.tap(find.text('Đã biết').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('affect'), findsWidgets);
  });
}
