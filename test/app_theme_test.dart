import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leximon/core/constants/app_colors.dart';
import 'package:leximon/core/theme/app_theme.dart';

void main() {
  test('uses the violet and coral brand palette', () {
    final theme = buildAppTheme();

    expect(AppColors.primary, const Color(0xFF7C5CFC));
    expect(AppColors.secondary, const Color(0xFFFF6F91));
    expect(AppColors.highlight, const Color(0xFFFF9F68));
    expect(AppColors.background, const Color(0xFFF8F5FF));
    expect(AppColors.textPrimary, const Color(0xFF282238));
    expect(
      AppColors.primaryGradient,
      const [Color(0xFF7C5CFC), Color(0xFFC05CFF), Color(0xFFFF6F91)],
    );
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.secondary);
    expect(theme.colorScheme.tertiary, AppColors.highlight);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}
