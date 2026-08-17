import 'dart:math';

import 'package:flutter/services.dart';

import '../datasources/sentence_asset_data_source.dart';
import '../datasources/topic_asset_data_source.dart';
import '../local/app_database.dart';
import '../models/sentence_exercise.dart';

class SentenceLessonUnavailableException implements Exception {
  const SentenceLessonUnavailableException();
}

class SentenceLesson {
  const SentenceLesson({
    required this.wordIds,
    required this.exercises,
    this.sentences = const [],
  });

  final List<int> wordIds;
  final List<SentenceExercise> exercises;
  final List<SentenceRecord> sentences;
}

class SentenceLessonService {
  SentenceLessonService({
    required AppDatabase database,
    AssetBundle? assetBundle,
    SentenceAssetDataSource? assetDataSource,
    String languageCode = 'vi',
    Random? random,
  }) : _database = database,
       _assetDataSource =
           assetDataSource ?? SentenceAssetDataSource(bundle: assetBundle),
       _languageCode = languageCode,
       _allowAssetFallback = assetBundle != null,
       _random = random ?? Random();

  static const _wordCount = 4;

  final AppDatabase _database;
  final SentenceAssetDataSource _assetDataSource;
  final String _languageCode;
  final bool _allowAssetFallback;
  final Random _random;
  Future<List<SentenceRecord>>? _cachedSentences;

  Future<int> eligibleWordCount({int? topicId}) async {
    final results = await Future.wait<Object>([
      _loadSentences(),
      _database.enabledWords(),
      _database.select(_database.learningProgressModels).get(),
    ]);
    final availableSentenceWordIds = (results[0] as List<SentenceRecord>)
        .map((sentence) => sentence.wordId)
        .toSet();
    final words = results[1] as List<WordRow>;
    final progressById = {
      for (final row in results[2] as List<LearningProgressRow>) row.id: row,
    };
    return words
        .where(
          (word) =>
              (topicId == null || word.topicId == topicId) &&
              availableSentenceWordIds.contains(word.id) &&
              _isEligible(progressById[word.id]),
        )
        .map((word) => word.id)
        .toSet()
        .length;
  }

  Future<SentenceLesson> loadLesson({int? topicId}) async {
    final results = await Future.wait<Object>([
      _loadSentences(),
      _database.enabledWords(),
      _database.select(_database.learningProgressModels).get(),
      _database.select(_database.wordSentenceProgressModels).get(),
      _database.select(_database.sentenceExposureModels).get(),
    ]);
    final sentences = results[0] as List<SentenceRecord>;
    final enabledWords = results[1] as List<WordRow>;
    final progressRows = results[2] as List<LearningProgressRow>;
    final progressById = {for (final row in progressRows) row.id: row};
    final wordExposureById = {
      for (final row in results[3] as List<WordSentenceProgressRow>)
        row.wordId: row.finishedCount,
    };
    final sentenceExposureById = {
      for (final row in results[4] as List<SentenceExposureRow>)
        row.sentenceId: row,
    };

    final sentencesByWordId = <int, List<SentenceRecord>>{};
    for (final sentence in sentences) {
      if (sentence.spelling.trim().isEmpty ||
          sentence.translation.trim().isEmpty) {
        continue;
      }
      sentencesByWordId.putIfAbsent(sentence.wordId, () => []).add(sentence);
    }

    final uniqueWords = <int, WordRow>{};
    for (final word in enabledWords) {
      uniqueWords.putIfAbsent(word.id, () => word);
    }
    final candidates = uniqueWords.values
        .where(
          (word) =>
              (topicId == null || word.topicId == topicId) &&
              sentencesByWordId.containsKey(word.id) &&
              _isEligible(progressById[word.id]),
        )
        .toList();
    candidates.sort((a, b) {
      final byExposure = (wordExposureById[a.id] ?? 0).compareTo(
        wordExposureById[b.id] ?? 0,
      );
      return byExposure != 0 ? byExposure : a.id.compareTo(b.id);
    });

    if (candidates.length < _wordCount) {
      throw const SentenceLessonUnavailableException();
    }
    final wordIds = candidates
        .take(_wordCount)
        .map((word) => word.id)
        .toList(growable: false);

    final selectedSentences = <SentenceRecord>[];
    for (final wordId in wordIds) {
      final wordSentences = List<SentenceRecord>.of(sentencesByWordId[wordId]!)
        ..sort((a, b) {
          final aFinished =
              sentenceExposureById[a.sentenceId]?.finishedCount ?? a.difficulty;
          final bFinished =
              sentenceExposureById[b.sentenceId]?.finishedCount ?? b.difficulty;
          final byExposure = aFinished.compareTo(bFinished);
          return byExposure != 0
              ? byExposure
              : a.sentenceId.compareTo(b.sentenceId);
        });
      selectedSentences.addAll(wordSentences.take(2));
    }

    final exercises = _buildExercises(
      selectedSentences,
      enabledWords.map((word) => word.writing).toList(growable: false),
      sentenceExposureById,
    )..shuffle(_random);
    if (exercises.isEmpty) throw const SentenceLessonUnavailableException();
    return SentenceLesson(
      wordIds: List.unmodifiable(wordIds),
      exercises: List.unmodifiable(exercises),
      sentences: List.unmodifiable(selectedSentences),
    );
  }

