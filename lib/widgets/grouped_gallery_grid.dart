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
  });

  final List<ClothingItem> items;
  final int density;
  final void Function(ClothingItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: items.length,
      density: density,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableGalleryTile(key: ValueKey(item.id), item: item, onTap: () => onItemTap(item));
      },
    );
  }
}
