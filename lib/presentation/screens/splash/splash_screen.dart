import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minimumDisplayTime = Duration(milliseconds: 800);

  Object? _initializationError;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final minimumDisplay = Future<void>.delayed(_minimumDisplayTime);
    final initialization = ref.read(applicationInitializationProvider.future);

    if (mounted) {
      setState(() {
        _initializationError = null;
        _isRetrying = true;
      });
    }

    try {
      await Future.wait([initialization, minimumDisplay]);
      final destination = await initialization;
      if (!mounted) return;
      context.go(switch (destination) {
        AppStartupDestination.languageOnboarding => '/onboarding/language',
        AppStartupDestination.assessmentIntro => '/onboarding/assessment-intro',
        AppStartupDestination.freeTrialOffer =>
          '/onboarding/assessment-intro/survey/free-trial',
        AppStartupDestination.home => '/',
      });
    } catch (error) {
      await minimumDisplay;
      if (!mounted) return;
      setState(() {
        _initializationError = error;
        _isRetrying = false;
      });
    }
  }

  void _retry() {
    ref.invalidate(localDataInitializationProvider);
    ref.invalidate(selectedTopicOrdersHydrationProvider);
    ref.invalidate(applicationInitializationProvider);
    unawaited(_initialize());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF00164D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF00164D),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash.png', fit: BoxFit.cover),
            if (_initializationError != null)
              SafeArea(
                minimum: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _StartupError(onRetry: _isRetrying ? null : _retry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD900164D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Không thể khởi tạo ứng dụng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng kiểm tra và thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
