import 'enums.dart';

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    this.category,
    this.color,
    this.season,
    this.material,
    this.hasGraphic,
    this.hasPattern,
    required this.imagePath,
    required this.createdAt,
    this.acquiredAt,
    this.location = '',
    this.memo = '',
    this.wearCount = 0,
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final ClothingCategory? category;
  final ClothingColor? color;
  final Season? season;
  final ClothingMaterial? material;

  /// 그래픽(그림·로고·프린트) 유무. AI 자동 태깅 대상이라 "아직 태깅 안 됨"을 표현하려
  /// nullable이다 — `false`(그래픽 없음)와 `null`(모름)은 다른 상태다.
  ///
  /// [hasPattern]과 독립이다(한 옷에 둘 다 있을 수 있다). 원래 MVP 명세는 3택1
  /// (민무늬/패턴/프린트)이었으나 상호배타가 실제와 맞지 않아 독립 2개로 쪼갰다
  /// (`docs/reference/data/00_DataSchema.md` Open Question #12).
  final bool? hasGraphic;

  /// 패턴(줄무늬·체크 등 반복 텍스타일 패턴) 유무. [hasGraphic]과 독립이며 nullable 의미도 동일하다.
  final bool? hasPattern;

  final String imagePath;

  /// 옷장 "날짜·시간" 분류 기준의 소분류(연도) 근거. non-nullable이라 이 기준엔 미분류
  /// 카드가 생기지 않는다(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md` §3.2).
  ///
  /// 앱에 등록(입력)한 시각이다 — 실제 구매·획득 시각은 [acquiredAt]을 쓴다.
  final DateTime createdAt;

  /// 실제 습득(구매 등)일. 오래된 옷을 나중에 등록하면 [createdAt]과 달라지므로 별도
  /// 필드다. 모르거나 안 적을 수 있어 nullable이다.
  final DateTime? acquiredAt;

  final String location;
  final String memo;
  final int wearCount;
  final bool isIncomplete;
  final bool isDeleted;

  /// 휴지통 이동 시각 — `isDeleted:true`와 함께 세팅, 복원 시 다시 null.
  /// `daysUntilPurge` 계산 근거(`lib/providers/trash_providers.dart`).
  final DateTime? deletedAt;

  /// `copyWith`의 nullable 필드용 sentinel — 파라미터 기본값으로 써서 "안 넘김"과
  /// "명시적으로 null 넘김"을 구분한다(`identical` 비교). 리스트업: category/color/season/
  /// material/hasGraphic/hasPattern/acquiredAt/deletedAt 8개(`docs/history/TechnicalDebt.md` 원 버그 항목 참고).
  static const Object _unset = Object();

  ClothingItem copyWith({
    String? id,
    String? name,
    Object? category = _unset,
    Object? color = _unset,
    Object? season = _unset,
    Object? material = _unset,
    Object? hasGraphic = _unset,
    Object? hasPattern = _unset,
    String? imagePath,
    DateTime? createdAt,
    Object? acquiredAt = _unset,
    String? location,
    String? memo,
    int? wearCount,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: identical(category, _unset) ? this.category : category as ClothingCategory?,
      color: identical(color, _unset) ? this.color : color as ClothingColor?,
      season: identical(season, _unset) ? this.season : season as Season?,
      material: identical(material, _unset) ? this.material : material as ClothingMaterial?,
      hasGraphic: identical(hasGraphic, _unset) ? this.hasGraphic : hasGraphic as bool?,
      hasPattern: identical(hasPattern, _unset) ? this.hasPattern : hasPattern as bool?,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      acquiredAt: identical(acquiredAt, _unset) ? this.acquiredAt : acquiredAt as DateTime?,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
