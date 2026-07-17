import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';

/// 옷 목록을 가로 스크롤 스트립으로 보여주는 공용 위젯 — `composition_detail_screen.dart`의
/// "사용된 옷"(`showLabel: true`, `tileSize: 72`)과 `style_log_viewer_screen.dart`의
/// "착용 옷"(`showLabel: false`, `tileSize: 96`)에서 거의 동일하게 반복됐던 인라인 구현을
/// 추출했다(`docs/history/Decision.md` "옷 상세의 '연결된 코디' 캐러셀 타일을 단일
/// 대표이미지에서 '사용된 옷' 가로 스크롤로 교체" 참고).
///
/// 이 위젯 자체는 조회/역참조 로직을 갖지 않는다 — 호출부가 이미 resolve한
/// `List<ClothingItem>`을 그대로 받는다(예: `style_log_viewer_screen.dart`의
/// `additionalImagePaths` → `ClothingItem` 역참조 매칭은 호출부에서 끝내고 넘긴다).
class ClothingItemsRow extends StatelessWidget {
  const ClothingItemsRow({
    super.key,
    required this.items,
    required this.onTap,
    this.showLabel = true,
    this.tileSize = 72,
  });

  final List<ClothingItem> items;
  final void Function(ClothingItem item) onTap;

  /// true면 이미지 아래 이름 라벨을 함께 그린다(기존 "사용된 옷" 방식). false면 이미지만
  /// (기존 "착용 옷" 방식).
  final bool showLabel;

  /// 각 옷 이미지의 한 변 길이(정사각).
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showLabel ? tileSize + AppSpacing.lg : tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              item.imagePath,
              width: tileSize,
              height: tileSize,
              fit: BoxFit.cover,
            ),
          );

          return GestureDetector(
            key: ValueKey(item.id),
            onTap: () => onTap(item),
            child: showLabel
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      image,
                      SizedBox(
                        width: tileSize,
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : image,
          );
        },
      ),
    );
  }
}
