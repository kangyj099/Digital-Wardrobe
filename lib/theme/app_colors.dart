import 'package:flutter/material.dart';

/// 팔레트 한 세트를 표현하는 데이터 클래스 — 이 필드 6개를 채우면
/// 라이트 테마의 ColorScheme/AppSemanticColors가 전부 파생된다.
class ColorPalette {
  const ColorPalette({
    required this.name,
    required this.gray50,
    required this.gray100,
    required this.primary300,
    required this.primary500,
    required this.accent,
    required this.text,
  });

  final String name;
  final Color gray50;
  final Color gray100;
  final Color primary300;
  final Color primary500;
  final Color accent;
  final Color text;
  // bg는 두 팔레트 모두 gray50과 동일한 값이라 별도 필드 없이 gray50을 재사용한다.

  static const current = ColorPalette(
    name: 'Current (Brand Guide Pass 2)',
    gray50: Color(0xFFF7F6F3),
    gray100: Color(0xFFDDD4C8),
    primary300: Color(0xFFC5D3C7), // 기존 secondary(세이지)
    primary500: Color(0xFF394550), // 기존 primary
    accent: Color(0xFFC5D3C7), // 기존엔 accent 개념이 별도로 없어 secondary와 동일값 재사용
    text: Color(0xFF2B2D30),
  );

  static const palette1 = ColorPalette(
    name: 'Palette 1',
    gray50: Color(0xFFF8F5EF),
    gray100: Color(0xFFE9E0D2),
    primary300: Color(0xFFAFC8E8),
    primary500: Color(0xFF6D8DB5),
    accent: Color(0xFFC8D4C4),
    text: Color(0xFF2F3438),
  );

  static const palette2 = ColorPalette(
    name: 'Palette 2',
    gray50: Color(0xFFFAF7F2),
    gray100: Color(0xFFE8DDD1),
    primary300: Color(0xFFBFDDF4),
    primary500: Color(0xFF577899),
    accent: Color(0xFFB9B6B1),
    text: Color(0xFF2E3338),
  );
}

/// 활성 팔레트 — 이 한 줄만 바꾸면 앱 전체 라이트 테마 색이 바뀐다.
const ColorPalette activePalette = ColorPalette.current;

/// Brand Guide Pass 2(T1~T3) 값을 Material 3 ColorScheme으로 매핑.
/// 값 자체는 임시 확정값 — Brand Guide Pass 3 정식 확정 시 이 파일만 교체.
class AppColors {
  AppColors._();

  static ColorScheme get light => ColorScheme(
        brightness: Brightness.light,
        primary: activePalette.primary500,
        onPrimary: activePalette.gray50,
        secondary: activePalette.accent,
        onSecondary: activePalette.text,
        surface: activePalette.gray50,
        onSurface: activePalette.text,
        error: const Color(0xFFA34B50), // 팔레트에 없는 role — 기존 고정값 유지
        onError: activePalette.gray50,
      );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF93B5CC),
    onPrimary: Color(0xFF232B31),
    secondary: Color(0xFF8FA890),
    onSecondary: Color(0xFF232B31),
    surface: Color(0xFF2C3841),
    onSurface: Color(0xFFEDE9E1),
    error: Color(0xFFD98A8E),
    onError: Color(0xFF1D262D),
  );
}

/// T2(Neutral Gray) + T3(Semantic State) 역할 — Material 3 ColorScheme에
/// 없는 역할이라 ThemeExtension으로 별도 정의.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.warning,
    required this.success,
    required this.background,
    required this.onBackground,
    required this.primaryLight,
    required this.accent,
  });

  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color warning;
  final Color success;
  final Color background;
  final Color onBackground;
  final Color primaryLight;
  final Color accent;

  static AppSemanticColors get light => AppSemanticColors(
        gray50: activePalette.gray50,
        gray100: activePalette.gray100,
        gray200: const Color(0xFFCBC0B0),
        gray300: const Color(0xFFB3A99A),
        gray400: const Color(0xFF948E86),
        gray500: const Color(0xFF6E7679),
        gray600: const Color(0xFF52606A),
        gray700: const Color(0xFF3E4C56),
        gray800: const Color(0xFF2C3841),
        gray900: const Color(0xFF1D262D),
        warning: const Color(0xFFB98A3D),
        success: const Color(0xFF394550),
        background: activePalette.gray50,
        onBackground: activePalette.text,
        primaryLight: activePalette.primary300,
        accent: activePalette.accent,
      );

  static const dark = AppSemanticColors(
    gray50: Color(0xFFF7F6F3),
    gray100: Color(0xFFDDD4C8),
    gray200: Color(0xFFCBC0B0),
    gray300: Color(0xFFB3A99A),
    gray400: Color(0xFF948E86),
    gray500: Color(0xFF6E7679),
    gray600: Color(0xFF52606A),
    gray700: Color(0xFF3E4C56),
    gray800: Color(0xFF2C3841),
    gray900: Color(0xFF1D262D),
    warning: Color(0xFFD9A05C),
    success: Color(0xFF93B5CC),
    background: Color(0xFF1D262D),
    onBackground: Color(0xFFEDE9E1),
    primaryLight: Color(0xFF93B5CC),
    accent: Color(0xFF8FA890),
  );

  @override
  AppSemanticColors copyWith({
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? warning,
    Color? success,
    Color? background,
    Color? onBackground,
    Color? primaryLight,
    Color? accent,
  }) {
    return AppSemanticColors(
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      gray50: Color.lerp(gray50, other.gray50, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      background: Color.lerp(background, other.background, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
    );
  }
}
