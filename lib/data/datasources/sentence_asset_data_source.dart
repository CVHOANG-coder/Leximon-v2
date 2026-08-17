import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../models/sentence_exercise.dart';
import 'topic_asset_data_source.dart';

const _sentenceAssetDirectory = 'assets/data/sentences';
const _sentenceRemoteDirectory = '/data/sentences';

class SentenceAssetDataSource {
  SentenceAssetDataSource({this.bundle, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AssetBundle? bundle;
  final ApiClient _apiClient;
  final _cache = <String, Future<List<SentenceRecord>>>{};

  Future<List<SentenceRecord>> load({String languageCode = 'vi'}) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    if (canonicalCode == 'en') {
      // English is the source language, so there is no native translation
      // sentence pack to import. Treat the package as intentionally empty.
      return _cache[canonicalCode] ??= Future<List<SentenceRecord>>.value(
        const <SentenceRecord>[],
      );
    }
    return _cache[canonicalCode] ??= _loadPackage(canonicalCode);
  }

  Future<List<SentenceRecord>> reload({String languageCode = 'vi'}) {
    final canonicalCode = TopicAssetDataSource.canonicalizeLanguageCode(
      languageCode,
    );
    _cache.remove(canonicalCode);
    return load(languageCode: canonicalCode);
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

  Future<List<SentenceRecord>> _loadPackage(String languageCode) async {
    final assetBundle = bundle;
    if (assetBundle != null) {
      final source = await assetBundle.loadString(assetPathFor(languageCode));
      return compute(_decodeSentenceAsset, source);
    }

    final response = await _apiClient.get(
      '$_sentenceRemoteDirectory/$languageCode.json',
    );
    return compute(_decodeSentenceAsset, response.body);
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
