import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/listening_exercise.dart';

class ListeningAssetDataSource {
  ListeningAssetDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<ListeningExercise> loadLesson({
    required String courseIndexAsset,
    required int lessonId,
  }) async {
    final assetPath = await _findLessonAsset(courseIndexAsset, lessonId);
    final encoded = await _bundle.loadString(assetPath);
    final wrapper = jsonDecode(encoded) as Map<String, dynamic>;
    final detail = wrapper['detail'] as Map<String, dynamic>?;
    if (detail == null) {
      throw const FormatException('Lesson asset does not contain detail data.');
    }

    final rawChallenges = detail['challenges'] as List<dynamic>? ?? const [];
    final lessonName =
        detail['lessonName'] as String? ?? detail['name'] as String? ?? '';
    final isSelectionLesson = rawChallenges.firstOrNull is List<dynamic>;
    final challenges = isSelectionLesson
        ? _selectionChallengesFromJson(rawChallenges, lessonName)
        : (rawChallenges
              .whereType<Map<String, dynamic>>()
              .map(_challengeFromJson)
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position)));
    if (challenges.isEmpty) {
      throw const FormatException(
        'This lesson does not support Listen & Type exercises.',
      );
    }

    final rawTranslations =
        wrapper['translations'] as Map<String, dynamic>? ?? const {};
    final translations = <int, String>{};
    for (final entry in rawTranslations.entries) {
      final challengeId = int.tryParse(entry.key);
      final value = entry.value;
      if (challengeId != null && value is Map<String, dynamic>) {
        final text = value['text'] as String?;
        if (text != null && text.isNotEmpty) translations[challengeId] = text;
      }
    }

    return ListeningExercise(
      id: detail['id'] as int? ?? lessonId,
      name: _cleanLessonName(lessonName),
      levelName: detail['levelName'] as String? ?? '',
      audioUrl: detail['audioSrc'] as String? ?? '',
      challenges: challenges,
      translations: translations,
      youtubeVideoId: detail['youtubeVideoId'] as String?,
    );
  }

  Future<String> _findLessonAsset(String courseIndexAsset, int lessonId) async {
    final courseDirectory = courseIndexAsset.substring(
      0,
      courseIndexAsset.lastIndexOf('/'),
    );
    final prefix = '$courseDirectory/lessons/';
    final idPattern = RegExp('^\\d+-$lessonId-');
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final matches = manifest
        .listAssets()
        .where((asset) => asset.startsWith(prefix))
        .where((asset) => idPattern.hasMatch(asset.substring(prefix.length)))
        .toList();
    if (matches.isEmpty) {
      throw StateError('No bundled lesson asset found for lesson $lessonId.');
    }
    return matches.first;
  }

  ListeningChallenge _challengeFromJson(Map<String, dynamic> json) {
    final rawSolutions = json['solution'] as List<dynamic>? ?? const [];
    return ListeningChallenge(
      id: json['id'] as int,
      position: json['position'] as int? ?? 1,
      content: json['content'] as String? ?? '',
      defaultInput: json['defaultInput'] as String? ?? '',
      solutions: rawSolutions.map<List<String>>((token) {
        if (token is List<dynamic>) {
          return token.map((variant) => variant.toString()).toList();
        }
        return [token.toString()];
      }).toList(),
      audioUrl: json['audioSrc'] as String? ?? '',
      timeStart: (json['timeStart'] as num?)?.toDouble(),
      timeEnd: (json['timeEnd'] as num?)?.toDouble(),
    );
  }

  List<ListeningChallenge> _selectionChallengesFromJson(
    List<dynamic> rawChallenges,
    String lessonName,
  ) {
    final result = <ListeningChallenge>[];
    for (var groupIndex = 0; groupIndex < rawChallenges.length; groupIndex++) {
      final rawGroup = rawChallenges[groupIndex];
      if (rawGroup is! List<dynamic>) continue;
      final rawOptions = rawGroup.whereType<Map<String, dynamic>>().toList();
      if (rawOptions.length < 2) continue;

      final phonemeLabels = _phonemeLabels(lessonName, rawOptions.length);
      final recordingKey = '${(groupIndex % 6) + 1}';
      final options = <ListeningSelectionOption>[];
      final optionIds = <int>[];
      for (
        var optionIndex = 0;
        optionIndex < rawOptions.length;
        optionIndex++
      ) {
        final rawOption = rawOptions[optionIndex];
        final recordings =
            rawOption['recordings'] as Map<String, dynamic>? ?? const {};
        final rawRecording =
            recordings[recordingKey] ?? recordings.values.firstOrNull;
        if (rawRecording is! Map<String, dynamic>) continue;
        final fullPhonetic = rawRecording['secondaryText'] as String? ?? '';
        options.add(
          ListeningSelectionOption(
            text: rawRecording['text'] as String? ?? '',
            phonetic: phonemeLabels?[optionIndex] ?? fullPhonetic,
            audioUrl: rawRecording['audioSrc'] as String? ?? '',
          ),
        );
        optionIds.add(rawOption['id'] as int? ?? groupIndex + 1);
      }
      if (options.length < 2) continue;

      // Alternate the target so learners practise both sides of each contrast.
      final correctIndex = (groupIndex + 1) % options.length;
      final correctOption = options[correctIndex];
      result.add(
        ListeningChallenge(
          id: optionIds[correctIndex],
          position: groupIndex + 1,
          content: correctOption.text,
          defaultInput: '',
          solutions: [
            [correctOption.text],
          ],
          audioUrl: correctOption.audioUrl,
          selectionOptions: List.unmodifiable(options),
          correctSelectionIndex: correctIndex,
        ),
      );
    }
    return result;
  }

  List<String>? _phonemeLabels(String lessonName, int optionCount) {
    final matches = RegExp(r'/([^/]+)/').allMatches(lessonName).toList();
    if (matches.length != optionCount) return null;
    return matches.map((match) => match.group(1) ?? '').toList();
  }
}

String _cleanLessonName(String value) =>
    value.replaceFirst(RegExp(r'^\d+\.\s*'), '');
