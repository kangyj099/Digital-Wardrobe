import 'package:flutter/material.dart';

/// T4(Typography Roles) — Material 3 기본 type scale 크기 채택.
/// 전 역할 Pretendard 단일화(옷장 메인 재설계 시 KoPubDotum 제거).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface) {
    const pretendard = 'Pretendard';

    TextStyle style(String family, double size, FontWeight weight) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: onSurface,
      );
    }

    return TextTheme(
      displayLarge: style(pretendard, 57, FontWeight.w400),
      displayMedium: style(pretendard, 45, FontWeight.w400),
      displaySmall: style(pretendard, 36, FontWeight.w400),
      headlineLarge: style(pretendard, 32, FontWeight.w600),
      headlineMedium: style(pretendard, 28, FontWeight.w600),
      headlineSmall: style(pretendard, 24, FontWeight.w600),
      titleLarge: style(pretendard, 22, FontWeight.w600),
      titleMedium: style(pretendard, 16, FontWeight.w600),
      titleSmall: style(pretendard, 14, FontWeight.w600),
      bodyLarge: style(pretendard, 16, FontWeight.w500),
      bodyMedium: style(pretendard, 14, FontWeight.w500),
      bodySmall: style(pretendard, 12, FontWeight.w500),
      labelLarge: style(pretendard, 14, FontWeight.w500),
      labelMedium: style(pretendard, 12, FontWeight.w500),
      labelSmall: style(pretendard, 11, FontWeight.w500),
    );
  }
}
