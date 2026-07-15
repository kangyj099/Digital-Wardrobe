import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import 'gallery_meta_label.dart';
import 'status_badge.dart';

class SelectableGalleryTile extends StatelessWidget {
  const SelectableGalleryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onIncompleteTap,
    this.selected = false,
  });

  final ClothingItem item;
  final VoidCallback onTap;

  /// 미완성 항목 탭 핸들러 — 기본값 null이면 기존과 동일하게 탭 자체가 비활성화된다
  /// (네이티브 진입 시 동작, 변경 없음). 선택 모달(`selectionMode`)에서는 완성 화면으로
  /// 이동시키는 콜백을 넘겨 탭을 되살린다(`_공통 규칙.md` "미완성/휴지통 항목은 바인딩
  /// 불가 — 터치하면 해당 항목의 완성 화면으로 이동").
  final VoidCallback? onIncompleteTap;
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
        onTap: item.isIncomplete ? onIncompleteTap : onTap,
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
                  GalleryMetaLabel(label: item.category.label, maxWidth: constraints.maxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