  bool _isEligible(LearningProgressRow? progress) {
    return progress != null &&
        !progress.deletedByUser &&
        !progress.markedAsKnown &&
        (progress.repetitionStep > 0 || progress.onFastBrain);
  }

  Future<List<SentenceRecord>> _loadSentences() {
    return _cachedSentences ??= _loadPersistedSentences();
  }

  Future<List<SentenceRecord>> _loadPersistedSentences() async {
    final languageCode = TopicAssetDataSource.canonicalizeLanguageCode(
      _languageCode,
    );
    final localSentences = await _database.loadSentenceContent(
      languageCode: languageCode,
    );
    if (localSentences.isNotEmpty) return localSentences;
    if (_allowAssetFallback) {
      // Explicit asset injection is retained for isolated unit tests only.
      return _assetDataSource.load(languageCode: languageCode);
    }
    return const <SentenceRecord>[];
  }

  List<SentenceExercise> _buildExercises(
    List<SentenceRecord> sentences,
    List<String> fallbackWords,
    Map<int, SentenceExposureRow> exposureBySentenceId,
  ) {
    final exercises = <SentenceExercise>[];
    for (var index = 0; index < sentences.length; index++) {
      final sentence = sentences[index];
      final exposure = exposureBySentenceId[sentence.sentenceId];
      final exposureByType = {
        SentenceExerciseType.constructor: exposure?.constructorTask ?? 1,
        SentenceExerciseType.inverse: exposure?.constructorInverseTask ?? 0,
        SentenceExerciseType.audio: exposure?.constructorAudioTask ?? 0,
        SentenceExerciseType.insertWord: exposure?.insertWordTask ?? 0,
      };
      final orderedTypes = List<SentenceExerciseType>.of(
        SentenceExerciseType.values,
      )..shuffle(_random);
      orderedTypes.sort(
        (a, b) => exposureByType[a]!.compareTo(exposureByType[b]!),
      );
      final count = index.isEven ? 2 : 1;
      var added = 0;
      for (final type in orderedTypes) {
        final exercise = _createExercise(
          sentence,
          type,
          sentences,
          fallbackWords,
        );
        if (exercise == null) continue;
        exercises.add(exercise);
        added++;
        if (added == count) break;
      }
    }
    return exercises;
  }

  SentenceExercise? _createExercise(
    SentenceRecord sentence,
    SentenceExerciseType type,
    List<SentenceRecord> sessionSentences,
    List<String> fallbackWords,
  ) {
    final expected = switch (type) {
      SentenceExerciseType.inverse => tokenizeSentence(sentence.translation),
      SentenceExerciseType.insertWord => sentence.taskSpellings,
      SentenceExerciseType.constructor ||
      SentenceExerciseType.audio => tokenizeSentence(sentence.spelling),
    };
    if (expected.isEmpty) return null;
    if (type == SentenceExerciseType.insertWord && sentence.task.isEmpty) {
      return null;
    }

    final choices = List<String>.of(expected);
    if (type == SentenceExerciseType.inverse) {
      final distractors =
          sessionSentences
              .where((item) => item.sentenceId != sentence.sentenceId)
              .expand((item) => tokenizeSentence(item.translation))
              .where((token) => !expected.contains(token))
              .toSet()
              .toList()
            ..shuffle(_random);
      choices.addAll(distractors.take(max(0, min(4, 10 - choices.length))));
    } else if (type == SentenceExerciseType.insertWord) {
      choices.addAll(
        sentence.wrongSpellings.where((token) => !choices.contains(token)),
      );
      if (choices.length < 6) {
        final fallbacks =
            fallbackWords
                .where(
                  (token) => !choices.contains(token) && !token.contains(' '),
                )
                .toList()
              ..shuffle(_random);
        choices.addAll(fallbacks.take(6 - choices.length));
      }
    }
    choices.shuffle(_random);
    return SentenceExercise(
      sentence: sentence,
      type: type,
      choices: List.unmodifiable(choices),
      expectedTokens: List.unmodifiable(expected),
    );
  }
}
