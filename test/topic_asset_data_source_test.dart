import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads English topics without a dedicated English asset', () async {
    final dataSource = TopicAssetDataSource(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/data/topics/data_en_vi.json');
          return http.Response(
            '{"version":1,"topics":[{"id":1,"order":1,"original":"Travel","translated":"Du lich","enabled":true,"words":[{"id":2,"writing":"travel","translation":"du lich","enabled":true}]}]}',
            200,
          );
        }),
      ),
    );
    final payload = await dataSource.load(languageCode: 'en');

    expect(payload.topics, isNotEmpty);
    final topic = payload.topics.first;
    expect(topic.translated, topic.original);
    expect(topic.words, isNotEmpty);
    expect(topic.words.first.translation, topic.words.first.writing);
  });
}
