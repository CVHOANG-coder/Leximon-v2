import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_language_service.dart';
import '../../core/services/auth_token_storage.dart';
import '../../core/services/device_info_service.dart';
import '../../data/datasources/sentence_asset_data_source.dart';
import '../../data/datasources/ipa_asset_data_source.dart';
import '../../data/datasources/listening_asset_data_source.dart';
import '../../data/datasources/reading_asset_data_source.dart';
import '../../data/datasources/grammar_asset_data_source.dart';
import '../../data/datasources/topic_asset_data_source.dart';
import '../../data/local/app_database.dart';
import '../../data/models/grammar_content.dart';
import '../../data/models/ipa_sound.dart';
import '../../data/models/listening_catalog.dart';
import '../../data/models/learning_language_level.dart';
import '../../data/models/reading_story.dart';
import '../../data/models/sentence_exercise.dart';
import '../../data/models/topic.dart';
import '../../data/models/user_profile_response.dart';
import '../../data/models/vocabulary_collection.dart';
import '../../data/repositories/topic_repository.dart';
import '../../data/repositories/grammar_repository.dart';
import '../../data/services/additional_task_service.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/iap_catalog_service.dart';
import '../../data/services/iap_package_api_service.dart';
import '../../data/services/iap_purchase_service.dart';
import '../../data/services/iap_transaction_api_service.dart';
import '../../data/services/challenge_dashboard_service.dart';
import '../../data/services/app_usage_service.dart';
import '../../data/services/daily_card_service.dart';
import '../../data/services/difficult_words_training_service.dart';
import '../../data/services/home_main_task_service.dart';
import '../../data/services/listening_progress_service.dart';
import '../../data/services/speaking_progress_service.dart';
import '../../data/services/ipa_progress_service.dart';
import '../../data/services/grammar_progress_service.dart';
import '../../data/services/reading_progress_service.dart';
import '../../data/services/reading_vocabulary_service.dart';
import '../../data/services/reading_word_translation_service.dart';
import '../../data/services/profile_statistics_service.dart';
import '../../data/services/progress_dashboard_service.dart';
import '../../data/services/sentence_ai_service.dart';
import '../../data/services/sentence_lesson_service.dart';
import '../../data/services/sentence_progress_service.dart';
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

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => AuthTokenStorage(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    tokenLoader: ref.watch(authTokenStorageProvider).loadToken,
  );
  ref.onDispose(client.close);
  return client;
});

final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => DeviceInfoService(),
);

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(
    apiClient: ref.watch(apiClientProvider),
    deviceIdentityProvider: ref.watch(deviceInfoServiceProvider),
    languageService: ref.watch(appLanguageServiceProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );
});

final iapPackageApiServiceProvider = Provider<IapPackageApiService>((ref) {
  return IapPackageApiService(apiClient: ref.watch(apiClientProvider));
});

final iapCatalogServiceProvider = Provider<IapCatalogService>((ref) {
  return IapCatalogService(apiService: ref.watch(iapPackageApiServiceProvider));
});

final iapTransactionApiServiceProvider = Provider<IapTransactionApiService>((
  ref,
) {
  return IapTransactionApiService(ref.watch(apiClientProvider));
});

final iapStoreGatewayProvider = Provider<IapStoreGateway>((ref) {
  return FlutterIapStoreGateway();
});

/// Global Riverpod cache for the platform IAP catalog. Since this provider is
/// not auto-disposed, returning to SubscriptionPlanScreen reuses the result
/// and does not call /iap/packages again during the app session.
final iapCatalogProvider = FutureProvider<IapCatalog>((ref) {
  final platform = defaultTargetPlatform == TargetPlatform.iOS
      ? 'IOS'
      : 'ANDROID';
  return _loadIapCatalog(ref, platform: platform);
});

Future<IapCatalog> _loadIapCatalog(Ref ref, {required String platform}) async {
  // The packages endpoint is authenticated. Constructing this provider also
  // installs the shared 401/403 token-refresh handler on ApiClient.
  await ref.watch(authApiServiceProvider).ensureToken();
  return ref.watch(iapCatalogServiceProvider).load(platform: platform);
}

