import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'composition_cover_image.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

/// 휴지통 전용 순수 썸네일 타일 — 옷장/코디처럼 그룹 계층이 있는 그리드가 아니라
/// 제목 텍스트 없이 이미지 중심(`00_페이지 타입 정의.md` "휴지통의 추가 확장 요소").
/// `StyleLogGalleryTile`/`SelectableGalleryTile`과 같은 Stack 오버레이 패턴을 재사용해
/// 좌상단에 유형 아이콘 배지, 좌하단에 "N일"(영구 삭제까지 남은 일수) 텍스트를 얹는다.
///
/// 유형 배지는 전용 enum을 새로 만들지 않고 이미 있는 [AppCategory](closet/composition/
/// styleLog — 옷/코디/스타일일지 도메인과 정확히 1:1 대응)를 재사용한다. 아이콘 매핑은
/// (`AppDensity.iconFor`가 `lib/theme/app_spacing.dart`에 승격된 것과 같은 이유로) 이
/// 위젯 파일의 private 함수로 둔다 — `AppCategory`는 `lib/models/`의 순수 데이터 enum이라
/// `IconData`(Flutter 의존)를 모델 레이어에 얹지 않는다.
///
/// 타일 탭은 다른 Main형처럼 상세 페이지로 전환되지 않고 정보 팝업으로 이어진다(호출부
/// 책임) — 복원/영구삭제는 그 팝업에서 처리하므로 이 타일 자체엔 스와이프 단축 액션을
/// 두지 않는다.
class TrashGalleryTile extends StatelessWidget {
  const TrashGalleryTile({
    super.key,
    required this.imagePath,
    required this.category,
    required this.daysUntilPurge,
    required this.onTap,
    this.onLongPress,
    this.multiSelectMode = false,
    this.selected = false,
  });

  /// `TrashEntry.imagePath` — 세 도메인에서 오는 경로가 섞인다: 옷(`ClothingItem.imagePath`)/
  /// 스타일일지(`StyleLog.coverImagePath`)는 번들 에셋(`assets/...`)이지만, 코디는
  /// `Composition.coverImagePath`라 커밋된 적이 있으면 런타임 저장 스냅샷의 로컬 파일
  /// 절대경로다(`lib/providers/trash_providers.dart`의 매핑 참고). 그래서 렌더링에
  /// `Image.asset`을 직접 쓰지 않고 경로 종류를 분기하는 [CompositionCoverImage]를 쓴다
  /// (`docs/reference/data/00_DataSchema.md` §13.3).
  final String imagePath;

  final AppCategory category;

  /// 영구 삭제까지 남은 일수.
  final int daysUntilPurge;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool multiSelectMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final daysLabel = '$daysUntilPurge일';
    return Semantics(
      button: true,
      label: '${category.label}, 영구 삭제까지 $daysLabel${selected ? ', 선택됨' : ''}',
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
                    child: imagePath.isNotEmpty
                        ? CompositionCoverImage(path: imagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: AppSpacing.xxs,
                    left: AppSpacing.xxs,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: semantic.gray50.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_categoryIcon(category), size: 14),
                    ),
                  ),
                  if (multiSelectMode)
                    Positioned(
                      top: AppSpacing.xxs,
                      right: AppSpacing.xxs,
                      child: MultiSelectCheckmark(selected: selected),
                    ),
                  GalleryMetaLabel(label: daysLabel, maxWidth: constraints.maxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(AppCategory category) => switch (category) {
        AppCategory.closet => Icons.checkroom,
        AppCategory.composition => Icons.dashboard_customize,
        AppCategory.styleLog => Icons.photo_camera_back,
      };
}
