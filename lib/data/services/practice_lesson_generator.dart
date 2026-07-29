import 'dart:math';

import '../models/practice_exercise.dart';

class PracticeLessonGenerator {
  PracticeLessonGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds the compact lesson used by the progress/repetition flow.
  ///
  /// Repetition deliberately keeps one question per word. Unlike a new-word
  /// lesson, it is not limited to four words and it only needs one distractor
  /// beside the correct translation.
  List<PracticeExercise> buildRepetitionLesson({
    required List<ExerciseWord> words,
    required List<ExerciseWord> enabledWords,
  }) {
    return words
        .map((target) {
          final targetTranslation = _normalizedTranslation(target.translation);
          final sameTopic =
              enabledWords
                  .where(
                    (word) =>
                        word.id != target.id &&
                        word.topicId == target.topicId &&
                        _normalizedTranslation(word.translation) !=
                            targetTranslation,
                  )
                  .toList()
                ..shuffle(_random);
          final distractor = sameTopic.firstOrNull;
          if (distractor == null) return null;
          final variants = [distractor, target];

          return PracticeExercise(
            word: target,
            variants: _shuffled(variants),
            trainingExercise: TrainingExerciseType.choiceOfTwo,
          );
        })
        .nonNulls
        .toList(growable: false);
  }

  List<PracticeExercise> buildLesson({
    required List<ExerciseWord> words,
    required List<ExerciseWord> enabledWords,
    Map<int, List<int>> similarWordIds = const {},
    bool listeningEnabled = true,
    bool pronouncingEnabled = true,
  }) {
    if (words.isEmpty || words.length > 4) {
      throw ArgumentError.value(
        words.length,
        'words',
        'A practice lesson requires between one and four selected words.',
      );
    }

    final result = <PracticeExercise>[
      ...words.map((word) => _buildChoiceOfFourToEng(word, enabledWords)),
      ...words.map(
        (word) => _buildChoiceOfFourFromEng(word, enabledWords, similarWordIds),
      ),
    ];

    if (listeningEnabled) {
      result.addAll(
        words.map(
          (word) =>
              _buildChoiceOfThreeListening(word, enabledWords, similarWordIds),
        ),
      );
    }

    result.addAll(words.map(_buildConstructor));

    if (listeningEnabled) {
      result.addAll(
        words.map((word) => _buildChoiceOfFourListening(word, enabledWords)),
      );
    }

    if (pronouncingEnabled) {
      result.addAll(words.map(_buildSpeaking));
    }

    return List.unmodifiable(result);
  }

  PracticeExercise _buildChoiceOfFourToEng(
    ExerciseWord target,
    List<ExerciseWord> enabledWords,
  ) {
    final distractors = _randomWordsInTopic(
      target: target,
      enabledWords: enabledWords,
      count: 3,
    );
    return PracticeExercise(
      word: target,
      variants: _shuffled([...distractors, target]),
      trainingExercise: TrainingExerciseType.choiceOfFourToEng,
    );
  }

  PracticeExercise _buildChoiceOfFourFromEng(
    ExerciseWord target,
    List<ExerciseWord> enabledWords,
    Map<int, List<int>> similarWordIds,
  ) {
    final distractors = _similarWordsOrRandomFallback(
      target: target,
      enabledWords: enabledWords,
      similarWordIds: similarWordIds,
      count: 3,
    );
    final variants = _shuffled([...distractors, target])
        .map(
          (variant) => variant.copyWith(
            writing: _matchCapitalization(
              target: target.writing,
              value: variant.writing,
            ),
          ),
        )
        .toList(growable: false);
    return PracticeExercise(
      word: target,
      variants: variants,
      trainingExercise: TrainingExerciseType.choiceOfFourFromEng,
    );
  }

  PracticeExercise _buildChoiceOfThreeListening(
    ExerciseWord target,
    List<ExerciseWord> enabledWords,
    Map<int, List<int>> similarWordIds,
  ) {
    final distractors = _similarWordsOrRandomFallback(
      target: target,
      enabledWords: enabledWords,
      similarWordIds: similarWordIds,
      count: 2,
    );
    return PracticeExercise(
      word: target,
      variants: _shuffled([...distractors, target]),
      trainingExercise: TrainingExerciseType.choiceOfThreeListening,
    );
  }

  PracticeExercise _buildConstructor(ExerciseWord target) {
    return PracticeExercise(
      word: target,
      variants: const [],
      trainingExercise: TrainingExerciseType.constructor,
    );
  }

  PracticeExercise _buildChoiceOfFourListening(
    ExerciseWord target,
    List<ExerciseWord> enabledWords,
  ) {
    final distractors = _randomWordsInTopic(
      target: target,
      enabledWords: enabledWords,
      count: 3,
    );
    return PracticeExercise(
      word: target,
      variants: _shuffled([...distractors, target]),
      trainingExercise: TrainingExerciseType.choiceOfFourListening,
    );
  }

  PracticeExercise _buildSpeaking(ExerciseWord target) {
    return PracticeExercise(
      word: target,
      variants: const [],
      trainingExercise: TrainingExerciseType.speaking,
    );
  }

  List<ExerciseWord> _randomWordsInTopic({
    required ExerciseWord target,
    required List<ExerciseWord> enabledWords,
    required int count,
  }) {
    final candidates = enabledWords
        .where((word) => word.id != target.id && word.topicId == target.topicId)
        .toList();
    candidates.shuffle(_random);
    return candidates.take(count).toList(growable: false);
  }

  List<ExerciseWord> _similarWordsOrRandomFallback({
    required ExerciseWord target,
    required List<ExerciseWord> enabledWords,
    required Map<int, List<int>> similarWordIds,
    required int count,
  }) {
    final wordsById = <int, ExerciseWord>{
      for (final word in enabledWords) word.id: word,
    };
    final shuffledSimilarIds = [...similarWordIds[target.id] ?? const <int>[]]
      ..shuffle(_random);
    final selectedSimilarIds = <int>{};
    final result = <ExerciseWord>[];

    for (final id in shuffledSimilarIds) {
      if (result.length == count) break;
      if (!selectedSimilarIds.add(id)) continue;
      final word = wordsById[id];
      if (word != null && word.id != target.id) result.add(word);
    }

    final missingCount = count - result.length;
    if (missingCount > 0) {
      final fallback =
          enabledWords.where((word) => word.id != target.id).toList()
            ..shuffle(_random);
      result.addAll(fallback.take(missingCount));
    }

    return result;
  }

  List<ExerciseWord> _shuffled(List<ExerciseWord> words) {
    return List<ExerciseWord>.of(words)..shuffle(_random);
  }
}

String _normalizedTranslation(String value) {
  return value.trim().toLowerCase();
}

String _matchCapitalization({required String target, required String value}) {
  if (target.isEmpty || value.isEmpty) return value;

  final letters = target.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.isNotEmpty && letters == letters.toUpperCase()) {
    return value.toUpperCase();
  }
  if (letters.isNotEmpty && letters == letters.toLowerCase()) {
    return value.toLowerCase();
  }

  final targetStartsUpper = target[0] == target[0].toUpperCase();
  final first = targetStartsUpper
      ? value[0].toUpperCase()
      : value[0].toLowerCase();
  return '$first${value.substring(1)}';
}
