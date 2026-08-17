import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/topic_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads English topics without a dedicated English asset', () async {
    final payload = await TopicAssetDataSource().load(languageCode: 'en');

    expect(payload.topics, isNotEmpty);
    final topic = payload.topics.first;
    expect(topic.translated, topic.original);
    expect(topic.words, isNotEmpty);
    expect(topic.words.first.translation, topic.words.first.writing);
  });
}
