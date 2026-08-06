import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/learning_language_level.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/presentation/screens/learning_filter/learning_filter_screen.dart';
import 'package:leximon/presentation/screens/review_practice/review_practice_screen.dart';
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

  testWidgets('topic strip keeps its visual and reveals selected topic', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.reset);

    final topics = [
      for (var index = 1; index <= 8; index++)
        Topic(
          id: index,
          order: index,
          original: 'Topic $index',
          translated: 'Chủ đề số $index',
          words: [
            {
              'id': index,
              'writing': 'word $index',
              'translation': 'nghĩa $index',
            },
          ],
        ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => topics),
          wordProgressProvider.overrideWith(
            (ref) async => const <int, LearningProgressRow>{},
          ),
        ],
        child: MaterialApp(home: WordStudyScreen(topic: topics.first)),
      ),
    );
    await tester.pumpAndSettle();

    final lastCardFinder = find.byKey(
      const ValueKey('word-study-topic-card-8'),
    );
    final lastCardTap = find.ancestor(
      of: lastCardFinder,
      matching: find.byType(GestureDetector),
    );
    tester.widget<GestureDetector>(lastCardTap.first).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Chủ đề số 8'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('word-study-active-topic-star')),
      findsOneWidget,
    );
    final selectedCard = tester.widget<AnimatedContainer>(lastCardFinder);
    final selectedDecoration = selectedCard.decoration! as BoxDecoration;
    expect(selectedDecoration.color, const Color(0xFFFFFFFF));

    final stripRect = tester.getRect(
      find.byKey(const Key('word-study-topic-strip')),
    );
    final cardRect = tester.getRect(lastCardFinder);
    expect(cardRect.left, greaterThanOrEqualTo(stripRect.left));
    expect(cardRect.right, lessThanOrEqualTo(stripRect.right));
  });

  testWidgets('automatically speaks each newly visible word card', (
    tester,
  ) async {
    final spokenWords = <String>[];
    const ttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          if (call.method == 'speak') {
            final arguments = call.arguments;
            spokenWords.add(
              arguments is Map
                  ? arguments['text'] as String
                  : arguments as String,
            );
          }
          return 1;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ttsChannel, null),
    );

    const topic = Topic(
      id: 57,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'airport', 'translation': 'sân bay'},
        {'id': 2, 'writing': 'passport', 'translation': 'hộ chiếu'},
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => [topic]),
          wordProgressProvider.overrideWith(
            (ref) async => const <int, LearningProgressRow>{},
          ),
        ],
        child: const MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pumpAndSettle();
    await _waitForSpokenWord(tester, spokenWords, 'airport');

    await tester.tap(find.bySemanticsLabel('Từ tiếp theo'));
    await tester.pumpAndSettle();
    await _waitForSpokenWord(tester, spokenWords, 'passport');

    expect(spokenWords.where((word) => word == 'airport'), hasLength(1));
    expect(spokenWords.last, 'passport');
  });

  testWidgets('opens learning filters from the study settings button', (
    tester,
  ) async {
    const topic = Topic(
      id: 57,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'airport', 'translation': 'sân bay'},
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topicsProvider.overrideWith((ref) async => [topic]),
          wordProgressProvider.overrideWith(
            (ref) async => const <int, LearningProgressRow>{},
          ),
        ],
        child: const MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Cài đặt'));
    await tester.pumpAndSettle();

    expect(find.byType(LearningFilterScreen), findsOneWidget);
    expect(find.text('BỘ LỌC HỌC'), findsOneWidget);
    expect(find.text('Bước 1 / 2'), findsNothing);
    expect(find.text('Tiếp tục'), findsNothing);
    expect(find.text('Áp dụng'), findsOneWidget);
    expect(find.byKey(const ValueKey('assets/svgs/book.svg')), findsOneWidget);
  });

  testWidgets('clears selected words after exiting practice early', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const topic = Topic(
      id: 57,
      order: 1,
      original: 'Traveling',
      translated: 'Du lịch',
      words: [
        {'id': 1, 'writing': 'trip', 'translation': 'chuyến đi'},
        {'id': 2, 'writing': 'passport', 'translation': 'hộ chiếu'},
        {'id': 3, 'writing': 'visa', 'translation': 'thị thực'},
        {'id': 4, 'writing': 'suitcase', 'translation': 'va li'},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          topicsProvider.overrideWith((ref) async => [topic]),
          wordProgressProvider.overrideWith(
            (ref) async => const <int, LearningProgressRow>{},
          ),
        ],
        child: const MaterialApp(home: WordStudyScreen(topic: topic)),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.text('Học từ này').hitTestable().first);
      await tester.pumpAndSettle();
    }

    expect(find.byType(ReviewPracticeScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('review-practice-close-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc ôn tập'));
    await tester.pumpAndSettle();

    expect(find.byType(WordStudyScreen), findsOneWidget);
    expect(find.text('Đã chọn 0 / 4 từ'), findsOneWidget);
    expect(find.text('Chưa phân loại'), findsWidgets);
    expect(find.text('Học từ này'), findsWidgets);
  });

  testWidgets('shows recommended words from selected topics and level', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    for (final row in [
      (id: 1, topicId: 10, level: 1, showCount: 3),
      (id: 2, topicId: 10, level: 1, showCount: 0),
      (id: 3, topicId: 20, level: 1, showCount: 0),
      (id: 4, topicId: 20, level: 4, showCount: 0),
    ]) {
      await database
          .into(database.wordModels)
          .insert(
            WordModelsCompanion.insert(
              id: row.id,
              topicId: row.topicId,
              writing: 'word ${row.id}',
              translation: 'nghĩa ${row.id}',
              isEnabled: true,
              priority: 1,
              level: row.level,
              showCount: Value(row.showCount),
            ),
          );
    }
    final topics = [
      Topic(
        id: 10,
        order: 1,
        original: 'One',
        translated: 'Một',
        words: [
          _studyWord(1, topicId: 10, level: 1, showCount: 3),
          _studyWord(2, topicId: 10, level: 1, showCount: 0),
        ],
      ),
      Topic(
        id: 20,
        order: 2,
        original: 'Two',
        translated: 'Hai',
        words: [
          _studyWord(3, topicId: 20, level: 1, showCount: 0),
          _studyWord(4, topicId: 20, level: 4, showCount: 0),
        ],
      ),
    ];
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        topicsProvider.overrideWith((ref) async => topics),
        wordProgressProvider.overrideWith(
          (ref) async => const <int, LearningProgressRow>{},
        ),
        selectedTopicOrdersProvider.overrideWith((ref) => {1, 2}),
        selectedLanguageLevelsProvider.overrideWith(
          (ref) => {LearningLanguageLevel.beginner},
        ),
      ],
    );
    container.read(appDatabaseProvider);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: WordStudyScreen(topic: topics.first)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khuyên dùng'), findsOneWidget);
    await tester.tap(find.text('Khuyên dùng'));
    await tester.pumpAndSettle();

    expect(find.text('★  Khuyên dùng'), findsOneWidget);
    expect(find.text('word 2'), findsWidgets);
    expect(find.text('word 4'), findsNothing);

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        final row =
            await (database.select(
                  database.wordModels,
                )..where((word) => word.id.equals(2) & word.topicId.equals(10)))
                .getSingle();
        if (row.showCount == 1) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('Recommended card showCount was not incremented.');
    });
  });
}

Map<String, dynamic> _studyWord(
  int id, {
  required int topicId,
  required int level,
  required int showCount,
}) {
  return {
    'id': id,
    'topicId': topicId,
    'writing': 'word $id',
    'translation': 'nghĩa $id',
    'level': level,
    'showCount': showCount,
    'enabled': true,
  };
}

Future<void> _waitForSpokenWord(
  WidgetTester tester,
  List<String> spokenWords,
  String expected,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      if (spokenWords.contains(expected)) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('TTS did not speak "$expected". Calls: $spokenWords');
  });
}
