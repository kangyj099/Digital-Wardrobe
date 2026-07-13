import 'package:flutter/material.dart';

/// 스크롤 상단 힌트 — `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`
/// §2/§5·§6. 콘텐츠를 마스킹하지 않고 그 "위"에 얹는 Overlay 그라디언트라 `ShaderMask`/
/// `ClipPath` 등 콘텐츠 마스킹 방식은 절대 쓰지 않는다(스펙 §5 AI Constraints). 표시 여부
/// ([visible])는 호출부([AppScrollContainer])가 `ScrollController`를 관찰해 계산한
/// `scrollTop > 2px` 결과를 그대로 넘겨받는다 — 이 위젯 자체는 스크롤 상태를 모른다.
class TopGradientOverlay extends StatelessWidget {
  const TopGradientOverlay({super.key, required this.visible});

  final bool visible;

  /// 스펙 §2 "Top Gradient" 수치 그대로(height=40px, opacity=0.85, transition .3s ease) —
  /// 이 프로젝트의 공식 스펙 문서가 Source of Truth인 값이라 매직넘버 TechDebt 등록 대상이
  /// 아니다(이름 있는 const + 출처 주석, 기존 `CrossReferenceLinkBar.height` Review 판정과
  /// 동일 근거).
  static const double height = 40;
  static const double _visibleOpacity = 0.85;
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        // Overlay일 뿐 인터랙션을 가로채면 안 된다 — 아래 스크롤 콘텐츠의 제스처/탭을
        // 그대로 통과시킨다.
        child: AnimatedOpacity(
          opacity: visible ? _visibleOpacity : 0,
          duration: _fadeDuration,
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [surface, surface.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
