import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_language_service.dart';
import '../../data/datasources/topic_asset_data_source.dart';
import '../../data/local/app_database.dart';
import '../../data/models/learning_language_level.dart';
import '../../data/models/topic.dart';
import '../../data/models/vocabulary_collection.dart';
import '../../data/repositories/topic_repository.dart';
import '../../data/services/additional_task_service.dart';
import '../../data/services/app_usage_service.dart';
import '../../data/services/daily_card_service.dart';
import '../../data/services/difficult_words_training_service.dart';
import '../../data/services/home_main_task_service.dart';
import '../../data/services/profile_statistics_service.dart';
import '../../data/services/progress_dashboard_service.dart';
import '../../data/services/topic_progress_service.dart';
import '../../data/services/topic_repetition_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final topicAssetDataSourceProvider = Provider<TopicAssetDataSource>(
  (ref) => TopicAssetDataSource(),
);

final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => TopicRepository(
    database: ref.watch(appDatabaseProvider),
    assetDataSource: ref.watch(topicAssetDataSourceProvider),
  ),
);

final appUsageServiceProvider = Provider<AppUsageService>((ref) {
  final service = AppUsageService(ref.watch(appDatabaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

final appLanguageServiceProvider = Provider<AppLanguageService>(
  (ref) => AppLanguageService(),
);

final selectedAppLanguageProvider = StateProvider<String>((ref) => 'vi');

final localDataInitializationProvider = FutureProvider<void>((ref) {
  return ref.watch(topicRepositoryProvider).initialize();
});

final userProfileProvider = FutureProvider<UserProfileRow?>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  return ref.watch(appDatabaseProvider).loadUserProfile();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  return ref.watch(topicRepositoryProvider).loadTopics();
});

/// Progress is kept separately from topic content so screens can refresh the
/// card state without reloading the bundled vocabulary payload.
final wordProgressProvider = FutureProvider<Map<int, LearningProgressRow>>((
  ref,
) async {
  await ref.watch(localDataInitializationProvider.future);
  final database = ref.watch(appDatabaseProvider);
  final rows = await database.select(database.learningProgressModels).get();
  return {for (final row in rows) row.id: row};
});

final selectedTopicFilterProvider = StateProvider<String>((ref) => 'Tất cả');

final topicSetupOpenProvider = StateProvider<bool>((ref) => false);

final topicSetupStartAtTopicsProvider = StateProvider<bool>((ref) => true);

final selectedTopicOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});

final selectedLanguageLevelsProvider =
    StateProvider<Set<LearningLanguageLevel>>(
      (ref) => {LearningLanguageLevel.beginner},
    );

final dailyWordsPerDayProvider = StateProvider<int>(
  (ref) => DailyCardService.defaultLearnWordsGoal,
);

final selectedTopicOrdersHydrationProvider = FutureProvider<void>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  final selectedOrders = await ref
      .watch(topicRepositoryProvider)
      .selectedTopicOrders();
  if (ref.read(selectedTopicOrdersProvider).isEmpty) {
    ref.read(selectedTopicOrdersProvider.notifier).state =
        selectedOrders.isEmpty ? {1, 2, 3} : selectedOrders;
  }
});

enum AppStartupDestination { languageOnboarding, assessmentIntro, home }

/// Completes once everything required before leaving the splash screen is
/// ready, then tells the router whether first-run onboarding is still needed.
final applicationInitializationProvider = FutureProvider<AppStartupDestination>(
  (ref) async {
    await ref.watch(localDataInitializationProvider.future);
    await ref.watch(selectedTopicOrdersHydrationProvider.future);
    final savedLanguage = await ref
        .watch(appLanguageServiceProvider)
        .loadSelectedLanguage();
    if (savedLanguage == null) {
      return AppStartupDestination.languageOnboarding;
    }
    ref.read(selectedAppLanguageProvider.notifier).state = savedLanguage;
    final savedLevel = await ref
        .watch(appLanguageServiceProvider)
        .loadSelectedLearningLevel();
    if (savedLevel != null) {
      ref.read(selectedLanguageLevelsProvider.notifier).state = {
        LearningLanguageLevel.fromLabel(savedLevel),
      };
    }
    final onboardingCompleted = await ref
        .watch(appLanguageServiceProvider)
        .isOnboardingCompleted();
    return onboardingCompleted
        ? AppStartupDestination.home
        : AppStartupDestination.assessmentIntro;
  },
);

final dailyCardServiceProvider = Provider<DailyCardService>((ref) {
  return DailyCardService(
    ref.watch(appDatabaseProvider),
    wordsPerDay: ref.watch(dailyWordsPerDayProvider),
  );
});

final homeMainTaskServiceProvider = Provider<HomeMainTaskService>((ref) {
  return HomeMainTaskService(ref.watch(appDatabaseProvider));
});

