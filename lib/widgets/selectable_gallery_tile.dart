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

  /// 오늘(2026-07-10) 기준 기본 밀도(AppDensity.mid=2)에서 렌더링되는 타일 폭 대비,
  /// 라벨 박스 여백이 기존 고정값 4px(AppSpacing.xxs)과 같아지도록 역산한 비율.
  /// 산출: 실행 창 기본 폭 1280px(windows/runner/main.cpp Win32Window::Size) 기준
  /// 컬럼 폭 = (1280 - AppSpacing.sm*2 - AppSpacing.galleryGap*(density-1)) / density
  ///         = (1280 - 12*2 - 1*(2-1)) / 2 = 627.5px
  /// ratio = 4 / 627.5 ≈ 0.006375
  static const double _labelMarginRatio = 4 / 627.5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.color}, 착용 ${item.wearCount}회'
          '${item.isIncomplete ? ", 미완성" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: item.isIncomplete ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: item.isIncomplete ? 0.4 : 1.0),
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labelMargin = constraints.maxWidth * _labelMarginRatio;
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
                    left: labelMargin,
                    bottom: labelMargin,
                    right: labelMargin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        item.category.label,
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
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
