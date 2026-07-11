import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.color}, 착용 ${item.wearCount}회'
          '${item.isIncomplete ? ", 미완성" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: item.isIncomplete ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: semantic.gray200,
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: item.imagePath.isNotEmpty
                        ? Image.asset(item.imagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  if (item.isIncomplete)
                    const Positioned(top: AppSpacing.xxs, left: AppSpacing.xxs, child: StatusBadge(label: '미완성')),
                  Positioned(
                    left: AppSpacing.xxs,
                    bottom: AppSpacing.xxs,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth - AppSpacing.xxs * 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: semantic.gray50.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          item.category.label,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
