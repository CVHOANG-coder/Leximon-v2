import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/sentence_exercise.dart';
import 'daily_card_service.dart';
import 'sentence_lesson_service.dart';

class SentenceCompletionResult {
  const SentenceCompletionResult({
    required this.wordCount,
    required this.sentenceCount,
    required this.exerciseCount,
  });

  final int wordCount;
  final int sentenceCount;
  final int exerciseCount;
}

/// Applies Words in Sentences exposure only after the whole lesson completes.
/// Correct and wrong answers intentionally receive the same exposure credit,
/// matching the scheduling behavior documented for the original app.
class SentenceProgressService {
  SentenceProgressService(this._database);

  final AppDatabase _database;

  Future<SentenceCompletionResult> completeLesson(SentenceLesson lesson) {
    final wordIds = lesson.wordIds.toSet();
    final sentences = lesson.sentences.isEmpty
        ? {
            for (final exercise in lesson.exercises)
              exercise.sentence.sentenceId: exercise.sentence,
          }.values.toList(growable: false)
        : {
            for (final sentence in lesson.sentences)
              sentence.sentenceId: sentence,
          }.values.toList(growable: false);
    final exercisesBySentenceId = <int, List<SentenceExercise>>{};
    for (final exercise in lesson.exercises) {
      exercisesBySentenceId
          .putIfAbsent(exercise.sentence.sentenceId, () => [])
          .add(exercise);
    }

    return _database.transaction(() async {
      for (final wordId in wordIds) {
        final existing = await (_database.select(
          _database.wordSentenceProgressModels,
        )..where((row) => row.wordId.equals(wordId))).getSingleOrNull();
        await _database
            .into(_database.wordSentenceProgressModels)
            .insertOnConflictUpdate(
              WordSentenceProgressModelsCompanion.insert(
                wordId: Value(wordId),
                finishedCount: Value((existing?.finishedCount ?? 0) + 1),
              ),
            );
      }

      for (final sentence in sentences) {
        final existing =
            await (_database.select(_database.sentenceExposureModels)
                  ..where((row) => row.sentenceId.equals(sentence.sentenceId)))
                .getSingleOrNull();
        var insertWordCount = existing?.insertWordTask ?? 0;
        var constructorCount = existing?.constructorTask ?? 1;
        var audioCount = existing?.constructorAudioTask ?? 0;
        var inverseCount = existing?.constructorInverseTask ?? 0;
        for (final exercise
            in exercisesBySentenceId[sentence.sentenceId] ?? const []) {
          switch (exercise.type) {
            case SentenceExerciseType.insertWord:
              insertWordCount++;
            case SentenceExerciseType.constructor:
              constructorCount++;
            case SentenceExerciseType.audio:
              audioCount++;
            case SentenceExerciseType.inverse:
              inverseCount++;
          }
        }
        await _database
            .into(_database.sentenceExposureModels)
            .insertOnConflictUpdate(
              SentenceExposureModelsCompanion.insert(
                sentenceId: Value(sentence.sentenceId),
                wordId: sentence.wordId,
                finishedCount: Value(
                  (existing?.finishedCount ?? sentence.difficulty) + 1,
                ),
                insertWordTask: Value(insertWordCount),
                constructorTask: Value(constructorCount),
                constructorAudioTask: Value(audioCount),
                constructorInverseTask: Value(inverseCount),
              ),
            );
      }

      await _updateVisit(
        wordCount: wordIds.length,
        sentenceCount: sentences.length,
      );
      return SentenceCompletionResult(
        wordCount: wordIds.length,
        sentenceCount: sentences.length,
        exerciseCount: lesson.exercises.length,
      );
    });
  }

  Future<void> _updateVisit({
    required int wordCount,
    required int sentenceCount,
  }) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final existing = await (_database.select(
      _database.visitModels,
    )..where((row) => row.date.equals(date))).getSingleOrNull();
    if (existing == null) {
      await _database
          .into(_database.visitModels)
          .insert(
            VisitModelsCompanion.insert(
              date: date,
              atLeastOneTaskFinished: const Value(true),
              wordsInSentencesCount: Value(wordCount),
              sentencesTrainedCount: Value(sentenceCount),
            ),
          );
      return;
    }

    final newWordCount = existing.wordsInSentencesCount + wordCount;
    final newSentenceCount = existing.sentencesTrainedCount + sentenceCount;
    final newExtraCount = existing.wordsInSentencesGoal == 0
        ? existing.sentencesTrainedExtraCount + sentenceCount
        : (newWordCount - existing.wordsInSentencesGoal)
              .clamp(0, 1 << 30)
              .toInt();
    final allGoalsFinished = areDailyTaskGoalsFinished(
      repeatWordsGoal: existing.repeatWordsGoal,
      repeatedWordsCount: existing.repeatedWordsCount,
      learnWordsGoal: existing.learnWordsGoal,
      learnedWordsCount: existing.learnedWordsCount,
      trainWordsGoal: existing.trainWordsGoal,
      trainedWordsCount: existing.trainedWordsCount,
      difficultWordsGoal: existing.difficultWordsGoal,
      difficultWordsTrainedCount: existing.difficultWordsTrainedCount,
      wordsInSentencesGoal: existing.wordsInSentencesGoal,
      wordsInSentencesCount: newWordCount,
    );
    await (_database.update(
      _database.visitModels,
    )..where((row) => row.id.equals(existing.id))).write(
      VisitModelsCompanion(
        atLeastOneTaskFinished: const Value(true),
        areDailyTasksFinished: Value(allGoalsFinished),
        wordsInSentencesCount: Value(newWordCount),
        sentencesTrainedCount: Value(newSentenceCount),
        sentencesTrainedExtraCount: Value(newExtraCount),
      ),
    );
  }
}
