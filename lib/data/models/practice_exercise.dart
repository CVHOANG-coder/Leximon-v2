enum TrainingExerciseType {
  choiceOfFourToEng,
  choiceOfFourFromEng,
  choiceOfThreeListening,
  constructor,
  choiceOfFourListening,
  speaking,
  choiceOfTwo,
}

enum ExerciseAnswerState { notAnswered, correct, wrong, skipped }

class ExerciseWord {
  const ExerciseWord({
    required this.id,
    required this.topicId,
    required this.writing,
    required this.translation,
    required this.transliteration,
  });

  factory ExerciseWord.fromMap(Map<String, dynamic> map) {
    return ExerciseWord(
      id: map['id'] as int? ?? 0,
      topicId: map['topicId'] as int? ?? 0,
      writing: map['writing'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      transliteration:
          map['transliteration'] as String? ??
          map['transcription'] as String? ??
          '',
    );
  }

  final int id;
  final int topicId;
  final String writing;
  final String translation;
  final String transliteration;

  ExerciseWord copyWith({String? writing}) {
    return ExerciseWord(
      id: id,
      topicId: topicId,
      writing: writing ?? this.writing,
      translation: translation,
      transliteration: transliteration,
    );
  }
}

class PracticeExercise {
  const PracticeExercise({
    required this.word,
    required this.variants,
    required this.trainingExercise,
    this.answer = ExerciseAnswerState.notAnswered,
  });

  final ExerciseWord word;
  final List<ExerciseWord> variants;
  final TrainingExerciseType trainingExercise;
  final ExerciseAnswerState answer;
}
