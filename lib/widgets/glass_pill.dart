import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 프로스티드글래스(블러+반투명 배경+얇은 화이트 보더+soft shadow) 캡슐형(pill) 컨테이너 —
/// `docs/history/Decision.md`의 "Header/HUD Pinned Rule"이 요구하는 "시각적 스타일은
/// 공유하되, 여러 조작 요소를 하나의 Container/Row로 병합하지 않는다"를 만족시키는 공용
/// primitive. 카테고리 토글, 계절 필터, "선택" 버튼 등 floating pill control은 전부 이
/// 위젯 하나로 개별 감싸야 하며, 여러 컨트롤을 하나의 [GlassPill] 안에 함께 담지 않는다
/// (Pinned Rule 위반).
///
/// 높이를 [kMinInteractiveDimension](48)로 고정하는 이유: `AppMainScaffold`의 Content
/// Spacer(스펙 §4)가 실측 대신 알려진 고정값으로 헤더 높이를 계산하므로, 모든 floating
/// control(이 위젯과 [GlassCircleButton])이 같은 높이를 공유해야 그 계산이 어긋나지 않는다.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // 보더/그림자는 ClipRRect 바깥의 Container에서 그린다 — 안 그러면 BackdropFilter의
    // 클립 경계에서 그림자가 잘려 보이지 않는다.
    return Container(
      height: kMinInteractiveDimension,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
            child: child,
          ),
        ),
      ),
    );
  }
}
