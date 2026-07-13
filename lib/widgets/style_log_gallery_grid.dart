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
  });

  final List<StyleLog> logs;
  final void Function(StyleLog styleLog) onItemTap;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: logs.length,
      density: AppDensity.mid,
      itemBuilder: (context, index) {
        final log = logs[index];
        return StyleLogGalleryTile(
          key: ValueKey(log.id),
          styleLog: log,
          onTap: () => onItemTap(log),
        );
      },
    );
  }
}
