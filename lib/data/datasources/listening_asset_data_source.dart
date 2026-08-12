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
    final challenges =
        rawChallenges
            .whereType<Map<String, dynamic>>()
            .map(_challengeFromJson)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
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
      name: _cleanLessonName(
        detail['lessonName'] as String? ?? detail['name'] as String? ?? '',
      ),
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
}

String _cleanLessonName(String value) =>
    value.replaceFirst(RegExp(r'^\d+\.\s*'), '');
