import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/data/datasources/listening_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/listening_exercise.dart';
import 'package:leximon/data/services/listening_answer_checker.dart';
import 'package:leximon/data/services/listening_progress_service.dart';
import 'package:leximon/data/services/youtube_video_info_service.dart';
import 'package:leximon/presentation/screens/listening_practice/listening_exercise_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('listening assets and answer checking', () {
    test('loads the bundled First snowfall lesson', () async {
      final lesson = await ListeningAssetDataSource().loadLesson(
        courseIndexAsset:
            'assets/data/listens/02-short-stories/course-index.json',
        lessonId: 1,
      );

      expect(lesson.name, 'First snowfall');
      expect(lesson.challenges, hasLength(21));
      expect(lesson.challenges.first.content, 'Today is November 26th.');
      expect(lesson.translations[1], 'Hôm nay là ngày 26 tháng 11.');
    });

    test('accepts configured solution variants', () {
      const challenge = ListeningChallenge(
        id: 6,
        position: 6,
        content: "My mom doesn't like the snow.",
        defaultInput: '',
        solutions: [
          ['My'],
          ['mom', 'mum'],
          ["doesn't", 'does not'],
          ['like'],
          ['the'],
          ['snow.'],
        ],
        audioUrl: '',
      );
      const checker = ListeningAnswerChecker();

      expect(
        checker.check("My mum doesn't like the snow", challenge).isCorrect,
        isTrue,
      );
      expect(
        checker.check('My mom does not like the snow.', challenge).isCorrect,
        isTrue,
      );
      expect(checker.check('My mom', challenge).isCorrect, isFalse);
    });

    test('loads YouTube video id and sentence timestamps', () async {
      final lesson = await ListeningAssetDataSource().loadLesson(
        courseIndexAsset:
            'assets/data/listens/13-stories-for-kids/course-index.json',
        lessonId: 1905,
      );

      expect(lesson.youtubeVideoId, 'ki_DGMh2r0c');
      expect(lesson.isYoutubeLesson, isTrue);
      expect(lesson.challenges.first.timeStart, 5);
      expect(lesson.challenges.first.timeEnd, 8.55);
      expect(lesson.challenges.first.audioUrl, isEmpty);
    });

    test('loads IPA lessons as pronunciation choices', () async {
      final lesson = await ListeningAssetDataSource().loadLesson(
        courseIndexAsset: 'assets/data/listens/09-ipa/course-index.json',
        lessonId: 684,
      );

      expect(lesson.isSelectionLesson, isTrue);
      expect(lesson.challenges, hasLength(10));
      expect(lesson.challenges.first.content, 'eat');
      expect(lesson.challenges.first.correctSelectionIndex, 1);
      expect(
        lesson.challenges.first.selectionOptions.map((item) => item.phonetic),
        ['ɪ', 'i:'],
      );
    });

    test('loads YouTube title and author from oEmbed', () async {
      Uri? requestedUri;
      final service = YoutubeVideoInfoService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"title":"Rapunzel - UK English accent",'
            '"author_name":"The Fable Cottage",'
            '"thumbnail_url":"https://i.ytimg.com/example.jpg"}',
            200,
          );
        }),
      );

      final info = await service.load('ki_DGMh2r0c');

      expect(requestedUri?.host, 'www.youtube.com');
      expect(requestedUri?.path, '/oembed');
      expect(requestedUri?.queryParameters['url'], contains('ki_DGMh2r0c'));
      expect(info.title, 'Rapunzel - UK English accent');
      expect(info.author, 'The Fable Cottage');
    });
  });

  group('local listening progress', () {
    late AppDatabase database;
    late ListeningProgressService progress;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      progress = ListeningProgressService(database);
    });

    tearDown(() => database.close());

    test(
      'persists challenge completion, resume position, and active time',
      () async {
        await progress.startLesson(
          courseId: 2,
          lessonId: 1,
          totalChallenges: 21,
          now: DateTime(2026, 8, 11, 9),
        );
        await progress.saveAttempt(
          courseId: 2,
          lessonId: 1,
          challengeId: 1,
          position: 1,
          totalChallenges: 21,
          answer: 'Today is November 26th.',
          isCorrect: true,
          now: DateTime(2026, 8, 11, 9, 1),
        );
        await progress.addActiveTime(
          courseId: 2,
          lessonId: 1,
          duration: const Duration(minutes: 3),
          now: DateTime(2026, 8, 11, 9, 3),
        );

        final lesson = await progress.loadLesson(courseId: 2, lessonId: 1);
        final challenges = await progress.loadChallenges(
          courseId: 2,
          lessonId: 1,
        );
        expect(lesson?.completedChallenges, 1);
        expect(lesson?.currentChallengePosition, 2);
        expect(lesson?.status, ListeningLessonStatus.inProgress.index);
        expect(challenges.single.isCompleted, isTrue);
        expect(
          await progress.activeTimeToday(now: DateTime(2026, 8, 11, 20)),
          const Duration(minutes: 3),
        );
      },
    );

    testWidgets('renders incorrect and correct answer states', (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const challenge = ListeningChallenge(
        id: 1,
        position: 1,
        content: 'Today is November 26th.',
        defaultInput: '',
        solutions: [
          ['Today'],
          ['is'],
          ['November'],
          ['26th.'],
        ],
        audioUrl: 'test://audio',
      );
      const exercise = ListeningExercise(
        id: 1,
        name: 'First snowfall',
        levelName: 'A1',
        audioUrl: '',
        challenges: [challenge],
        translations: {1: 'Hôm nay là ngày 26 tháng 11.'},
      );
      final audioController = _FakeAudioController();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ListeningExerciseScreen(
              courseId: 2,
              courseIndexAsset:
                  'assets/data/listens/02-short-stories/course-index.json',
              lessonId: 1,
              initialExercise: exercise,
              progressService: progress,
              audioController: audioController,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('First snowfall'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(audioController.playCalls, 1);
      expect(audioController.lastUrl, 'test://audio');
      expect(audioController.lastSpeed, 1);
      expect(audioController.lastRestart, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('listening-playback-toggle')));
      await tester.pump();
      expect(audioController.pauseCalls, 1);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('listening-playback-toggle')));
      await tester.pump();
      expect(audioController.playCalls, 2);
      expect(audioController.lastRestart, isFalse);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('Hôm nay là ngày 26 tháng 11.'), findsNothing);

      await tester.ensureVisible(find.text('Skip'));
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(find.text('Hôm nay là ngày 26 tháng 11.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Redo'));
      await tester.pump();
      expect(find.text('Hôm nay là ngày 26 tháng 11.'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('listening-answer-field')),
        'Today is',
      );
      await tester.ensureVisible(find.text('Check'));
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(
        find.text('Something seems missing or incorrect.'),
        findsOneWidget,
      );
      expect(find.text('Hôm nay là ngày 26 tháng 11.'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('listening-answer-field')),
        'Today is November 26th.',
      );
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Hôm nay là ngày 26 tháng 11.'), findsOneWidget);

      final saved = await progress.loadLesson(courseId: 2, lessonId: 1);
      expect(saved?.status, ListeningLessonStatus.completed.index);
    });

    testWidgets('renders IPA choice, retry, and success states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const challenge = ListeningChallenge(
        id: 32746,
        position: 1,
        content: 'eat',
        defaultInput: '',
        solutions: [
          ['eat'],
        ],
        audioUrl: 'test://eat',
        selectionOptions: [
          ListeningSelectionOption(
            text: 'it',
            phonetic: 'ɪ',
            audioUrl: 'test://it',
          ),
          ListeningSelectionOption(
            text: 'eat',
            phonetic: 'i:',
            audioUrl: 'test://eat',
          ),
        ],
        correctSelectionIndex: 1,
      );
      const exercise = ListeningExercise(
        id: 684,
        name: '/ɪ/ vs /i:/ (it vs eat)',
        levelName: '',
        audioUrl: '',
        challenges: [challenge],
        translations: {},
      );
      final audioController = _FakeAudioController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ListeningExerciseScreen(
              courseId: 9,
              courseIndexAsset: 'assets/data/listens/09-ipa/course-index.json',
              lessonId: 684,
              initialExercise: exercise,
              progressService: progress,
              audioController: audioController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('IPA PRACTICE'), findsOneWidget);
      expect(find.text('eat'), findsWidgets);
      expect(find.text('/ɪ/'), findsOneWidget);
      expect(find.text('/i:/'), findsOneWidget);
      expect(find.text('(it)'), findsNothing);
      expect(find.text('(eat)'), findsNothing);
      expect(find.text('Check'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('ipa-option-0')));
      await tester.pumpAndSettle();
      expect(audioController.lastUrl, 'test://it');
      expect(find.text("That's not correct!  Try again!"), findsNothing);
      expect(find.text('(it)'), findsNothing);
      expect(find.text('(eat)'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ipa-primary-action')));
      await tester.pumpAndSettle();
      expect(find.text("That's not correct!  Try again!"), findsOneWidget);
      expect(find.text('(it)'), findsOneWidget);
      expect(find.text('(eat)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ipa-option-1')));
      await tester.pumpAndSettle();
      expect(audioController.lastUrl, 'test://eat');
      expect(find.text('You are correct!'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ipa-primary-action')));
      await tester.pumpAndSettle();
      expect(find.text('You are correct!'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeAudioController implements ListeningAudioController {
  final _playing = StreamController<bool>.broadcast();
  bool _isPlaying = false;
  int playCalls = 0;
  int pauseCalls = 0;
  String? lastUrl;
  double? lastSpeed;
  bool? lastRestart;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Future<void> pause() async {
    pauseCalls++;
    _isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> playUrl(
    String url, {
    required double speed,
    bool restart = true,
  }) async {
    playCalls++;
    lastUrl = url;
    lastSpeed = speed;
    lastRestart = restart;
    _isPlaying = true;
    _playing.add(true);
  }

  @override
  Future<void> dispose() => _playing.close();
}
