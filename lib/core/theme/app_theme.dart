import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.cyan,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shadowColor: Color(0x332C65A4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 18),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: .94),
      indicatorColor: AppColors.primary,
      height: 78,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textMuted,
          size: 21,
        ),
      ),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'M PLUS Rounded 1c',
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
  );
}
