import 'package:flutter/material.dart';
import '../models/composition.dart';
import 'app_gallery_grid.dart';
import 'composition_gallery_tile.dart';

/// `List<Composition>` + [CompositionGalleryTile] 매핑 전용 어댑터 — `GroupedGalleryGrid`와
/// 동일한 얇은 어댑터 패턴. 순수 그리드 레이아웃 메커니즘(패딩/density→crossAxisCount/gap/
/// aspectRatio) 자체는 [AppGalleryGrid]가 담당한다.
class CompositionGalleryGrid extends StatelessWidget {
  const CompositionGalleryGrid({
    super.key,
    required this.compositions,
    required this.density,
    required this.onItemTap,
  });

  final List<Composition> compositions;
  final int density;
  final void Function(Composition composition) onItemTap;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: compositions.length,
      density: density,
      itemBuilder: (context, index) {
        final composition = compositions[index];
        return CompositionGalleryTile(
          key: ValueKey(composition.id),
          composition: composition,
          onTap: () => onItemTap(composition),
        );
      },
    );
  }
}
