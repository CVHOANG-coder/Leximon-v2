import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';

class LanguagePackageLoadingScreen extends ConsumerStatefulWidget {
  const LanguagePackageLoadingScreen({super.key});

  @override
  ConsumerState<LanguagePackageLoadingScreen> createState() =>
      _LanguagePackageLoadingScreenState();
}

class _LanguagePackageLoadingScreenState
    extends ConsumerState<LanguagePackageLoadingScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadPackage());
    });
  }

  Future<void> _loadPackage() async {
    if (mounted) {
      ref
          .read(languagePackageLoadingProgressProvider.notifier)
          .state = const LanguagePackageLoadingProgress(
        progress: .08,
        statusKey: 'preparingLanguagePackage',
      );
      setState(() {
        _error = null;
      });
    }

    try {
      await ref.read(languagePackageInitializationProvider.future);
      if (!mounted) return;
      ref
          .read(languagePackageLoadingProgressProvider.notifier)
          .state = const LanguagePackageLoadingProgress(
        progress: .97,
        statusKey: 'checkingLanguageModels',
      );
      final languageCode = ref.read(selectedAppLanguageProvider);
      unawaited(_downloadLanguageModelsInBackground(languageCode));
      if (!mounted) return;
      ref
          .read(languagePackageLoadingProgressProvider.notifier)
          .state = const LanguagePackageLoadingProgress(
        progress: 1,
        statusKey: 'languageModelsReady',
      );
      // Keep the completed state visible long enough for the animated bar to
      // reach 100% before replacing this route.
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      context.pushReplacement('/onboarding/assessment-intro');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
      });
    }
  }

  Future<void> _downloadLanguageModelsInBackground(String languageCode) async {
    try {
      await ref
          .read(languageModelDownloaderProvider)
          .downloadRequiredModels(targetLanguageCode: languageCode);
    } on Object catch (error, stackTrace) {
      // Content loading must not be blocked by an optional offline model.
      // Reading will retry through the same downloader when translation is
      // actually requested.
      debugPrint('Background ML Kit model download failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _retry() {
    ref.invalidate(languagePackageInitializationProvider);
    unawaited(_loadPackage());
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final loadingProgress = ref.watch(languagePackageLoadingProgressProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7FAFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('language-package-loading-screen'),
        backgroundColor: const Color(0xFFF7FAFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/loading/bg_loading.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 720;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 26 : 34,
                      compact ? 20 : 46,
                      compact ? 26 : 34,
                      compact ? 20 : 34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.loading,
                          key: const ValueKey('language-package-loading-title'),
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: compact ? 31 : 38,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.text('listeningReadingData'),
                          key: const ValueKey(
                            'language-package-loading-description',
                          ),
                          style: TextStyle(
                            color: const Color(0xFF6F88AD),
                            fontSize: compact ? 15 : 17,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              'assets/images/loading/owl_loading.png',
                              key: const ValueKey(
                                'language-package-loading-owl',
                              ),
                              fit: BoxFit.contain,
                              width: _min(
                                constraints.maxWidth * .92,
                                compact ? 370 : 440,
                              ),
                            ),
                          ),
                        ),
                        if (error == null)
                          _LanguagePackageProgress(
                            progress: loadingProgress.progress,
                            statusKey: loadingProgress.statusKey,
                            statusValues: loadingProgress.statusValues,
                          )
                        else
                          _LanguagePackageError(onRetry: _retry),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePackageProgress extends StatelessWidget {
  const _LanguagePackageProgress({
    required this.progress,
    required this.statusKey,
    required this.statusValues,
  });

  final double progress;
  final String statusKey;
  final Map<String, Object?> statusValues;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('language-package-loading-progress'),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, animatedProgress, _) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 17,
                    child: LinearProgressIndicator(
                      value: animatedProgress,
                      backgroundColor: const Color(0xFFDCE9F9),
                      color: const Color(0xFF0964FF),
                      minHeight: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.text(statusKey, values: statusValues),
                        key: const ValueKey('language-package-loading-status'),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${(animatedProgress * 100).round()}%',
                      key: const ValueKey('language-package-loading-percent'),
                      style: const TextStyle(
                        color: Color(0xFF0964E9),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  context.l10n.text('pleaseWait'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A91B2),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LanguagePackageError extends StatelessWidget {
  const _LanguagePackageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('language-package-loading-error'),
      children: [
        Text(
          context.l10n.text('splashInitializationError'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          context.l10n.text('checkConnectionTryAgain'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7A91B2),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: Text(context.l10n.back),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const ValueKey('language-package-loading-retry'),
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double _min(double first, double second) => first < second ? first : second;
