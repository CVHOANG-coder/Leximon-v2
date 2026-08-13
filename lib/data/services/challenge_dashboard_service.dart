import 'dart:math' as math;

import '../local/app_database.dart';
import '../models/grammar_content.dart';
import '../models/ipa_sound.dart';
import '../models/learning_language_level.dart';
import '../models/listening_catalog.dart';
import '../models/reading_story.dart';
import 'practice_session_service.dart';
import 'speaking_progress_service.dart';

enum PracticeSkill { listening, speaking, grammar, pronunciation, reading }

class PracticeModeProgress {
  const PracticeModeProgress({
    required this.skill,
    required this.completed,
    required this.total,
    required this.weekSessions,
  });

  final PracticeSkill skill;
  final int completed;
  final int total;
  final int weekSessions;

  double get ratio => total == 0 ? 0 : (completed / total).clamp(0, 1);
}

class PracticeRecommendation {
  const PracticeRecommendation({
    required this.skill,
    required this.title,
    required this.contextLabel,
    required this.reason,
    required this.durationMinutes,
    this.contentId,
    this.parentId,
    this.assetPath,
  });

  final PracticeSkill skill;
  final String title;
  final String contextLabel;
  final String reason;
  final int durationMinutes;
  final String? contentId;
  final int? parentId;
  final String? assetPath;
}

class WeeklyPracticeActivity {
  const WeeklyPracticeActivity({required this.date, required this.sessions});

  final DateTime date;
  final int sessions;
}

class PracticeHistoryEntry {
  const PracticeHistoryEntry({
    required this.skill,
    required this.title,
    required this.contextLabel,
    required this.completedAt,
  });

  final PracticeSkill skill;
  final String title;
  final String contextLabel;
  final DateTime completedAt;
}

class ChallengeDashboardSnapshot {
  const ChallengeDashboardSnapshot({
    required this.modes,
    required this.recommendation,
    required this.weekCompleted,
    required this.weekGoal,
    required this.knownWordCount,
    required this.levelLabel,
    this.weeklyActivity = const [],
    this.recentHistory = const [],
  });

  final List<PracticeModeProgress> modes;
  final PracticeRecommendation recommendation;
  final int weekCompleted;
  final int weekGoal;
  final int knownWordCount;
  final String levelLabel;
  final List<WeeklyPracticeActivity> weeklyActivity;
  final List<PracticeHistoryEntry> recentHistory;

  double get weekProgress =>
      weekGoal == 0 ? 0 : (weekCompleted / weekGoal).clamp(0, 1);

  PracticeModeProgress progressFor(PracticeSkill skill) => modes.firstWhere(
    (mode) => mode.skill == skill,
    orElse: () => PracticeModeProgress(
      skill: skill,
      completed: 0,
      total: 0,
      weekSessions: 0,
    ),
  );
}

class ChallengeDashboardService {
  const ChallengeDashboardService(this._database);

  static const weekGoal = 24;
  static const _skillWeekGoal = 6;

  final AppDatabase _database;

