import 'package:flutter/material.dart';

/// Shared surface for bottom sheets across the app.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        side: BorderSide(color: Color(0xFFD9E8FB), width: 1.2),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppBottomSheetHandle(),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomSheetHandle extends StatelessWidget {
  const AppBottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFCFE1FA),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class AppBottomSheetTitle extends StatelessWidget {
  const AppBottomSheetTitle({
    required this.title,
    this.icon = Icons.auto_awesome_rounded,
    this.color = const Color(0xFF2B72E8),
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF071A3D),
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
        ),
      ],
    );
  }
}
