import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../models/listening_exercise.dart';
import '../models/listening_catalog.dart';
import 'topic_asset_data_source.dart';

class ListeningAssetDataSource {
  ListeningAssetDataSource({
    AssetBundle? bundle,
    this.languageCode = 'vi',
    http.Client? client,
    Future<Directory> Function()? cacheDirectory,
    this.useRemote = true,
  }) : _bundle = bundle ?? rootBundle,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _cacheDirectory = cacheDirectory ?? _defaultCacheDirectory;

  final AssetBundle _bundle;
  final String languageCode;
  final bool useRemote;
  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _cacheDirectory;
  final _jsonCache = <String, Future<String>>{};

  static const remoteBaseUrl =
      'https://leximonenglish.giddychat.com/data/listens';
  static const cacheMaxAge = Duration(days: 1);

  static const courseIndexAssets = <String>[
    'assets/data/listens/06-conversations/course-index.json',
    'assets/data/listens/02-short-stories/course-index.json',
    'assets/data/listens/13-stories-for-kids/course-index.json',
    'assets/data/listens/10-toeic-listening/course-index.json',
    'assets/data/listens/01-ielts-listening/course-index.json',
    'assets/data/listens/08-random-videos/course-index.json',
    'assets/data/listens/14-news/course-index.json',
    'assets/data/listens/12-ted/course-index.json',
    'assets/data/listens/07-toefl-listening/course-index.json',
    'assets/data/listens/18-medical-english-oet/course-index.json',
    'assets/data/listens/09-ipa/course-index.json',
    'assets/data/listens/04-numbers/course-index.json',
    'assets/data/listens/03-spelling-names/course-index.json',
  ];

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<List<ListeningCourseSummary>> loadCatalog() async {
    final encodedCourses = await Future.wait(
      courseIndexAssets.map(loadCourseIndex),
    );
    return [
      for (var index = 0; index < encodedCourses.length; index++)
        _courseFromJson(encodedCourses[index], courseIndexAssets[index]),
    ];
  }

