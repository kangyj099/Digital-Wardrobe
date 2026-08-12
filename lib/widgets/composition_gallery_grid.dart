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
    this.deletedClothingItemIds = const {},
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

  /// 휴지통으로 이동(소프트 삭제)된 옷 id 집합 — 스펙("옷 삭제 시 코디 캐스케이드 처리"
  /// §"코디 목록: 삭제된 옷 포함 코디는 타일에 작은 배지") 판정용. `selectedIds`와 같은
  /// 패턴으로 호출부(`composition_main_screen.dart`)가 `closetItemsProvider`를 한 번만
  /// watch해 만든 id 집합을 그대로 넘긴다 — 각 코디가 이 집합에 속한 옷을 참조하는지는
  /// 이 어댑터가 `composition.items`를 순회하며 매핑 시점에 판정해
  /// [CompositionGalleryTile.hasDeletedItem]으로 변환한다.
  final Set<String> deletedClothingItemIds;

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
          hasDeletedItem: composition.items.any((p) => deletedClothingItemIds.contains(p.clothingItemId)),
        );
      },
    );
  }
}
