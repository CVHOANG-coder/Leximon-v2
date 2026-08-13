import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../datasources/listening_asset_data_source.dart';
import '../models/listening_exercise.dart';

enum ListeningPreloadStage { loadingLesson, loadingAudio, ready }

class ListeningPreloadProgress {
  const ListeningPreloadProgress({
    required this.stage,
    required this.loadedAudioCount,
    required this.totalAudioCount,
    this.lessonName = '',
  });

  const ListeningPreloadProgress.loadingLesson()
    : stage = ListeningPreloadStage.loadingLesson,
      loadedAudioCount = 0,
      totalAudioCount = 0,
      lessonName = '';

  final ListeningPreloadStage stage;
  final int loadedAudioCount;
  final int totalAudioCount;
  final String lessonName;

  double get fraction {
    if (stage == ListeningPreloadStage.ready) return 1;
    if (totalAudioCount == 0) return 0;
    return (loadedAudioCount / totalAudioCount).clamp(0, 1);
  }
}

typedef ListeningPreloadProgressCallback =
    void Function(ListeningPreloadProgress progress);

abstract class ListeningLessonPreloader {
  Future<ListeningExercise> preload({
    required String courseIndexAsset,
    required int lessonId,
    required ListeningPreloadProgressCallback onProgress,
  });
}

/// Loads the lesson JSON and stores every exercise audio clip in the app cache.
/// The returned exercise points at the local files, so entering and moving
/// through the exercise does not need another network request.
class CachedListeningLessonPreloader implements ListeningLessonPreloader {
  factory CachedListeningLessonPreloader({
    required ListeningAssetDataSource assetDataSource,
    http.Client? client,
    Future<Directory> Function()? cacheDirectory,
    int parallelDownloads = 4,
  }) {
    return CachedListeningLessonPreloader._(
      assetDataSource,
      client ?? http.Client(),
      client == null,
      cacheDirectory ?? getTemporaryDirectory,
      parallelDownloads,
    );
  }

  CachedListeningLessonPreloader._(
    this._assetDataSource,
    this._client,
    this._ownsClient,
    this._cacheDirectory,
    this.parallelDownloads,
  );

  final ListeningAssetDataSource _assetDataSource;
  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _cacheDirectory;
  final int parallelDownloads;

  @override
  Future<ListeningExercise> preload({
    required String courseIndexAsset,
    required int lessonId,
    required ListeningPreloadProgressCallback onProgress,
  }) async {
    onProgress(const ListeningPreloadProgress.loadingLesson());
    try {
      final exercise = await _assetDataSource.loadLesson(
        courseIndexAsset: courseIndexAsset,
        lessonId: lessonId,
      );
      final urls = _audioUrls(exercise).toList(growable: false);
      var loadedCount = 0;

      void report(ListeningPreloadStage stage) {
        onProgress(
          ListeningPreloadProgress(
            stage: stage,
            loadedAudioCount: loadedCount,
            totalAudioCount: urls.length,
            lessonName: exercise.name,
          ),
        );
      }

      report(ListeningPreloadStage.loadingAudio);
      if (urls.isEmpty) {
        report(ListeningPreloadStage.ready);
        return exercise;
      }

      final root = Directory(
        '${(await _cacheDirectory()).path}/leximon-listening-audio',
      );
      await root.create(recursive: true);
      final localUrls = <String, String>{};
      var nextIndex = 0;

      Future<void> worker() async {
        while (nextIndex < urls.length) {
          final index = nextIndex++;
          final remoteUrl = urls[index];
          final file = File('${root.path}/${_cacheFileName(remoteUrl)}');
          if (!await file.exists() || await file.length() == 0) {
            await _download(remoteUrl, file);
          }
          localUrls[remoteUrl] = Uri.file(file.path).toString();
          loadedCount++;
          report(ListeningPreloadStage.loadingAudio);
        }
      }

      final workerCount = math.min(math.max(1, parallelDownloads), urls.length);
      await Future.wait(List.generate(workerCount, (_) => worker()));
      report(ListeningPreloadStage.ready);
      return _withLocalAudio(exercise, localUrls);
    } finally {
      if (_ownsClient) _client.close();
    }
  }

  Set<String> _audioUrls(ListeningExercise exercise) {
    final urls = <String>{};
    for (final challenge in exercise.challenges) {
      if (challenge.audioUrl.isNotEmpty) urls.add(challenge.audioUrl);
      for (final option in challenge.selectionOptions) {
        if (option.audioUrl.isNotEmpty) urls.add(option.audioUrl);
      }
    }
    return urls;
  }

  Future<void> _download(String url, File destination) async {
    final partial = File('${destination.path}.part');
    try {
      if (await partial.exists()) await partial.delete();
      final response = await _client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Audio request failed with status ${response.statusCode}.',
          uri: Uri.parse(url),
        );
      }
      await response.stream
          .timeout(const Duration(seconds: 30))
          .pipe(partial.openWrite());
      if (await partial.length() == 0) {
        throw const HttpException('Downloaded audio is empty.');
      }
      await partial.rename(destination.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  String _cacheFileName(String url) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(url)) {
      hash = ((hash ^ byte) * 0x100000001b3) & 0x7fffffffffffffff;
    }
    final extension = _safeExtension(Uri.parse(url).path);
    return '${hash.toRadixString(16).padLeft(16, '0')}.$extension';
  }

  String _safeExtension(String path) {
    final match = RegExp(r'\.([a-zA-Z0-9]{2,5})$').firstMatch(path);
    return match?.group(1)?.toLowerCase() ?? 'audio';
  }

  ListeningExercise _withLocalAudio(
    ListeningExercise exercise,
    Map<String, String> localUrls,
  ) {
    String local(String value) => localUrls[value] ?? value;

    return ListeningExercise(
      id: exercise.id,
      name: exercise.name,
      levelName: exercise.levelName,
      audioUrl: local(exercise.audioUrl),
      translations: exercise.translations,
      youtubeVideoId: exercise.youtubeVideoId,
      challenges: [
        for (final challenge in exercise.challenges)
          ListeningChallenge(
            id: challenge.id,
            position: challenge.position,
            content: challenge.content,
            defaultInput: challenge.defaultInput,
            solutions: challenge.solutions,
            audioUrl: local(challenge.audioUrl),
            timeStart: challenge.timeStart,
            timeEnd: challenge.timeEnd,
            correctSelectionIndex: challenge.correctSelectionIndex,
            selectionOptions: [
              for (final option in challenge.selectionOptions)
                ListeningSelectionOption(
                  text: option.text,
                  phonetic: option.phonetic,
                  audioUrl: local(option.audioUrl),
                ),
            ],
          ),
      ],
    );
  }
}
