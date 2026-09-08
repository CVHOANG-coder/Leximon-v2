import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'core/services/app_tracking_transparency_service.dart';
import 'core/services/review_mode_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LeximonApp()));

  // Firebase and the orientation platform channel are not needed to paint the
  // first Flutter frame. Starting them afterwards prevents native plugin setup
  // from extending the blank launch-screen interval on slower devices.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Keep ATT independent from the orientation channel. A platform-channel
    // failure on newer iPadOS versions must never skip the privacy prompt.
    unawaited(_configurePreferredOrientations());
    unawaited(_initializePrivacyAwareServices());
  });
}

Future<void> _configurePreferredOrientations() async {
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } on Object catch (error, stackTrace) {
    debugPrint('Preferred orientation setup skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializePrivacyAwareServices() async {
  PermissionStatus? trackingStatus;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // Ask only after the first frame and once iOS reports the app as active.
    // Firebase Analytics is disabled by Info.plist until this finishes.
    trackingStatus = await AppTrackingTransparencyService.requestIfNeeded();
  }

  try {
    await Firebase.initializeApp();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        trackingStatus?.isGranted ?? false,
      );
    }
    await ReviewModeService.instance.initialize();
  } on Object catch (error, stackTrace) {
    // Firebase is optional for local/dev builds. Firebase-backed services
    // remain best-effort when a platform configuration is unavailable.
    debugPrint('Firebase initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
    ReviewModeService.instance.markUnavailable();
  }
}
