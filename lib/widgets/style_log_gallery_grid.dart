import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_spacing.dart';
import 'app_gallery_grid.dart';
import 'style_log_gallery_tile.dart';

/// `List<StyleLog>` + [StyleLogGalleryTile] 매핑 전용 어댑터 — `GroupedGalleryGrid`와 동일한
/// 얇은 어댑터 패턴이지만, 스타일일지 메인에는 밀도 토글 UI 자체가 없어(`AppDensity`
/// 주석 — "Grouped Main 그리드(옷장/코디) 전용") `density` 파라미터를 받지 않고 내부에서
/// `AppDensity.mid`를 고정 사용한다.
class StyleLogGalleryGrid extends StatelessWidget {
  const StyleLogGalleryGrid({
    super.key,
    required this.logs,
    required this.onItemTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<StyleLog> logs;
  final void Function(StyleLog styleLog) onItemTap;

  /// [StyleLogGalleryTile.onLongPress]로 그대로 전달 — 다중선택 모드 진입 트리거.
  final void Function(StyleLog styleLog)? onItemLongPress;

  /// [StyleLogGalleryTile.multiSelectMode]로 그대로 전달.
  final bool multiSelectMode;

  /// 선택된 항목 id 집합 — [StyleLogGalleryTile.selected]로 `log.id` 포함 여부를 변환해 전달.
  final Set<String> selectedIds;

  /// [AppScrollContainer]가 연결하는 스크롤 컨트롤러 — [AppGalleryGrid]로 그대로 전달.
  final ScrollController? controller;

  /// Content Spacer(스펙 §4) — [AppGalleryGrid.topSpacing]으로 그대로 전달.
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: logs.length,
      density: AppDensity.mid,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final log = logs[index];
        return StyleLogGalleryTile(
          key: ValueKey(log.id),
          styleLog: log,
          onTap: () => onItemTap(log),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(log),
          multiSelectMode: multiSelectMode,
          selected: selectedIds.contains(log.id),
        );
      },
    );
  }
}
