import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// The shared confirmation/information dialog used across the app.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon = Icons.close_rounded,
    this.iconColor = AppColors.primary,
    this.imageAsset,
    super.key,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData icon;
  final Color iconColor;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final hasSecondaryAction = secondaryLabel != null && onSecondary != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D071A3D),
              blurRadius: 32,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogIcon(icon: icon, color: iconColor, imageAsset: imageAsset),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -.65,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7187AA),
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const _DialogDivider(),
            const SizedBox(height: 24),
            if (hasSecondaryAction)
              Row(
                children: [
                  Expanded(
                    child: _DialogOutlinedButton(
                      label: secondaryLabel!,
                      onPressed: onSecondary!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogFilledButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                    ),
                  ),
                ],
              )
            else
              _DialogFilledButton(label: primaryLabel, onPressed: onPrimary),
          ],
        ),
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon, required this.color, this.imageAsset});

  final IconData icon;
  final Color color;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null) {
      return SizedBox(
        width: 160,
        height: 73,
        child: Image.asset(imageAsset!, fit: BoxFit.contain),
      );
    }

    return SizedBox(
      width: 76,
      height: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .12),
          border: Border.all(color: color.withValues(alpha: .16), width: 8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 38),
      ),
    );
  }
}

class _DialogDivider extends StatelessWidget {
  const _DialogDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDCE8FA), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFA8C9FF),
            size: 19,
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDCE8FA), height: 1)),
      ],
    );
  }
}

class _DialogOutlinedButton extends StatelessWidget {
  const _DialogOutlinedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DialogFilledButton extends StatelessWidget {
  const _DialogFilledButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
