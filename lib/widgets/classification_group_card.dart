import 'package:flutter/material.dart';
import '../providers/classification_models.dart';
import '../theme/app_spacing.dart';
import 'composition_cover_image.dart';

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

/// 썸네일 경로는 도메인에 따라 번들 에셋(`assets/...` — 옷/스타일일지)일 수도, 런타임에
/// 저장된 코디 스냅샷의 로컬 파일 절대경로일 수도 있다(`Composition.coverImagePath`,
/// `docs/reference/data/00_DataSchema.md` §13.3이 이 그룹 요약 썸네일을 명시적으로
/// [CompositionCoverImage] 호출부로 지정). 그래서 `Image.asset`을 직접 쓰지 않고 경로 종류를
/// 분기하는 [CompositionCoverImage]를 쓴다 — 에셋 경로면 내부적으로 `Image.asset`이라
/// 옷/스타일일지 그룹 카드의 동작은 이전과 동일하다.
class _ThumbnailCollage extends StatelessWidget {
  const _ThumbnailCollage({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    }
    if (paths.length == 1) {
      return CompositionCoverImage(path: paths.first);
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final path in paths.take(4)) CompositionCoverImage(path: path)],
    );
  }
}
