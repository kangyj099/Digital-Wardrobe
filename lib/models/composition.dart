import 'enums.dart';

/// 코디 아트보드에서 옷 1개의 배치. `lib/widgets/interactive_artboard/artboard_item.dart`의
/// `ArtboardItem`과 동일한 앵커 규약을 쓴다(코디 편집기 연결 시 두 타입을 상호 변환하므로
/// 규약이 어긋나면 안 됨 — `docs/superpowers/specs/2026-07-19-composition-artboard-isolated-widget-design.md`
/// §9 후속 통합 메모).
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

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 **중심** 앵커 기준(모서리 아님).
  final double x;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 **중심** 앵커 기준(모서리 아님).
  final double y;

  /// 아이템 렌더 배율. 1.0이 기본 크기.
  final double scale;

  /// 회전각(라디안).
  final double rotation;

  /// 렌더 순서 — 값이 클수록 위에 그려진다.
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
    this.backgroundColor,
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;

  /// 코디 "날짜·시간" 분류 기준의 소분류(연도) 근거 — `ClothingItem.createdAt`과 동일 성격.
  final DateTime createdAt;
  final Season? season;

  /// 코디 자체에 붙는 선택적 태그(실제 착용일 관측 날씨가 아님) — `season`과 동일 성격.
  final Weather? weather;

  /// 코디의 평면 렌더 스냅샷 PNG 경로 — 사용자가 직접 고르는 게 아니라, 에디터 완료(✔)
  /// 커밋 시점 또는 "삭제된 옷 자동 정리" write-back 시점마다
  /// `captureCompositionSnapshot`/`saveCompositionSnapshot`
  /// (`lib/widgets/interactive_artboard/composition_snapshot_capture.dart`,
  /// `lib/services/composition_snapshot_service.dart`)이 자동 생성해 채운다
  /// (`docs/reference/data/00_DataSchema.md` §13). 아직 한 번도 커밋된 적 없는 코디는
  /// `null`이고, 이 경우 [compositionCoverImageProvider]가 첫 번째 옷 이미지로 폴백한다.
  final String? coverImagePath;

  /// 아트보드 배경색 스와치 값(`ArtboardBackgroundColor`, 흰색/밝은회색/어두운회색/검정
  /// 4단 닫힌 어휘 — `lib/models/enums.dart`, `Color` 매핑은 `lib/widgets/
  /// interactive_artboard/artboard_background_color.dart`의 위젯 레이어 extension).
  /// `null`이면 미설정(코디 편집기가 기본값으로 흰색을 씀). Editor Draft/Commit/Cancel
  /// 모델(`docs/history/Decision.md` "Editor 저장 모델 전환")에 따라 완료(✔) 시점에만
  /// Draft의 값이 이 필드에 반영된다.
  final ArtboardBackgroundColor? backgroundColor;

  final bool isIncomplete;
  final bool isDeleted;

  /// 휴지통 이동 시각 — `isDeleted:true`와 함께 세팅, 복원 시 다시 null.
  /// `daysUntilPurge` 계산 근거(`lib/providers/trash_providers.dart`).
  final DateTime? deletedAt;

  /// `copyWith`의 nullable 필드용 sentinel — 파라미터 기본값으로 써서 "안 넘김"과
  /// "명시적으로 null 넘김"을 구분한다(`identical` 비교). 리스트업: season/weather/
  /// coverImagePath/backgroundColor/deletedAt 5개.
  static const Object _unset = Object();

  Composition copyWith({
    String? id,
    String? name,
    List<CompositionItemPlacement>? items,
    DateTime? createdAt,
    Object? season = _unset,
    Object? weather = _unset,
    Object? coverImagePath = _unset,
    Object? backgroundColor = _unset,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return Composition(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      season: identical(season, _unset) ? this.season : season as Season?,
      weather: identical(weather, _unset) ? this.weather : weather as Weather?,
      coverImagePath: identical(coverImagePath, _unset) ? this.coverImagePath : coverImagePath as String?,
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as ArtboardBackgroundColor?,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
