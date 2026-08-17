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
  static const _maximumFakeProgress = .99;

  Object? _error;
  Timer? _progressTimer;
  double _progress = 0;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPackage());
  }

  Future<void> _loadPackage() async {
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = null;
        _progress = .04;
      });
    }
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() {
        _progress = (_progress + .018).clamp(0, _maximumFakeProgress);
      });
    });

    try {
      await ref.read(languagePackageInitializationProvider.future);
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() => _progress = 1);
      context.pushReplacement('/onboarding/assessment-intro');
    } catch (error) {
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _error = error;
        _progress = _maximumFakeProgress;
      });
    }
  }

  void _retry() {
    ref.invalidate(languagePackageInitializationProvider);
    unawaited(_loadPackage());
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
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
                          _LanguagePackageProgress(progress: _progress)
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
  const _LanguagePackageProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('language-package-loading-progress'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 17,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Color(0xFFDCE9F9),
              color: Color(0xFF0964FF),
              minHeight: 17,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.loading,
                key: const ValueKey('language-package-loading-status'),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
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
