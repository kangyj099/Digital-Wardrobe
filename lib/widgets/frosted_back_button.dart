import 'dart:ui';
import 'package:flutter/material.dart';

/// 하단 좌측 뒤로가기 버튼 — [OverlayHeader]와 동일한 프로스티드글래스 톤(블러/보더/그림자 값)을
/// 원형 버튼에 맞춰 재구성한 것. 지름은 임의값이 아니라 Flutter Material이 정의하는 최소 탭
/// 타깃 상수(kMinInteractiveDimension, 48)를 그대로 채택 — 접근성 표준을 그대로 쓰는 것이므로
/// 뷰포트 역산 등 금지된 하드코딩 패턴에 해당하지 않는다.
///
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준, "뒤로가기 O"
/// 화면 전체에서 공용으로 쓰인다(원래 `closet_main_screen.dart`의 private `_FrostedBackButton`을
/// 추출).
class FrostedBackButton extends StatelessWidget {
  const FrostedBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: kMinInteractiveDimension,
                height: kMinInteractiveDimension,
              ),
              onPressed: onTap,
              icon: const Icon(Icons.arrow_back),
              tooltip: '뒤로가기',
            ),
          ),
        ),
      ),
    );
  }
}
