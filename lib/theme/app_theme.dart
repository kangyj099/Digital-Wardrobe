import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, AppSemanticColors.light);
  static ThemeData get dark => _build(AppColors.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme colorScheme, AppSemanticColors semantic) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: AppTypography.textTheme(colorScheme.onSurface),
      extensions: [semantic],
    );
  }
}
