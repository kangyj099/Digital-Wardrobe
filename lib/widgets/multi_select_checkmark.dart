import 'package:flutter/material.dart';

/// 다중선택 모드의 타일 우상단 체크서클 — 4개 도메인 타일(`SelectableGalleryTile` 등)이
/// 공유하는 순수 UI 원자(도메인 정보 없음). 미선택=아웃라인 원, 선택=프라이머리 채움+체크.
class MultiSelectCheckmark extends StatelessWidget {
  const MultiSelectCheckmark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colorScheme.primary : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: colorScheme.primary, width: selected ? 0 : 1.5),
      ),
      child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }
}
