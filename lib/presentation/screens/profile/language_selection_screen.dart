import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/topic_asset_data_source.dart';
import '../../../data/models/topic_language.dart';
import '../../../shared/providers/app_providers.dart';

/// Language picker opened from the personal quick settings.
///
/// This is deliberately separate from the first-run onboarding screen. A
/// returning learner can change the translation language without resetting
/// onboarding checkpoints or any learning/progress tables.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late String _selectedLanguageCode;
  bool _isSaving = false;
  double _saveProgress = 0;
  String _saveStatusKey = 'preparingLanguagePackage';
  Map<String, Object?> _saveStatusValues = const {};

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = ref.read(selectedAppLanguageProvider);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final nextLanguage = TopicAssetDataSource.canonicalizeLanguageCode(
      _selectedLanguageCode,
    );
    final previousLanguage = ref.read(selectedAppLanguageProvider);
    if (nextLanguage == previousLanguage) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _saveProgress = .08;
      _saveStatusKey = 'preparingLanguagePackage';
      _saveStatusValues = const {};
    });
    final languageService = ref.read(appLanguageServiceProvider);
    try {
      // Persist the user's choice first so the app can resume this migration
      // after a process death. The content metadata is only advanced after
      // the new packages have been written successfully.
      await languageService.saveSelectedLanguage(nextLanguage);
      ref.read(selectedAppLanguageProvider.notifier).state = nextLanguage;
      ref.invalidate(languagePackageInitializationProvider);
      ref.invalidate(localDataInitializationProvider);
      await ref.read(languagePackageInitializationProvider.future);
      if (!mounted) return;
      setState(() {
        _saveProgress = .4;
        _saveStatusKey = 'checkingLanguageModels';
      });
      unawaited(_downloadLanguageModelsInBackground(nextLanguage));
      if (!mounted) return;
      setState(() {
        _saveProgress = .96;
        _saveStatusKey = 'finalizingLanguageChange';
        _saveStatusValues = const {};
      });
      await ref.read(localDataInitializationProvider.future);

      final databaseVersion = await languageService.loadDatabaseVersion();
      if (databaseVersion == null) {
        await languageService.saveNativeLanguage(nextLanguage);
      } else {
        await languageService.saveContentSyncMetadata(
          languageCode: nextLanguage,
          databaseVersion: databaseVersion,
        );
      }

      _invalidateContentProviders();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      // Keep a failed migration from leaving the running app pointing at a
      // package that was not written completely.
      ref.read(selectedAppLanguageProvider.notifier).state = previousLanguage;
      try {
        await languageService.saveSelectedLanguage(previousLanguage);
      } on Object {
        // The next startup will retry the migration if persistence is down.
      }
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveProgress = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.languageSaveError)));
    }
  }

  Future<void> _downloadLanguageModelsInBackground(String languageCode) async {
    try {
      await ref
          .read(languageModelDownloaderProvider)
          .downloadRequiredModels(targetLanguageCode: languageCode);
    } on Object catch (error, stackTrace) {
      // The language package is already usable. Reading will retry the model
      // download if the background attempt did not succeed.
      debugPrint('Background ML Kit model download failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _invalidateContentProviders() {
    ref.invalidate(topicsProvider);
    ref.invalidate(onboardingTopicsProvider);
    ref.invalidate(sentenceAssetWordIdsProvider);
    ref.invalidate(wordProgressProvider);
    ref.invalidate(vocabularyCollectionProvider);
    ref.invalidate(dailyCardProvider);
    ref.invalidate(challengeDashboardProvider);
    ref.invalidate(profileStatisticsProvider);
    ref.invalidate(progressDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final languagesState = ref.watch(supportedLanguagesProvider);
    final available =
        languagesState.valueOrNull ?? TopicAssetDataSource.knownLanguages;
    final languages = _orderedLanguages(available);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _LanguageHero(
                  onBack: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('app-language-list'),
                    padding: EdgeInsets.fromLTRB(
                      18,
                      10,
                      18,
                      _isSaving ? 176 : 112,
                    ),
                    itemCount: languages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      return _SelectableLanguageTile(
                        language: language,
                        selected: language.code == _selectedLanguageCode,
                        onTap: _isSaving
                            ? null
                            : () => setState(
                                () => _selectedLanguageCode = language.code,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving) ...[
                      _LanguageSaveProgress(
                        progress: _saveProgress,
                        statusKey: _saveStatusKey,
                        statusValues: _saveStatusValues,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _SaveButton(isSaving: _isSaving, onPressed: _save),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSaveProgress extends StatelessWidget {
  const _LanguageSaveProgress({
    required this.progress,
    required this.statusKey,
    required this.statusValues,
  });

  final double progress;
  final String statusKey;
  final Map<String, Object?> statusValues;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181B5DAA),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
        child: Column(
          key: const ValueKey('language-model-download-progress'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.text(statusKey, values: statusValues),
                    key: const ValueKey('language-model-download-status'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  key: const ValueKey('language-model-download-percent'),
                  style: const TextStyle(
                    color: Color(0xFF0964E9),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: const Color(0xFFDCE9F9),
                color: const Color(0xFF0964FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<TopicLanguage> _orderedLanguages(List<TopicLanguage> available) {
  final byCode = <String, TopicLanguage>{
    for (final language in available)
      TopicAssetDataSource.canonicalizeLanguageCode(language.code): language,
  };
  byCode['en'] = const TopicLanguage(code: 'en', label: 'English');
  const recommended = ['en', 'vi', 'zh', 'ja', 'ko', 'fr'];
  final result = <TopicLanguage>[];
  for (final code in recommended) {
    final language = byCode[code];
    if (language != null) result.add(language);
  }
  for (final language in byCode.values) {
    if (!recommended.contains(language.code)) result.add(language);
  }
  return result;
}

class _LanguageHero extends StatelessWidget {
  const _LanguageHero({required this.onBack});

  static const _sectionHeight = 315.0;
  static const _bannerHeight = 255.0;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sectionHeight,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _bannerHeight,
            child: Image.asset(
              'assets/images/banner_choose_language.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // const Positioned.fill(
          //   child: DecoratedBox(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [Color(0x00FDFEFF), Color(0xFFFDFEFF)],
          //         stops: [0.8, 0.86],
          //       ),
          //       borderRadius: BorderRadius.vertical(
          //         top: Radius.circular(100),
          //         bottom: Radius.zero,
          //       ),
          //     ),
          //   ),
          // ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, top: 12),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 5,
                  shadowColor: const Color(0x332A70B8),
                  child: IconButton(
                    key: const ValueKey('language-selection-back'),
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primaryDark,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDFEFF), Color(0xFFFDFEFF)],
                  stops: [0.1, 0.86],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(100),
                  bottom: Radius.zero,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.text('languagePickerTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.text('languagePickerSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF657BA5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableLanguageTile extends StatelessWidget {
  const _SelectableLanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final TopicLanguage language;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = language.label;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: ValueKey('app-language-${language.code}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? const Color(0xFF1770FF)
                    : const Color(0xFFF0F3F8),
                width: selected ? 2.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x101B5DAA),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  flagAssetPath(language.code),
                  width: 70,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        englishLanguageName(language.code, label),
                        style: const TextStyle(
                          color: Color(0xFF7185AA),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0xFF1D75FF) : Colors.white,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1D75FF)
                          : const Color(0xFFD7E0EE),
                      width: 2.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 17)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSaving
                ? const [Color(0xFF78A2FF), Color(0xFF8DB4FF)]
                : const [Color(0xFF2378FF), Color(0xFF46CFC0)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x321D75FF),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            key: const ValueKey('language-selection-save'),
            onTap: isSaving ? null : onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 23,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      context.l10n.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

String englishLanguageName(String code, String fallback) {
  const names = <String, String>{
    'en': 'English',
    'vi': 'Vietnamese',
    'zh': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'fr': 'French',
    'de': 'German',
    'es-ES': 'Spanish (Spain)',
    'es-US': 'Spanish (Latin America)',
    'th': 'Thai',
    'ru': 'Russian',
    'pt': 'Portuguese',
    'it': 'Italian',
  };
  return names[code] ?? fallback;
}

String flagAssetPath(String code) {
  const flags = <String, String>{
    'ar': 'Arabic.svg',
    'cs': 'Czech.svg',
    'da': 'Danish.svg',
    'de': 'Deutsch.svg',
    'en': 'english.svg',
    'es-ES': 'Spanish.svg',
    'es-US': 'Spanish.svg',
    'fi': 'Finland.svg',
    'fil': 'Philippines.svg',
    'fr': 'French.svg',
    'hi': 'India.svg',
    'hu': 'Hungary.svg',
    'in': 'Indonesia.svg',
    'it': 'Italy.svg',
    'iw': 'Israel.svg',
    'ja': 'Japanese.svg',
    'ko': 'Korean.svg',
    'ms': 'Malaysia.svg',
    'nb': 'Norwegian.svg',
    'nl': 'Nederlands.svg',
    'pl': 'Poland.svg',
    'pt': 'Portuguese.svg',
    'ro': 'Romania.svg',
    'ru': 'Russian.svg',
    'sv': 'Swedish.svg',
    'th': 'thailand.svg',
    'tr': 'Turkey.svg',
    'uk': 'Ukraine.svg',
    'vi': 'Vietnamese.svg',
    'zh': 'Chinese.svg',
    'zh-TW': 'taiwan.svg',
  };
  return 'assets/svgs/flags/${flags[code] ?? flags['en']}';
}
