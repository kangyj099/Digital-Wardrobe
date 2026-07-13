import 'package:flutter/material.dart';

/// T4(Typography Roles) — Material 3 기본 type scale 크기 채택.
/// 전 역할 Pretendard 단일화(옷장 메인 재설계 시 KoPubDotum 제거).
class AppTypography {
  AppTypography._();

  static const String _pretendard = 'Pretendard';

  /// `actionMinimal` — M3 표준 15-role `TextTheme`에 없는 보조 역할.
  /// "선택" 같은 보조 액션 버튼 전용, 앱 전체에서 가장 작은 텍스트가 되도록 고정
  /// (Brand Guide `01_BrandGuid.md` §3, `Decision.md` "Typography Pass 3 확정" 참고).
  /// color는 의도적으로 지정하지 않는다 — 이 role을 쓰는 `Text`가 상위 위젯(예: `TextButton`의
  /// foreground color)의 색을 그대로 상속하도록 비워둔다.
  static const TextStyle actionMinimal = TextStyle(
    fontFamily: _pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static TextTheme textTheme(Color onSurface) {
    const pretendard = _pretendard;

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
      labelSmall: style(pretendard, 13, FontWeight.w500),
    );
  }
}
