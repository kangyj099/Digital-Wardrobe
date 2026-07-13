import 'package:flutter/material.dart';
import 'glass_circle_button.dart';

/// 하단 좌측 뒤로가기 버튼 — [GlassCircleButton](공용 프로스티드글래스 원형 버튼 primitive)의
/// 얇은 어댑터. `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표
/// 기준, "뒤로가기 O" 화면 전체에서 공용으로 쓰인다.
class FrostedBackButton extends StatelessWidget {
  const FrostedBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCircleButton(icon: Icons.arrow_back, onTap: onTap, tooltip: '뒤로가기');
  }
}
