import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class ReadingWordTranslator {
  Future<String> translateWord(String word);
}

enum LanguageModelDownloadPhase { checking, downloading, complete }

class LanguageModelDownloadProgress {
  const LanguageModelDownloadProgress({
    required this.phase,
    required this.progress,
    required this.completedModels,
    required this.totalModels,
    this.languageCode,
  });

  final LanguageModelDownloadPhase phase;
  final double progress;
  final int completedModels;
  final int totalModels;
  final String? languageCode;
}

typedef LanguageModelProgressCallback =
    void Function(LanguageModelDownloadProgress progress);

abstract class LanguageModelDownloader {
  Future<void> downloadRequiredModels({
    required String targetLanguageCode,
    LanguageModelProgressCallback? onProgress,
  });
}

/// Makes the English and selected-language ML Kit models available offline.
///
/// ML Kit exposes completion for each model download, but not transferred
/// bytes. Progress therefore represents completed model steps rather than an
/// estimated network byte percentage.
class MlKitLanguageModelDownloader implements LanguageModelDownloader {
  MlKitLanguageModelDownloader({OnDeviceTranslatorModelManager? modelManager})
    : _modelManager = modelManager ?? OnDeviceTranslatorModelManager();

  final OnDeviceTranslatorModelManager _modelManager;

  @override
  Future<void> downloadRequiredModels({
    required String targetLanguageCode,
    LanguageModelProgressCallback? onProgress,
  }) async {
    final targetLanguage = translateLanguageForAppCode(targetLanguageCode);
    if (targetLanguage == null) {
      throw UnsupportedError('ML Kit does not support this app language.');
    }

    if (targetLanguage == TranslateLanguage.english) {
      onProgress?.call(
        const LanguageModelDownloadProgress(
          phase: LanguageModelDownloadPhase.complete,
          progress: 1,
          completedModels: 0,
          totalModels: 0,
          languageCode: 'en',
        ),
      );
      return;
    }

    final languages = [TranslateLanguage.english, targetLanguage];
    var completedModels = 0;
    for (var index = 0; index < languages.length; index++) {
      final code = languages[index].bcpCode;
      onProgress?.call(
        LanguageModelDownloadProgress(
          phase: LanguageModelDownloadPhase.checking,
          progress: completedModels / languages.length,
          completedModels: completedModels,
          totalModels: languages.length,
          languageCode: code,
        ),
      );
      final isDownloaded = await _modelManager.isModelDownloaded(code);
      if (!isDownloaded) {
        onProgress?.call(
          LanguageModelDownloadProgress(
            phase: LanguageModelDownloadPhase.downloading,
            progress: completedModels / languages.length,
            completedModels: completedModels,
            totalModels: languages.length,
            languageCode: code,
          ),
        );
        final downloaded = await _modelManager.downloadModel(
          code,
          isWifiRequired: false,
        );
        if (!downloaded) {
          throw StateError('Could not download the ML Kit $code model.');
        }
      }
      completedModels = index + 1;
      onProgress?.call(
        LanguageModelDownloadProgress(
          phase: completedModels == languages.length
              ? LanguageModelDownloadPhase.complete
              : LanguageModelDownloadPhase.checking,
          progress: completedModels / languages.length,
          completedModels: completedModels,
          totalModels: languages.length,
          languageCode: code,
        ),
      );
    }
  }
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
    LanguageModelDownloader? modelDownloader,
    OnDeviceTranslatorFactory? translatorFactory,
  }) : _targetLanguage = translateLanguageForAppCode(targetLanguageCode),
       _modelDownloader =
           modelDownloader ??
           MlKitLanguageModelDownloader(modelManager: modelManager),
       _translatorFactory = translatorFactory ?? _createTranslator;

  final TranslateLanguage? _targetLanguage;
  final LanguageModelDownloader _modelDownloader;
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

    final modelsReady = _modelsReady ??= _modelDownloader
        .downloadRequiredModels(targetLanguageCode: targetLanguage.bcpCode);
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
