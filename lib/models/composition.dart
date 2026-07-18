import 'enums.dart';

class CompositionItemPlacement {
  const CompositionItemPlacement({
    required this.clothingItemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  final String clothingItemId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
}

class Composition {
  const Composition({
    required this.id,
    required this.name,
    required this.items,
    this.season,
    this.coverImagePath,
    this.isIncomplete = false,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;
  final Season? season;

  /// 사용자가 지정한 대표 이미지(신규 기능, 이번 라운드에 선택 UI는 없음 — `docs/history/
  /// TechnicalDebt.md` "CompositionGalleryTile이 아직 텍스트만 표시" 참고). `null`이면
  /// [compositionCoverImageProvider]가 첫 번째 옷 이미지로 폴백한다.
  final String? coverImagePath;
  final bool isIncomplete;
  final bool isDeleted;
}