  Future<ChallengeDashboardSnapshot> load({
    required List<ListeningCourseSummary> listeningCourses,
    required List<GrammarPackContent> grammarPacks,
    required List<IpaSound> ipaSounds,
    required List<ReadingStory> readingStories,
    required LearningLanguageLevel selectedLevel,
    String? assessmentLevel,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final weekStart = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day - currentTime.weekday + 1,
    ).millisecondsSinceEpoch;

    await PracticeSessionService(_database).reconcileIpaAndReadingProgress();

    final results = await Future.wait<Object>([
      _database.select(_database.listeningLessonProgressModels).get(),
      _database.select(_database.listeningChallengeProgressModels).get(),
      _database.select(_database.grammarUserResponseModels).get(),
      _database.select(_database.ipaSoundProgressModels).get(),
      _database.select(_database.readingStoryProgressModels).get(),
      _database.select(_database.practiceSessionHistoryModels).get(),
      _database.enabledWords(),
      _database.select(_database.learningProgressModels).get(),
      _database.select(_database.speakingLessonProgressModels).get(),
      _database.select(_database.speakingSentenceProgressModels).get(),
    ]);
    final listeningProgress = results[0] as List<ListeningLessonProgressRow>;
    final listeningChallenges =
        results[1] as List<ListeningChallengeProgressRow>;
    final grammarResponses = results[2] as List<GrammarUserResponseRow>;
    final ipaProgress = results[3] as List<IpaSoundProgressRow>;
    final readingProgress = results[4] as List<ReadingStoryProgressRow>;
    final completedSessions = results[5] as List<PracticeSessionHistoryRow>;
    final words = results[6] as List<WordRow>;
    final wordProgress = results[7] as List<LearningProgressRow>;
    final speakingProgress = results[8] as List<SpeakingLessonProgressRow>;
    final speakingSentences = results[9] as List<SpeakingSentenceProgressRow>;

    final progressByWordId = {for (final row in wordProgress) row.id: row};
    final knownWords = <String>{};
    for (final word in words) {
      final progress = progressByWordId[word.id];
      if (progress?.markedAsKnown == true || progress?.learnedDate != null) {
        knownWords.add(word.writing.trim().toLowerCase());
      }
    }
    final catalogWords = {
      for (final word in words) word.writing.trim().toLowerCase(),
    };
    final dueWordCount = wordProgress
        .where(
          (row) =>
              !row.deletedByUser &&
              row.repetitionDate != null &&
              row.repetitionDate! <= currentTime.millisecondsSinceEpoch,
        )
        .length;
    final dueRatio = words.isEmpty
        ? 0.0
        : (dueWordCount / math.max(1, words.length)).clamp(0.0, 1.0);
    final ability = _ability(
      assessmentLevel: assessmentLevel,
      selectedLevel: selectedLevel,
      knownWordCount: knownWords.length,
      totalWordCount: words.length,
    );

    final listeningLessons = listeningCourses
        .expand((course) => course.lessons)
        .toList(growable: false);
    final grammarTopics = grammarPacks
        .expand((pack) => pack.topics)
        .toList(growable: false);
    final weeklyActivity = List<WeeklyPracticeActivity>.generate(7, (index) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        weekStart,
      ).add(Duration(days: index));
      final nextDate = date.add(const Duration(days: 1));
      final count = completedSessions.where((row) {
        final completedAt = DateTime.fromMillisecondsSinceEpoch(
          row.completedAt,
        );
        return row.status == 'completed' &&
            !completedAt.isBefore(date) &&
            completedAt.isBefore(nextDate);
      }).length;
      return WeeklyPracticeActivity(date: date, sessions: count);
    }, growable: false);
    final recentHistory = _buildRecentHistory(
      sessions: completedSessions,
      listeningCourses: listeningCourses,
      grammarPacks: grammarPacks,
      ipaSounds: ipaSounds,
      readingStories: readingStories,
    );

    int completedThisWeek(PracticeSessionSkill skill) => completedSessions
        .where(
          (row) =>
              row.status == 'completed' &&
              row.skill == skill.name &&
              row.completedAt >= weekStart,
        )
        .length;
    final listeningWeek = completedThisWeek(PracticeSessionSkill.listening);
    final speakingWeek = completedThisWeek(PracticeSessionSkill.speaking);
    final grammarWeek = completedThisWeek(PracticeSessionSkill.grammar);
    final ipaWeek = completedThisWeek(PracticeSessionSkill.pronunciation);
    final readingWeek = completedThisWeek(PracticeSessionSkill.reading);

    final modes = <PracticeModeProgress>[
      PracticeModeProgress(
        skill: PracticeSkill.listening,
        completed: listeningProgress.where((row) => row.status == 2).length,
        total: listeningLessons.length,
        weekSessions: listeningWeek,
      ),
      PracticeModeProgress(
        skill: PracticeSkill.speaking,
        completed: speakingProgress.where((row) => row.status == 2).length,
        total: listeningLessons.length,
        weekSessions: speakingWeek,
      ),
      PracticeModeProgress(
        skill: PracticeSkill.grammar,
        completed: grammarTopics.where((topic) => topic.isComplete).length,
        total: grammarTopics.length,
        weekSessions: grammarWeek,
      ),
      PracticeModeProgress(
        skill: PracticeSkill.pronunciation,
        completed: ipaProgress.where((row) => row.completedAt != null).length,
        total: ipaSounds.length,
        weekSessions: ipaWeek,
      ),
      PracticeModeProgress(
        skill: PracticeSkill.reading,
        completed: readingProgress
            .where((row) => row.completedAt != null)
            .length,
        total: readingStories.length,
        weekSessions: readingWeek,
      ),
    ];

    final weaknesses = <PracticeSkill, double>{
      PracticeSkill.listening: _listeningWeakness(listeningChallenges),
      PracticeSkill.speaking: _speakingWeakness(speakingSentences),
      PracticeSkill.grammar: _grammarWeakness(grammarResponses),
      PracticeSkill.pronunciation: _completionWeakness(
        completed: modes[3].completed,
        started: ipaProgress.length,
      ),
      PracticeSkill.reading: _completionWeakness(
        completed: modes[4].completed,
        started: readingProgress.length,
      ),
    };
    final continuity = <PracticeSkill, double>{
      PracticeSkill.listening: listeningProgress.any((row) => row.status == 1)
          ? 1
          : 0,
      PracticeSkill.speaking: speakingProgress.any((row) => row.status == 1)
          ? 1
          : 0,
      PracticeSkill.grammar:
          grammarTopics.any((topic) => topic.progress > 0 && !topic.isComplete)
          ? 1
          : 0,
      PracticeSkill.pronunciation:
          ipaProgress.any((row) => row.completedAt == null) ? 1 : 0,
      PracticeSkill.reading:
          readingProgress.any((row) => row.completedAt == null) ? 1 : 0,
    };
    final lastActivity = <PracticeSkill, int>{
      PracticeSkill.listening: _maxOrZero(
        listeningProgress.map((row) => row.updatedAt),
      ),
      PracticeSkill.speaking: _maxOrZero(
        speakingProgress.map((row) => row.updatedAt),
      ),
      PracticeSkill.grammar: _maxOrZero(
        grammarResponses.map((row) => row.updatedAt),
      ),
      PracticeSkill.pronunciation: _maxOrZero(
        ipaProgress.map((row) => row.updatedAt),
      ),
      PracticeSkill.reading: _maxOrZero(
        readingProgress.map((row) => row.updatedAt),
      ),
    };
    final latestActivity = lastActivity.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final latestSkill = latestActivity.value == 0 ? null : latestActivity.key;
    final skillScores = <PracticeSkill, double>{};
    for (final mode in modes) {
      final gap = ((_skillWeekGoal - mode.weekSessions) / _skillWeekGoal).clamp(
        0.0,
        1.0,
      );
      final reviewUrgency = switch (mode.skill) {
        PracticeSkill.listening ||
        PracticeSkill.speaking ||
        PracticeSkill.reading => dueRatio,
        _ => 0.0,
      };
      final variety = lastActivity[mode.skill] == 0 ? 1.0 : 0.35;
      final repetitionPenalty = latestSkill == mode.skill ? .12 : 0.0;
      skillScores[mode.skill] =
          .32 * gap +
          .28 * (weaknesses[mode.skill] ?? .5) +
          .20 * reviewUrgency +
          .12 * (continuity[mode.skill] ?? 0) +
          .08 * variety -
          repetitionPenalty;
    }
    final selectedSkill = skillScores.entries
        .reduce((left, right) => left.value >= right.value ? left : right)
        .key;

    final recommendation = _recommend(
      selectedSkill: selectedSkill,
      ability: ability,
      knownWords: knownWords,
      catalogWords: catalogWords,
      listeningCourses: listeningCourses,
      listeningProgress: listeningProgress,
      speakingProgress: speakingProgress,
      grammarPacks: grammarPacks,
      ipaSounds: ipaSounds,
      ipaProgress: ipaProgress,
      readingStories: readingStories,
      readingProgress: readingProgress,
      skillWeekSessions: modes
          .firstWhere((mode) => mode.skill == selectedSkill)
          .weekSessions,
      weakness: weaknesses[selectedSkill] ?? .5,
    );

    return ChallengeDashboardSnapshot(
      modes: modes,
      recommendation: recommendation,
      weekCompleted:
          listeningWeek + speakingWeek + grammarWeek + ipaWeek + readingWeek,
      weekGoal: weekGoal,
      knownWordCount: knownWords.length,
      levelLabel: assessmentLevel ?? selectedLevel.label,
      weeklyActivity: weeklyActivity,
      recentHistory: recentHistory,
    );
  }

  List<PracticeHistoryEntry> _buildRecentHistory({
    required List<PracticeSessionHistoryRow> sessions,
    required List<ListeningCourseSummary> listeningCourses,
    required List<GrammarPackContent> grammarPacks,
    required List<IpaSound> ipaSounds,
    required List<ReadingStory> readingStories,
  }) {
    final listeningTitles = <String, ({String title, String context})>{};
    for (final course in listeningCourses) {
      for (final lesson in course.lessons) {
        listeningTitles['${course.id}:${lesson.id}'] = (
          title: lesson.name,
          context: 'Luyện nghe • ${course.name}',
        );
      }
    }
    final grammarTitles = <String, ({String title, String context})>{};
    for (final pack in grammarPacks) {
      for (final topic in pack.topics) {
        grammarTitles[topic.id.toString()] = (
          title: topic.label,
          context: 'Ngữ pháp • ${pack.title}',
        );
      }
    }
    final ipaTitles = {
      for (final sound in ipaSounds)
        sound.symbol: (
          title: '/${sound.symbol}/ • ${sound.example}',
          context: 'IPA & phát âm',
        ),
    };
    final readingTitles = {
      for (final story in readingStories)
        story.id.toString(): (title: story.title, context: 'Luyện đọc'),
    };

    final sorted =
        sessions
            .where((row) => row.status == 'completed')
            .toList(growable: false)
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final history = <PracticeHistoryEntry>[];
    for (final session in sorted) {
      final skill = switch (session.skill) {
        'listening' => PracticeSkill.listening,
        'speaking' => PracticeSkill.speaking,
        'grammar' => PracticeSkill.grammar,
        'pronunciation' => PracticeSkill.pronunciation,
        'reading' => PracticeSkill.reading,
        _ => null,
      };
      if (skill == null) continue;
      final item = switch (skill) {
        PracticeSkill.listening =>
          listeningTitles['${session.parentId}:${session.contentId}'],
        PracticeSkill.speaking =>
          listeningTitles['${session.parentId}:${session.contentId}'],
        PracticeSkill.grammar => grammarTitles[session.contentId],
        PracticeSkill.pronunciation => ipaTitles[session.contentId],
        PracticeSkill.reading => readingTitles[session.contentId],
      };
      history.add(
        PracticeHistoryEntry(
          skill: skill,
          title: item?.title ?? _fallbackHistoryTitle(skill, session.contentId),
          contextLabel: skill == PracticeSkill.speaking
              ? 'Luyện nói • ${item?.context.split(' • ').last ?? 'Bài nghe'}'
              : item?.context ?? _skillLabel(skill),
          completedAt: DateTime.fromMillisecondsSinceEpoch(session.completedAt),
        ),
      );
      if (history.length == 6) break;
    }
    return history;
  }

  String _fallbackHistoryTitle(PracticeSkill skill, String contentId) =>
      switch (skill) {
        PracticeSkill.listening => 'Bài nghe $contentId',
        PracticeSkill.speaking => 'Bài nói $contentId',
        PracticeSkill.grammar => 'Chủ đề ngữ pháp $contentId',
        PracticeSkill.pronunciation => 'Âm /$contentId/',
        PracticeSkill.reading => 'Bài đọc $contentId',
      };

  PracticeRecommendation _recommend({
    required PracticeSkill selectedSkill,
    required double ability,
    required Set<String> knownWords,
    required Set<String> catalogWords,
    required List<ListeningCourseSummary> listeningCourses,
    required List<ListeningLessonProgressRow> listeningProgress,
    required List<SpeakingLessonProgressRow> speakingProgress,
    required List<GrammarPackContent> grammarPacks,
    required List<IpaSound> ipaSounds,
    required List<IpaSoundProgressRow> ipaProgress,
    required List<ReadingStory> readingStories,
    required List<ReadingStoryProgressRow> readingProgress,
    required int skillWeekSessions,
    required double weakness,
  }) {
    final reason = _reason(
      skill: selectedSkill,
      weekSessions: skillWeekSessions,
      weakness: weakness,
    );
    return switch (selectedSkill) {
      PracticeSkill.listening => _recommendListening(
        listeningCourses,
        listeningProgress,
        ability,
        reason,
      ),
      PracticeSkill.speaking => _recommendSpeaking(
        listeningCourses,
        speakingProgress,
        ability,
        reason,
      ),
      PracticeSkill.grammar => _recommendGrammar(grammarPacks, ability, reason),
      PracticeSkill.pronunciation => _recommendIpa(
        ipaSounds,
        ipaProgress,
        ability,
        reason,
      ),
      PracticeSkill.reading => _recommendReading(
        readingStories,
        readingProgress,
        knownWords,
        catalogWords,
        ability,
        reason,
      ),
    };
  }

  PracticeRecommendation _recommendListening(
    List<ListeningCourseSummary> courses,
    List<ListeningLessonProgressRow> progress,
    double ability,
    String reason,
  ) {
    final allLessons = courses.expand((course) => course.lessons).toList();
    final progressByKey = {
      for (final row in progress) '${row.courseId}:${row.lessonId}': row,
    };
    final inProgress = progress.where((row) => row.status == 1).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    ListeningLessonSummary? lesson;
    if (inProgress.isNotEmpty) {
      final row = inProgress.first;
      lesson = allLessons
          .where(
            (item) => item.courseId == row.courseId && item.id == row.lessonId,
          )
          .firstOrNull;
    }
    lesson ??=
        (allLessons.where((item) {
              final row = progressByKey['${item.courseId}:${item.id}'];
              return row?.status != 2;
            }).toList()..sort((left, right) {
              final leftFit = (_levelValue(left.levelName) - ability).abs();
              final rightFit = (_levelValue(right.levelName) - ability).abs();
              return leftFit.compareTo(rightFit);
            }))
            .firstOrNull;
    lesson ??= allLessons.firstOrNull;
    if (lesson == null) return _fallback(PracticeSkill.listening, reason);
    final course = courses.firstWhere((item) => item.id == lesson!.courseId);
    return PracticeRecommendation(
      skill: PracticeSkill.listening,
      title: lesson.name,
      contextLabel: 'Luyện nghe • ${course.name}',
      reason: inProgress.isNotEmpty ? 'Tiếp tục bài đang làm dở' : reason,
      durationMinutes: math.max(5, (lesson.totalChallenges / 2).ceil()),
      contentId: '${lesson.id}',
      parentId: lesson.courseId,
      assetPath: lesson.courseIndexAsset,
    );
  }

  PracticeRecommendation _recommendSpeaking(
    List<ListeningCourseSummary> courses,
    List<SpeakingLessonProgressRow> progress,
    double ability,
    String reason,
  ) {
    final allLessons = courses.expand((course) => course.lessons).toList();
    final progressByKey = {
      for (final row in progress) '${row.courseId}:${row.lessonId}': row,
    };
    final inProgress = progress.where((row) => row.status == 1).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    ListeningLessonSummary? lesson;
    if (inProgress.isNotEmpty) {
      final row = inProgress.first;
      lesson = allLessons
          .where(
            (item) => item.courseId == row.courseId && item.id == row.lessonId,
          )
          .firstOrNull;
    }
    lesson ??=
        (allLessons.where((item) {
              final row = progressByKey['${item.courseId}:${item.id}'];
              return row?.status != SpeakingLessonStatus.completed.index;
            }).toList()..sort((left, right) {
              final leftFit = (_levelValue(left.levelName) - ability).abs();
              final rightFit = (_levelValue(right.levelName) - ability).abs();
              return leftFit.compareTo(rightFit);
            }))
            .firstOrNull;
    lesson ??= allLessons.firstOrNull;
    if (lesson == null) return _fallback(PracticeSkill.speaking, reason);
    final course = courses.firstWhere((item) => item.id == lesson!.courseId);
    return PracticeRecommendation(
      skill: PracticeSkill.speaking,
      title: lesson.name,
      contextLabel: 'Luyện nói • ${course.name}',
      reason: inProgress.isNotEmpty ? 'Tiếp tục bài nói đang làm dở' : reason,
      durationMinutes: math.max(5, (lesson.totalChallenges / 2).ceil()),
      contentId: '${lesson.id}',
      parentId: lesson.courseId,
      assetPath: lesson.courseIndexAsset,
    );
  }

  PracticeRecommendation _recommendGrammar(
    List<GrammarPackContent> packs,
    double ability,
    String reason,
  ) {
    final candidates =
        <({GrammarPackContent pack, GrammarTopicContent topic})>[
          for (final pack in packs)
            for (final topic in pack.topics)
              if (!topic.isComplete) (pack: pack, topic: topic),
        ]..sort((left, right) {
          final leftResume = left.topic.progress > 0 ? 0 : 1;
          final rightResume = right.topic.progress > 0 ? 0 : 1;
          if (leftResume != rightResume) {
            return leftResume.compareTo(rightResume);
          }
          return (_grammarLevelValue(left.pack.level) - ability)
              .abs()
              .compareTo(
                (_grammarLevelValue(right.pack.level) - ability).abs(),
              );
        });
    final candidate = candidates.firstOrNull;
    if (candidate == null) return _fallback(PracticeSkill.grammar, reason);
    return PracticeRecommendation(
      skill: PracticeSkill.grammar,
      title: candidate.topic.label,
      contextLabel: 'Ngữ pháp • ${candidate.pack.title}',
      reason: candidate.topic.progress > 0
          ? 'Tiếp tục chủ đề đang làm dở'
          : reason,
      durationMinutes: math.max(5, candidate.topic.questionCount),
      contentId: '${candidate.topic.id}',
      parentId: candidate.pack.id,
    );
  }

  PracticeRecommendation _recommendIpa(
    List<IpaSound> sounds,
    List<IpaSoundProgressRow> progress,
    double ability,
    String reason,
  ) {
    final progressBySymbol = {for (final row in progress) row.symbol: row};
    final candidates = sounds
        .where((sound) => progressBySymbol[sound.symbol]?.completedAt == null)
        .toList();
    candidates.sort((left, right) {
      final leftIndex = sounds.indexOf(left) / math.max(1, sounds.length - 1);
      final rightIndex = sounds.indexOf(right) / math.max(1, sounds.length - 1);
      return (leftIndex - ability).abs().compareTo(
        (rightIndex - ability).abs(),
      );
    });
    final sound = candidates.firstOrNull ?? sounds.firstOrNull;
    if (sound == null) return _fallback(PracticeSkill.pronunciation, reason);
    final opened = progressBySymbol[sound.symbol] != null;
    return PracticeRecommendation(
      skill: PracticeSkill.pronunciation,
      title: '${sound.name.trim()} /${sound.symbol}/',
      contextLabel: 'IPA & phát âm • ${sound.typeLabel}',
      reason: opened ? 'Tiếp tục âm đang luyện' : reason,
      durationMinutes: 6,
      contentId: sound.symbol,
    );
  }

  PracticeRecommendation _recommendReading(
    List<ReadingStory> stories,
    List<ReadingStoryProgressRow> progress,
    Set<String> knownWords,
    Set<String> catalogWords,
    double ability,
    String reason,
  ) {
    final progressByStoryId = {for (final row in progress) row.storyId: row};
    final candidates = stories
        .where((story) => progressByStoryId[story.id]?.completedAt == null)
        .toList();
    candidates.sort((left, right) {
      final leftProgress = progressByStoryId[left.id];
      final rightProgress = progressByStoryId[right.id];
      final leftResume = leftProgress != null ? 0 : 1;
      final rightResume = rightProgress != null ? 0 : 1;
      if (leftResume != rightResume) return leftResume.compareTo(rightResume);
      final leftCoverage = _lexicalCoverage(
        left.originalContent,
        knownWords,
        catalogWords,
      );
      final rightCoverage = _lexicalCoverage(
        right.originalContent,
        knownWords,
        catalogWords,
      );
      final leftFit = leftCoverage == null
          ? ((left.id / math.max(1, stories.length - 1)) - ability).abs()
          : (leftCoverage - .92).abs();
      final rightFit = rightCoverage == null
          ? ((right.id / math.max(1, stories.length - 1)) - ability).abs()
          : (rightCoverage - .92).abs();
      return leftFit.compareTo(rightFit);
    });
    final story = candidates.firstOrNull ?? stories.firstOrNull;
    if (story == null) return _fallback(PracticeSkill.reading, reason);
    final wordCount = RegExp(
      r"[A-Za-zÀ-ỹ']+",
    ).allMatches(story.originalContent).length;
    return PracticeRecommendation(
      skill: PracticeSkill.reading,
      title: story.originalTitle,
      contextLabel: 'Luyện đọc • Truyện ngắn',
      reason: progressByStoryId[story.id] != null
          ? 'Tiếp tục bài đọc đang dở'
          : reason,
      durationMinutes: math.max(5, (wordCount / 180).ceil()),
      contentId: '${story.id}',
    );
  }

  PracticeRecommendation _fallback(PracticeSkill skill, String reason) {
    final title = switch (skill) {
      PracticeSkill.listening => 'Chọn một bài luyện nghe',
      PracticeSkill.speaking => 'Chọn một bài luyện nói',
      PracticeSkill.grammar => 'Chọn một chủ đề ngữ pháp',
      PracticeSkill.pronunciation => 'Chọn một âm IPA',
      PracticeSkill.reading => 'Chọn một bài đọc',
    };
    return PracticeRecommendation(
      skill: skill,
      title: title,
      contextLabel: _skillLabel(skill),
      reason: reason,
      durationMinutes: 5,
    );
  }

  String _reason({
    required PracticeSkill skill,
    required int weekSessions,
    required double weakness,
  }) {
    if (weakness >= .55) return '${_skillLabel(skill)} đang cần cải thiện';
    final remaining = math.max(0, _skillWeekGoal - weekSessions);
    if (remaining > 0) {
      return 'Còn $remaining phiên để cân bằng mục tiêu tuần';
    }
    return 'Phù hợp với trình độ hiện tại của bạn';
  }

  String _skillLabel(PracticeSkill skill) => switch (skill) {
    PracticeSkill.listening => 'Luyện nghe',
    PracticeSkill.speaking => 'Luyện nói',
    PracticeSkill.grammar => 'Ngữ pháp',
    PracticeSkill.pronunciation => 'IPA & phát âm',
    PracticeSkill.reading => 'Luyện đọc',
  };

  double _ability({
    required String? assessmentLevel,
    required LearningLanguageLevel selectedLevel,
    required int knownWordCount,
    required int totalWordCount,
  }) {
    final selectedPrior = switch (selectedLevel) {
      LearningLanguageLevel.beginner => .2,
      LearningLanguageLevel.intermediate => .5,
      LearningLanguageLevel.advanced => .82,
    };
    final assessmentPrior = assessmentLevel == null
        ? selectedPrior
        : _brightLevelValue(assessmentLevel);
    final vocabularyEvidence = totalWordCount == 0
        ? selectedPrior
        : math.sqrt(knownWordCount / totalWordCount).clamp(0.0, 1.0);
    return (.75 * assessmentPrior + .25 * vocabularyEvidence).clamp(0, 1);
  }

  double _brightLevelValue(String level) {
    const levels = ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
    final index = levels.indexOf(level.toUpperCase());
    return index < 0 ? .2 : index / (levels.length - 1);
  }

  double _levelValue(String level) {
    final normalized = level.toUpperCase().split('-').first;
    return switch (normalized) {
      'A1' => .1,
      'A2' => .28,
      'B1' => .46,
      'B2' => .63,
      'C1' => .8,
      'C2' || 'C3' => .95,
      _ => .3,
    };
  }

  double _grammarLevelValue(String level) => switch (level.toLowerCase()) {
    'beginner' => .1,
    'elementary' => .28,
    'intermediate' => .55,
    'advanced' => .85,
    _ => .3,
  };

  double _listeningWeakness(List<ListeningChallengeProgressRow> rows) {
    if (rows.isEmpty) return .5;
    final attempts = rows.fold<int>(
      0,
      (sum, row) => sum + math.max(1, row.attemptCount),
    );
    final completed = rows.where((row) => row.isCompleted).length;
    return (1 - completed / math.max(1, attempts)).clamp(0.0, 1.0);
  }

  double _speakingWeakness(List<SpeakingSentenceProgressRow> rows) {
    if (rows.isEmpty) return .5;
    final recent = [...rows]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final sample = recent.take(30).toList();
    final averageAccuracy =
        sample.fold<int>(0, (sum, row) => sum + row.accuracyPercent) /
        sample.length;
    return (1 - averageAccuracy / 100).clamp(0.0, 1.0);
  }

  double _grammarWeakness(List<GrammarUserResponseRow> rows) {
    if (rows.isEmpty) return .5;
    final recent = [...rows]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final sample = recent.take(30).toList();
    final correct = sample.where((row) => row.isCorrect).length;
    return (1 - correct / sample.length).clamp(0.0, 1.0);
  }

  double _completionWeakness({required int completed, required int started}) {
    if (started == 0) return .5;
    return (1 - completed / started).clamp(0.0, 1.0);
  }

  double? _lexicalCoverage(
    String content,
    Set<String> knownWords,
    Set<String> catalogWords,
  ) {
    final tokens = RegExp(r"[A-Za-z']+")
        .allMatches(content.toLowerCase())
        .map((match) => match.group(0)!)
        .where(catalogWords.contains)
        .toSet();
    if (tokens.isEmpty) return null;
    return tokens.where(knownWords.contains).length / tokens.length;
  }

  int _maxOrZero(Iterable<int> values) =>
      values.isEmpty ? 0 : values.reduce(math.max);
}
