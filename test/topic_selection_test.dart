import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/topic_repository.dart';
import 'package:leximon/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late TopicRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TopicRepository(
      database: database,
      assetDataSource: TopicAssetDataSource(),
    );
  });

  tearDown(() => database.close());

  test(
    'persists selected learning-filter topics for Home to restore',
    () async {
      await repository.loadTopics();
      await repository.saveSelectedTopicOrders({2, 5, 8});

      expect(await repository.selectedTopicOrders(), {2, 5, 8});
    },
  );

  test('onboarding uses the complete enabled topic catalogue', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final topics = await container.read(onboardingTopicsProvider.future);

    expect(topics, hasLength(47));
    expect(topics.first.translated, 'Du lịch');
    expect(topics.last.order, 71);
    expect(topics.map((topic) => topic.order).toSet(), hasLength(47));
  });

  test('language choices match the topic asset files', () async {
    final languages = await TopicAssetDataSource().loadAvailableLanguages();

    expect(languages, hasLength(30));
    expect(languages.map((language) => language.code), contains('es-US'));
    expect(languages.map((language) => language.code), contains('zh-TW'));
    expect(
      languages.map((language) => language.code),
      isNot(contains('es-419')),
    );
  });
}
