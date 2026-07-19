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
    required this.createdAt,
    this.season,
    this.weather,
    this.coverImagePath,
    this.isIncomplete = false,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;

  /// 코디 "날짜·시간" 분류 기준의 소분류(연도) 근거 — `ClothingItem.createdAt`과 동일 성격.
  final DateTime createdAt;
  final Season? season;

  /// 코디 자체에 붙는 선택적 태그(실제 착용일 관측 날씨가 아님) — `season`과 동일 성격.
  final Weather? weather;

  /// 사용자가 지정한 대표 이미지(신규 기능, 이번 라운드에 선택 UI는 없음 — `docs/history/
  /// TechnicalDebt.md` "CompositionGalleryTile이 아직 텍스트만 표시" 참고). `null`이면
  /// [compositionCoverImageProvider]가 첫 번째 옷 이미지로 폴백한다.
  final String? coverImagePath;
  final bool isIncomplete;
  final bool isDeleted;
}
