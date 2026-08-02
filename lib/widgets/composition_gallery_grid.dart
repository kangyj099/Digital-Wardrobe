import 'package:flutter/material.dart';
import '../models/composition.dart';
import 'app_gallery_grid.dart';
import 'composition_gallery_tile.dart';

/// `List<Composition>` + [CompositionGalleryTile] 매핑 전용 어댑터 — `GroupedGalleryGrid`와
/// 동일한 얇은 어댑터 패턴. 순수 그리드 레이아웃 메커니즘(패딩/density→crossAxisCount/gap/
/// aspectRatio) 자체는 [AppGalleryGrid]가 담당한다.
class CompositionGalleryGrid extends StatelessWidget {
  const CompositionGalleryGrid({
    super.key,
    required this.compositions,
    required this.density,
    required this.onItemTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<Composition> compositions;
  final int density;
  final void Function(Composition composition) onItemTap;

  /// [CompositionGalleryTile.onLongPress]로 그대로 전달 — 다중선택 모드 진입 트리거.
  final void Function(Composition composition)? onItemLongPress;

  /// [CompositionGalleryTile.multiSelectMode]로 그대로 전달.
  final bool multiSelectMode;

  /// 선택된 항목 id 집합 — [CompositionGalleryTile.selected]로 `composition.id` 포함 여부를
  /// 변환해 전달.
  final Set<String> selectedIds;

  /// [AppScrollContainer]가 연결하는 스크롤 컨트롤러 — [AppGalleryGrid]로 그대로 전달.
  final ScrollController? controller;

  /// Content Spacer(스펙 §4) — [AppGalleryGrid.topSpacing]으로 그대로 전달.
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: compositions.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final composition = compositions[index];
        return CompositionGalleryTile(
          key: ValueKey(composition.id),
          composition: composition,
          onTap: () => onItemTap(composition),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(composition),
          multiSelectMode: multiSelectMode,
          selected: selectedIds.contains(composition.id),
        );
      },
    );
  }
}
