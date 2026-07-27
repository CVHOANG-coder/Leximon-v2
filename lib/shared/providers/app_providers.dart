import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';

final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => const TopicRepository(),
);

final topicsProvider = FutureProvider<List<Topic>>((ref) {
  return ref.read(topicRepositoryProvider).loadTopics();
});

final selectedTopicFilterProvider = StateProvider<String>((ref) => 'Tất cả');

final topicSetupOpenProvider = StateProvider<bool>((ref) => false);

final selectedTopicOrdersProvider = StateProvider<Set<int>>((ref) => <int>{});
