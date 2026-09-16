import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/iap_packages_response.dart';
import '../../shared/providers/app_providers.dart';
import '../screens/legal/legal_webview_screen.dart';

/// Shows the price, trial conversion, and auto-renewal terms beside the CTA.
class SubscriptionBillingDisclosure extends StatelessWidget {
  const SubscriptionBillingDisclosure({
    super.key,
    required this.package,
    required this.product,
    required this.trialDays,
    this.textColor = const Color(0xFF536686),
    this.backgroundColor = const Color(0xFFF1F6FD),
    this.borderColor = const Color(0xFFD9E6F8),
  });

  final IapPackage package;
  final ProductDetails? product;
  final int trialDays;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final price = product?.price.trim();
    if (price == null || price.isEmpty) return const SizedBox.shrink();

    final period = _billingPeriod(context, package.packDurationDay);
    final message = context.l10n.text(
      trialDays > 0
          ? 'subscriptionTrialBillingDisclosure'
          : 'subscriptionBillingDisclosure',
      values: {'days': trialDays, 'price': price, 'period': period},
    );

    return Semantics(
      container: true,
      label: message,
      child: Container(
        key: const ValueKey('subscription-billing-disclosure'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.autorenew_rounded, color: textColor, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _billingPeriod(BuildContext context, int days) {
    if (days >= 36500) return context.l10n.text('subscriptionLifetime');
    if (days >= 330) {
      return context.l10n.text(
        'subscriptionYears',
        values: {'count': (days / 365).round()},
      );
    }
    if (days >= 28) {
      return context.l10n.text(
        'subscriptionMonths',
        values: {'count': (days / 30).round()},
      );
    }
    if (days >= 7) {
      return context.l10n.text(
        'subscriptionWeeks',
        values: {'count': (days / 7).round()},
      );
    }
    return context.l10n.text('subscriptionDays', values: {'count': days});
  }
}

/// Starts the native App Store/Google Play restore flow on demand.
class PurchaseRestoreButton extends ConsumerStatefulWidget {
  const PurchaseRestoreButton({
    super.key,
    this.textColor = const Color(0xFF536686),
  });

  final Color textColor;

  @override
  ConsumerState<PurchaseRestoreButton> createState() =>
      _PurchaseRestoreButtonState();
}

class _PurchaseRestoreButtonState extends ConsumerState<PurchaseRestoreButton> {
  bool _isRestoring = false;

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      await ref.read(iapPurchaseServiceProvider).restorePurchases();
      if (!mounted) return;
      _showMessage(context.l10n.text('subscriptionRestoreStarted'));
    } on Object {
      if (!mounted) return;
      _showMessage(context.l10n.text('subscriptionRestoreError'));
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('subscription-restore'),
    onPressed: _isRestoring ? null : _restorePurchases,
    style: TextButton.styleFrom(
      foregroundColor: widget.textColor,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: _isRestoring
        ? SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(
              color: widget.textColor,
              strokeWidth: 2,
            ),
          )
        : const Icon(Icons.restore_rounded, size: 20),
    label: Text(
      context.l10n.text('subscriptionRestore'),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

/// Functional Terms of Use and Privacy Policy links for purchase screens.
class PurchaseLegalLinks extends StatelessWidget {
  const PurchaseLegalLinks({
    super.key,
    this.textColor = const Color(0xFF536686),
  });

  static final privacyPolicyUri = Uri.parse(
    'https://leximonenglish.giddychat.com/privacy-policy.html',
  );
  static final termsOfUseUri = Uri.parse(
    'https://leximonenglish.giddychat.com/terms.html',
  );

  final Color textColor;

  void _openDocument(
    BuildContext context, {
    required String title,
    required Uri uri,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalWebViewScreen(title: title, uri: uri),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Purchase legal information',
      child: Wrap(
        key: const ValueKey('purchase-legal-links'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 0,
        children: [
          _LegalLinkButton(
            key: const ValueKey('subscription-terms'),
            label: context.l10n.text('subscriptionTerms'),
            color: textColor,
            onPressed: () => _openDocument(
              context,
              title: context.l10n.text('subscriptionTerms'),
              uri: termsOfUseUri,
            ),
          ),
          Text('•', style: TextStyle(color: textColor, fontSize: 13)),
          _LegalLinkButton(
            key: const ValueKey('subscription-privacy'),
            label: context.l10n.text('subscriptionPrivacy'),
            color: textColor,
            onPressed: () => _openDocument(
              context,
              title: context.l10n.text('subscriptionPrivacy'),
              uri: privacyPolicyUri,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkButton extends StatelessWidget {
  const _LegalLinkButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}
