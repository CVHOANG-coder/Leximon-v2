import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sentence_exercise.dart';
import 'topic_asset_data_source.dart';

const _sentenceAssetDirectory = 'assets/data/sentences';

class SentenceAssetDataSource {
  SentenceAssetDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _cache = <String, Future<List<SentenceRecord>>>{};

  Future<List<SentenceRecord>> load({String languageCode = 'vi'}) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    return _cache[canonicalCode] ??= _loadSafely(canonicalCode);
  }

  Future<Set<int>> loadWordIds({String languageCode = 'vi'}) async {
    final sentences = await load(languageCode: languageCode);
    return sentences
        .where(
          (sentence) =>
              sentence.wordId > 0 &&
              sentence.spelling.trim().isNotEmpty &&
              sentence.translation.trim().isNotEmpty,
        )
        .map((sentence) => sentence.wordId)
        .toSet();
  }

  Future<List<SentenceRecord>> _loadSafely(String languageCode) async {
    try {
      final source = await _bundle.loadString(assetPathFor(languageCode));
      return compute(_decodeSentenceAsset, source);
    } on Object {
      return const <SentenceRecord>[];
    }
  }

  String assetPathFor(String languageCode) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    return '$_sentenceAssetDirectory/$canonicalCode.json';
  }
}

List<SentenceRecord> _decodeSentenceAsset(String source) {
  final data = jsonDecode(source);
  if (data is! List<dynamic>) {
    throw const FormatException('Sentence asset must contain a JSON array.');
  }
  return data
      .whereType<Map<String, dynamic>>()
      .map(SentenceRecord.fromJson)
      .toList(growable: false);
}
