import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8F5FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF3EEFF);
  static const surfaceBlue = Color(0xFFF0EBFF);
  static const primary = Color(0xFF7C5CFC);
  static const primaryDark = Color(0xFF4B347D);
  static const secondary = Color(0xFFFF6F91);
  static const highlight = Color(0xFFFF9F68);
  static const gradientMid = Color(0xFFC05CFF);
  static const cyan = secondary;
  static const yellow = Color(0xFFFFC928);
  static const green = Color(0xFF20C988);
  static const orange = highlight;
  static const purple = gradientMid;
  static const pink = secondary;
  static const textPrimary = Color(0xFF282238);
  static const textSecondary = Color(0xFF6E667D);
  static const textMuted = Color(0xFF9A91A8);
  static const divider = Color(0xFFE8E0F2);
  static const success = Color(0xFF20C988);

  static const primaryGradient = <Color>[primary, gradientMid, secondary];
  static const onboardingPrimaryGradient = <Color>[primary, secondary];
  static const onboardingPrimaryGradientStops = <double>[0, 1];
}
