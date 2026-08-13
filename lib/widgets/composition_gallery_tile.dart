import 'package:flutter/material.dart';
import '../models/composition.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'composition_cover_image.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

/// `Composition` 1개를 표시하는 갤러리 타일. `composition.coverImagePath`가 있으면
/// [CompositionCoverImage]로 평면 렌더 스냅샷(또는 mock 데이터의 번들 에셋)을 채워
/// `SelectableGalleryTile`(옷장 타일)과 동일한 "이미지 + 메타 라벨/배지" 구성을 쓴다
/// (`docs/reference/data/00_DataSchema.md` §13.3). `coverImagePath`가 없으면(아직 한 번도
/// 커밋되지 않은 코디 등) 폴백으로 기존 동일 배경(`semantic.gray200`) 위 코디 이름 텍스트만
/// 표시하는 텍스트 전용 렌더링을 그대로 유지한다 — 새 placeholder 아트를 만들지 않는다.
class CompositionGalleryTile extends StatelessWidget {
  const CompositionGalleryTile({
    super.key,
    required this.composition,
    required this.onTap,
    this.onLongPress,
    this.multiSelectMode = false,
    this.selected = false,
    this.hasDeletedItem = false,
  });

  final Composition composition;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool multiSelectMode;
  final bool selected;

  /// 이 코디가 참조하는 옷 중 하나 이상이 완전 삭제(purge)됐거나 휴지통(소프트 삭제) 상태인지
  /// — 스펙("옷 삭제 시 코디 캐스케이드 처리" §"코디 목록: 삭제된 옷 포함 코디는 타일에 작은
  /// 배지(연결끊김 아이콘, 차분한 톤)") 표시용. 이 위젯은 순수 프레젠테이션이라 직접 provider를
  /// 조회하지 않고, 호출부(`composition_gallery_grid.dart`)가
  /// `compositionHasDeletedItemsProvider`(§13.4의 공유 판정)를 조회한 결과를 그대로
  /// 넘겨받는다.
  final bool hasDeletedItem;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final season = composition.season;
    final coverImagePath = composition.coverImagePath;
    return Semantics(
      button: true,
      label: (season == null ? composition.name : '${composition.name}, ${season.label}') +
          (hasDeletedItem ? ', 연결 끊긴 옷 포함' : '') +
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
                  if (coverImagePath != null)
                    Positioned.fill(
                      child: CompositionCoverImage(path: coverImagePath),
                    )
                  else
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
                  // 스펙("옷 삭제 시 코디 캐스케이드 처리" §"코디 목록") "삭제된 옷 포함 코디는
                  // 타일에 작은 배지(연결끊김 아이콘, 차분한 톤)" — 좌하단(계절 라벨)/우상단
                  // (다중선택 체크)과 겹치지 않도록 좌상단에 배치, `TrashGalleryTile`의 유형
                  // 아이콘 배지와 같은 원형 반투명 배경 패턴을 재사용한다.
                  if (hasDeletedItem)
                    Positioned(
                      top: AppSpacing.xxs,
                      left: AppSpacing.xxs,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        decoration: BoxDecoration(
                          color: semantic.gray50.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.link_off, size: 14, color: semantic.gray600),
                      ),
                    ),
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
