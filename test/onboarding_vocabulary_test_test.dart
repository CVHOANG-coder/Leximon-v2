import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/onboarding_vocabulary_test.dart';
import 'package:leximon/data/models/sentence_exercise.dart';
import 'package:leximon/data/services/onboarding_vocabulary_test_service.dart';
import 'package:leximon/presentation/screens/onboarding/vocabulary_test_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all local test levels and builds valid choices', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final definitions =
        (jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/vocabulary_test.json',
                  ),
                )
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        for (final definition in definitions)
          WordModelsCompanion.insert(
            id: definition['id'] as int,
            topicId: 1,
            writing: 'word-${definition['id']}',
            translation: 'meaning-${definition['id']}',
            isEnabled: true,
            priority: 1,
            level: 1,
          ),
      ]);
    });
    final sentences = [
      for (final definition in definitions)
        if (definition['taskType'] == 'Constructor')
          SentenceRecord(
            translationId: definition['id'] as int,
            wordId: definition['id'] as int,
            sentenceId: definition['id'] as int,
            spelling: definition['task'] as String,
            translation: 'translation-${definition['id']}',
            difficulty: 1,
            wrongSpellings: const [],
            taskSpellings: const [],
            task: definition['task'] as String,
            soundUrl: '',
            alternativeTranslations: const [],
          ),
    ];
    await database.replaceSentenceContent(
      languageCode: 'vi',
      sentences: sentences,
    );
    final service = OnboardingVocabularyTestService(database: database);
    const expectedCounts = {
      BrightLevel.a1: 5,
      BrightLevel.a2: 6,
      BrightLevel.a3: 5,
      BrightLevel.b1: 5,
      BrightLevel.b2: 6,
      BrightLevel.b3: 5,
      BrightLevel.c1: 6,
      BrightLevel.c2: 6,
      BrightLevel.c3: 5,
    };

    for (final entry in expectedCounts.entries) {
      final questions = await service.loadQuestions(entry.key);
      expect(questions, hasLength(entry.value));
      for (final question in questions) {
        if (question.isConstructor) {
          expect(question.choices, isEmpty);
          expect(question.sentenceExercise, isNotNull);
          expect(question.sentenceExercise!.expectedTokens, isNotEmpty);
          continue;
        }
        final expectedChoiceCount =
            question.definition.type == VocabularyTaskType.audioThree ? 3 : 4;
        expect(question.choices, hasLength(expectedChoiceCount));
        expect(
          question.choices.where((choice) => choice.isCorrect),
          hasLength(1),
        );
        expect(
          question.choices.map((choice) => choice.text).toSet(),
          hasLength(expectedChoiceCount),
        );
      }
    }
  });

  test('follows the documented adaptive assessment branches', () {
    final beginner = VocabularyAssessmentTree.forBand(
      VocabularyStartingBand.beginner,
    );
    expect(beginner.level, BrightLevel.a2);
    expect(
      beginner
          .next(didPass: true)
          .next(didPass: false)
          .next(didPass: true)
          .level,
      BrightLevel.a2,
    );

    final intermediate = VocabularyAssessmentTree.forBand(
      VocabularyStartingBand.intermediate,
    );
    expect(intermediate.level, BrightLevel.b2);
    expect(
      intermediate
          .next(didPass: true)
          .next(didPass: true)
          .next(didPass: false)
          .level,
      BrightLevel.b3,
    );

    final advanced = VocabularyAssessmentTree.forBand(
      VocabularyStartingBand.advanced,
    );
    expect(advanced.level, BrightLevel.c2);
    expect(
      advanced
          .next(didPass: true)
          .next(didPass: true)
          .next(didPass: false)
          .level,
      BrightLevel.c1,
    );
  });

  testWidgets('renders sentence constructor UI and allows it to continue', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: VocabularyTestScreen(
          startingBand: VocabularyStartingBand.beginner,
          service: _FakeVocabularyTestService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Từ này có nghĩa là gì?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vocabulary-test-choice-0')),
      findsOneWidget,
    );

    for (var question = 0; question < 3; question++) {
      await tester.tap(find.byKey(const ValueKey('vocabulary-test-choice-0')));
      await tester.pump();
      expect(find.text('Tiếp theo'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('vocabulary-test-next')));
      await tester.pump();
    }

    expect(
      find.byKey(const ValueKey('vocabulary-test-sentence-constructor')),
      findsOneWidget,
    );
    expect(find.text('GHÉP CÂU TIẾNG ANH'), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      await tester.tap(
        find.byKey(ValueKey('vocabulary-test-sentence-token-$index')),
      );
      await tester.pump();
    }
    expect(find.text('Kiểm tra'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('vocabulary-test-next')));
    await tester.pumpAndSettle();
    expect(find.text('Chính xác!'), findsOneWidget);
    expect(find.text('Câu trả lời của bạn'), findsOneWidget);
    expect(find.text('Câu trả lời đúng'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vocabulary-test-next')), findsOneWidget);
  });

  testWidgets('shows the wrong-answer sheet for an incorrect meaning choice', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: VocabularyTestScreen(
          startingBand: VocabularyStartingBand.beginner,
          service: _FakeVocabularyTestService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('vocabulary-test-choice-1')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Chú ý'), findsOneWidget);
    expect(find.text('CÂU TRẢ LỜI CỦA BẠN'), findsOneWidget);
    expect(find.text('CÂU TRẢ LỜI ĐÚNG'), findsOneWidget);
    expect(find.text('Sai 1'), findsNWidgets(2));
    expect(find.text('Đúng'), findsNWidgets(2));

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('Chú ý'), findsNothing);
  });
}

class _FakeVocabularyTestService extends OnboardingVocabularyTestService {
  @override
  Future<List<VocabularyTestQuestion>> loadQuestions(BrightLevel level) async {
    return List.generate(5, (index) {
      final type = switch (index) {
        0 => VocabularyTaskType.text,
        1 => VocabularyTaskType.inverseText,
        2 => VocabularyTaskType.audioThree,
        3 => VocabularyTaskType.constructor,
        _ => VocabularyTaskType.text,
      };
      return VocabularyTestQuestion(
        definition: VocabularyTestDefinition(
          id: level.index * 10 + index,
          task: 'word-$index',
          frequency: 100 - index,
          type: type,
          level: level,
        ),
        writing: type == VocabularyTaskType.constructor
            ? 'Everything is ready'
            : 'word-$index',
        translation: 'nghĩa-$index',
        transcription: '/word/',
        choices: type == VocabularyTaskType.constructor
            ? const []
            : const [
                VocabularyTestChoice(text: 'Đúng', isCorrect: true),
                VocabularyTestChoice(text: 'Sai 1', isCorrect: false),
                VocabularyTestChoice(text: 'Sai 2', isCorrect: false),
                VocabularyTestChoice(text: 'Sai 3', isCorrect: false),
              ],
        sentenceExercise: type == VocabularyTaskType.constructor
            ? SentenceExercise(
                sentence: SentenceRecord(
                  translationId: 1,
                  wordId: level.index * 10 + index,
                  sentenceId: 1,
                  spelling: 'Can I help you?',
                  translation: 'Tôi có thể giúp bạn không?',
                  difficulty: 0,
                  wrongSpellings: const [],
                  taskSpellings: const ['help'],
                  task: 'Can I |help| you?',
                  soundUrl: '',
                  alternativeTranslations: const [],
                ),
                type: SentenceExerciseType.constructor,
                choices: const ['Can', 'I', 'help', 'you?'],
                expectedTokens: const ['Can', 'I', 'help', 'you?'],
              )
            : null,
      );
    });
  }
}
