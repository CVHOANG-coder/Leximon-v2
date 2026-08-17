import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ipa_sound.dart';
import 'ipa_local_data_source.dart';

abstract final class IpaAssetDataSource {
  static const remoteDirectory = '/data/ipa';
  static const remoteManifestPath = '$remoteDirectory/manifest.json';

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
    http.Client? client,
    String languageCode = 'en',
    IpaDownloadProgressCallback? onProgress,
  }) async {
    final ipaDirectory = await IpaLocalDataSource.ensureReady(
      symbols: _catalog.values.expand((symbols) => symbols).toList(),
      languageCode: languageCode,
      client: client,
      onProgress: onProgress,
    );
    return _loadLocal(ipaDirectory, languageCode: languageCode);
  }

  static Future<List<IpaSound>> _loadLocal(
    Directory ipaDirectory, {
    required String languageCode,
  }) async {
    final config = await _loadLocalConfig(ipaDirectory);
    final videoCatalog = _videoCatalogFromJson(
      await File(
        '${ipaDirectory.path}/${config.youtubeCatalog}',
      ).readAsString(),
    );
    final descriptions = _descriptionsFromJson(
      await File(
        '${ipaDirectory.path}/${config.descriptionsDirectory}/'
        '${_descriptionLanguage(languageCode)}.json',
      ).readAsString(),
    );
    final sounds = <IpaSound>[];
    for (final entry in _catalog.entries) {
      for (final symbol in entry.value) {
        final source = await File(
          '${ipaDirectory.path}/${config.jsonDirectory}/'
          '$symbol.json',
        ).readAsString();
        sounds.add(
          _soundFromJson(
            source,
            symbol,
            entry.key,
            videoCatalog,
            descriptions,
            ipaDirectory.path,
          ),
        );
      }
    }
    return sounds;
  }

  static Future<_IpaRemoteConfig> _loadLocalConfig(
    Directory ipaDirectory,
  ) async {
    final json = jsonDecode(
      await File('${ipaDirectory.path}/manifest.json').readAsString(),
    );
    if (json is! Map<String, dynamic>) {
      throw const FormatException('IPA remote manifest must be an object.');
    }
    return _IpaRemoteConfig.fromJson(json);
  }

  static String _descriptionLanguage(String languageCode) {
    const supportedLanguages = {'en', 'es', 'fr', 'pt', 'ru'};
    final normalizedLanguageCode = languageCode
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    return supportedLanguages.contains(normalizedLanguageCode)
        ? normalizedLanguageCode
        : 'en';
  }

  static IpaSound _soundFromJson(
    String source,
    String symbol,
    IpaSoundGroup group,
    _IpaVideoCatalog videoCatalog,
    Map<String, String> descriptions,
    String localRoot,
  ) {
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
      audioAsset: _normalizeMediaPath(
        json['audioPath']?.toString() ?? '',
        localRoot,
      ),
      group: group,
      description:
          descriptions[symbol]?.trim() ??
          json['description']?.toString().trim() ??
          '',
      photoAsset: _normalizeMediaPath(
        json['photoPath']?.toString() ?? '',
        localRoot,
      ),
      spellingWords: words
          .map((word) => _wordFromJson(word, localRoot))
          .toList(growable: false),
      beginningWords: _practiceWords(practice, 'beginningSound', localRoot),
      middleWords: _practiceWords(practice, 'middleSound', localRoot),
      endWords: _practiceWords(practice, 'endSound', localRoot),
      youtubeVideoId: videoCatalog.videoId,
      youtubeStartSeconds: videoStartSeconds.toDouble(),
    );
  }

  static IpaWord _wordFromJson(Map<String, dynamic> json, String localRoot) {
    final name = json['name']?.toString().trim() ?? '';
    return IpaWord(
      name: name,
      transcription: _phoneticTranscription(
        json['transcription']?.toString().trim() ?? '',
      ),
      audioAsset: _normalizeMediaPath(
        json['audioPath']?.toString() ?? '',
        localRoot,
      ),
    );
  }

  static List<IpaWord> _practiceWords(
    Map<String, dynamic> practice,
    String key,
    String localRoot,
  ) => (practice[key] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>()
      .map((word) => _wordFromJson(word, localRoot))
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

  static _IpaVideoCatalog _videoCatalogFromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final starts = (json['startSeconds'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );
    return _IpaVideoCatalog(
      videoId: json['videoId']?.toString().trim() ?? '',
      startSeconds: starts,
    );
  }

  static Map<String, String> _descriptionsFromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return json.map((symbol, value) => MapEntry(symbol, value.toString()));
  }

  static String _normalizeMediaPath(String sourcePath, String localRoot) {
    if (sourcePath.isEmpty) return '';
    final parsed = Uri.tryParse(sourcePath);
    if (parsed?.hasScheme == true) return sourcePath;
    const legacyPrefix = 'AmericanSounds/';
    final relative = sourcePath.startsWith(legacyPrefix)
        ? sourcePath.substring(legacyPrefix.length)
        : sourcePath;
    return '$localRoot/$relative';
  }
}

class _IpaRemoteConfig {
  const _IpaRemoteConfig({
    this.jsonDirectory = 'json',
    this.descriptionsDirectory = 'descriptions',
    this.youtubeCatalog = 'youtube_videos.json',
  });

  factory _IpaRemoteConfig.fromJson(Map<String, dynamic> json) {
    String read(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty
          ? value.trim()
          : fallback;
    }

    return _IpaRemoteConfig(
      jsonDirectory: read('jsonDirectory', 'json'),
      descriptionsDirectory: read('descriptionsDirectory', 'descriptions'),
      youtubeCatalog: read('youtubeCatalog', 'youtube_videos.json'),
    );
  }

  final String jsonDirectory;
  final String descriptionsDirectory;
  final String youtubeCatalog;
}

class _IpaVideoCatalog {
  const _IpaVideoCatalog({required this.videoId, required this.startSeconds});

  final String videoId;
  final Map<String, int> startSeconds;
}
