import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';
import 'package:leximon/data/local/app_database.dart';
import 'package:leximon/data/repositories/topic_repository.dart';

import 'remote_content_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reuses the active topic package without a startup request', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final payload = await testTopicDataSource().load(languageCode: 'vi');
    await database.upsertTopicContent(payload, languageCode: 'vi');

    var requestCount = 0;
    final dataSource = TopicAssetDataSource(
      apiClient: ApiClient(
        client: MockClient((request) async {
          requestCount++;
          return http.Response('unexpected startup request', 500);
        }),
      ),
    );
    final repository = TopicRepository(
      database: database,
      assetDataSource: dataSource,
    );

    await repository.initialize(languageCode: 'vi');

    expect(requestCount, 0);
    expect(await repository.loadTopics(languageCode: 'vi'), isNotEmpty);
  });
}
