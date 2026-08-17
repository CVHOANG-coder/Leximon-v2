import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/services/just_audio_asset_path.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preserves percent-encoded text in literal IPA asset filenames', () {
    const assetKey =
        'assets/data/ipa/result/vowelSounds/aʊ/practice/'
        'Middle Sound/flour%2fflower.mp3';

    final encodedPath = justAudioAssetPath(assetKey);

    expect(encodedPath, contains('flour%252fflower.mp3'));
    expect(Uri.parse(encodedPath).pathSegments.join('/'), assetKey);
  });

  test('preserves spaces, unicode, apostrophes, and repeated escapes', () {
    const assetKeys = [
      'assets/data/ipa/result/vowelSounds/aʊ/practice/Beginning sound/'
          'hour%2four.mp3',
      'assets/data/ipa/result/consonantSounds/ð/practice/Beginning sound/'
          "their%2fthere%2fthey're.mp3",
      'assets/data/ipa/result/vowelSounds/ɑɪ/practice/Beginning sound/'
          'eye%2fI.mp3',
    ];

    for (final assetKey in assetKeys) {
      final encodedPath = justAudioAssetPath(assetKey);
      expect(Uri.parse(encodedPath).pathSegments.join('/'), assetKey);
    }
  });
}
