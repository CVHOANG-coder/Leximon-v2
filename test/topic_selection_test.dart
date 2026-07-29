import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/topic_repository.dart';

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

  test('persists selected onboarding topics for Home to restore', () async {
    await repository.loadTopics();
    await repository.saveSelectedTopicOrders({2, 5, 8});

    expect(await repository.selectedTopicOrders(), {2, 5, 8});
  });
}
