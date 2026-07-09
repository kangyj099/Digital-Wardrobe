import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/settings_providers.dart';
import 'package:digittal_wardrobe/screens/settings_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';

void main() {
  testWidgets('SettingsScreen은 알림 로우와 로그아웃 로우 2개만 렌더링한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
      ),
    );

    expect(find.text('알림'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('알림 스위치를 탭하면 확인 없이 즉시 상태가 전환된다', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SettingsScreen();
            },
          ),
        ),
      ),
    );

    final before = capturedRef.read(notificationEnabledProvider);
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(capturedRef.read(notificationEnabledProvider), !before);
  });

  testWidgets('로그아웃 탭 시 confirm 없이 즉시 전환되고 Toast의 실행취소로 복원할 수 있다', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SettingsScreen();
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('로그아웃'));
    await tester.pump();
    // SnackBar 진입 애니메이션이 끝날 때까지 진행 — 자동 소멸(4초) 전에 멈춰야
    // 실행취소 버튼을 탭할 수 있다.
    await tester.pump(const Duration(milliseconds: 750));

    // 블로킹 confirm 다이얼로그 없이 즉시 로그아웃 상태로 전환됨.
    expect(capturedRef.read(isLoggedInProvider), isFalse);
    expect(find.text('로그아웃되었습니다'), findsOneWidget);

    await tester.tap(find.text('실행취소'));
    await tester.pump();

    expect(capturedRef.read(isLoggedInProvider), isTrue);
  });
}
