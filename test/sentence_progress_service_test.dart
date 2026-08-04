import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/sentence_exercise.dart';
import 'package:leximon/data/services/sentence_lesson_service.dart';
import 'package:leximon/data/services/sentence_progress_service.dart';

void main() {
  test(
    'completion applies word, sentence, exercise and Visit exposure',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      await database
          .into(database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: today,
              wordsInSentencesGoal: const Value(4),
            ),
          );
      final sentence = _sentence(11, 1);
      final lesson = SentenceLesson(
        wordIds: const [1, 2, 3, 4],
        sentences: [sentence],
        exercises: [
          SentenceExercise(
            sentence: sentence,
            type: SentenceExerciseType.inverse,
            choices: const ['Tôi', 'uống', 'trà'],
            expectedTokens: const ['Tôi', 'uống', 'trà'],
          ),
          SentenceExercise(
            sentence: sentence,
            type: SentenceExerciseType.insertWord,
            choices: const ['tea'],
            expectedTokens: const ['tea'],
          ),
        ],
      );

      final result = await SentenceProgressService(
        database,
      ).completeLesson(lesson);

      expect(result.wordCount, 4);
      expect(result.sentenceCount, 1);
      final wordRows = await database
          .select(database.wordSentenceProgressModels)
          .get();
      expect(wordRows, hasLength(4));
      expect(wordRows.map((row) => row.finishedCount), everyElement(1));
      final exposure = await database
          .select(database.sentenceExposureModels)
          .getSingle();
      expect(exposure.finishedCount, 1);
      expect(exposure.constructorTask, 1);
      expect(exposure.constructorInverseTask, 1);
      expect(exposure.insertWordTask, 1);
      expect(exposure.constructorAudioTask, 0);
      final visit = await database.select(database.visitModels).getSingle();
      expect(visit.wordsInSentencesCount, 4);
      expect(visit.sentencesTrainedCount, 1);
      expect(visit.sentencesTrainedExtraCount, 0);
      expect(visit.areDailyTasksFinished, isTrue);
    },
  );

  test('skipped audio does not increment its exercise counter', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final sentence = _sentence(12, 1);
    final lesson = SentenceLesson(
      wordIds: const [1],
      sentences: [sentence],
      exercises: [
        SentenceExercise(
          sentence: sentence,
          type: SentenceExerciseType.constructor,
          choices: const ['I', 'drink', 'tea'],
          expectedTokens: const ['I', 'drink', 'tea'],
        ),
      ],
    );

    await SentenceProgressService(database).completeLesson(lesson);

    final exposure = await database
        .select(database.sentenceExposureModels)
        .getSingle();
    expect(exposure.constructorTask, 2);
    expect(exposure.constructorAudioTask, 0);
  });
}

SentenceRecord _sentence(int sentenceId, int wordId) {
  return SentenceRecord(
    translationId: 100 + sentenceId,
    wordId: wordId,
    sentenceId: sentenceId,
    spelling: 'I drink tea',
    translation: 'Tôi uống trà',
    difficulty: 0,
    wrongSpellings: const [],
    taskSpellings: const ['tea'],
    task: 'I drink |tea|',
    soundUrl: '',
    alternativeTranslations: const [],
  );
}
