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

  static Future<List<IpaSound>> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final sounds = <Future<IpaSound>>[];

    for (final entry in _catalog.entries) {
      for (final symbol in entry.value) {
        sounds.add(_loadSound(assets, symbol, entry.key));
      }
    }

    return Future.wait(sounds);
  }

  static Future<IpaSound> _loadSound(
    AssetBundle assets,
    String symbol,
    IpaSoundGroup group,
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

    return IpaSound(
      symbol: json['transcription']?.toString().trim() ?? symbol,
      name: json['name']?.toString().trim() ?? '',
      example: example,
      audioAsset: _normalizeAssetPath(json['audioPath'].toString()),
      group: group,
    );
  }

  static String _normalizeAssetPath(String sourcePath) {
    const legacyPrefix = 'AmericanSounds/';
    final relative = sourcePath.startsWith(legacyPrefix)
        ? sourcePath.substring(legacyPrefix.length)
        : sourcePath;
    return 'assets/data/ipa/$relative';
  }
}
