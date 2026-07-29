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
  int _latestRequestId = 0;

  Future<void> speak(
    String text, {
    String language = 'en-US',
    double speechRate = defaultSpeechRate,
  }) {
    _latestRequestId++;
    final request = _speakChain.then(
      (_) => _speakNow(text, language, speechRate),
    );
    _speakChain = request.catchError((_) {});
    return request;
  }

  Future<void> speakLatest(
    String text, {
    String language = 'en-US',
    double speechRate = defaultSpeechRate,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final requestId = ++_latestRequestId;

    try {
      await _tts.stop();
      if (requestId != _latestRequestId) return;
      await _configure(language);
      if (requestId != _latestRequestId) return;
      await _tts.setSpeechRate(speechRate);
      if (requestId != _latestRequestId) return;
      await _tts.speak(value);
    } on Object {
      // Keep pronunciation best-effort on platforms without a TTS engine.
    }
  }

  Future<void> stop() async {
    _latestRequestId++;
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
      await _configure(language);
      await _tts.setSpeechRate(speechRate);
      await _tts.stop();
      await _tts.speak(value);
    } on Object {
      // Keep pronunciation best-effort on platforms without a TTS engine.
    }
  }

  Future<void> _configure(String language) async {
    if (_configuredLanguage == language) return;
    await _tts.setLanguage(language);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    await _tts.awaitSpeakCompletion(true);
    _configuredLanguage = language;
  }
}
