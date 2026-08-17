import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/app_localizations.dart';

const streakIconAsset = 'assets/svgs/streak.svg';
const streakAccentColor = Color(0xFFFF5F72);
const streakBackgroundColor = Color(0xFFFFF1F3);

class StreakIcon extends StatelessWidget {
  const StreakIcon({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    streakIconAsset,
    key: const ValueKey(streakIconAsset),
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticsLabel: context.l10n.text('streakDaysLabel'),
  );
}
