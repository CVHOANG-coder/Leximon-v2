import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LeximonApp()));

  // Firebase and the orientation platform channel are not needed to paint the
  // first Flutter frame. Starting them afterwards prevents native plugin setup
  // from extending the blank launch-screen interval on slower devices.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePlatformServices());
  });
}

Future<void> _initializePlatformServices() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await Firebase.initializeApp();
  } on Object catch (error, stackTrace) {
    // Firebase is optional for local/dev builds. Firebase-backed services
    // remain best-effort when a platform configuration is unavailable.
    debugPrint('Firebase initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
