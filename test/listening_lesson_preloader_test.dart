import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/theme/app_theme.dart';
import 'package:leximon/data/datasources/listening_asset_data_source.dart';
import 'package:leximon/data/models/listening_exercise.dart';
import 'package:leximon/data/services/listening_lesson_preloader.dart';
import 'package:leximon/presentation/screens/listening_practice/listening_preload_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('downloads distinct lesson audio and returns local file URLs', () async {
    final cacheDirectory = await Directory.systemTemp.createTemp(
      'leximon-listening-preload-',
    );
    addTearDown(() => cacheDirectory.delete(recursive: true));
    final requested = <String>[];
    final client = MockClient((request) async {
      requested.add(request.url.toString());
      return http.Response.bytes([1, 2, 3, 4], 200);
    });
    addTearDown(client.close);
    final progress = <ListeningPreloadProgress>[];
    final preloader = CachedListeningLessonPreloader(
      assetDataSource: _FakeAssetDataSource(_exercise),
      client: client,
      cacheDirectory: () async => cacheDirectory,
      parallelDownloads: 2,
    );

    final result = await preloader.preload(
      courseIndexAsset: 'test/course-index.json',
      lessonId: 7,
      onProgress: progress.add,
    );

    expect(requested, hasLength(3));
    expect(progress.first.stage, ListeningPreloadStage.loadingLesson);
    expect(progress.last.stage, ListeningPreloadStage.ready);
    expect(progress.last.loadedAudioCount, 3);
    expect(progress.last.totalAudioCount, 3);
    expect(result.challenges.first.audioUrl, startsWith('file:'));
    expect(
      result.challenges.last.selectionOptions
          .map((option) => option.audioUrl)
          .every((url) => url.startsWith('file:')),
      isTrue,
    );
    for (final url in <String>{
      result.challenges.first.audioUrl,
      ...result.challenges.last.selectionOptions.map(
        (option) => option.audioUrl,
      ),
    }) {
      expect(await File(Uri.parse(url).toFilePath()).readAsBytes(), [
        1,
        2,
        3,
        4,
      ]);
    }
  });

  testWidgets('shows the lesson name and real audio count while loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preloader = _PendingPreloader();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: ListeningPreloadScreen(
            courseId: 2,
            courseIndexAsset: 'test/course-index.json',
            lessonId: 7,
            lessonName: 'First snowfall',
            preloader: preloader,
          ),
        ),
      ),
    );
    await tester.pump();

    preloader.report(
      const ListeningPreloadProgress(
        stage: ListeningPreloadStage.loadingAudio,
        loadedAudioCount: 7,
        totalAudioCount: 21,
        lessonName: 'First snowfall',
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('listening-preload-screen')),
      findsOneWidget,
    );
    expect(find.text('Đang tải bài nghe'), findsOneWidget);
    expect(find.textContaining('First snowfall'), findsOneWidget);
    expect(find.text('Đã tải 7/21 audio'), findsOneWidget);
    expect(find.text('Đang tải audio 7/21...'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _exercise = ListeningExercise(
  id: 7,
  name: 'Audio lesson',
  levelName: 'A1',
  audioUrl: '',
  translations: {},
  challenges: [
    ListeningChallenge(
      id: 1,
      position: 1,
      content: 'One',
      defaultInput: '',
      solutions: [
        ['One'],
      ],
      audioUrl: 'https://example.com/one.mp3',
    ),
    ListeningChallenge(
      id: 2,
      position: 2,
      content: 'Two',
      defaultInput: '',
      solutions: [
        ['Two'],
      ],
      audioUrl: 'https://example.com/one.mp3',
      correctSelectionIndex: 0,
      selectionOptions: [
        ListeningSelectionOption(
          text: 'Two',
          phonetic: 'tuː',
          audioUrl: 'https://example.com/two.mp3',
        ),
        ListeningSelectionOption(
          text: 'Three',
          phonetic: 'θriː',
          audioUrl: 'https://example.com/three.mp3',
        ),
      ],
    ),
  ],
);

class _FakeAssetDataSource extends ListeningAssetDataSource {
  _FakeAssetDataSource(this.exercise);

  final ListeningExercise exercise;

  @override
  Future<ListeningExercise> loadLesson({
    required String courseIndexAsset,
    required int lessonId,
  }) async => exercise;
}

class _PendingPreloader implements ListeningLessonPreloader {
  final _completer = Completer<ListeningExercise>();
  ListeningPreloadProgressCallback? _onProgress;

  @override
  Future<ListeningExercise> preload({
    required String courseIndexAsset,
    required int lessonId,
    required ListeningPreloadProgressCallback onProgress,
  }) {
    _onProgress = onProgress;
    return _completer.future;
  }

  void report(ListeningPreloadProgress progress) => _onProgress!(progress);
}
