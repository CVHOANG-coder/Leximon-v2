import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/models/topic.dart';
import 'package:leximon/data/services/daily_card_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';
import 'package:leximon/presentation/screens/home/home_screen.dart';
import 'package:leximon/presentation/screens/repetition_practice/repetition_practice_screen.dart';
import 'package:leximon/presentation/screens/review_practice/review_practice_screen.dart';
import 'package:leximon/presentation/screens/sentence_training/sentence_training_screen.dart';
import 'package:leximon/presentation/screens/word_study/word_study_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  testWidgets('Home shows the first-training greeting for Learn-only plan', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _pumpHome(tester, database);

    expect(
      find.text('Xin chào, hãy cùng học những từ đầu tiên'),
      findsOneWidget,
    );
    expect(find.text('Học từ mới'), findsOneWidget);
  });

  testWidgets('Home renders exact completed task states without counters', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await database
        .into(database.visitModels)
        .insert(
          VisitModelsCompanion.insert(
            date: today,
            atLeastOneTaskFinished: const Value(true),
            areDailyTasksFinished: const Value(true),
            repeatWordsGoal: const Value(3),
            repeatedWordsCount: const Value(3),
            learnWordsGoal: const Value(4),
            learnedWordsCount: const Value(4),
            trainWordsGoal: const Value(4),
            trainedWordsCount: const Value(4),
            difficultWordsGoal: const Value(4),
            difficultWordsTrainedCount: const Value(4),
          ),
        );
    await _pumpHome(tester, database);

    expect(find.text('Đã lặp lại 3 từ'), findsOneWidget);
    expect(find.text('4 từ đã học'), findsOneWidget);
    expect(find.text('Đã luyện được 4 từ'), findsOneWidget);
    expect(find.text('4 từ khó đã được luyện tập'), findsOneWidget);
    for (final type in DailyTaskType.values) {
      final tile = find.byKey(ValueKey('daily-task-${type.name}'));
      expect(
        find.descendant(of: tile, matching: find.textContaining(' / ')),
        findsNothing,
      );
    }
  });

  testWidgets('Home Repeat opens the due-word repetition lesson', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    await _insertHomeData(database, now: now, type: DailyTaskType.repeat);
    await _pumpHome(tester, database);

    await tester.tap(find.text('Lặp lại các từ'));
    await _pumpNavigation(tester);

    expect(find.byType(RepetitionPracticeScreen), findsOneWidget);
    expect(find.byType(WordStudyScreen), findsNothing);
    expect(find.text('Sẵn sàng ôn lại?'), findsOneWidget);
    expect(find.text('4 từ'), findsWidgets);
  });

  testWidgets('Home Train opens Fast Brain with four due words', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    await _insertHomeData(database, now: now, type: DailyTaskType.train);
    await _pumpHome(tester, database);

    await tester.tap(find.text('Luyện tập các từ'));
    await _pumpNavigation(tester);

    expect(find.byType(ReviewPracticeScreen), findsOneWidget);
    expect(find.byType(WordStudyScreen), findsNothing);
    expect(find.text('FAST BRAIN'), findsOneWidget);
    expect(find.text('0 / 24'), findsOneWidget);
  });

  testWidgets('Home Difficult rebuilds only stored error exercises', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    await _insertHomeData(database, now: now, type: DailyTaskType.difficult);
    await _pumpHome(tester, database);

    await tester.tap(find.text('Luyện tập từ khó'));
    await _pumpNavigation(tester);

    expect(find.byType(ReviewPracticeScreen), findsOneWidget);
    expect(find.byType(WordStudyScreen), findsNothing);
    expect(find.text('DIFFICULT WORDS'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
  });

  testWidgets('Home opens Words in Sentences as a daily task', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    const sentenceWordIds = [4, 5, 9, 11];
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        for (final id in sentenceWordIds)
          WordModelsCompanion.insert(
            id: id,
            topicId: 1,
            writing: 'word$id',
            translation: 'nghĩa $id',
            isEnabled: true,
            priority: 1,
            level: 1,
          ),
      ]);
      batch.insertAll(database.learningProgressModels, [
        for (final id in sentenceWordIds)
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: now.millisecondsSinceEpoch,
            repetitionStep: const Value(1),
          ),
      ]);
    });
    await _pumpHome(tester, database);

    expect(find.text('Ghép câu theo ngữ cảnh'), findsOneWidget);
    await tester.tap(find.text('Ghép câu theo ngữ cảnh'));
    await _pumpNavigation(tester);

    final screen = tester.widget<SentenceTrainingScreen>(
      find.byType(SentenceTrainingScreen),
    );
    expect(screen.source.name, 'daily');
  });
}

Future<void> _pumpHome(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        localDataInitializationProvider.overrideWith((ref) async {}),
        selectedTopicOrdersHydrationProvider.overrideWith((ref) async {}),
        topicsProvider.overrideWith((ref) async => const <Topic>[]),
        topicProgressProvider.overrideWith(
          (ref) async => const <int, double>{},
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _pumpNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _insertHomeData(
  AppDatabase database, {
  required DateTime now,
  required DailyTaskType type,
}) async {
  await database.batch((batch) {
    batch.insertAll(database.wordModels, [
      for (var id = 1; id <= 4; id++)
        WordModelsCompanion.insert(
          id: id,
          topicId: id.isEven ? 2 : 1,
          writing: 'word$id',
          translation: 'nghĩa $id',
          isEnabled: true,
          priority: 1,
          level: 1,
        ),
    ]);
  });

  final errorBit = LearningProgressService.bitForType(
    TrainingExerciseType.constructor,
  );
  await database.batch((batch) {
    batch.insertAll(database.learningProgressModels, [
      for (var id = 1; id <= 4; id++)
        LearningProgressModelsCompanion.insert(
          id: Value(id),
          creationDate: now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
          trainingError: Value(type == DailyTaskType.difficult ? errorBit : 0),
          repetitionStep: Value(type == DailyTaskType.repeat ? 1 : 0),
          repetitionDate: Value(
            type == DailyTaskType.repeat
                ? now
                      .subtract(const Duration(minutes: 1))
                      .millisecondsSinceEpoch
                : null,
          ),
          onFastBrain: Value(type == DailyTaskType.train),
          repetitionFastBrainDate: Value(
            type == DailyTaskType.train
                ? now
                      .subtract(const Duration(minutes: 1))
                      .millisecondsSinceEpoch
                : null,
          ),
        ),
    ]);
  });

  final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  await database
      .into(database.visitModels)
      .insert(
        VisitModelsCompanion.insert(
          date: today,
          repeatWordsGoal: Value(type == DailyTaskType.repeat ? 4 : 0),
          learnWordsGoal: const Value(8),
          trainWordsGoal: Value(type == DailyTaskType.train ? 4 : 0),
          difficultWordsGoal: Value(type == DailyTaskType.difficult ? 4 : 0),
        ),
      );
}
