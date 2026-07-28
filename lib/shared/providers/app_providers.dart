import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/topic_asset_data_source.dart';
import '../../data/local/app_database.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';

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

final selectedTopicFilterProvider = StateProvider<String>((ref) => 'Tất cả');

final topicSetupOpenProvider = StateProvider<bool>((ref) => false);

final selectedTopicOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});
