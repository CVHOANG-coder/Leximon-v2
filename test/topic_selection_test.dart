import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
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
      assetDataSource: TopicAssetDataSource(bundle: rootBundle),
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
    final container = ProviderContainer(
      overrides: [
        topicAssetDataSourceProvider.overrideWithValue(
          TopicAssetDataSource(bundle: rootBundle),
        ),
        selectedAppLanguageProvider.overrideWith((ref) => 'vi'),
      ],
    );
    addTearDown(container.dispose);

    final topics = await container.read(onboardingTopicsProvider.future);

    expect(topics, hasLength(47));
    expect(topics.first.translated, 'Du lịch');
    expect(topics.last.order, 71);
    expect(topics.map((topic) => topic.order).toSet(), hasLength(47));
  });

  test('language choices match the topic asset files', () async {
    final languages = await TopicAssetDataSource(
      bundle: rootBundle,
    ).loadAvailableLanguages();

    expect(languages, hasLength(30));
    expect(
      languages.map((language) => language.code),
      containsAll(<String>['es-ES', 'es-US']),
    );
    expect(
      languages
          .where((language) => language.code.startsWith('es-'))
          .map((language) => language.label)
          .toSet(),
      {'Español (España)', 'Español (Latinoamérica)'},
    );
    expect(
      languages.map((language) => language.code),
      containsAll(<String>['zh', 'zh-TW']),
    );
    expect(
      languages
          .where((language) => language.code.startsWith('zh'))
          .map((language) => language.label)
          .toSet(),
      {'简体中文', '繁體中文'},
    );
    expect(
      languages.map((language) => language.code),
      isNot(contains('es-419')),
    );
  });
}
