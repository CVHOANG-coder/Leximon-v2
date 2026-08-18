import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/reading_story.dart';

const _readingRemoteDirectory =
    'https://leximonenglish.giddychat.com/data/books';

class ReadingAssetDataSource {
  ReadingAssetDataSource({
    http.Client? client,
    Future<Directory> Function()? cacheDirectory,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory;

  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _cacheDirectory;
  final _cache = <String, Future<List<ReadingStory>>>{};

  static const remoteBaseUrl = _readingRemoteDirectory;
  static const cacheMaxAge = Duration(days: 1);

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<List<ReadingStory>> load({String languageCode = 'vi'}) {
    final assetCode = _assetCodeFor(languageCode);
    return _cache[assetCode] ??= _loadStories(assetCode);
  }

  Future<List<ReadingStory>> reload({String languageCode = 'vi'}) {
    final assetCode = _assetCodeFor(languageCode);
    _cache.remove(assetCode);
    return load(languageCode: assetCode);
  }

  Future<List<ReadingStory>> _loadStories(String assetCode) async {
    final localizedStories = await _loadPackage(assetCode);
    if (assetCode == 'en') {
      return localizedStories
          .map((story) => story.withEnglishVersion(story))
          .toList(growable: false);
    }

    final englishStories = await _loadPackage('en');
    final englishById = {for (final story in englishStories) story.id: story};
    return localizedStories
        .map(
          (story) => englishById[story.id] == null
              ? story
              : story.withEnglishVersion(englishById[story.id]!),
        )
        .toList(growable: false);
  }

  Future<List<ReadingStory>> _loadPackage(String assetCode) async {
    final cacheFile = await _cacheFile(assetCode);
    List<ReadingStory>? cachedStories;
    if (await cacheFile.exists()) {
      try {
        cachedStories = _decodeStories(await cacheFile.readAsString());
        final age = DateTime.now().difference(await cacheFile.lastModified());
        if (age <= cacheMaxAge) return cachedStories;
      } on Object {
        // Ignore an incomplete/corrupt cache and try the server below.
      }
    }

    try {
      final response = await _client
          .get(_remoteUri(assetCode))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Reading package request failed with status ${response.statusCode}.',
          uri: _remoteUri(assetCode),
        );
      }
      final stories = await compute(_decodeStories, response.body);
      await _writeCache(cacheFile, response.body);
      return stories;
    } on Object {
      if (cachedStories != null) return cachedStories;
      rethrow;
    }
  }

  String _assetCodeFor(String languageCode) {
    return switch (languageCode) {
      'es-419' || 'es-US' || 'es-ES' => 'es',
      'id' || 'in' => 'id',
      'he' || 'iw' => 'iw',
      'zh-TW' => 'zh',
      // The Reading catalogue does not include these app languages yet.
      'cs' || 'da' || 'fi' || 'hu' || 'nb' || 'no' || 'sv' => 'en',
      _ => languageCode,
    };
  }

  Uri _remoteUri(String assetCode) {
    return Uri.parse(
      '$_readingRemoteDirectory/language_reading_$assetCode.json',
    );
  }

  Future<File> _cacheFile(String assetCode) async {
    final directory = await _cacheDirectory();
    return File('${directory.path}/language_reading_$assetCode.json');
  }

  Future<void> _writeCache(File file, String contents) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  static Future<Directory> _defaultCacheDirectory() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    return Directory('${appSupportDirectory.path}/data/books');
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
