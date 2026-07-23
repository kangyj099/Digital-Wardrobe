import 'package:flutter/material.dart';
import '../providers/classification_models.dart';
import '../theme/app_spacing.dart';

/// 그룹 개요 상태의 폴더형 카드 — 소분류 값 하나에 속한 아이템들의 썸네일 콜라주 +
/// 라벨 + 개수(스펙 §3.1, "폰 갤러리 앱의 폴더 카드"). 빈 그룹은 애초에
/// `ClassificationGroupSummary` 목록에 안 들어오므로(provider 단계에서 필터링, Task 3/4)
/// 이 위젯은 항상 `count > 0`인 카드만 그린다.
class ClassificationGroupCard extends StatelessWidget {
  const ClassificationGroupCard({super.key, required this.summary, required this.onTap});

  final ClassificationGroupSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${summary.label}, ${summary.count}개',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ThumbnailCollage(paths: summary.thumbnailPaths),
              Positioned(
                left: AppSpacing.xs,
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${summary.label} · ${summary.count}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailCollage extends StatelessWidget {
  const _ThumbnailCollage({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    }
    if (paths.length == 1) {
      return Image.asset(paths.first, fit: BoxFit.cover);
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final path in paths.take(4)) Image.asset(path, fit: BoxFit.cover)],
    );
  }
}
