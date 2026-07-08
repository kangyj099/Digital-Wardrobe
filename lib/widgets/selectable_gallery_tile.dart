import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import 'status_badge.dart';

class SelectableGalleryTile extends StatelessWidget {
  const SelectableGalleryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  final ClothingItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.color}, 착용 ${item.wearCount}회'
          '${item.isIncomplete ? ", 미완성" : ""}',
      child: GestureDetector(
        onTap: item.isIncomplete ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: item.isIncomplete ? 0.4 : 1.0),
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: item.imagePath.isNotEmpty
                    ? Image.asset(item.imagePath, fit: BoxFit.cover)
                    : const SizedBox.shrink(),
              ),
              if (item.isIncomplete)
                const Positioned(top: AppSpacing.xxs, left: AppSpacing.xxs, child: StatusBadge(label: '미완성')),
              Positioned(
                left: AppSpacing.xxs,
                bottom: AppSpacing.xxs,
                right: AppSpacing.xxs,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