  Future<Map<String, dynamic>> loadCourseIndex(String indexAsset) async {
    final encoded = await _loadJson(indexAsset);
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Listening course index must be an object.');
    }
    return decoded;
  }

  ListeningCourseSummary _courseFromJson(
    Map<String, dynamic> json,
    String indexAsset,
  ) {
    final courseId = json['id'] as int;
    final courseLevel = json['levelName'] as String? ?? 'A1';
    final fallbackLevel = courseLevel.split('-').first;
    final lessons = (json['lessons'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (lesson) => ListeningLessonSummary(
            id: lesson['id'] as int,
            courseId: courseId,
            name: _cleanLessonName(lesson['name'] as String? ?? ''),
            levelName: (lesson['levelName'] as String?)?.isNotEmpty == true
                ? lesson['levelName'] as String
                : fallbackLevel,
            totalChallenges: lesson['totalChallenges'] as int? ?? 0,
            courseIndexAsset: indexAsset,
          ),
        )
        .toList(growable: false);
    return ListeningCourseSummary(
      id: courseId,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'audio',
      levelName: courseLevel,
      indexAsset: indexAsset,
      lessons: lessons,
      totalLessons: json['totalLessons'] as int? ?? lessons.length,
    );
  }

  Future<ListeningExercise> loadLesson({
    required String courseIndexAsset,
    required int lessonId,
  }) async {
    final assetPath = await _findLessonAsset(courseIndexAsset, lessonId);
    final encoded = await _loadJson(assetPath);
    final wrapper = jsonDecode(encoded) as Map<String, dynamic>;
    final detail = wrapper['detail'] as Map<String, dynamic>?;
    if (detail == null) {
      throw const FormatException('Lesson asset does not contain detail data.');
    }

    final rawChallenges = detail['challenges'] as List<dynamic>? ?? const [];
    final lessonName =
        detail['lessonName'] as String? ?? detail['name'] as String? ?? '';
    final isSelectionLesson = rawChallenges.firstOrNull is List<dynamic>;
    final challenges = isSelectionLesson
        ? _selectionChallengesFromJson(rawChallenges, lessonName)
        : (rawChallenges
              .whereType<Map<String, dynamic>>()
              .map(_challengeFromJson)
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position)));
    if (challenges.isEmpty) {
      throw const FormatException(
        'This lesson does not support Listen & Type exercises.',
      );
    }

    final rawTranslations = wrapper['translations'];
    final selectedTranslations = rawTranslations is Map<String, dynamic>
        ? _translationMapForLanguage(rawTranslations, languageCode)
        : const <String, dynamic>{};
    final translations = <int, String>{};
    for (final entry in selectedTranslations.entries) {
      final challengeId = int.tryParse(entry.key);
      final value = entry.value;
      if (challengeId != null && value is Map<String, dynamic>) {
        final text = value['text'] as String?;
        if (text != null && text.isNotEmpty) translations[challengeId] = text;
      }
    }

    return ListeningExercise(
      id: detail['id'] as int? ?? lessonId,
      name: _cleanLessonName(lessonName),
      levelName: detail['levelName'] as String? ?? '',
      audioUrl: detail['audioSrc'] as String? ?? '',
      challenges: challenges,
      translations: translations,
      youtubeVideoId: detail['youtubeVideoId'] as String?,
    );
  }

  Map<String, dynamic> _translationMapForLanguage(
    Map<String, dynamic> translations,
    String requestedLanguageCode,
  ) {
    final requestedCode = TopicAssetDataSource.canonicalizeLanguageCode(
      requestedLanguageCode,
    );

    // Prefer an exact canonical match. This is important for simplified vs
    // traditional Chinese, which must never fall back to one another.
    for (final entry in translations.entries) {
      if (entry.value is Map<String, dynamic> &&
          TopicAssetDataSource.canonicalizeLanguageCode(entry.key) ==
              requestedCode) {
        return entry.value as Map<String, dynamic>;
      }
    }

    // The lesson payload has one generic Spanish key, while the app exposes
    // es-ES and es-US separately. Use that generic catalog only when no
    // regional Spanish catalog exists.
    if (requestedCode == 'es-ES' || requestedCode == 'es-US') {
      final genericSpanish = translations['es'];
      if (genericSpanish is Map<String, dynamic>) return genericSpanish;
    }
    return const <String, dynamic>{};
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
      if (!useRemote) {
        throw StateError('No bundled lesson asset found for lesson $lessonId.');
      }

      // The remote directory does not expose a listing endpoint. The server
      // follows the same position-id-slug naming convention as the bundled
      // files, so derive the path from the course index when a new lesson is
      // not present in the local manifest.
      final index = await loadCourseIndex(courseIndexAsset);
      final rawLessons = index['lessons'] as List<dynamic>? ?? const [];
      final lessonIndex = rawLessons.indexWhere(
        (item) => item is Map<String, dynamic> && item['id'] == lessonId,
      );
      if (lessonIndex < 0) {
        throw StateError('No remote lesson asset found for lesson $lessonId.');
      }
      final lesson = rawLessons[lessonIndex] as Map<String, dynamic>;
      final position = lesson['position'] as int? ?? lessonIndex + 1;
      final name = _slugify(lesson['name'] as String? ?? '$lessonId');
      return '$prefix${position.toString().padLeft(3, '0')}-'
          '$lessonId-$name.json';
    }
    return matches.first;
  }

  Future<String> _loadJson(String assetPath) {
    return _jsonCache[assetPath] ??= _loadJsonUncached(assetPath);
  }

  Future<String> _loadJsonUncached(String assetPath) async {
    if (!useRemote) return _bundle.loadString(assetPath);

    final cacheFile = await _cacheFile(assetPath);
    String? cached;
    if (await cacheFile.exists()) {
      try {
        cached = await cacheFile.readAsString();
        final age = DateTime.now().difference(await cacheFile.lastModified());
        if (age <= cacheMaxAge) return cached;
      } on Object {
        cached = null;
      }
    }

    try {
      final relativePath = _relativeRemotePath(assetPath);
      final uri = Uri.parse('$remoteBaseUrl/$relativePath');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Listening data request failed with status ${response.statusCode}.',
          uri: uri,
        );
      }
      await _writeCache(cacheFile, response.body);
      return response.body;
    } on Object {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<File> _cacheFile(String assetPath) async {
    final directory = await _cacheDirectory();
    return File('${directory.path}/${_relativeRemotePath(assetPath)}');
  }

  Future<void> _writeCache(File file, String contents) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  String _relativeRemotePath(String assetPath) {
    const prefix = 'assets/data/listens/';
    return assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;
  }

  static String _slugify(String value) {
    var normalized = value.toLowerCase();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    normalized = normalized.replaceAll(RegExp(r"['’]"), '');
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Future<Directory> _defaultCacheDirectory() async {
    final appSupportDirectory = await getApplicationSupportDirectory();
    return Directory('${appSupportDirectory.path}/data/listens');
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

  List<ListeningChallenge> _selectionChallengesFromJson(
    List<dynamic> rawChallenges,
    String lessonName,
  ) {
    final result = <ListeningChallenge>[];
    for (var groupIndex = 0; groupIndex < rawChallenges.length; groupIndex++) {
      final rawGroup = rawChallenges[groupIndex];
      if (rawGroup is! List<dynamic>) continue;
      final rawOptions = rawGroup.whereType<Map<String, dynamic>>().toList();
      if (rawOptions.length < 2) continue;

      final phonemeLabels = _phonemeLabels(lessonName, rawOptions.length);
      final recordingKey = '${(groupIndex % 6) + 1}';
      final options = <ListeningSelectionOption>[];
      final optionIds = <int>[];
      for (
        var optionIndex = 0;
        optionIndex < rawOptions.length;
        optionIndex++
      ) {
        final rawOption = rawOptions[optionIndex];
        final recordings =
            rawOption['recordings'] as Map<String, dynamic>? ?? const {};
        final rawRecording =
            recordings[recordingKey] ?? recordings.values.firstOrNull;
        if (rawRecording is! Map<String, dynamic>) continue;
        final fullPhonetic = rawRecording['secondaryText'] as String? ?? '';
        options.add(
          ListeningSelectionOption(
            text: rawRecording['text'] as String? ?? '',
            phonetic: phonemeLabels?[optionIndex] ?? fullPhonetic,
            audioUrl: rawRecording['audioSrc'] as String? ?? '',
          ),
        );
        optionIds.add(rawOption['id'] as int? ?? groupIndex + 1);
      }
      if (options.length < 2) continue;

      // Alternate the target so learners practise both sides of each contrast.
      final correctIndex = (groupIndex + 1) % options.length;
      final correctOption = options[correctIndex];
      result.add(
        ListeningChallenge(
          id: optionIds[correctIndex],
          position: groupIndex + 1,
          content: correctOption.text,
          defaultInput: '',
          solutions: [
            [correctOption.text],
          ],
          audioUrl: correctOption.audioUrl,
          selectionOptions: List.unmodifiable(options),
          correctSelectionIndex: correctIndex,
        ),
      );
    }
    return result;
  }

  List<String>? _phonemeLabels(String lessonName, int optionCount) {
    final matches = RegExp(r'/([^/]+)/').allMatches(lessonName).toList();
    if (matches.length != optionCount) return null;
    return matches.map((match) => match.group(1) ?? '').toList();
  }
}

String _cleanLessonName(String value) =>
    value.replaceFirst(RegExp(r'^\d+\.\s*'), '');
