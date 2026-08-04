import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/onboarding_vocabulary_test.dart';

class OnboardingVocabularyTestService {
  static const _definitionsAsset = 'assets/data/vocabulary_test.json';
  static const _catalogAsset = 'assets/data/topics/data_en_vi.json';
  Future<_VocabularyTestSource>? _source;

  Future<List<VocabularyTestQuestion>> loadQuestions(BrightLevel level) async {
    final source = await (_source ??= _loadSource());
    return source.definitions
        .where((definition) => definition.level == level)
        .map((definition) => _buildQuestion(definition, source.catalog))
        .toList(growable: false);
  }

  Future<_VocabularyTestSource> _loadSource() async {
    final payloads = await Future.wait([
      rootBundle.loadString(_definitionsAsset),
      rootBundle.loadString(_catalogAsset),
    ]);

    final definitions = (jsonDecode(payloads[0]) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(VocabularyTestDefinition.fromJson)
        .toList(growable: false);
    final catalog = _readCatalog(payloads[1]);
    return _VocabularyTestSource(definitions: definitions, catalog: catalog);
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
  ) {
    final target = catalog.byId[definition.id];
    if (target == null) {
      throw StateError('Vocabulary word ${definition.id} is missing.');
    }

    if (definition.type == VocabularyTaskType.constructor) {
      return VocabularyTestQuestion(
        definition: definition,
        writing: target.writing,
        translation: target.translation,
        transcription: target.transcription,
        choices: const [],
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
}

class _VocabularyTestSource {
  const _VocabularyTestSource({
    required this.definitions,
    required this.catalog,
  });

  final List<VocabularyTestDefinition> definitions;
  final _VocabularyCatalog catalog;
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
