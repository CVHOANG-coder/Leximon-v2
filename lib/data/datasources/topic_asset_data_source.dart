import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../core/localization/language_code.dart';
import '../models/topic_language.dart';
import '../models/topic_asset_payload.dart';

const _topicAssetDirectory = 'assets/data/topics';
const _topicRemoteDirectory = '/data/topics';
final _topicAssetPattern = RegExp(r'^assets/data/topics/data_en_(.+)\.json$');

const _languageLabels = <String, String>{
  'ar': 'العربية',
  'cs': 'Čeština',
  'da': 'Dansk',
  'de': 'Deutsch',
  'es-ES': 'Español (España)',
  'es-US': 'Español (Latinoamérica)',
  'fi': 'Suomi',
  'fil': 'Filipino',
  'fr': 'Français',
  'hi': 'हिन्दी',
  'hu': 'Magyar',
  'in': 'Bahasa Indonesia',
  'it': 'Italiano',
  'iw': 'עברית',
  'ja': '日本語',
  'ko': '한국어',
  'ms': 'Bahasa Melayu',
  'nb': 'Norsk bokmål',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'pt': 'Português',
  'ro': 'Română',
  'ru': 'Русский',
  'sv': 'Svenska',
  'th': 'ไทย',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'vi': 'Tiếng Việt',
  'zh-TW': '繁體中文',
  'zh': '简体中文',
};

class TopicAssetDataSource {
  TopicAssetDataSource({AssetBundle? bundle, ApiClient? apiClient})
    : bundle = bundle ?? rootBundle,
      _bundleOverride = bundle,
      _apiClient = apiClient ?? ApiClient();

  final AssetBundle bundle;
  final AssetBundle? _bundleOverride;
  final ApiClient _apiClient;

  static const knownLanguages = <TopicLanguage>[
    TopicLanguage(code: 'ar', label: 'العربية'),
    TopicLanguage(code: 'es-US', label: 'Español (Latinoamérica)'),
    TopicLanguage(code: 'es-ES', label: 'Español (España)'),
    TopicLanguage(code: 'ru', label: 'Русский'),
    TopicLanguage(code: 'uk', label: 'Українська'),
    TopicLanguage(code: 'vi', label: 'Tiếng Việt'),
    TopicLanguage(code: 'de', label: 'Deutsch'),
    TopicLanguage(code: 'th', label: 'ไทย'),
    TopicLanguage(code: 'ja', label: '日本語'),
    TopicLanguage(code: 'tr', label: 'Türkçe'),
    TopicLanguage(code: 'pt', label: 'Português'),
    TopicLanguage(code: 'cs', label: 'Čeština'),
    TopicLanguage(code: 'da', label: 'Dansk'),
    TopicLanguage(code: 'fi', label: 'Suomi'),
    TopicLanguage(code: 'fil', label: 'Filipino'),
    TopicLanguage(code: 'fr', label: 'Français'),
    TopicLanguage(code: 'hi', label: 'हिन्दी'),
    TopicLanguage(code: 'hu', label: 'Magyar'),
    TopicLanguage(code: 'in', label: 'Bahasa Indonesia'),
    TopicLanguage(code: 'it', label: 'Italiano'),
    TopicLanguage(code: 'iw', label: 'עברית'),
    TopicLanguage(code: 'ko', label: '한국어'),
    TopicLanguage(code: 'ms', label: 'Bahasa Melayu'),
    TopicLanguage(code: 'nb', label: 'Norsk bokmål'),
    TopicLanguage(code: 'nl', label: 'Nederlands'),
    TopicLanguage(code: 'pl', label: 'Polski'),
    TopicLanguage(code: 'ro', label: 'Română'),
    TopicLanguage(code: 'sv', label: 'Svenska'),
    TopicLanguage(code: 'zh-TW', label: '繁體中文'),
    TopicLanguage(code: 'zh', label: '简体中文'),
  ];

  static String canonicalizeLanguageCode(String languageCode) {
    return canonicalLanguageCode(languageCode);
  }

  Future<List<TopicLanguage>> loadAvailableLanguages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final discoveredCodes = manifest
        .listAssets()
        .map(_languageCodeFromAsset)
        .whereType<String>()
        // English is the source language, not a native-language topic pack.
        .where((code) => code != 'en')
        .toSet();

    if (discoveredCodes.isEmpty) return knownLanguages;

    final codes = [
      ...knownLanguages
          .map((language) => language.code)
          .where(discoveredCodes.contains),
      ...discoveredCodes
          .difference(knownLanguages.map((e) => e.code).toSet())
          .toList()
        ..sort(),
    ];

    return codes
        .map(
          (code) =>
              TopicLanguage(code: code, label: _languageLabels[code] ?? code),
        )
        .toList(growable: false);
  }

  Future<TopicAssetPayload> load({String languageCode = 'vi'}) async {
    final canonicalCode = canonicalizeLanguageCode(languageCode);
    // An explicitly supplied bundle is retained for deterministic tests. The
    // application datasource has no bundle override and always loads remotely.
    if (_bundleOverride != null) {
      // There is no separate English translation asset because the source
      // vocabulary is already English.
      final assetCode = canonicalCode == 'en' ? 'vi' : canonicalCode;
      final rawJson = await bundle.loadString(assetPathFor(assetCode));
      return compute(
        canonicalCode == 'en'
            ? _decodeEnglishTopicPayload
            : _decodeTopicPayload,
        rawJson,
      );
    }

    // The backend currently has no data_en_en.json. Reuse the Vietnamese
    // source catalogue and map its translated fields to the English source.
    final remoteCode = canonicalCode == 'en' ? 'vi' : canonicalCode;
    final response = await _apiClient.get(
      '$_topicRemoteDirectory/data_en_$remoteCode.json',
    );
    final data = response.mapData;
    if (data == null) {
      throw const FormatException('Topic response must contain a JSON object.');
    }
    if (data['topics'] is! List) {
      throw const FormatException(
        'Topic response does not contain a topics package.',
      );
    }
    final payload = TopicAssetPayload.fromJson(data);
    if (payload.topics.isEmpty) {
      throw const FormatException('Topic package is empty.');
    }
    return canonicalCode == 'en' ? _mapEnglishTopicPayload(payload) : payload;
  }

  String assetPathFor(String languageCode) {
    final canonicalCode = canonicalizeLanguageCode(languageCode);
    return '$_topicAssetDirectory/data_en_$canonicalCode.json';
  }
}

String? _languageCodeFromAsset(String assetPath) {
  return _topicAssetPattern.firstMatch(assetPath)?.group(1);
}

TopicAssetPayload _decodeTopicPayload(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Topic asset must contain a JSON object.');
  }
  return TopicAssetPayload.fromJson(decoded);
}

TopicAssetPayload _decodeEnglishTopicPayload(String rawJson) {
  return _mapEnglishTopicPayload(_decodeTopicPayload(rawJson));
}

TopicAssetPayload _mapEnglishTopicPayload(TopicAssetPayload payload) {
  return TopicAssetPayload(
    version: payload.version,
    topics: payload.topics
        .map(
          (topic) => TopicAssetItem(
            id: topic.id,
            order: topic.order,
            original: topic.original,
            translated: topic.original,
            isEnabled: topic.isEnabled,
            words: topic.words
                .map(
                  (word) => WordAssetItem(
                    id: word.id,
                    writing: word.writing,
                    translation: word.writing,
                    transcription: word.transcription,
                    transliteration: word.transliteration,
                    isEnabled: word.isEnabled,
                    priority: word.priority,
                    level: word.level,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
  );
}
