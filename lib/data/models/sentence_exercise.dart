enum SentenceExerciseType { constructor, inverse, audio, insertWord }

enum SentenceTrainingSource { daily, additional, topic }

class SentenceRecord {
  const SentenceRecord({
    required this.translationId,
    required this.wordId,
    required this.sentenceId,
    required this.spelling,
    required this.translation,
    required this.difficulty,
    required this.wrongSpellings,
    required this.taskSpellings,
    required this.task,
    required this.soundUrl,
    required this.alternativeTranslations,
  });

  factory SentenceRecord.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false);

    return SentenceRecord(
      translationId: (json['id'] as num?)?.toInt() ?? 0,
      wordId: (json['word_id'] as num?)?.toInt() ?? 0,
      sentenceId: (json['sentence_id'] as num?)?.toInt() ?? 0,
      spelling: json['spelling'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 0,
      wrongSpellings: strings('wrong_spellings'),
      taskSpellings: strings('task_spellings'),
      task: json['task'] as String? ?? '',
      soundUrl: json['sound'] as String? ?? '',
      alternativeTranslations: strings('alternative_translations'),
    );
  }

  final int translationId;
  final int wordId;
  final int sentenceId;
  final String spelling;
  final String translation;
  final int difficulty;
  final List<String> wrongSpellings;
  final List<String> taskSpellings;
  final String task;
  final String soundUrl;
  final List<String> alternativeTranslations;
}

class SentenceExercise {
  const SentenceExercise({
    required this.sentence,
    required this.type,
    required this.choices,
    required this.expectedTokens,
  });

  final SentenceRecord sentence;
  final SentenceExerciseType type;
  final List<String> choices;
  final List<String> expectedTokens;

  String get trainingType => switch (type) {
    SentenceExerciseType.constructor => 'constructor_into_eng',
    SentenceExerciseType.inverse => 'constructor_into_native',
    SentenceExerciseType.audio => 'wwe_constructor',
    SentenceExerciseType.insertWord => 'insert_word',
  };

  String get titleKey => switch (type) {
    SentenceExerciseType.constructor => 'sentenceTypeConstructor',
    SentenceExerciseType.inverse => 'sentenceTypeInverse',
    SentenceExerciseType.audio => 'sentenceTypeAudio',
    SentenceExerciseType.insertWord => 'sentenceTypeInsertWord',
  };

  String get instructionKey => switch (type) {
    SentenceExerciseType.constructor => 'sentenceInstructionConstructor',
    SentenceExerciseType.inverse => 'sentenceInstructionInverse',
    SentenceExerciseType.audio => 'sentenceInstructionAudio',
    SentenceExerciseType.insertWord => 'sentenceInstructionInsertWord',
  };

  String get answer => expectedTokens.join(' ');

  String get fullAnswer => switch (type) {
    SentenceExerciseType.inverse => sentence.translation,
    SentenceExerciseType.insertWord => sentence.spelling,
    SentenceExerciseType.constructor ||
    SentenceExerciseType.audio => sentence.spelling,
  };

  bool isCorrect(List<String> selectedTokens) {
    if (type == SentenceExerciseType.insertWord) {
      if (selectedTokens.length != expectedTokens.length) return false;
      for (var index = 0; index < expectedTokens.length; index++) {
        if (_normalize(selectedTokens[index]) !=
            _normalize(expectedTokens[index])) {
          return false;
        }
      }
      return true;
    }

    final selected = _normalize(selectedTokens.join(' '));
    if (type == SentenceExerciseType.inverse) {
      return <String>[
        sentence.translation,
        ...sentence.alternativeTranslations,
      ].any((answer) => _normalize(answer) == selected);
    }
    return _normalize(sentence.spelling) == selected;
  }
}

List<String> tokenizeSentence(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((token) => token.isNotEmpty)
    .toList(growable: false);

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(' - ', ' ')
    .replaceAll(RegExp(r'[.,!|?:;]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
