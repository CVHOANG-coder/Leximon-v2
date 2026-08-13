import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/models/grammar_content.dart';
import 'package:leximon/data/models/ipa_sound.dart';
import 'package:leximon/data/models/learning_language_level.dart';
import 'package:leximon/data/models/listening_catalog.dart';
import 'package:leximon/data/models/reading_story.dart';
import 'package:leximon/data/services/challenge_dashboard_service.dart';
import 'package:leximon/data/services/ipa_progress_service.dart';
import 'package:leximon/data/services/listening_progress_service.dart';
import 'package:leximon/data/services/practice_session_service.dart';
import 'package:leximon/data/services/reading_progress_service.dart';
import 'package:leximon/data/services/speaking_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('maps real progress and recommends an unfinished weak skill', () async {
    final now = DateTime(2026, 8, 13, 10);
    final listening = ListeningProgressService(database);
    await listening.startLesson(
      courseId: 1,
      lessonId: 10,
      totalChallenges: 1,
      now: now,
    );
    await listening.saveAttempt(
      courseId: 1,
      lessonId: 10,
      challengeId: 100,
      position: 1,
      totalChallenges: 1,
      answer: 'hello',
      isCorrect: true,
      now: now,
    );
    await IpaProgressService(database).recordPracticed('i', now: now);
    final reading = ReadingProgressService(database);
    await reading.recordOpened(1, now: now);
    await reading.recordScrollProgress(1, 100, now: now);
    final speaking = SpeakingProgressService(database);
    await speaking.startLesson(
      courseId: 1,
      lessonId: 10,
      totalSentences: 1,
      now: now,
    );
    await speaking.saveAssessment(
      courseId: 1,
      lessonId: 10,
      challengeId: 100,
      position: 1,
      totalSentences: 1,
      transcript: 'hello',
      accuracyPercent: 100,
      isCorrect: true,
      now: now,
    );

    final snapshot = await ChallengeDashboardService(database).load(
      listeningCourses: const [
        ListeningCourseSummary(
          id: 1,
          name: 'Conversations',
          type: 'audio',
          levelName: 'A1',
          indexAsset: 'course.json',
          lessons: [
            ListeningLessonSummary(
              id: 10,
              courseId: 1,
              name: 'Hello',
              levelName: 'A1',
              totalChallenges: 1,
              courseIndexAsset: 'course.json',
            ),
            ListeningLessonSummary(
              id: 11,
              courseId: 1,
              name: 'At home',
              levelName: 'A2',
              totalChallenges: 8,
              courseIndexAsset: 'course.json',
            ),
          ],
        ),
      ],
      grammarPacks: const [
        GrammarPackContent(
          id: 2,
          guid: 'elementary',
          level: 'Elementary',
          title: 'Elementary',
          description: '',
          iconAsset: '',
          progress: 50,
          topics: [
            GrammarTopicContent(
              id: 20,
              packId: 2,
              label: 'Present simple',
              questionCount: 10,
              progress: 30,
              isComplete: false,
            ),
            GrammarTopicContent(
              id: 21,
              packId: 2,
              label: 'Past simple',
              questionCount: 10,
              progress: 100,
              isComplete: true,
            ),
          ],
        ),
      ],
      ipaSounds: const [
        IpaSound(
          symbol: 'i',
          name: 'Long E',
          example: 'see',
          audioAsset: '',
          group: IpaSoundGroup.vowel,
        ),
        IpaSound(
          symbol: 'æ',
          name: 'Short A',
          example: 'cat',
          audioAsset: '',
          group: IpaSoundGroup.vowel,
        ),
      ],
      readingStories: const [
        ReadingStory(
          id: 1,
          title: 'First story',
          content: 'A short story.',
          imageAsset: '',
        ),
        ReadingStory(
          id: 2,
          title: 'Second story',
          content: 'Another story.',
          imageAsset: '',
        ),
      ],
      selectedLevel: LearningLanguageLevel.beginner,
      assessmentLevel: 'A2',
      now: now,
    );

    expect(snapshot.progressFor(PracticeSkill.listening).completed, 1);
    expect(snapshot.progressFor(PracticeSkill.listening).total, 2);
    expect(snapshot.progressFor(PracticeSkill.speaking).completed, 1);
    expect(snapshot.progressFor(PracticeSkill.speaking).total, 2);
    expect(snapshot.progressFor(PracticeSkill.grammar).completed, 1);
    expect(snapshot.progressFor(PracticeSkill.pronunciation).completed, 1);
    expect(snapshot.progressFor(PracticeSkill.reading).completed, 1);
    expect(snapshot.weekCompleted, 4);
    expect(snapshot.recommendation.skill, PracticeSkill.grammar);
    expect(snapshot.recommendation.title, 'Present simple');
    expect(snapshot.recommendation.contentId, '20');
    expect(snapshot.weeklyActivity, hasLength(7));
    expect(snapshot.weeklyActivity[now.weekday - 1].sessions, 4);
    expect(
      snapshot.weeklyActivity.fold<int>(
        0,
        (sum, activity) => sum + activity.sessions,
      ),
      4,
    );
    expect(snapshot.recentHistory, hasLength(4));
    expect(
      snapshot.recentHistory.map((entry) => entry.title),
      containsAll(<String>['Hello', '/i/ • see', 'First story']),
    );
    expect(
      snapshot.recentHistory.map((entry) => entry.contextLabel),
      contains('Luyện nói • Conversations'),
    );
  });

  test('persists IPA and reading completion in SQLite', () async {
    final now = DateTime(2026, 8, 13, 9);
    await IpaProgressService(database).recordOpened('θ', now: now);
    await ReadingProgressService(database).recordOpened(7, now: now);
    expect(
      await database.select(database.practiceSessionHistoryModels).get(),
      isEmpty,
      reason: 'Opening content must not increase the weekly goal.',
    );

    await IpaProgressService(database).recordPracticed('θ', now: now);
    await ReadingProgressService(
      database,
    ).recordScrollProgress(7, 85, now: now);

    final ipa = await database.select(database.ipaSoundProgressModels).get();
    final reading = await database
        .select(database.readingStoryProgressModels)
        .get();

    expect(ipa.single.symbol, 'θ');
    expect(ipa.single.practiceCount, 1);
    expect(ipa.single.completedAt, isNotNull);
    expect(reading.single.storyId, 7);
    expect(reading.single.maxScrollPercent, 85);
    expect(reading.single.completedAt, isNotNull);
    final sessions = await database
        .select(database.practiceSessionHistoryModels)
        .get();
    expect(sessions, hasLength(2));
    expect(
      sessions.map((session) => session.skill),
      containsAll(<String>['pronunciation', 'reading']),
    );
  });

  test(
    'concurrent open and completion cannot erase IPA or reading progress',
    () async {
      final now = DateTime(2026, 8, 13, 9);
      final ipa = IpaProgressService(database);
      final reading = ReadingProgressService(database);

      await Future.wait<void>([
        ipa.recordOpened('ð', now: now),
        ipa.recordPracticed('ð', now: now.add(const Duration(seconds: 1))),
        reading.recordOpened(8, now: now),
        reading.recordScrollProgress(
          8,
          100,
          now: now.add(const Duration(seconds: 1)),
        ),
      ]);

      final ipaRow = await database
          .select(database.ipaSoundProgressModels)
          .getSingle();
      final readingRow = await database
          .select(database.readingStoryProgressModels)
          .getSingle();
      final sessions = await database
          .select(database.practiceSessionHistoryModels)
          .get();

      expect(ipaRow.completedAt, isNotNull);
      expect(ipaRow.practiceCount, 1);
      expect(readingRow.completedAt, isNotNull);
      expect(readingRow.maxScrollPercent, 100);
      expect(sessions, hasLength(2));
    },
  );

  test(
    'repairs IPA and reading progress from completed session history',
    () async {
      final now = DateTime(2026, 8, 13, 9);
      final sessions = PracticeSessionService(database);
      await sessions.recordCompleted(
        skill: PracticeSessionSkill.pronunciation,
        contentId: 'ʃ',
        completedAt: now,
      );
      await sessions.recordCompleted(
        skill: PracticeSessionSkill.reading,
        contentId: '9',
        completedAt: now,
      );

      await sessions.reconcileIpaAndReadingProgress();

      final ipa = await database
          .select(database.ipaSoundProgressModels)
          .getSingle();
      final reading = await database
          .select(database.readingStoryProgressModels)
          .getSingle();
      expect(ipa.completedAt, now.millisecondsSinceEpoch);
      expect(ipa.practiceCount, 1);
      expect(reading.completedAt, now.millisecondsSinceEpoch);
      expect(reading.maxScrollPercent, 80);
    },
  );
}
