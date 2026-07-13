import 'package:flutter/material.dart';

/// 스크롤 하단 힌트 — [TopGradientOverlay]의 하단 대응 위젯.
/// `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`
/// §2/§5·§6 참고(콘텐츠 마스킹 금지, Overlay Layer로만 존재). 표시 여부([visible])는
/// 호출부([AppScrollContainer])가 `scrollTop < scrollHeight - clientHeight - 2px`
/// (아래로 더 스크롤 가능)을 계산해 넘겨준다.
class BottomGradientOverlay extends StatelessWidget {
  const BottomGradientOverlay({super.key, required this.visible});

  final bool visible;

  /// 스펙 §2 "Bottom Gradient" 수치 그대로(height=48px, opacity=0.85, transition .3s ease).
  static const double height = 48;
  static const double _visibleOpacity = 0.85;
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? _visibleOpacity : 0,
          duration: _fadeDuration,
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [surface, surface.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
