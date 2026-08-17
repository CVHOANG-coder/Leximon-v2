import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:leximon/core/localization/app_localizations.dart';

void main() {
  test('provides the five supported interface locales', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['en', 'fr', 'vi', 'ru', 'de']),
    );
    expect(
      AppLocalizations.supportedLanguageOptions.map((option) => option.code),
      containsAll(<String>[
        'ar',
        'cs',
        'da',
        'es-ES',
        'es-US',
        'fi',
        'fil',
        'hi',
        'hu',
        'in',
        'it',
        'iw',
        'ja',
        'ko',
        'ms',
        'nb',
        'nl',
        'pl',
        'pt',
        'ro',
        'sv',
        'th',
        'tr',
        'uk',
        'zh-TW',
        'zh',
      ]),
    );
  });

  test('loads translated navigation and language labels', () {
    final expected = <String, List<String>>{
      'en': ['Learn', 'English'],
      'fr': ['Apprendre', 'Français'],
      'vi': ['Học tập', 'Tiếng Việt'],
      'ru': ['Учёба', 'Русский'],
      'de': ['Lernen', 'Deutsch'],
    };

    for (final entry in expected.entries) {
      final localizations = AppLocalizations(
        AppLocalizations.localeForCode(entry.key),
      );
      expect(localizations.navStudy, entry.value.first);
    }
  });

  test('falls back safely for unsupported locale codes', () {
    expect(AppLocalizations.localeForCode('xx'), const Locale('en'));
    expect(AppLocalizations.localeForCode('ja'), const Locale('ja'));
    expect(AppLocalizations.localeForCode('es'), const Locale('es', 'ES'));
    expect(AppLocalizations.localeForCode('es-ES'), const Locale('es', 'ES'));
    expect(AppLocalizations.localeForCode('es-US'), const Locale('es', 'US'));
    expect(AppLocalizations.localeForCode('es-MX'), const Locale('es', 'US'));
    expect(AppLocalizations.localeForCode('es-419'), const Locale('es', 'US'));
  });

  test('uses separate Spanish catalogs and defaults generic es to es-ES', () {
    expect(AppLocalizations.languageCodeForLocale(const Locale('es')), 'es-ES');
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('es', 'ES')),
      'es-ES',
    );
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('es', 'US')),
      'es-US',
    );
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('es', 'MX')),
      'es-US',
    );

    final spain = AppLocalizations(AppLocalizations.localeForCode('es-ES'));
    final latinAmerica = AppLocalizations(
      AppLocalizations.localeForCode('es-US'),
    );
    expect(spain.openSettings, 'Abrir ajustes');
    expect(latinAmerica.openSettings, 'Abrir configuración');
  });

  test('uses separate Chinese catalogs and defaults generic zh to zh', () {
    expect(AppLocalizations.languageCodeForLocale(const Locale('zh')), 'zh');
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('zh', 'CN')),
      'zh',
    );
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('zh', 'TW')),
      'zh-TW',
    );
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('zh', 'HK')),
      'zh-TW',
    );
    expect(
      AppLocalizations.languageCodeForLocale(const Locale('zh', 'MO')),
      'zh-TW',
    );

    expect(AppLocalizations.localeForCode('zh'), const Locale('zh'));
    expect(AppLocalizations.localeForCode('zh-CN'), const Locale('zh'));
    expect(AppLocalizations.localeForCode('zh-TW'), const Locale('zh', 'TW'));
    expect(AppLocalizations.localeForCode('zh-HK'), const Locale('zh', 'TW'));

    final simplified = AppLocalizations(AppLocalizations.localeForCode('zh'));
    final traditional = AppLocalizations(
      AppLocalizations.localeForCode('zh-TW'),
    );
    expect(simplified.openSettings, '打开设置');
    expect(traditional.openSettings, '開啟設定');
  });

  test('device locale fallback is always an available language code', () {
    expect(
      AppLocalizations.supportedLanguageOptions.map((option) => option.code),
      contains(AppLocalizations.deviceLanguageCode()),
    );
  });

  test('resolves the newly added English keys and placeholders', () {
    final english = AppLocalizations(AppLocalizations.localeForCode('en'));

    expect(
      english.text('difficultResultRemaining', values: {'count': 3}),
      '3 words still need more practice',
    );
    expect(
      english.text(
        'speakingRecognitionError',
        values: {'message': 'Not available'},
      ),
      'Speech recognition error: Not available',
    );
    expect(english.text('repetitionNotCorrect'), 'Not quite');
    expect(
      english.text('challengeSessionsRemaining', values: {'count': 3}),
      '3 sessions left to stay on track with your weekly goal',
    );
    expect(english.text('reviewEndAction'), 'End review');
    expect(
      english.text('sentenceCompleteTitle'),
      'Sentence-building session complete!',
    );

    for (final code in ['de', 'fr', 'ru', 'vi', 'ja', 'zh-TW']) {
      final localizations = AppLocalizations(
        AppLocalizations.localeForCode(code),
      );
      expect(
        localizations.text('reviewEndAction'),
        code == 'vi' ? 'Kết thúc ôn tập' : 'End review',
      );
    }
  });
}
