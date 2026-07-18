import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/bottom_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/top_gradient_overlay.dart';

/// `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`
/// §2/§5 — 콘텐츠를 마스킹하지 않는 Overlay 그라디언트라는 계약을 검증한다: `visible`에 따라
/// opacity가 0↔0.85로 전환되고, `ShaderMask`/`ClipPath`를 전혀 쓰지 않는다.
void main() {
  testWidgets('TopGradientOverlay는 visible=false면 opacity 0, true면 0.85이고 ShaderMask/ClipPath를 쓰지 않는다',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Stack(children: [TopGradientOverlay(visible: false)])),
      ),
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(ClipPath), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Stack(children: [TopGradientOverlay(visible: true)])),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.85,
    );
  });

  testWidgets(
      'BottomGradientOverlay는 visible=false면 opacity 0, true면 0.85이고 ShaderMask/ClipPath를 쓰지 않는다',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Stack(children: [BottomGradientOverlay(visible: false)])),
      ),
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(ClipPath), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Stack(children: [BottomGradientOverlay(visible: true)])),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.85,
    );
  });
}
