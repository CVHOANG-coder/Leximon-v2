import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/grammar_asset_data_source.dart';

void main() {
  test('resolves grammar media filenames to the server endpoint', () {
    expect(
      GrammarAssetDataSource.mediaUrl('door.mp3'),
      'https://leximonenglish.giddychat.com/data/grammar/allpack/door.mp3',
    );
    expect(
      GrammarAssetDataSource.mediaUrl('picture with space.jpg'),
      'https://leximonenglish.giddychat.com/data/grammar/allpack/picture%20with%20space.jpg',
    );
  });

  test('does not rewrite an already absolute media URL', () {
    const url = 'https://cdn.example.com/grammar/door.mp3';
    expect(GrammarAssetDataSource.mediaUrl(url), url);
  });
}
