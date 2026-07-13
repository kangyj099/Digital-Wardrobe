import 'dart:ui';
import 'package:flutter/material.dart';

/// [GlassPill]과 동일한 프로스티드글래스 톤(블러/보더/그림자 값)을 원형 버튼에 맞춰
/// 재구성한 공용 primitive — 밀도 토글, 뒤로가기, 정렬, 기능 미정 스텁 버튼 등 원형
/// floating control이 전부 이 위젯 하나로 개별 감싸져야 한다(`docs/history/Decision.md`
/// "Header/HUD Pinned Rule").
///
/// 지름은 Flutter Material이 정의하는 최소 탭 타깃 상수([kMinInteractiveDimension], 48)를
/// 그대로 채택 — 접근성 표준을 그대로 쓰는 것이라 뷰포트 역산 등 금지된 하드코딩 패턴에
/// 해당하지 않으며(기존 `FrostedBackButton` 주석과 동일 근거), [GlassPill]과 높이를
/// 맞춰야 `AppMainScaffold`의 Content Spacer 고정값 계산이 어긋나지 않는다.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

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
              icon: Icon(icon),
              tooltip: tooltip,
            ),
          ),
        ),
      ),
    );
  }
}
