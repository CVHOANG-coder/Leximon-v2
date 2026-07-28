import 'package:flutter_tts/flutter_tts.dart';

/// Shared text-to-speech controller for English vocabulary in the app.
class TextToSpeechService {
  TextToSpeechService._();

  static final TextToSpeechService instance = TextToSpeechService._();
  static const defaultSpeechRate = .45;
  static const slowSpeechRate = .2;

  final FlutterTts _tts = FlutterTts();
  Future<void> _speakChain = Future<void>.value();
  String? _configuredLanguage;

  Future<void> speak(
    String text, {
    String language = 'en-US',
    double speechRate = defaultSpeechRate,
  }) {
    final request = _speakChain.then(
      (_) => _speakNow(text, language, speechRate),
    );
    _speakChain = request.catchError((_) {});
    return request;
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // TTS is an optional platform capability; keep the UI usable if the
      // native engine is unavailable or has not been initialized yet.
    }
  }

  Future<void> _speakNow(
    String text,
    String language,
    double speechRate,
  ) async {
    final value = text.trim();
    if (value.isEmpty) return;

    try {
      if (_configuredLanguage != language) {
        await _tts.setLanguage(language);
        await _tts.setVolume(1);
        await _tts.setPitch(1);
        await _tts.awaitSpeakCompletion(true);
        _configuredLanguage = language;
      }
      await _tts.setSpeechRate(speechRate);
      await _tts.stop();
      await _tts.speak(value);
    } on Object {
      // Keep pronunciation best-effort on platforms without a TTS engine.
    }
  }
}
