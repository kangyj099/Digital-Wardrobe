import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// `StyleLog` 1개를 표시하는 갤러리 타일 — `coverImagePath`로 대표이미지를 렌더링하고
/// (`SelectableGalleryTile`의 `Image.asset(... fit: BoxFit.contain)` 패턴과 동일), 하단에
/// 착용 날짜(+있으면 장소) 라벨을 얹는다.
class StyleLogGalleryTile extends StatelessWidget {
  const StyleLogGalleryTile({
    super.key,
    required this.styleLog,
    required this.onTap,
  });

  final StyleLog styleLog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final dateLabel = styleLog.wornDate.toIso8601String().substring(0, 10);
    final metaLabel = styleLog.location.isEmpty ? dateLabel : '$dateLabel · ${styleLog.location}';
    return Semantics(
      button: true,
      label: metaLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: semantic.gray200),
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
                          metaLabel,
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
