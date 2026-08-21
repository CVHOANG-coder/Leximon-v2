import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests Apple's App Tracking Transparency permission at app launch.
class AppTrackingTransparencyService {
  const AppTrackingTransparencyService._();

  static Future<void> requestIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final status = await Permission.appTrackingTransparency.status;
      // permission_handler maps ATT's `notDetermined` to `denied`, while a
      // previous user decision is exposed as `permanentlyDenied`.
      if (!status.isDenied) return;

      await Permission.appTrackingTransparency.request();
    } on Object catch (error, stackTrace) {
      // ATT is optional and must never prevent the app from starting.
      debugPrint('ATT permission request skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
