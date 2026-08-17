import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/services/text_to_speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reconfigures and retries when the TTS engine rejects a request',
    () async {
      const channel = MethodChannel('flutter_tts');
      var languageAttempts = 0;
      var speakCalls = 0;
      final awaitCompletionValues = <bool>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'setLanguage':
                languageAttempts++;
                return languageAttempts == 1 ? 0 : 1;
              case 'awaitSpeakCompletion':
                awaitCompletionValues.add(call.arguments as bool);
                return 1;
              case 'speak':
                speakCalls++;
                return 1;
              default:
                return 1;
            }
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await TextToSpeechService.instance.speak('hello');

      expect(languageAttempts, 2);
      expect(speakCalls, 1);
      expect(awaitCompletionValues, [false]);
    },
  );
}
