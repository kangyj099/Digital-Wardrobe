// lib/widgets/interactive_artboard/artboard_item.dart

/// 코디 편집기 아트보드에 배치되는 아이템 1개.
///
/// `Composition`/`ClothingItem` 도메인 모델과 독립적이다 — `clothingItemId` 같은
/// FK를 포함하지 않아, 이 위젯이 Composition 도메인에 결합되지 않는다.
class ArtboardItem {
  const ArtboardItem({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  /// 아이템 고유 ID. 선택 상태(`selectedItemId`)와 삭제(`onItemDeleted`) 콜백이
  /// 이 값을 기준으로 아이템을 식별한다.
  final String id;

  /// 렌더링할 이미지 asset 경로.
  final String imagePath;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 중심 앵커 기준.
  final double x;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 중심 앵커 기준.
  final double y;

  /// 렌더 박스 배율. 1.0이 기본 크기(`baseItemSize`).
  final double scale;

  /// 회전각(라디안).
  final double rotation;

  /// 렌더 순서 — 값이 클수록 위에 그려진다.
  final int zIndex;

  ArtboardItem copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
  }) {
    return ArtboardItem(
      id: id,
      imagePath: imagePath,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
