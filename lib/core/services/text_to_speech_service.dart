import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared text-to-speech controller for English vocabulary in the app.
class TextToSpeechService {
  TextToSpeechService._() {
    _attachHandlers();
  }

  static final TextToSpeechService instance = TextToSpeechService._();
  static const defaultSpeechRate = .45;
  static const slowSpeechRate = .2;

  FlutterTts _tts = FlutterTts();
  int _latestRequestId = 0;
  bool _needsRecovery = false;

  Future<void> speak(
    String text, {
    String language = 'en-US',
    double speechRate = defaultSpeechRate,
  }) {
    return speakLatest(text, language: language, speechRate: speechRate);
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
      await _speakWithRecovery(value, language, speechRate, requestId);
    } on Object catch (error, stackTrace) {
      _needsRecovery = true;
      _logError('speak', error, stackTrace);
    }
  }

  Future<void> stop() async {
    _latestRequestId++;
    try {
      await _tts.stop();
    } on Object catch (error, stackTrace) {
      _needsRecovery = true;
      _logError('stop', error, stackTrace);
    }
  }

  Future<void> _speakWithRecovery(
    String text,
    String language,
    double speechRate,
    int requestId,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (requestId != _latestRequestId) return;
        if (_needsRecovery) await _recoverEngine();
        if (requestId != _latestRequestId) return;

        await _configure(language);
        if (requestId != _latestRequestId) return;

        _ensureSucceeded(await _tts.setSpeechRate(speechRate), 'setSpeechRate');
        await _tts.stop();
        if (requestId != _latestRequestId) return;

        // Do not await utterance completion here. flutter_tts can leave that
        // Future pending after an Android cancellation/error, which would block
        // every later request in this singleton service.
        _ensureSucceeded(await _tts.speak(text, focus: true), 'speak');
        if (requestId != _latestRequestId) await _tts.stop();
        return;
      } on Object catch (error, stackTrace) {
        _needsRecovery = true;
        _logError('speak attempt ${attempt + 1}', error, stackTrace);
        if (attempt == 1 || requestId != _latestRequestId) return;
        await _recoverEngine();
      }
    }
  }

  Future<void> _configure(String language) async {
    // Configure on every request because recording and media plugins can change
    // the shared audio session while the app remains alive.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [IosTextToSpeechAudioCategoryOptions.duckOthers],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      _ensureSucceeded(await _tts.setSharedInstance(true), 'setSharedInstance');
      await _tts.autoStopSharedSession(true);
    }

    _ensureSucceeded(
      await _tts.setLanguage(language),
      'setLanguage($language)',
    );
    _ensureSucceeded(await _tts.setVolume(1), 'setVolume');
    _ensureSucceeded(await _tts.setPitch(1), 'setPitch');
    _ensureSucceeded(
      await _tts.awaitSpeakCompletion(false),
      'awaitSpeakCompletion',
    );
  }

  Future<void> _recoverEngine() async {
    try {
      await _tts.stop();
    } on Object {
      // The current native instance may already be disconnected.
    }

    _tts = FlutterTts();
    _attachHandlers();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final engine = await _tts.getDefaultEngine;
      if (engine is String && engine.isNotEmpty) {
        await _tts.setEngine(engine);
      }
    }

    _needsRecovery = false;
  }

  void _attachHandlers() {
    _tts.setErrorHandler((message) {
      _needsRecovery = true;
      debugPrint('TextToSpeechService native error: $message');
    });
  }

  void _ensureSucceeded(dynamic result, String operation) {
    final failed = result == false || (result is num && result <= 0);
    if (failed) {
      throw StateError('flutter_tts $operation returned $result');
    }
  }

  void _logError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('TextToSpeechService $operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
