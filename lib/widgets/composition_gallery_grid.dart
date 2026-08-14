import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import 'app_gallery_grid.dart';
import 'composition_gallery_tile.dart';

/// `List<Composition>` + [CompositionGalleryTile] 매핑 전용 어댑터 — `GroupedGalleryGrid`와
/// 동일한 얇은 어댑터 패턴. 순수 그리드 레이아웃 메커니즘(패딩/density→crossAxisCount/gap/
/// aspectRatio) 자체는 [AppGalleryGrid]가 담당한다.
///
/// `ConsumerWidget`인 이유: [CompositionGalleryTile.hasDeletedItem] 판정(§13.4,
/// `docs/reference/data/00_DataSchema.md`)에 필요한 `closetItemsProvider`를 **이 build()에서
/// 단 한 번** watch하기 위함 — 이전에는 호출부(`composition_main_screen.dart`)가 만든 inline
/// `Set<String>`(소프트 삭제된 옷만 봄, 완전 삭제/purge된 경우를 놓침)을 넘겨받았다.
///
/// 주의: 항목별 판정을 `itemBuilder` 안에서 `compositionHasDeletedItemsProvider`로 `ref.watch`
/// 하면 안 된다 — 빌드 중 `setState()` 크래시를 일으킨다(근거와 재현 경로는
/// `composition_providers.dart`의 §13.4 섹션 주석 참고). 그래서 여기서는 base provider를
/// 직접 한 번만 watch하고, 판정은 같은 §13.4 순수 함수 [compositionHasDeletedItems]로
/// 항목마다 계산한다(판정 로직은 provider 경로와 완전히 동일한 단일 소스).
class CompositionGalleryGrid extends ConsumerWidget {
  const CompositionGalleryGrid({
    super.key,
    required this.compositions,
    required this.density,
    required this.onItemTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<Composition> compositions;
  final int density;
  final void Function(Composition composition) onItemTap;

  /// [CompositionGalleryTile.onLongPress]로 그대로 전달 — 다중선택 모드 진입 트리거.
  final void Function(Composition composition)? onItemLongPress;

  /// [CompositionGalleryTile.multiSelectMode]로 그대로 전달.
  final bool multiSelectMode;

  /// 선택된 항목 id 집합 — [CompositionGalleryTile.selected]로 `composition.id` 포함 여부를
  /// 변환해 전달.
  final Set<String> selectedIds;

  /// [AppScrollContainer]가 연결하는 스크롤 컨트롤러 — [AppGalleryGrid]로 그대로 전달.
  final ScrollController? controller;

  /// Content Spacer(스펙 §4) — [AppGalleryGrid.topSpacing]으로 그대로 전달.
  final double topSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closetItems = ref.watch(closetItemsProvider);
    return AppGalleryGrid(
      itemCount: compositions.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final composition = compositions[index];
        final hasDeletedItem = compositionHasDeletedItems(composition, closetItems);
        return CompositionGalleryTile(
          key: ValueKey(composition.id),
          composition: composition,
          onTap: () => onItemTap(composition),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(composition),
          multiSelectMode: multiSelectMode,
          selected: selectedIds.contains(composition.id),
          hasDeletedItem: hasDeletedItem,
        );
      },
    );
  }
}
