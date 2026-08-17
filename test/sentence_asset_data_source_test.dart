import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leximon/core/network/api_client.dart';
import 'package:leximon/data/datasources/sentence_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads sentence words from the selected language asset', () async {
    final dataSource = SentenceAssetDataSource(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/data/sentences/de.json');
          return http.Response(
            '[{"id":1,"word_id":4,"sentence_id":2,"spelling":"Guten Tag","translation":"Hallo","wrong_spellings":[],"task_spellings":[],"alternative_translations":[],"difficulty":1,"task":"","sound":""}]',
            200,
          );
        }),
      ),
    );

    final germanWordIds = await dataSource.loadWordIds(languageCode: 'de');

    expect(germanWordIds, isNotEmpty);
    expect(germanWordIds, contains(4));
  });

  test('returns no sentence words when the language asset is empty', () async {
    final dataSource = SentenceAssetDataSource(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/data/sentences/da.json');
          return http.Response('[]', 200);
        }),
      ),
    );

    final danishWordIds = await dataSource.loadWordIds(languageCode: 'da');

    expect(danishWordIds, isEmpty);
  });

  test('skips the English sentence package', () async {
    var requested = false;
    final dataSource = SentenceAssetDataSource(
      apiClient: ApiClient(
        client: MockClient((request) async {
          requested = true;
          return http.Response('[]', 200);
        }),
      ),
    );

    expect(await dataSource.load(languageCode: 'en'), isEmpty);
    expect(requested, isFalse);
  });
}
