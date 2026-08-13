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
}

class _DownloadedModelManager extends OnDeviceTranslatorModelManager {
  final List<String> checkedModels = [];

  @override
  Future<bool> isModelDownloaded(String model) async {
    checkedModels.add(model);
    return true;
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
