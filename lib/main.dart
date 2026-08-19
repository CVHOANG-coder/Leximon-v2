import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } on Object catch (error, stackTrace) {
    // Firebase is optional for local/dev builds. Firebase-backed services
    // remain best-effort when a platform configuration is unavailable.
    debugPrint('Firebase initialization skipped: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: LeximonApp()));
}
