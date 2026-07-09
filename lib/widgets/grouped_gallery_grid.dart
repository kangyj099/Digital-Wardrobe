import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import 'selectable_gallery_tile.dart';

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
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: density,
        crossAxisSpacing: AppSpacing.galleryGap,
        mainAxisSpacing: AppSpacing.galleryGap,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableGalleryTile(key: ValueKey(item.id), item: item, onTap: () => onItemTap(item));
      },
    );
  }
}
