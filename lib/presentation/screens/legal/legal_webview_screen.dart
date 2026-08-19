import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';

class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({required this.title, required this.uri, super.key});

  final String title;
  final Uri uri;

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _errorMessage = null;
              _loadingProgress = 0;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loadingProgress = 100);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() => _errorMessage = error.description);
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = _errorMessage == null && _loadingProgress < 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          if (_errorMessage == null)
            WebViewWidget(controller: _controller)
          else
            _ErrorView(
              message: _errorMessage!,
              onRetry: () {
                setState(() {
                  _errorMessage = null;
                  _loadingProgress = 0;
                });
                _controller.reload();
              },
            ),
          if (showProgress)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                value: _loadingProgress == 0 ? null : _loadingProgress / 100,
                minHeight: 2,
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textMuted,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load this page.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
