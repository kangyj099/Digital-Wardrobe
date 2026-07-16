import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'style_log_gallery_tile.dart';

/// 옷 상세/코디 상세 공용 — 연결된 스타일일지를 2열 갤러리로 보여준다. [onAddTap]이 있고
/// [logs]가 비어 있으면 "+" 바인딩 타일을 대신 그린다(코디 상세 전용 — 옷 상세는 바인딩
/// 액션이 없어 onAddTap을 넘기지 않고, 비면 섹션 자체가 사라진다).
class StyleLogCrossReferenceGallery extends StatelessWidget {
  const StyleLogCrossReferenceGallery({
    super.key,
    required this.logs,
    required this.onTap,
    this.onAddTap,
    this.expandSingle = true,
  });

  final List<StyleLog> logs;
  final void Function(StyleLog styleLog) onTap;
  final VoidCallback? onAddTap;

  /// true(기본값, 코디 상세 전용)면 `02_코디 UX명세서`의 "2열, 1개면 2칸 확대 배치" 규칙대로
  /// 1개일 때 가로로 넓은 타일. false(옷 상세 전용)면 개수와 무관하게 항상 정사각형 타일.
  final bool expandSingle;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      if (onAddTap == null) return const SizedBox.shrink();
      return _AddTile(onTap: onAddTap!);
    }

    final singleRow = expandSingle && logs.length == 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: singleRow ? 1 : 2,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        // 1개일 때 가로 2칸 폭(2열 그리드의 한 행 높이는 유지, 폭만 2배) 비율을 근사.
        childAspectRatio: singleRow ? 2 : 1,
      ),
      itemBuilder: (context, index) {
        final log = logs[index];
        return StyleLogGalleryTile(styleLog: log, onTap: () => onTap(log));
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return AspectRatio(
      aspectRatio: 2,
      child: Material(
        color: semantic.gray100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                Text('스타일일지 연결하기', style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
