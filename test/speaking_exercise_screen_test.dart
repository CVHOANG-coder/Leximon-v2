import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/listening_exercise.dart';
import 'package:leximon/data/services/speaking_progress_service.dart';
import 'package:leximon/presentation/screens/speaking_practice/speaking_exercise_screen.dart';

void main() {
  testWidgets('records, replays and checks a sentence word by word', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final recorder = _FakeRecorder();
    final recognizer = _FakeRecognizer('I like juice');
    final playback = _FakePlayback();
    const exercise = ListeningExercise(
      id: 10,
      name: 'At the cafe',
      levelName: 'A1',
      audioUrl: 'https://example.com/full.mp3',
      challenges: [
        ListeningChallenge(
          id: 100,
          position: 1,
          content: 'I would like orange juice',
          defaultInput: '',
          solutions: [
            ['I'],
            ['would'],
            ['like'],
            ['orange'],
            ['juice'],
          ],
          audioUrl: 'https://example.com/sentence.mp3',
        ),
      ],
      translations: {},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SpeakingExerciseScreen(
            courseId: 6,
            courseIndexAsset: 'course.json',
            lessonId: 10,
            initialExercise: exercise,
            progressService: SpeakingProgressService(database),
            recorder: recorder,
            recognizer: recognizer,
            playback: playback,
            recordingPathFactory: () async => '/tmp/leximon-speaking-test.m4a',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I would like orange juice'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('speaking-sample-audio')));
    await tester.pump();
    expect(playback.lastUrl, 'https://example.com/sentence.mp3');

    await tester.tap(
      find.byKey(const ValueKey('speaking-sentence-record-button')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Đang ghi âm'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('speaking-sentence-record-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('speaking-recording-playback')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('speaking-recording-playback')));
    await tester.pump();
    expect(playback.lastFile, '/tmp/leximon-speaking-test.m4a');

    await tester.tap(find.byKey(const ValueKey('speaking-check-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cần luyện thêm'), findsOneWidget);
    expect(find.text('Đúng'), findsOneWidget);
    expect(find.text('Sai/thừa'), findsOneWidget);
    expect(find.text('Thiếu'), findsOneWidget);
    final rows = await database
        .select(database.speakingSentenceProgressModels)
        .get();
    final sessions = await database
        .select(database.practiceSessionHistoryModels)
        .get();
    expect(rows.single.lastTranscript, 'I like juice');
    expect(sessions.single.skill, 'speaking');
    expect(tester.takeException(), isNull);
  });
}

class _FakeRecorder implements SpeakingRecorderController {
  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(String path) async {}

  @override
  Future<String?> stop() async => '/tmp/leximon-speaking-test.m4a';
}

class _FakeRecognizer implements SpeakingRecognizerController {
  _FakeRecognizer(this.transcript);

  final String transcript;

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> initialize({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) async => true;

  @override
  Future<void> listen(ValueChanged<String> onResult) async {
    onResult(transcript);
  }

  @override
  Future<void> stop() async {}
}

class _FakePlayback implements SpeakingPlaybackController {
  String? lastUrl;
  String? lastFile;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playFile(String path) async => lastFile = path;

  @override
  Future<void> playUrl(String url) async => lastUrl = url;

  @override
  Future<void> stop() async {}
}
