import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/sentence_exercise.dart';
import 'package:leximon/data/services/sentence_lesson_service.dart';

void main() {
  test('sentence exercises normalize punctuation and accept alternatives', () {
    final sentence = _sentence(
      spelling: 'She likes tea!',
      translation: 'Cô ấy thích trà',
      alternatives: const ['Cô ấy thích uống trà'],
    );
    final constructor = SentenceExercise(
      sentence: sentence,
      type: SentenceExerciseType.constructor,
      choices: const ['She', 'likes', 'tea'],
      expectedTokens: const ['She', 'likes', 'tea'],
    );
    final inverse = SentenceExercise(
      sentence: sentence,
      type: SentenceExerciseType.inverse,
      choices: const ['Cô', 'ấy', 'thích', 'uống', 'trà'],
      expectedTokens: const ['Cô', 'ấy', 'thích', 'trà'],
    );

    expect(constructor.isCorrect(const ['she', 'likes', 'tea']), isTrue);
    expect(
      inverse.isCorrect(const ['Cô', 'ấy', 'thích', 'uống', 'trà']),
      isTrue,
    );
  });

  test('insert-word exercise requires the exact token order', () {
    final sentence = _sentence(taskSpellings: const ['hot', 'tea']);
    final exercise = SentenceExercise(
      sentence: sentence,
      type: SentenceExerciseType.insertWord,
      choices: const ['hot', 'tea'],
      expectedTokens: const ['hot', 'tea'],
    );

    expect(exercise.isCorrect(const ['hot', 'tea']), isTrue);
    expect(exercise.isCorrect(const ['tea', 'hot']), isFalse);
  });

  test(
    'lesson uses four local words and creates the documented 12 tasks',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.batch((batch) {
        batch.insertAll(database.wordModels, [
          for (var id = 1; id <= 5; id++)
            WordModelsCompanion.insert(
              id: id,
              topicId: 1,
              writing: 'word$id',
              translation: 'từ $id',
              isEnabled: true,
              priority: 1,
              level: 1,
            ),
        ]);
        batch.insertAll(database.learningProgressModels, [
          for (var id = 1; id <= 5; id++)
            LearningProgressModelsCompanion.insert(
              id: Value(id),
              creationDate: 1,
              repetitionStep: const Value(1),
            ),
        ]);
      });
      await database
          .into(database.wordSentenceProgressModels)
          .insert(
            WordSentenceProgressModelsCompanion.insert(
              wordId: const Value(1),
              finishedCount: const Value(10),
            ),
          );
      final records = <SentenceRecord>[
        for (var wordId = 1; wordId <= 5; wordId++)
          for (var offset = 0; offset < 2; offset++)
            SentenceRecord(
              translationId: 1000 + wordId * 10 + offset,
              wordId: wordId,
              sentenceId: wordId * 10 + offset,
              spelling: 'This is word$wordId',
              translation: 'Đây là từ $wordId',
              difficulty: offset,
              wrongSpellings: const ['wrong'],
              taskSpellings: ['word$wordId'],
              task: 'This is |word$wordId|',
              soundUrl: '',
              alternativeTranslations: const [],
            ),
      ];
      await database.replaceSentenceContent(
        languageCode: 'vi',
        sentences: records,
      );
      final service = SentenceLessonService(
        database: database,
        random: Random(7),
      );

      final lesson = await service.loadLesson();

      expect(lesson.wordIds.toSet(), {2, 3, 4, 5});
      expect(lesson.exercises, hasLength(12));
      expect(
        lesson.exercises.map((exercise) => exercise.type).toSet(),
        containsAll([
          SentenceExerciseType.inverse,
          SentenceExerciseType.audio,
          SentenceExerciseType.insertWord,
        ]),
      );
    },
  );
}

SentenceRecord _sentence({
  String spelling = 'I like hot tea',
  String translation = 'Tôi thích trà nóng',
  List<String> alternatives = const [],
  List<String> taskSpellings = const ['tea'],
}) {
  return SentenceRecord(
    translationId: 1,
    wordId: 1,
    sentenceId: 1,
    spelling: spelling,
    translation: translation,
    difficulty: 0,
    wrongSpellings: const [],
    taskSpellings: taskSpellings,
    task: 'I like hot |tea|',
    soundUrl: '',
    alternativeTranslations: alternatives,
  );
}
