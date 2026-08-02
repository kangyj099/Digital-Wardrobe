import 'package:flutter/material.dart';
import '../models/composition.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

/// `Composition` 1개를 표시하는 갤러리 타일. 아직 아트보드 스냅샷 렌더링 기능이 없다(모델에
/// 썸네일 필드 자체가 없음) — 그래서 `SelectableGalleryTile`처럼 옷 이미지를 대표사진으로
/// 꽂지 않고, 동일한 배경(`semantic.gray200`) 위에 코디 이름 텍스트 + (있으면) 계절 배지만
/// 표시한다. 배지 위치/스타일은 `SelectableGalleryTile`의 카테고리 라벨 패턴을 따르되
/// `StatusBadge`(경고색 고정)는 재사용하지 않는다 — 계절은 경고 의미가 아니기 때문.
class CompositionGalleryTile extends StatelessWidget {
  const CompositionGalleryTile({
    super.key,
    required this.composition,
    required this.onTap,
    this.onLongPress,
    this.multiSelectMode = false,
    this.selected = false,
  });

  final Composition composition;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool multiSelectMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final season = composition.season;
    return Semantics(
      button: true,
      label: (season == null ? composition.name : '${composition.name}, ${season.label}') +
          (selected ? ', 선택됨' : ''),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        composition.name,
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  if (season != null)
                    GalleryMetaLabel(label: season.label, maxWidth: constraints.maxWidth),
                  if (multiSelectMode)
                    Positioned(
                      top: AppSpacing.xxs,
                      right: AppSpacing.xxs,
                      child: MultiSelectCheckmark(selected: selected),
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
