import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/presentation/screens/repetition_practice/repetition_practice_screen.dart';

void main() {
  testWidgets('retries a wrong word and counts the original word only once', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now().millisecondsSinceEpoch;
    await database
        .into(database.learningProgressModels)
        .insert(
          LearningProgressModelsCompanion.insert(
            id: const Value(1),
            creationDate: now - const Duration(days: 2).inMilliseconds,
            trainingError: const Value(1),
            repetitionStep: const Value(1),
            repetitionDate: Value(now - 1),
            learnedDate: Value(now - const Duration(days: 1).inMilliseconds),
          ),
        );

    const target = ExerciseWord(
      id: 1,
      topicId: 7,
      writing: 'apple',
      translation: 'quả táo',
      transliteration: '',
    );
    const distractor = ExerciseWord(
      id: 2,
      topicId: 7,
      writing: 'orange',
      translation: 'quả cam',
      transliteration: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepetitionPracticeScreen(
          title: 'Ôn tập bổ sung',
          words: const [target],
          distractorWords: const [target, distractor],
          database: database,
          loadNextWords: () async => const [],
        ),
      ),
    );

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('repetition-practice-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_repetition_practice.png',
    );
    expect(
      find.byKey(const Key('repetition-practice-close-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('repetition-practice-start-button')),
      findsOneWidget,
    );
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester
          .getBottomRight(
            find.byKey(const Key('repetition-practice-start-button')),
          )
          .dy,
      closeTo(viewportHeight - 16, .1),
    );

    await tester.ensureVisible(find.text('Bắt đầu ôn'));
    await tester.tap(find.text('Bắt đầu ôn'));
    await tester.pump();
    expect(find.byKey(const Key('repetition-countdown-card')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('repetition-question-card')), findsOneWidget);

    await tester.ensureVisible(find.text('quả cam'));
    await tester.tap(find.text('quả cam'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Luyện lại'), findsOneWidget);

    await tester.ensureVisible(find.text('quả táo'));
    await tester.tap(find.text('quả táo'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Hoàn thành rồi!'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    final sessionExercises = await database
        .select(database.sessionExercises)
        .get();
    final progress = await database
        .select(database.learningProgressModels)
        .getSingle();
    final visit = await database.select(database.visitModels).getSingle();

    expect(sessionExercises, hasLength(2));
    expect(sessionExercises.last.isRetry, isTrue);
    expect(progress.trainingError, 0);
    expect(progress.repetitionStep, 2);
    expect(visit.repeatedWordsCount, 1);

    await tester.ensureVisible(find.text('Tiếp tục ôn'));
    await tester.tap(find.text('Tiếp tục ôn'));
    await tester.pumpAndSettle();
    expect(find.text('Hiện không còn từ đến hạn ôn.'), findsOneWidget);
    expect(find.text('Hoàn thành rồi!'), findsOneWidget);
  });
}
