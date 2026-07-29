import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/practice_exercise.dart';
import 'package:leximon/data/services/difficult_words_training_service.dart';
import 'package:leximon/data/services/learning_progress_service.dart';

void main() {
  late AppDatabase database;
  late DifficultWordsTrainingService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = DifficultWordsTrainingService(database);
  });

  tearDown(() => database.close());

  test('queries all valid difficult words but trains at most four', () async {
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        for (var id = 1; id <= 8; id++)
          WordModelsCompanion.insert(
            id: id,
            topicId: id.isEven ? 2 : 1,
            writing: 'word$id',
            translation: 'nghĩa $id',
            isEnabled: id != 8,
            priority: 1,
            level: 1,
          ),
      ]);
      batch.insertAll(database.learningProgressModels, [
        for (var id = 1; id <= 8; id++)
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: 1,
            trainingError: Value(
              id == 1
                  ? 1
                  : LearningProgressService.bitForType(
                      TrainingExerciseType.constructor,
                    ),
            ),
            markedAsKnown: Value(id == 6),
            deletedByUser: Value(id == 7),
          ),
      ]);
    });

    final batch = await service.prepareBatch();

    expect(batch.remainingWordCount, 5);
    expect(batch.words, hasLength(4));
    expect(batch.words.map((word) => word.id), [1, 3, 5, 2]);
    expect(
      batch.exerciseMasksByWordId[1],
      LearningProgressService.bitForType(
        TrainingExerciseType.choiceOfFourToEng,
      ),
    );
    expect(
      batch.exerciseMasksByWordId.keys,
      batch.words.map((word) => word.id),
    );
    expect(batch.distractorWords, hasLength(7));
  });

  test('allows a final batch with fewer than four words', () async {
    await database.batch((batch) {
      batch.insertAll(database.wordModels, [
        for (var id = 1; id <= 2; id++)
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
        for (var id = 1; id <= 2; id++)
          LearningProgressModelsCompanion.insert(
            id: Value(id),
            creationDate: 1,
            trainingError: Value(
              LearningProgressService.bitForType(
                TrainingExerciseType.choiceOfFourFromEng,
              ),
            ),
          ),
      ]);
    });

    final batch = await service.prepareBatch();

    expect(batch.remainingWordCount, 2);
    expect(batch.words, hasLength(2));
  });
}
