import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// 앱 전역 라이트/다크 테마 상태 — `04_설정.md`의 "다크 모드" `Switch`가 이 값을 토글한다.
/// 시스템(OS) 테마 추종은 요구사항이 아니라([ThemeMode.system] 미사용), 상태는 항상
/// [ThemeMode.light] 또는 [ThemeMode.dark] 둘 중 하나로 고정된다. Hi-Fi mock 단계라 세션
/// 내 메모리 상태로만 유지하며 영속화(SharedPreferences 등)는 범위 밖이다.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void set(bool isDark) => state = isDark ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
