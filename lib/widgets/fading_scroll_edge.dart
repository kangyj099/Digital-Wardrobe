import 'package:flutter/material.dart';

/// 스크롤 가능 영역의 상단이 콘텐츠에 잘리지 않고 자연스럽게 사라지도록 하는 페이드 래퍼 —
/// `_공통 규칙.md` "스크롤 가능 영역은 그라데이션/여백 등으로 스크롤 가능함을 암시"의 구현.
///
/// 원래 `closet_main_screen.dart`가 `GroupedGalleryGrid`를 감싸던 인라인 `ShaderMask`
/// (상단 페이드, `BlendMode.dstIn` + `LinearGradient` stops `[0.0, 0.06]`)를 그대로 추출한
/// 것 — 임의의 [child]를 감싸는 재사용 가능한 wrapper.
class FadingScrollEdge extends StatelessWidget {
  const FadingScrollEdge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0.0, 0.06],
      ).createShader(rect),
      child: child,
    );
  }
}
