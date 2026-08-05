import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/onboarding_vocabulary_test.dart';
import '../models/sentence_exercise.dart';

class OnboardingVocabularyTestService {
  static const _definitionsAsset = 'assets/data/vocabulary_test.json';
  static const _catalogAsset = 'assets/data/topics/data_en_vi.json';
  static const _sentencesAsset = 'assets/data/sentences/vi.json';
  Future<_VocabularyTestSource>? _source;

  Future<List<VocabularyTestQuestion>> loadQuestions(BrightLevel level) async {
    final source = await (_source ??= _loadSource());
    return source.definitions
        .where((definition) => definition.level == level)
        .map(
          (definition) =>
              _buildQuestion(definition, source.catalog, source.sentences),
        )
        .toList(growable: false);
  }

  Future<_VocabularyTestSource> _loadSource() async {
    final payloads = await Future.wait([
      rootBundle.loadString(_definitionsAsset),
      rootBundle.loadString(_catalogAsset),
      rootBundle.loadString(_sentencesAsset),
    ]);

    final definitions = (jsonDecode(payloads[0]) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(VocabularyTestDefinition.fromJson)
        .toList(growable: false);
    final catalog = _readCatalog(payloads[1]);
    final sentences = (jsonDecode(payloads[2]) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(SentenceRecord.fromJson)
        .where(
          (sentence) =>
              sentence.spelling.trim().isNotEmpty &&
              sentence.translation.trim().isNotEmpty,
        )
        .toList(growable: false);
    return _VocabularyTestSource(
      definitions: definitions,
      catalog: catalog,
      sentences: sentences,
    );
  }

  _VocabularyCatalog _readCatalog(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final words = <_CatalogWord>[];

    for (final topicValue in json['topics'] as List<dynamic>) {
      final topic = topicValue as Map<String, dynamic>;
      final topicId = topic['id'] as int;
      for (final wordValue in topic['words'] as List<dynamic>) {
        final word = wordValue as Map<String, dynamic>;
        if (word['enabled'] != true) continue;
        words.add(
          _CatalogWord(
            id: word['id'] as int,
            topicId: topicId,
            writing: (word['writing'] as String? ?? '').trim(),
            translation: (word['translation'] as String? ?? '').trim(),
            transcription: (word['transcription'] as String? ?? '').trim(),
          ),
        );
      }
    }

    return _VocabularyCatalog(words);
  }

  VocabularyTestQuestion _buildQuestion(
    VocabularyTestDefinition definition,
    _VocabularyCatalog catalog,
    List<SentenceRecord> sentences,
  ) {
    final target = catalog.byId[definition.id];
    if (target == null) {
      throw StateError('Vocabulary word ${definition.id} is missing.');
    }

    if (definition.type == VocabularyTaskType.constructor) {
      final sentenceExercise = _buildSentenceExercise(
        definition,
        sentences,
        catalog,
      );
      return VocabularyTestQuestion(
        definition: definition,
        writing: target.writing,
        translation: target.translation,
        transcription: target.transcription,
        choices: const [],
        sentenceExercise: sentenceExercise,
      );
    }

    final choiceCount = definition.type == VocabularyTaskType.audioThree
        ? 3
        : 4;
    final inverse = definition.type == VocabularyTaskType.inverseText;
    final candidates = [
      ...catalog.words.where(
        (word) => word.topicId == target.topicId && word.id != target.id,
      ),
      ...catalog.words.where(
        (word) => word.topicId != target.topicId && word.id != target.id,
      ),
    ];
    final random = Random(definition.id);
    candidates.shuffle(random);

    final correctText = inverse ? target.writing : target.translation;
    final used = <String>{correctText.toLowerCase()};
    final choices = <VocabularyTestChoice>[
      VocabularyTestChoice(text: correctText, isCorrect: true),
    ];

    for (final candidate in candidates) {
      final text = inverse ? candidate.writing : candidate.translation;
      final normalized = text.toLowerCase();
      if (text.isEmpty || used.contains(normalized)) continue;
      used.add(normalized);
      choices.add(VocabularyTestChoice(text: text, isCorrect: false));
      if (choices.length == choiceCount) break;
    }

    choices.shuffle(random);
    return VocabularyTestQuestion(
      definition: definition,
      writing: target.writing,
      translation: target.translation,
      transcription: target.transcription,
      choices: List.unmodifiable(choices),
    );
  }

  SentenceExercise? _buildSentenceExercise(
    VocabularyTestDefinition definition,
    List<SentenceRecord> sentences,
    _VocabularyCatalog catalog,
  ) {
    final sentence =
        sentences
            .where((item) => item.wordId == definition.id)
            .toList(growable: false)
          ..sort((a, b) => a.sentenceId.compareTo(b.sentenceId));
    if (sentence.isEmpty) return null;

    final selected = sentence.first;
    final expectedTokens = tokenizeSentence(selected.spelling);
    if (expectedTokens.isEmpty) return null;

    final used = expectedTokens.map((token) => token.toLowerCase()).toSet();
    final distractors = <String>[];
    for (final candidate in sentences) {
      for (final token in tokenizeSentence(candidate.spelling)) {
        final normalized = token.toLowerCase();
        if (used.contains(normalized) ||
            distractors.any((item) => item.toLowerCase() == normalized)) {
          continue;
        }
        distractors.add(token);
        if (distractors.length == 3) break;
      }
      if (distractors.length == 3) break;
    }
    if (distractors.length < 3) {
      for (final word in catalog.words) {
        final token = word.writing.trim();
        final normalized = token.toLowerCase();
        if (token.isEmpty ||
            used.contains(normalized) ||
            distractors.any((item) => item.toLowerCase() == normalized)) {
          continue;
        }
        distractors.add(token);
        if (distractors.length == 3) break;
      }
    }

    final choices = [...expectedTokens, ...distractors];
    choices.shuffle(Random(definition.id));
    return SentenceExercise(
      sentence: selected,
      type: SentenceExerciseType.constructor,
      choices: List.unmodifiable(choices),
      expectedTokens: List.unmodifiable(expectedTokens),
    );
  }
}

class _VocabularyTestSource {
  const _VocabularyTestSource({
    required this.definitions,
    required this.catalog,
    required this.sentences,
  });

  final List<VocabularyTestDefinition> definitions;
  final _VocabularyCatalog catalog;
  final List<SentenceRecord> sentences;
}

class _VocabularyCatalog {
  _VocabularyCatalog(this.words)
    : byId = {for (final word in words) word.id: word};

  final List<_CatalogWord> words;
  final Map<int, _CatalogWord> byId;
}

class _CatalogWord {
  const _CatalogWord({
    required this.id,
    required this.topicId,
    required this.writing,
    required this.translation,
    required this.transcription,
  });

  final int id;
  final int topicId;
  final String writing;
  final String translation;
  final String transcription;
}
