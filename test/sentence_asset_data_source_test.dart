import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/sentence_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads sentence words from the selected language asset', () async {
    final dataSource = SentenceAssetDataSource();

    final germanWordIds = await dataSource.loadWordIds(languageCode: 'de');

    expect(germanWordIds, isNotEmpty);
    expect(germanWordIds, contains(4));
  });

  test('returns no sentence words when the language asset is empty', () async {
    final dataSource = SentenceAssetDataSource();

    final danishWordIds = await dataSource.loadWordIds(languageCode: 'da');

    expect(danishWordIds, isEmpty);
  });
}
