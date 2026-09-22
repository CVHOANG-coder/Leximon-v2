import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceBlue,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: Color(0xFFFFE8EF),
      onSecondaryContainer: Color(0xFF7A2945),
      tertiary: AppColors.highlight,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: Color(0xFFFFEBDD),
      onTertiaryContainer: Color(0xFF73391D),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.surfaceSoft,
      surfaceContainerHigh: AppColors.surfaceBlue,
      outline: Color(0xFFD8CDE8),
      outlineVariant: AppColors.divider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shadowColor: Color(0x334B347D),
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
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x244B347D),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: AppColors.divider),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface.withValues(alpha: .96),
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
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.primary.withValues(alpha: .36)
              : AppColors.primary,
        ),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(
          AppColors.secondary.withValues(alpha: .16),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          AppColors.primary.withValues(alpha: .3),
        ),
        elevation: const WidgetStatePropertyAll(2),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.primary, width: 1.4),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(AppColors.primary),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.textMuted),
      labelStyle: TextStyle(color: AppColors.textSecondary),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: AppColors.secondary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: AppColors.secondary, width: 1.6),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceSoft,
      selectedColor: AppColors.surfaceBlue,
      disabledColor: AppColors.surfaceSoft.withValues(alpha: .7),
      side: const BorderSide(color: AppColors.divider),
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      secondaryLabelStyle: const TextStyle(color: AppColors.primaryDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceBlue,
      circularTrackColor: AppColors.surfaceBlue,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surface,
      modalBarrierColor: Color(0x66282238),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: AppColors.highlight,
      behavior: SnackBarBehavior.floating,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x557C5CFC),
      selectionHandleColor: AppColors.primary,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'M PLUS Rounded 1c',
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
  );
}
