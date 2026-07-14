import 'package:flutter/material.dart';
import 'glass_circle_button.dart';

/// 선택 모달(Main 화면 3개를 `selectionMode: true`로 재호출할 때)의 우상단 닫기 버튼 —
/// [GlassCircleButton] 얇은 어댑터. [FrostedBackButton]과 동일한 패턴이지만, 선택
/// 모달은 "뒤로가기"가 아니라 "별도(닫기 X버튼)"를 쓴다(`docs/superpowers/specs/
/// 2026-07-12-cross-screen-ui-shell-design.md` §1 표 — 선택 모달 2행).
class FrostedCloseButton extends StatelessWidget {
  const FrostedCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCircleButton(icon: Icons.close, onTap: onTap, tooltip: '닫기');
  }
}
