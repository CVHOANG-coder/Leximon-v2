import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class ReadingWordTranslator {
  Future<String> translateWord(String word);
}

typedef OnDeviceTranslatorFactory =
    OnDeviceTranslator Function({
      required TranslateLanguage sourceLanguage,
      required TranslateLanguage targetLanguage,
    });

/// On-device English translation used only when Reading has no dictionary row.
class MlKitReadingWordTranslator implements ReadingWordTranslator {
  MlKitReadingWordTranslator({
    required String targetLanguageCode,
    OnDeviceTranslatorModelManager? modelManager,
    OnDeviceTranslatorFactory? translatorFactory,
  }) : _targetLanguage = translateLanguageForAppCode(targetLanguageCode),
       _modelManager = modelManager ?? OnDeviceTranslatorModelManager(),
       _translatorFactory = translatorFactory ?? _createTranslator;

  final TranslateLanguage? _targetLanguage;
  final OnDeviceTranslatorModelManager _modelManager;
  final OnDeviceTranslatorFactory _translatorFactory;
  Future<void>? _modelsReady;

  @override
  Future<String> translateWord(String word) async {
    final text = word.trim();
    if (text.isEmpty) return '';
    final targetLanguage = _targetLanguage;
    if (targetLanguage == null) {
      throw UnsupportedError('ML Kit does not support this app language.');
    }
    if (targetLanguage == TranslateLanguage.english) return text;

    final modelsReady = _modelsReady ??= _downloadRequiredModels(
      targetLanguage,
    );
    try {
      await modelsReady;
    } on Object {
      if (identical(_modelsReady, modelsReady)) _modelsReady = null;
      rethrow;
    }

    // A translator owns native ML Kit resources. Keep it alive for only one
    // request so Reading never retains the model engine after the sheet closes.
    final translator = _translatorFactory(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLanguage,
    );
    try {
      return await translator.translateText(text);
    } finally {
      await translator.close();
    }
  }

  Future<void> _downloadRequiredModels(TranslateLanguage targetLanguage) async {
    for (final language in [TranslateLanguage.english, targetLanguage]) {
      final code = language.bcpCode;
      if (await _modelManager.isModelDownloaded(code)) continue;
      final downloaded = await _modelManager.downloadModel(
        code,
        isWifiRequired: false,
      );
      if (!downloaded) {
        throw StateError('Could not download the ML Kit $code model.');
      }
    }
  }

  static OnDeviceTranslator _createTranslator({
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
  }) => OnDeviceTranslator(
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );
}

TranslateLanguage? translateLanguageForAppCode(String appLanguageCode) {
  final mlKitCode = switch (appLanguageCode) {
    'es-ES' || 'es-US' || 'es-419' => 'es',
    'fil' => 'tl',
    'in' => 'id',
    'iw' => 'he',
    'nb' => 'no',
    'zh-TW' => 'zh',
    _ => appLanguageCode,
  };
  for (final language in TranslateLanguage.values) {
    if (language.bcpCode == mlKitCode) return language;
  }
  return null;
}
