import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/topic_asset_data_source.dart';
import '../../data/local/app_database.dart';
import '../../data/models/topic.dart';
import '../../data/models/vocabulary_collection.dart';
import '../../data/repositories/topic_repository.dart';
import '../../data/services/daily_card_service.dart';
import '../../data/services/progress_dashboard_service.dart';
import '../../data/services/topic_progress_service.dart';

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

final localDataInitializationProvider = FutureProvider<void>((ref) {
  return ref.watch(topicRepositoryProvider).initialize();
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

final topicSetupStartAtTopicsProvider = StateProvider<bool>((ref) => false);

final selectedTopicOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});

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

final dailyCardServiceProvider = Provider<DailyCardService>((ref) {
  return DailyCardService(ref.watch(appDatabaseProvider));
});

final dailyCardProvider = FutureProvider<DailyCardSnapshot>((ref) async {
  return ref.watch(dailyCardServiceProvider).load();
});

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
