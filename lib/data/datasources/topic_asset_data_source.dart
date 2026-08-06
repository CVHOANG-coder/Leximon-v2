import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/topic_language.dart';
import '../models/topic_asset_payload.dart';

const _topicAssetDirectory = 'assets/data/topics';
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
  TopicAssetDataSource({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;

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
    return switch (languageCode) {
      'es-419' => 'es-US',
      'id' => 'in',
      'he' => 'iw',
      'no' => 'nb',
      _ => languageCode,
    };
  }

  Future<List<TopicLanguage>> loadAvailableLanguages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final discoveredCodes = manifest
        .listAssets()
        .map(_languageCodeFromAsset)
        .whereType<String>()
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
    final rawJson = await bundle.loadString(assetPathFor(canonicalCode));
    return compute(_decodeTopicPayload, rawJson);
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
