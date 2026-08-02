import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_providers.dart';
import 'providers/trash_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  final container = ProviderContainer();
  purgeExpiredTrash(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DigitalWardrobeApp(),
    ),
  );
}

/// [MaterialScrollBehavior]의 기본 `dragDevices`는 마우스를 포함하지 않는다(터치/스타일러스/
/// 트랙패드만) — Windows 데스크톱 빌드에서 실제 마우스 클릭+드래그로는 어떤 스크롤 위젯도
/// (특히 마우스 휠로 대체할 수 없는 가로 스와이프 `PageView` — 스타일일지 열람 대표이미지→
/// 코디 슬롯 캐러셀 등) 반응하지 않는 근본 원인이었다(사용자 실사용 버그 리포트,
/// 2026-07-29). `dragDevices`에 [PointerDeviceKind.mouse]를 더해 앱 전역에서 마우스
/// 클릭+드래그도 스크롤/스와이프로 인식되게 한다.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class DigitalWardrobeApp extends ConsumerWidget {
  const DigitalWardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Digital Wardrobe',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scrollBehavior: AppScrollBehavior(),
      routerConfig: router,
    );
  }
}
