import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Loads the App Review presentation switch after Firebase is initialized.
///
/// The safe default is `false`: normalized prices stay hidden while Remote
/// Config is loading, when the parameter is missing, or when fetching fails.
class ReviewModeService {
  ReviewModeService._();

  static final ReviewModeService instance = ReviewModeService._();
  static const String parameterKey = 'review_mode';

  final Completer<bool> _reviewMode = Completer<bool>();

  Future<bool> get reviewModeEnabled => _reviewMode.future;

  Future<void> initialize() async {
    if (_reviewMode.isCompleted) return;

    var enabled = false;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const {parameterKey: false});
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );

      try {
        await remoteConfig.fetchAndActivate();
      } on Object catch (error) {
        // A previously activated value can still be used when fetching fails.
        debugPrint('Remote Config fetch skipped: $error');
      }
      enabled = remoteConfig.getBool(parameterKey);
    } on Object catch (error, stackTrace) {
      debugPrint('Remote Config initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (!_reviewMode.isCompleted) _reviewMode.complete(enabled);
    }
  }

  void markUnavailable() {
    if (!_reviewMode.isCompleted) _reviewMode.complete(false);
  }
}
