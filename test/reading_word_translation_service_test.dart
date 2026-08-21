import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:leximon/data/services/reading_word_translation_service.dart';

void main() {
  test('maps app language aliases to ML Kit languages', () {
    expect(translateLanguageForAppCode('vi'), TranslateLanguage.vietnamese);
    expect(translateLanguageForAppCode('es-US'), TranslateLanguage.spanish);
    expect(translateLanguageForAppCode('fil'), TranslateLanguage.tagalog);
    expect(translateLanguageForAppCode('in'), TranslateLanguage.indonesian);
    expect(translateLanguageForAppCode('iw'), TranslateLanguage.hebrew);
    expect(translateLanguageForAppCode('nb'), TranslateLanguage.norwegian);
    expect(translateLanguageForAppCode('zh-TW'), TranslateLanguage.chinese);
    expect(translateLanguageForAppCode('unsupported'), isNull);
  });

  test(
    'creates a native translator only for a request and closes it',
    () async {
      final modelManager = _DownloadedModelManager();
      final nativeTranslators = <_FakeOnDeviceTranslator>[];
      final translator = MlKitReadingWordTranslator(
        targetLanguageCode: 'vi',
        modelManager: modelManager,
        translatorFactory:
            ({required sourceLanguage, required targetLanguage}) {
              final nativeTranslator = _FakeOnDeviceTranslator(
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
              );
              nativeTranslators.add(nativeTranslator);
              return nativeTranslator;
            },
      );

      expect(nativeTranslators, isEmpty);

      expect(await translator.translateWord('mystery'), 'translated mystery');
      expect(nativeTranslators, hasLength(1));
      expect(nativeTranslators.single.wasClosed, isTrue);

      expect(await translator.translateWord('winter'), 'translated winter');
      expect(nativeTranslators, hasLength(2));
      expect(nativeTranslators.every((item) => item.wasClosed), isTrue);
      expect(modelManager.checkedModels, [
        TranslateLanguage.english.bcpCode,
        TranslateLanguage.vietnamese.bcpCode,
      ]);
    },
  );

  test('closes the native translator when translation fails', () async {
    final nativeTranslator = _FakeOnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.vietnamese,
      error: StateError('translation failed'),
    );
    final translator = MlKitReadingWordTranslator(
      targetLanguageCode: 'vi',
      modelManager: _DownloadedModelManager(),
      translatorFactory: ({required sourceLanguage, required targetLanguage}) =>
          nativeTranslator,
    );

    await expectLater(
      translator.translateWord('mystery'),
      throwsA(isA<StateError>()),
    );
    expect(nativeTranslator.wasClosed, isTrue);
  });

  test('reports completed ML Kit model download steps', () async {
    final modelManager = _DownloadableModelManager();
    final downloader = MlKitLanguageModelDownloader(modelManager: modelManager);
    final progress = <LanguageModelDownloadProgress>[];

    await downloader.downloadRequiredModels(
      targetLanguageCode: 'vi',
      onProgress: progress.add,
    );

    expect(modelManager.downloadedModels, ['en', 'vi']);
    expect(
      progress
          .where((item) => item.phase == LanguageModelDownloadPhase.downloading)
          .map((item) => item.languageCode),
      ['en', 'vi'],
    );
    expect(progress.last.phase, LanguageModelDownloadPhase.complete);
    expect(progress.last.progress, 1);
    expect(progress.last.completedModels, 2);
  });

  test('retries a failed model download up to three attempts', () async {
    final modelManager = _FlakyModelManager(failuresBeforeSuccess: 2);
    final downloader = MlKitLanguageModelDownloader(
      modelManager: modelManager,
      retryDelay: Duration.zero,
    );

    await downloader.downloadRequiredModels(targetLanguageCode: 'vi');

    expect(modelManager.downloadAttempts['en'], 3);
    expect(modelManager.downloadAttempts['vi'], 1);
  });

  test('times out a model operation and retries it', () async {
    final modelManager = _HangingModelManager();
    final downloader = MlKitLanguageModelDownloader(
      modelManager: modelManager,
      operationTimeout: const Duration(milliseconds: 1),
      retryDelay: Duration.zero,
    );

    await expectLater(
      downloader.downloadRequiredModels(targetLanguageCode: 'vi'),
      throwsA(isA<TimeoutException>()),
    );
    expect(modelManager.checkAttempts, 3);
  });
}

class _DownloadedModelManager extends OnDeviceTranslatorModelManager {
  final List<String> checkedModels = [];

  @override
  Future<bool> isModelDownloaded(String model) async {
    checkedModels.add(model);
    return true;
  }
}

class _DownloadableModelManager extends OnDeviceTranslatorModelManager {
  final List<String> downloadedModels = [];

  @override
  Future<bool> isModelDownloaded(String model) async => false;

  @override
  Future<bool> downloadModel(String model, {bool isWifiRequired = true}) async {
    downloadedModels.add(model);
    return true;
  }
}

class _FlakyModelManager extends OnDeviceTranslatorModelManager {
  _FlakyModelManager({required this.failuresBeforeSuccess});

  final int failuresBeforeSuccess;
  final downloadAttempts = <String, int>{};

  @override
  Future<bool> isModelDownloaded(String model) async => false;

  @override
  Future<bool> downloadModel(String model, {bool isWifiRequired = true}) async {
    final attempt = (downloadAttempts[model] ?? 0) + 1;
    downloadAttempts[model] = attempt;
    if (model == 'en' && attempt <= failuresBeforeSuccess) return false;
    return true;
  }
}

class _HangingModelManager extends OnDeviceTranslatorModelManager {
  var checkAttempts = 0;

  @override
  Future<bool> isModelDownloaded(String model) async {
    checkAttempts++;
    return Completer<bool>().future;
  }
}

class _FakeOnDeviceTranslator extends OnDeviceTranslator {
  _FakeOnDeviceTranslator({
    required super.sourceLanguage,
    required super.targetLanguage,
    this.error,
  });

  final Object? error;
  bool wasClosed = false;

  @override
  Future<String> translateText(String text) async {
    final failure = error;
    if (failure != null) throw failure;
    return 'translated $text';
  }

  @override
  Future<void> close() async {
    wasClosed = true;
  }
}
