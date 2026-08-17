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
    expect(AppLocalizations.localeForCode('es-ES'), const Locale('es', 'ES'));
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
