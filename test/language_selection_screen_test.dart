import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/services/app_language_service.dart';
import 'package:leximon/data/models/topic_language.dart';
import 'package:leximon/data/services/reading_word_translation_service.dart';
import 'package:leximon/presentation/screens/profile/language_selection_screen.dart';
import 'package:leximon/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('saves a changed language and refreshes local packages', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      AppLanguageService.selectedLanguageKey: 'vi',
      AppLanguageService.nativeLanguageKey: 'vi',
      AppLanguageService.databaseVersionKey: 4,
    });
    var packageLoads = 0;
    final modelDownload = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        selectedAppLanguageProvider.overrideWith((ref) => 'vi'),
        supportedLanguagesProvider.overrideWith(
          (ref) async => const [
            TopicLanguage(code: 'en', label: 'English'),
            TopicLanguage(code: 'vi', label: 'Tiếng Việt'),
            TopicLanguage(code: 'de', label: 'Deutsch'),
          ],
        ),
        languagePackageInitializationProvider.overrideWith((ref) async {
          packageLoads++;
        }),
        languageModelDownloaderProvider.overrideWithValue(
          _ControlledLanguageModelDownloader(modelDownload.future),
        ),
        localDataInitializationProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LanguageSelectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiếng Việt'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('app-language-de')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('app-language-de')));
    await tester.tap(find.byKey(const ValueKey('language-selection-save')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(packageLoads, 1);
    expect(container.read(selectedAppLanguageProvider), 'de');
    expect(preferences.getString(AppLanguageService.selectedLanguageKey), 'de');
    expect(preferences.getString(AppLanguageService.nativeLanguageKey), 'de');

    // ML Kit continues in the background and is not required to finish the
    // language-package migration. Complete the fake download to avoid
    // leaving a pending future in the test container.
    modelDownload.complete();
  });
}

class _ControlledLanguageModelDownloader implements LanguageModelDownloader {
  _ControlledLanguageModelDownloader(this.download);

  final Future<void> download;

  @override
  Future<void> downloadRequiredModels({
    required String targetLanguageCode,
    LanguageModelProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const LanguageModelDownloadProgress(
        phase: LanguageModelDownloadPhase.downloading,
        progress: 0,
        completedModels: 0,
        totalModels: 2,
        languageCode: 'en',
      ),
    );
    await download;
    onProgress?.call(
      const LanguageModelDownloadProgress(
        phase: LanguageModelDownloadPhase.complete,
        progress: 1,
        completedModels: 2,
        totalModels: 2,
      ),
    );
  }
}