final dailyCardProvider = FutureProvider<DailyCardSnapshot>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  final currentLocalTime = DateTime.now();
  final rolloverTimer = Timer(
    nextLocalMidnight(currentLocalTime).difference(currentLocalTime),
    ref.invalidateSelf,
  );
  ref.onDispose(rolloverTimer.cancel);

  return ref.watch(dailyCardServiceProvider).load(now: currentLocalTime);
});

final additionalTaskServiceProvider = Provider<AdditionalTaskService>((ref) {
  return AdditionalTaskService(
    database: ref.watch(appDatabaseProvider),
    dailyCardService: ref.watch(dailyCardServiceProvider),
  );
});

final difficultWordsTrainingServiceProvider =
    Provider<DifficultWordsTrainingService>((ref) {
      return DifficultWordsTrainingService(ref.watch(appDatabaseProvider));
    });

DateTime nextLocalMidnight(DateTime currentLocalTime) => DateTime(
  currentLocalTime.year,
  currentLocalTime.month,
  currentLocalTime.day + 1,
);

final topicProgressServiceProvider = Provider<TopicProgressService>((ref) {
  return TopicProgressService(ref.watch(appDatabaseProvider));
});

final topicProgressProvider = FutureProvider<Map<int, double>>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  return ref.watch(topicProgressServiceProvider).load();
});

final topicProgressDetailsProvider = FutureProvider.family
    .autoDispose<TopicProgressDetails, int>((ref, topicId) async {
      await ref.watch(localDataInitializationProvider.future);
      return ref.watch(topicProgressServiceProvider).loadDetails(topicId);
    });

final topicRepetitionServiceProvider = Provider<TopicRepetitionService>((ref) {
  return TopicRepetitionService(ref.watch(appDatabaseProvider));
});

final topicRepetitionDataProvider = FutureProvider.family
    .autoDispose<TopicRepetitionData, int>((ref, topicId) async {
      await ref.watch(localDataInitializationProvider.future);
      return ref.watch(topicRepetitionServiceProvider).load(topicId);
    });

final progressDashboardServiceProvider = Provider<ProgressDashboardService>((
  ref,
) {
  return ProgressDashboardService(ref.watch(appDatabaseProvider));
});

final progressDashboardProvider = FutureProvider<ProgressDashboardSnapshot>((
  ref,
) async {
  await ref.watch(localDataInitializationProvider.future);
  return ref.watch(progressDashboardServiceProvider).load();
});

final profileStatisticsServiceProvider = Provider<ProfileStatisticsService>((
  ref,
) {
  return ProfileStatisticsService(ref.watch(appDatabaseProvider));
});

final profileStatisticsProvider = FutureProvider<ProfileStatisticsSnapshot>((
  ref,
) async {
  await ref.watch(localDataInitializationProvider.future);
  await ref.watch(selectedTopicOrdersHydrationProvider.future);
  final trackedTopicCount = ref.watch(selectedTopicOrdersProvider).length;
  await ref.watch(appUsageServiceProvider).checkpoint();
  return ref
      .watch(profileStatisticsServiceProvider)
      .load(trackedTopicCount: trackedTopicCount);
});

final vocabularyCollectionProvider =
    FutureProvider<VocabularyCollectionSnapshot>((ref) async {
      await ref.watch(localDataInitializationProvider.future);
      final topics = await ref.watch(topicsProvider.future);
      final words = await ref.watch(appDatabaseProvider).enabledWords();
      final progressRows = await ref
          .watch(appDatabaseProvider)
          .select(ref.watch(appDatabaseProvider).learningProgressModels)
          .get();
      final progressByWordId = {for (final row in progressRows) row.id: row};
      final topicById = {for (final topic in topics) topic.id: topic};
      final entries = <VocabularyCollectionEntry>[];

      for (final word in words) {
        final progress = progressByWordId[word.id];
        final topic = topicById[word.topicId];
        if (progress == null || topic == null || progress.deletedByUser) {
          continue;
        }

        final status = _vocabularyStatusFor(progress);
        if (status == null) continue;
        entries.add(
          VocabularyCollectionEntry(
            word: word,
            topic: topic,
            progress: progress,
            status: status,
          ),
        );
      }

      return VocabularyCollectionSnapshot(
        entries: entries,
        totalWordCount: words.length,
      );
    });

VocabularyCollectionStatus? _vocabularyStatusFor(LearningProgressRow progress) {
  if (progress.markedAsKnown) {
    return VocabularyCollectionStatus.mastered;
  }
  if (progress.trainingError > 0) {
    return VocabularyCollectionStatus.needsPractice;
  }
  if (progress.learnedDate != null ||
      progress.repetitionStep > 0 ||
      progress.trainingProgress > 0) {
    return VocabularyCollectionStatus.reviewing;
  }
  return null;
}
