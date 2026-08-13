import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/reading_story.dart';

const _readingAssetDirectory = 'assets/data/books';

class ReadingAssetDataSource {
  ReadingAssetDataSource({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;

  Future<List<ReadingStory>> load({String languageCode = 'vi'}) async {
    final path = assetPathFor(languageCode);
    final englishPath = assetPathFor('en');
    final payloads = await Future.wait([
      bundle.loadString(path),
      if (path != englishPath) bundle.loadString(englishPath),
    ]);
    final localizedStories = await compute(_decodeStories, payloads.first);
    if (path == englishPath) {
      return localizedStories
          .map((story) => story.withEnglishVersion(story))
          .toList(growable: false);
    }

    final englishStories = await compute(_decodeStories, payloads.last);
    final englishById = {for (final story in englishStories) story.id: story};
    return localizedStories
        .map(
          (story) => englishById[story.id] == null
              ? story
              : story.withEnglishVersion(englishById[story.id]!),
        )
        .toList(growable: false);
  }

  String assetPathFor(String languageCode) {
    final assetCode = switch (languageCode) {
      'es-419' || 'es-US' || 'es-ES' => 'es',
      'id' || 'in' => 'id',
      'he' || 'iw' => 'iw',
      'zh-TW' => 'zh',
      // The Reading catalogue does not include these app languages yet.
      'cs' || 'da' || 'fi' || 'hu' || 'nb' || 'no' || 'sv' => 'en',
      _ => languageCode,
    };
    return '$_readingAssetDirectory/language_reading_$assetCode.json';
  }
}

List<ReadingStory> _decodeStories(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! List<dynamic>) {
    throw const FormatException('Reading asset must contain a JSON array.');
  }

  return decoded
      .whereType<Map<String, dynamic>>()
      .map(ReadingStory.fromJson)
      .toList(growable: false);
}
