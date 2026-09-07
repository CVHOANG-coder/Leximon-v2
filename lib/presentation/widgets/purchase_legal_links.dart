import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../screens/legal/legal_webview_screen.dart';

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
