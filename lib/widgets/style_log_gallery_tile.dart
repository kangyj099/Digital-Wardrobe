import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

/// `StyleLog` 1개를 표시하는 갤러리 타일 — `coverImagePath`로 대표이미지를 렌더링하고
/// (`SelectableGalleryTile`의 `Image.asset(... fit: BoxFit.contain)` 패턴과 동일), 하단에
/// 착용 날짜(+있으면 장소) 라벨을 얹는다.
class StyleLogGalleryTile extends StatelessWidget {
  const StyleLogGalleryTile({
    super.key,
    required this.styleLog,
    required this.onTap,
    this.onLongPress,
    this.multiSelectMode = false,
    this.selected = false,
  });

  final StyleLog styleLog;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool multiSelectMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final wornDate = styleLog.wornDate;
    // 착용일은 안 적을 수 있다 — 그 경우 빈칸 대신 명시적으로 없음을 밝힌다.
    final dateLabel =
        wornDate == null ? '날짜 없음' : wornDate.toIso8601String().substring(0, 10);
    final metaLabel = styleLog.location.isEmpty ? dateLabel : '$dateLabel · ${styleLog.location}';
    return Semantics(
      button: true,
      label: metaLabel + (selected ? ', 선택됨' : ''),
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
                  Positioned.fill(
                    child: styleLog.coverImagePath.isNotEmpty
                        ? Image.asset(styleLog.coverImagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  GalleryMetaLabel(label: metaLabel, maxWidth: constraints.maxWidth),
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
