import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'style_log_gallery_tile.dart';

/// 옷 상세/코디 상세 공용 — 연결된 스타일일지를 항상 정사각형(1:1) 타일의 갤러리로
/// 보여준다. 기본 2열이며, [logs]가 정확히 1장이면 1열(타일이 컨테이너 폭 전체를 차지해
/// 더 커 보임 — 2:1 와이드 확대가 아니라 열 개수 자체를 줄이는 방식). [onAddTap]이 있고
/// [logs]가 비어 있으면 "+" 바인딩 타일을 대신 그린다(코디 상세 전용 — 옷 상세는 바인딩
/// 액션이 없어 onAddTap을 넘기지 않고, 비면 섹션 자체가 사라진다).
class StyleLogCrossReferenceGallery extends StatelessWidget {
  const StyleLogCrossReferenceGallery({
    super.key,
    required this.logs,
    required this.onTap,
    this.onAddTap,
  });

  final List<StyleLog> logs;
  final void Function(StyleLog styleLog) onTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      if (onAddTap == null) return const SizedBox.shrink();
      return _AddTile(onTap: onAddTap!);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: logs.length == 1 ? 1 : 2,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 1,
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
      aspectRatio: 1,
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