/// Starts listening to the store purchase queue for the whole app session.
/// This also recovers unfinished transactions delivered after a relaunch.
final iapPurchaseServiceProvider = Provider<IapPurchaseService>((ref) {
  final service = IapPurchaseService(
    ref.watch(iapStoreGatewayProvider),
    ref.watch(iapTransactionApiServiceProvider),
    (productId) async {
      final catalog = await ref.read(iapCatalogProvider.future);
      for (final package in catalog.packages) {
        if (package.productId == productId) return package;
      }
      return null;
    },
    ref.watch(authApiServiceProvider).ensureToken,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Restores the saved authentication session (or logs in) and verifies it by
/// loading the backend profile once per app session.
final remoteUserProfileProvider = FutureProvider<UserProfile>((ref) async {
  final authService = ref.watch(authApiServiceProvider);
  await authService.ensureToken();
  return (await authService.getUserProfile()).data;
});

final authLoginInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(remoteUserProfileProvider.future);
});

/// Stores the app/native language selected during onboarding and drives the
/// live locale of [MaterialApp]. The first-run value comes from the device.
final selectedAppLanguageProvider = StateProvider<String>(
  (ref) => AppLocalizations.deviceLanguageCode(),
);

final supportedLanguagesProvider = FutureProvider((ref) {
  return ref.watch(topicAssetDataSourceProvider).loadAvailableLanguages();
});

final sentenceAssetDataSourceProvider = Provider<SentenceAssetDataSource>(
  (ref) => SentenceAssetDataSource(),
);

final listeningAssetDataSourceProvider = Provider<ListeningAssetDataSource>((
  ref,
) {
  final dataSource = ListeningAssetDataSource(
    languageCode: ref.watch(selectedAppLanguageProvider),
    useRemote: true,
  );
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final listeningProgressServiceProvider = Provider<ListeningProgressService>(
  (ref) => ListeningProgressService(ref.watch(appDatabaseProvider)),
);

final speakingProgressServiceProvider = Provider<SpeakingProgressService>(
  (ref) => SpeakingProgressService(ref.watch(appDatabaseProvider)),
);

final listeningCatalogProvider = FutureProvider<List<ListeningCourseSummary>>(
  (ref) => ref.watch(listeningAssetDataSourceProvider).loadCatalog(),
);

final ipaSoundsProvider = FutureProvider<List<IpaSound>>((ref) {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  return IpaAssetDataSource.load(languageCode: languageCode);
});

final ipaProgressServiceProvider = Provider<IpaProgressService>(
  (ref) => IpaProgressService(ref.watch(appDatabaseProvider)),
);

final readingProgressServiceProvider = Provider<ReadingProgressService>(
  (ref) => ReadingProgressService(ref.watch(appDatabaseProvider)),
);

final readingVocabularyServiceProvider = Provider<ReadingVocabularyService>((
  ref,
) {
  // Rebuild the in-memory lookup when the translated vocabulary changes.
  ref.watch(selectedAppLanguageProvider);
  return ReadingVocabularyService(ref.watch(appDatabaseProvider));
});

final readingVocabularyTaskProvider =
    FutureProvider<ReadingVocabularyTaskSnapshot>((ref) async {
      await ref.watch(localDataInitializationProvider.future);
      return ref.watch(readingVocabularyServiceProvider).loadTask();
    });

final readingWordTranslatorProvider = Provider<ReadingWordTranslator>((ref) {
  return MlKitReadingWordTranslator(
    targetLanguageCode: ref.watch(selectedAppLanguageProvider),
  );
});

/// A present key means the story was opened; a `true` value means it reached
/// the reading completion threshold.
final readingCardProgressProvider = FutureProvider<Map<int, bool>>((ref) async {
  final rows = await ref.watch(readingProgressServiceProvider).loadAll();
  return {
    for (final entry in rows.entries)
      entry.key: entry.value.completedAt != null,
  };
});

final readingAssetDataSourceProvider = Provider<ReadingAssetDataSource>((ref) {
  final source = ReadingAssetDataSource();
  ref.onDispose(source.dispose);
  return source;
});

final readingStoriesProvider = FutureProvider<List<ReadingStory>>((ref) {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  return ref
      .watch(readingAssetDataSourceProvider)
      .load(languageCode: languageCode);
});

final grammarAssetDataSourceProvider = Provider<GrammarAssetDataSource>(
  (ref) => GrammarAssetDataSource(),
);

final grammarRepositoryProvider = Provider<GrammarRepository>(
  (ref) => GrammarRepository(
    database: ref.watch(appDatabaseProvider),
    assetDataSource: ref.watch(grammarAssetDataSourceProvider),
  ),
);

final grammarProgressServiceProvider = Provider<GrammarProgressService>(
  (ref) => GrammarProgressService(ref.watch(appDatabaseProvider)),
);

final grammarPacksProvider = FutureProvider<List<GrammarPackContent>>(
  (ref) => ref.watch(grammarRepositoryProvider).loadPacks(),
);

final grammarTopicQuestionsProvider =
    FutureProvider.family<List<GrammarQuestionContent>, int>(
      (ref, topicId) =>
          ref.watch(grammarRepositoryProvider).loadTopicQuestions(topicId),
    );

final sentenceAssetWordIdsProvider = FutureProvider<Set<int>>((ref) async {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  return ref
      .watch(appDatabaseProvider)
      .sentenceContentWordIds(
        languageCode: TopicAssetDataSource.canonicalizeLanguageCode(
          languageCode,
        ),
      );
});

final localDataInitializationProvider = FutureProvider<void>((ref) {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  return ref
      .watch(topicRepositoryProvider)
      .initialize(languageCode: languageCode);
});

/// Imports both native-language content packages after selection or when the
/// splash detects stale content. The sentence package is persisted locally
/// alongside topics so changing language replaces the previous package.
final languagePackageInitializationProvider = FutureProvider<void>((ref) async {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  final sentencePackage = languageCode == 'en'
      // English has no native-language sentence package. Treat it as an
      // intentionally empty package instead of requesting /sentences/en.json.
      ? Future<List<SentenceRecord>>.value(const <SentenceRecord>[])
      : ref
            .watch(sentenceAssetDataSourceProvider)
            .reload(languageCode: languageCode);
  final results = await Future.wait<Object?>([
    ref.watch(topicRepositoryProvider).reload(languageCode: languageCode),
    sentencePackage,
  ]);
  await ref
      .watch(appDatabaseProvider)
      .replaceSentenceContent(
        languageCode: TopicAssetDataSource.canonicalizeLanguageCode(
          languageCode,
        ),
        sentences: results[1] as List<SentenceRecord>,
      );

  // The profile is normally already loaded by splash. Persisting the
  // metadata here also avoids downloading the same package again after a
  // first-time onboarding selection.
  final profile = ref.read(remoteUserProfileProvider).valueOrNull;
  if (profile != null) {
    await ref
        .read(appLanguageServiceProvider)
        .saveContentSyncMetadata(
          languageCode: TopicAssetDataSource.canonicalizeLanguageCode(
            languageCode,
          ),
          databaseVersion: profile.databaseVersion,
        );
  }
});

final userProfileProvider = FutureProvider<UserProfileRow?>((ref) async {
  await ref.watch(localDataInitializationProvider.future);
  return ref.watch(appDatabaseProvider).loadUserProfile();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  await ref.watch(localDataInitializationProvider.future);
  return ref
      .watch(topicRepositoryProvider)
      .loadTopics(languageCode: languageCode);
});

/// Onboarding only needs the bundled topic catalogue. Keeping this separate
/// from [topicsProvider] lets the selection page render before the native
/// database has been opened.
final onboardingTopicsProvider = FutureProvider<List<Topic>>((ref) async {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  final payload = await ref
      .watch(topicAssetDataSourceProvider)
      .load(languageCode: languageCode);
  return payload.topics
      .where((topic) => topic.isEnabled)
      .map(
        (topic) => Topic(
          id: topic.id,
          order: topic.order,
          original: topic.original ?? '',
          translated: topic.translated ?? '',
          words: const <Map<String, dynamic>>[],
        ),
      )
      .toList(growable: false);
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

final selectedTopicFilterProvider = StateProvider<String>(
  (ref) => 'topicFilterAll',
);

final topicSetupOpenProvider = StateProvider<bool>((ref) => false);

final topicSetupStartAtTopicsProvider = StateProvider<bool>((ref) => true);

final selectedTopicOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});

final selectedLanguageLevelsProvider =
    StateProvider<Set<LearningLanguageLevel>>(
      (ref) => {LearningLanguageLevel.beginner},
    );

final vocabularyAssessmentLevelProvider = FutureProvider<String?>((ref) {
  return ref.watch(appLanguageServiceProvider).loadVocabularyAssessmentLevel();
});

final challengeDashboardServiceProvider = Provider<ChallengeDashboardService>(
  (ref) => ChallengeDashboardService(
    ref.watch(appDatabaseProvider),
    localizations: AppLocalizations(
      AppLocalizations.localeForCode(ref.watch(selectedAppLanguageProvider)),
    ),
  ),
);

final challengeDashboardProvider = FutureProvider<ChallengeDashboardSnapshot>((
  ref,
) async {
  await ref.watch(localDataInitializationProvider.future);
  final inputs = await Future.wait<Object?>([
    ref.watch(listeningCatalogProvider.future),
    ref.watch(grammarPacksProvider.future),
    ref.watch(ipaSoundsProvider.future),
    ref.watch(readingStoriesProvider.future),
    ref.watch(vocabularyAssessmentLevelProvider.future),
  ]);
  final selectedLevels = ref.watch(selectedLanguageLevelsProvider);
  final selectedLevel = selectedLevels.isEmpty
      ? LearningLanguageLevel.beginner
      : selectedLevels.first;
  return ref
      .watch(challengeDashboardServiceProvider)
      .load(
        listeningCourses: inputs[0] as List<ListeningCourseSummary>,
        grammarPacks: inputs[1] as List<GrammarPackContent>,
        ipaSounds: inputs[2] as List<IpaSound>,
        readingStories: inputs[3] as List<ReadingStory>,
        assessmentLevel: inputs[4] as String?,
        selectedLevel: selectedLevel,
      );
});

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

enum AppStartupDestination {
  languageOnboarding,
  assessmentIntro,
  freeTrialOffer,
  subscriptionPlan,
  home,
}

/// Completes once everything required before leaving the splash screen is
/// ready, then tells the router whether first-run onboarding is still needed.
final applicationInitializationProvider = FutureProvider<AppStartupDestination>(
  (ref) async {
    final savedLanguage = await ref
        .watch(appLanguageServiceProvider)
        .loadSelectedLanguage();
    final selectedLanguage = savedLanguage == null
        ? null
        : TopicAssetDataSource.canonicalizeLanguageCode(savedLanguage);
    if (selectedLanguage != null) {
      ref.read(selectedAppLanguageProvider.notifier).state = selectedLanguage;
    }

    // Authentication must finish successfully while the splash screen is
    // still visible. This restores a saved token when possible, logs in when
    // needed, and always verifies the resulting session with the profile API.
    await ref.watch(authLoginInitializationProvider.future);

    if (selectedLanguage == null) {
      return AppStartupDestination.languageOnboarding;
    }

    // Authentication initialization guarantees that the profile has been
    // loaded. Keep the profile as the source of truth for the app gate so a
    // stale local onboarding flag can never grant access to a non-premium
    // user.
    final profile = await ref.watch(remoteUserProfileProvider.future);
    // Content updates are a premium-only capability. Non-premium users keep
    // their current local catalogue and skip the version/language check.
    if (profile.isPremium) {
      final languageService = ref.read(appLanguageServiceProvider);
      final synchronizedLanguage = await languageService.loadNativeLanguage();
      final synchronizedDatabaseVersion = await languageService
          .loadDatabaseVersion();
      final languageChanged =
          TopicAssetDataSource.canonicalizeLanguageCode(
            synchronizedLanguage ?? '',
          ) !=
          selectedLanguage;
      final databaseVersionMissing = synchronizedDatabaseVersion == null;
      final databaseVersionOutdated =
          synchronizedDatabaseVersion != null &&
          synchronizedDatabaseVersion < profile.databaseVersion;

      if (languageChanged ||
          databaseVersionMissing ||
          databaseVersionOutdated) {
        await ref.watch(languagePackageInitializationProvider.future);
      }
      await languageService.saveContentSyncMetadata(
        languageCode: selectedLanguage,
        databaseVersion: profile.databaseVersion,
      );
    }

    await ref.watch(localDataInitializationProvider.future);
    await ref.watch(selectedTopicOrdersHydrationProvider.future);
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
    if (onboardingCompleted) {
      return profile.isPremium
          ? AppStartupDestination.home
          : AppStartupDestination.subscriptionPlan;
    }

    final carouselCompleted = await ref
        .watch(appLanguageServiceProvider)
        .isCarouselCompleted();
    return carouselCompleted
        ? AppStartupDestination.freeTrialOffer
        : AppStartupDestination.languageOnboarding;
  },
);

final sentenceLessonServiceProvider = Provider<SentenceLessonService>((ref) {
  return SentenceLessonService(
    database: ref.watch(appDatabaseProvider),
    assetDataSource: ref.watch(sentenceAssetDataSourceProvider),
    languageCode: ref.watch(selectedAppLanguageProvider),
  );
});

final sentenceProgressServiceProvider = Provider<SentenceProgressService>((
  ref,
) {
  return SentenceProgressService(ref.watch(appDatabaseProvider));
});

final sentenceAiServiceProvider = Provider<SentenceAiService>((ref) {
  return const SentenceAiService();
});

final dailyCardServiceProvider = Provider<DailyCardService>((ref) {
  final languageCode = ref.watch(selectedAppLanguageProvider);
  return DailyCardService(
    ref.watch(appDatabaseProvider),
    wordsPerDay: ref.watch(dailyWordsPerDayProvider),
    sentenceFeatureEnabled: true,
    sentenceLanguageCode: languageCode,
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
  return ProgressDashboardService(
    ref.watch(appDatabaseProvider),
    localizations: AppLocalizations(
      AppLocalizations.localeForCode(ref.watch(selectedAppLanguageProvider)),
    ),
  );
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
