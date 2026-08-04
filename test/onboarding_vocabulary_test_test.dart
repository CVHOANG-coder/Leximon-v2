import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/onboarding_vocabulary_test.dart';
import 'package:leximon/data/services/onboarding_vocabulary_test_service.dart';
import 'package:leximon/presentation/screens/onboarding/vocabulary_test_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all local test levels and builds valid choices', () async {
    final service = OnboardingVocabularyTestService();
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

  testWidgets('renders choices and allows constructor questions to continue', (
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
      find.byKey(const ValueKey('vocabulary-test-constructor-coming-soon')),
      findsOneWidget,
    );
    await tester.pump();
    expect(find.text('Coming soon'), findsNWidgets(2));
    await tester.tap(
      find.byKey(const ValueKey('constructor-coming-soon-close')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vocabulary-test-next')), findsOneWidget);
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
      );
    });
  }
}
