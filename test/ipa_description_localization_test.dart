import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/data/datasources/ipa_asset_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps every IPA sound to a localized description', () async {
    for (final languageCode in ['en', 'es', 'fr', 'pt', 'ru']) {
      final sounds = await IpaAssetDataSource.load(languageCode: languageCode);

      expect(sounds, hasLength(43));
      expect(
        sounds.every((sound) => sound.description.isNotEmpty),
        isTrue,
        reason: 'Missing $languageCode description',
      );
    }
  });

  test('normalizes regional locales and falls back to English', () async {
    final spanish = await IpaAssetDataSource.load(languageCode: 'es-MX');
    final fallback = await IpaAssetDataSource.load(languageCode: 'vi');

    expect(spanish.first.description, startsWith("El 'sonido ow'"));
    expect(fallback.first.description, startsWith("The 'ow sound'"));
  });
}
