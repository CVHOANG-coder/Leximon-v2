import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ipa_sound.dart';

abstract final class IpaAssetDataSource {
  static const _catalog = <IpaSoundGroup, List<String>>{
    IpaSoundGroup.vowel: [
      'aʊ',
      'eɪ',
      'i',
      'ju',
      'oʊ',
      'u',
      'æ',
      'ɑ',
      'ɑɪ',
      'ɔ',
      'ɔɪ',
      'ɛ',
      'ɪ',
      'ʊ',
      'ʌ',
    ],
    IpaSoundGroup.rControlledVowel: ['ɑr', 'ɔr', 'ɚ', 'ɛr'],
    IpaSoundGroup.consonant: [
      'b',
      'd',
      'f',
      'g',
      'h',
      'k',
      'l',
      'm',
      'n',
      'p',
      'r',
      's',
      't',
      'v',
      'w',
      'y',
      'z',
      'ð',
      'ŋ',
      'ʃ',
      'ʒ',
      'ʤ',
      'ʧ',
      'θ',
    ],
  };

  // These examples mirror the visual reference. If a preferred example is not
  // present in the source JSON, the first spelling word remains the fallback.
  static const _preferredExamples = <String, String>{
    'aʊ': 'brown',
    'eɪ': 'way',
    'i': 'seem',
    'ju': 'future',
    'oʊ': 'most',
    'u': 'clue',
    'æ': 'class',
    'ɑ': 'odd',
    'ɑɪ': 'dry',
    'ɔ': 'watch',
    'ɔɪ': 'joy',
    'ɛ': 'says',
    'ɪ': 'lip',
    'ʊ': 'put',
    'ʌ': 'us',
    'ɑr': 'car',
    'ɔr': 'more',
    'ɚ': 'heard',
    'ɛr': 'rare',
    'b': 'job',
    'd': 'ladder',
    'f': 'fine',
    'g': 'begin',
    'h': 'who',
    'k': 'duck',
    'l': 'like',
    'm': 'climb',
    'n': 'know',
    'p': 'pet',
    'r': 'write',
    's': 'next',
    't': 'take',
    'v': 'never',
    'w': 'rewind',
    'y': 'yes',
    'z': 'quiz',
    'ð': 'bathe',
    'ŋ': 'spring',
    'ʃ': 'ash',
    'ʒ': 'beige',
    'ʤ': 'juice',
    'ʧ': 'rich',
    'θ': 'thin',
  };

  static Future<List<IpaSound>> load({
    AssetBundle? bundle,
    String languageCode = 'en',
  }) async {
    final assets = bundle ?? rootBundle;
    final sounds = <Future<IpaSound>>[];
    final videoCatalog = await _loadVideoCatalog(assets);
    final descriptions = await _loadDescriptions(assets, languageCode);

    for (final entry in _catalog.entries) {
      for (final symbol in entry.value) {
        sounds.add(
          _loadSound(assets, symbol, entry.key, videoCatalog, descriptions),
        );
      }
    }

    return Future.wait(sounds);
  }

  static Future<IpaSound> _loadSound(
    AssetBundle assets,
    String symbol,
    IpaSoundGroup group,
    _IpaVideoCatalog videoCatalog,
    Map<String, String> descriptions,
  ) async {
    final source = await assets.loadString('assets/data/ipa/json/$symbol');
    final json = jsonDecode(source) as Map<String, dynamic>;
    final words = (json['spellingWordList'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final preferred = _preferredExamples[symbol];
    final matchingWord = words.where(
      (word) => word['name']?.toString().trim() == preferred,
    );
    final example = matchingWord.isNotEmpty
        ? matchingWord.first['name'].toString().trim()
        : (preferred ??
              (words.isEmpty
                  ? json['name'].toString().trim()
                  : words.first['name'].toString().trim()));
    final practice = json['soundPracticeWords'] as Map<String, dynamic>? ?? {};
    final videoStartSeconds = videoCatalog.startSeconds[symbol] ?? 0;

    return IpaSound(
      symbol: json['transcription']?.toString().trim() ?? symbol,
      name: json['name']?.toString().trim() ?? '',
      example: example,
      audioAsset: _normalizeAssetPath(json['audioPath'].toString()),
      group: group,
      description:
          descriptions[symbol]?.trim() ??
          json['description']?.toString().trim() ??
          '',
      photoAsset: _normalizeAssetPath(json['photoPath']?.toString() ?? ''),
      spellingWords: words.map(_wordFromJson).toList(growable: false),
      beginningWords: _practiceWords(practice, 'beginningSound'),
      middleWords: _practiceWords(practice, 'middleSound'),
      endWords: _practiceWords(practice, 'endSound'),
      youtubeVideoId: videoCatalog.videoId,
      youtubeStartSeconds: videoStartSeconds.toDouble(),
    );
  }

  static IpaWord _wordFromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    return IpaWord(
      name: name,
      transcription: _phoneticTranscription(
        json['transcription']?.toString().trim() ?? '',
      ),
      audioAsset: _normalizeAssetPath(json['audioPath']?.toString() ?? ''),
    );
  }

  static List<IpaWord> _practiceWords(
    Map<String, dynamic> practice,
    String key,
  ) => (practice[key] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>()
      .map(_wordFromJson)
      .toList(growable: false);

  static String _plainTranscription(String source) => source
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _phoneticTranscription(String source) {
    final plain = _plainTranscription(source);
    final firstSlash = plain.indexOf('/');
    final lastSlash = plain.lastIndexOf('/');
    if (firstSlash < 0 || lastSlash <= firstSlash) return '';
    return plain.substring(firstSlash, lastSlash + 1).trim();
  }

  static Future<_IpaVideoCatalog> _loadVideoCatalog(AssetBundle assets) async {
    final source = await assets.loadString(
      'assets/data/ipa/youtube_videos.json',
    );
    final json = jsonDecode(source) as Map<String, dynamic>;
    final starts = (json['startSeconds'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );
    return _IpaVideoCatalog(
      videoId: json['videoId']?.toString().trim() ?? '',
      startSeconds: starts,
    );
  }

  static Future<Map<String, String>> _loadDescriptions(
    AssetBundle assets,
    String languageCode,
  ) async {
    const supportedLanguages = {'en', 'es', 'fr', 'pt', 'ru'};
    final normalizedLanguageCode = languageCode
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    final selectedLanguage = supportedLanguages.contains(normalizedLanguageCode)
        ? normalizedLanguageCode
        : 'en';
    final source = await assets.loadString(
      'assets/data/ipa/descriptions/$selectedLanguage.json',
    );
    final json = jsonDecode(source) as Map<String, dynamic>;
    return json.map((symbol, value) => MapEntry(symbol, value.toString()));
  }

  static String _normalizeAssetPath(String sourcePath) {
    if (sourcePath.isEmpty) return '';
    const legacyPrefix = 'AmericanSounds/';
    final relative = sourcePath.startsWith(legacyPrefix)
        ? sourcePath.substring(legacyPrefix.length)
        : sourcePath;
    return 'assets/data/ipa/$relative';
  }
}

class _IpaVideoCatalog {
  const _IpaVideoCatalog({required this.videoId, required this.startSeconds});

  final String videoId;
  final Map<String, int> startSeconds;
}
