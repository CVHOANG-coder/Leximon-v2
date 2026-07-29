import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/practice_lesson_generator.dart';

void main() {
  const selectedWords = [
    ExerciseWord(
      id: 1,
      topicId: 57,
      writing: 'boarding pass',
      translation: 'thẻ lên máy bay',
      transliteration: '/ˈbɔːr.dɪŋ pæs/',
    ),
    ExerciseWord(
      id: 2,
      topicId: 57,
      writing: 'customs',
      translation: 'hải quan',
      transliteration: '/ˈkʌs.təmz/',
    ),
    ExerciseWord(
      id: 3,
      topicId: 57,
      writing: 'luggage',
      translation: 'hành lý',
      transliteration: '/ˈlʌɡ.ɪdʒ/',
    ),
    ExerciseWord(
      id: 4,
      topicId: 57,
      writing: 'flight attendant',
      translation: 'tiếp viên hàng không',
      transliteration: '/ˈflaɪt əˌten.dənt/',
    ),
  ];

  final enabledWords = [
    ...selectedWords,
    for (var id = 5; id <= 12; id++)
      ExerciseWord(
        id: id,
        topicId: id <= 8 ? 57 : 99,
        writing: 'word$id',
        translation: 'nghĩa $id',
        transliteration: '/word$id/',
      ),
  ];

  test('builds the exact six-block 24-question lesson', () {
    final questions = PracticeLessonGenerator(random: Random(24)).buildLesson(
      words: selectedWords,
      enabledWords: enabledWords,
      similarWordIds: const {
        1: [9, 10, 11],
        2: [9, 10, 11],
        3: [9, 10, 11],
        4: [9, 10, 11],
      },
    );

    expect(questions, hasLength(24));
    expect(
      questions.map((question) => question.answer),
      everyElement(ExerciseAnswerState.notAnswered),
    );
    expect(questions.map((question) => question.trainingExercise), [
      ...List.filled(4, TrainingExerciseType.choiceOfFourToEng),
      ...List.filled(4, TrainingExerciseType.choiceOfFourFromEng),
      ...List.filled(4, TrainingExerciseType.choiceOfThreeListening),
      ...List.filled(4, TrainingExerciseType.constructor),
      ...List.filled(4, TrainingExerciseType.choiceOfFourListening),
      ...List.filled(4, TrainingExerciseType.speaking),
    ]);

    for (var blockStart = 0; blockStart < 24; blockStart += 4) {
      expect(
        questions.skip(blockStart).take(4).map((question) => question.word.id),
        [1, 2, 3, 4],
      );
    }
  });

  test('builds a final difficult batch with fewer than four words', () {
    final questions = PracticeLessonGenerator(random: Random(12)).buildLesson(
      words: selectedWords.take(2).toList(),
      enabledWords: enabledWords,
    );

    expect(questions, hasLength(12));
    expect(questions.map((question) => question.trainingExercise), [
      ...List.filled(2, TrainingExerciseType.choiceOfFourToEng),
      ...List.filled(2, TrainingExerciseType.choiceOfFourFromEng),
      ...List.filled(2, TrainingExerciseType.choiceOfThreeListening),
      ...List.filled(2, TrainingExerciseType.constructor),
      ...List.filled(2, TrainingExerciseType.choiceOfFourListening),
      ...List.filled(2, TrainingExerciseType.speaking),
    ]);
  });

  test('builds one two-option question per repetition word', () {
    final questions = PracticeLessonGenerator(
      random: Random(3),
    ).buildRepetitionLesson(words: selectedWords, enabledWords: enabledWords);

    expect(questions, hasLength(4));
    for (final question in questions) {
      expect(question.variants, hasLength(2));
      expect(question.variants, contains(question.word));
      expect(
        question.variants.where((word) => word.id != question.word.id),
        everyElement(
          predicate<ExerciseWord>(
            (word) => word.topicId == question.word.topicId,
          ),
        ),
      );
      expect(question.trainingExercise, TrainingExerciseType.choiceOfTwo);
    }
  });

  test('does not use a duplicate translation as repetition distractor', () {
    final words = [
      selectedWords.first,
      ExerciseWord(
        id: 20,
        topicId: 57,
        writing: 'duplicate',
        translation: ' THẺ LÊN MÁY BAY ',
        transliteration: '',
      ),
      selectedWords[1],
    ];

    final question = PracticeLessonGenerator(random: Random(1))
        .buildRepetitionLesson(
          words: [selectedWords.first],
          enabledWords: words,
        )
        .single;

    expect(question.variants.map((word) => word.id), isNot(contains(20)));
    expect(question.variants, contains(selectedWords[1]));
  });

  test('skips repetition words without a same-topic distractor', () {
    final questions = PracticeLessonGenerator(random: Random(1))
        .buildRepetitionLesson(
          words: [selectedWords.first],
          enabledWords: [selectedWords.first, enabledWords.last],
        );

    expect(questions, isEmpty);
  });

  test('uses the correct variant source and includes the target word', () {
    final questions = PracticeLessonGenerator(random: Random(7)).buildLesson(
      words: selectedWords,
      enabledWords: enabledWords,
      similarWordIds: const {
        1: [9, 10, 11],
        2: [9, 10, 11],
        3: [9, 10, 11],
        4: [9, 10, 11],
      },
    );

    for (final question in questions.take(4)) {
      expect(question.variants, hasLength(4));
      expect(
        question.variants.where((word) => word.id != question.word.id),
        everyElement(predicate<ExerciseWord>((word) => word.topicId == 57)),
      );
      expect(
        question.variants.any((word) => word.id == question.word.id),
        isTrue,
      );
    }

    for (final question in questions.skip(4).take(4)) {
      expect(question.variants, hasLength(4));
      expect(
        question.variants
            .where((word) => word.id != question.word.id)
            .map((word) => word.id)
            .toSet(),
        containsAll([9, 10, 11]),
      );
    }

    for (final question in questions.skip(8).take(4)) {
      expect(question.variants, hasLength(3));
      expect(
        question.variants.any((word) => word.id == question.word.id),
        isTrue,
      );
    }

    for (final question in [
      ...questions.skip(12).take(4),
      ...questions.skip(20).take(4),
    ]) {
      expect(question.variants, isEmpty);
    }
  });

  test('respects listening and pronouncing settings', () {
    int questionCount({required bool listening, required bool pronouncing}) {
      return PracticeLessonGenerator(random: Random(1))
          .buildLesson(
            words: selectedWords,
            enabledWords: enabledWords,
            listeningEnabled: listening,
            pronouncingEnabled: pronouncing,
          )
          .length;
    }

    expect(questionCount(listening: false, pronouncing: false), 12);
    expect(questionCount(listening: false, pronouncing: true), 16);
    expect(questionCount(listening: true, pronouncing: false), 20);
    expect(questionCount(listening: true, pronouncing: true), 24);
  });

  test('matches FROM_ENG option capitalization to the target word', () {
    final uppercaseWords = [
      selectedWords.first.copyWith(writing: 'BOARDING PASS'),
      ...selectedWords.skip(1),
    ];
    final questions = PracticeLessonGenerator(random: Random(5)).buildLesson(
      words: uppercaseWords,
      enabledWords: enabledWords,
      similarWordIds: const {
        1: [9, 10, 11],
      },
    );

    expect(
      questions[4].variants.map((word) => word.writing),
      everyElement(
        predicate<String>((writing) => writing == writing.toUpperCase()),
      ),
    );
  });
}
