import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

typedef TrackingStatusReader = Future<PermissionStatus> Function();
typedef TrackingPermissionRequester = Future<PermissionStatus> Function();

/// Requests Apple's App Tracking Transparency permission while iOS can show it.
class AppTrackingTransparencyService {
  const AppTrackingTransparencyService._();

  static const _initialPromptDelay = Duration(milliseconds: 500);
  static const _retryDelay = Duration(seconds: 1);
  static const _maxRequestAttempts = 3;
  static Future<PermissionStatus?>? _requestInFlight;

  static Future<PermissionStatus?> requestIfNeeded() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return Future<PermissionStatus?>.value();
    }
    return _requestInFlight ??= _requestAndRelease();
  }

  static Future<PermissionStatus?> _requestAndRelease() async {
    try {
      return await requestWhenActive(
        readStatus: () => Permission.appTrackingTransparency.status,
        requestPermission: () => Permission.appTrackingTransparency.request(),
        waitUntilResumed: _waitUntilResumed,
        isResumed: _isResumed,
      );
    } on Object catch (error, stackTrace) {
      // ATT is optional and must never prevent the app from starting.
      debugPrint('ATT permission request skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _requestInFlight = null;
    }
  }

  /// Apple only presents ATT while the application is active. It also drops
  /// the request when another system permission dialog is pending, so a still
  /// undetermined result is retried after the app has settled.
  @visibleForTesting
  static Future<PermissionStatus> requestWhenActive({
    required TrackingStatusReader readStatus,
    required TrackingPermissionRequester requestPermission,
    required Future<void> Function() waitUntilResumed,
    required bool Function() isResumed,
    Future<void> Function(Duration) delay = Future<void>.delayed,
    Duration initialPromptDelay = _initialPromptDelay,
    Duration retryDelay = _retryDelay,
    int maxRequestAttempts = _maxRequestAttempts,
  }) async {
    var status = await readStatus();

    // permission_handler maps ATT's native `notDetermined` status to `denied`.
    // A decision that the user already made is returned as granted,
    // restricted, or permanentlyDenied and must never trigger another prompt.
    if (!status.isDenied) return status;

    var attempts = 0;
    while (attempts < maxRequestAttempts) {
      await waitUntilResumed();
      await delay(attempts == 0 ? initialPromptDelay : retryDelay);

      // The app may have become inactive during the settling delay. Waiting
      // again avoids sending a request that iOS is documented to discard.
      if (!isResumed()) continue;

      status = await readStatus();
      if (!status.isDenied) return status;

      attempts += 1;
      status = await requestPermission();
      if (!status.isDenied) return status;
    }

    return readStatus();
  }

  static bool _isResumed() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  static Future<void> _waitUntilResumed() async {
    while (!_isResumed()) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
