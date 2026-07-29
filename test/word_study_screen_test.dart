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
