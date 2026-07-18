import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'app_gallery_grid.dart';
import 'selectable_gallery_tile.dart';

/// `List<ClothingItem>` + [SelectableGalleryTile] 매핑 전용 어댑터 — 순수 그리드 레이아웃
/// 메커니즘(패딩/density→crossAxisCount/gap/aspectRatio) 자체는 [AppGalleryGrid]가 담당한다.
class GroupedGalleryGrid extends StatelessWidget {
  const GroupedGalleryGrid({
    super.key,
    required this.items,
    required this.density,
    required this.onItemTap,
    this.onIncompleteTap,
    this.controller,
    this.topSpacing = 0,
  });

  final List<ClothingItem> items;
  final int density;
  final void Function(ClothingItem item) onItemTap;

  /// [SelectableGalleryTile.onIncompleteTap]으로 그대로 전달 — null(기본)이면 미완성
  /// 항목 탭이 비활성화된 기존 동작 유지. 선택 모달(`selectionMode`)에서만 채워진다.
  final void Function(ClothingItem item)? onIncompleteTap;

  /// [AppScrollContainer]가 연결하는 스크롤 컨트롤러 — [AppGalleryGrid]로 그대로 전달.
  final ScrollController? controller;

  /// Content Spacer(스펙 §4) — [AppGalleryGrid.topSpacing]으로 그대로 전달.
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: items.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableGalleryTile(
          key: ValueKey(item.id),
          item: item,
          onTap: () => onItemTap(item),
          onIncompleteTap: onIncompleteTap == null ? null : () => onIncompleteTap!(item),
        );
      },
    );
  }
}
