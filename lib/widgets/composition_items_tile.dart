import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'clothing_items_row.dart';

/// `CompositionPreviewCarousel`의 각 페이지 콘텐츠 — 코디 이름 라벨(상단) + 그 코디에 실제로
/// 포함된 옷들의 가로 스크롤 스트립(`ClothingItemsRow`, `showLabel: false`)을 보여준다
/// (`docs/history/Decision.md` "옷 상세의 '연결된 코디' 캐러셀 타일을 단일 대표이미지에서
/// '사용된 옷' 가로 스크롤로 교체" 참고).
///
/// 탭 대상이 둘로 나뉜다 — 개별 옷 이미지를 탭하면 [onItemTap](그 옷 상세로), 그 외 영역
/// (이름 라벨/배경)을 탭하면 [onTap](이 코디 자체의 상세로). 안쪽 [ClothingItemsRow] 각
/// 아이템의 `GestureDetector`가 히트테스트상 바깥 `GestureDetector`보다 먼저 매치되므로,
/// 옷 이미지 위에서는 안쪽이, 그 외에서는 바깥쪽만 반응해 자연스럽게 분리된다.
///
/// 이름 라벨 영역에 세로 패딩을 넉넉히 둔 것은 알려진 리스크(캐러셀의 가로 스와이프와
/// [ClothingItemsRow]의 가로 스크롤이 같은 축에서 겹치는 제스처 경합) 완화용 — 라벨 영역이
/// 코디 간 스와이프를 시작할 수 있는 non-list 표면이 되게 한다. 실제 스와이프 동작 여부는
/// Tester가 실측 드래그로 검증한다.
class CompositionItemsTile extends StatelessWidget {
  const CompositionItemsTile({
    super.key,
    required this.composition,
    required this.items,
    required this.onTap,
    required this.onItemTap,
  });

  final Composition composition;
  final List<ClothingItem> items;
  final VoidCallback onTap;
  final void Function(ClothingItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          color: semantic.gray200,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  composition.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => ClothingItemsRow(
                    items: items,
                    onTap: onItemTap,
                    showLabel: false,
                    tileSize: constraints.maxHeight,
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
