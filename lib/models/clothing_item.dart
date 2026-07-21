import 'enums.dart';

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    this.category,
    this.color,
    this.season,
    this.material,
    required this.imagePath,
    required this.createdAt,
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
  final String? color;
  final Season? season;
  final ClothingMaterial? material;
  final String imagePath;

  /// 옷장 "날짜·시간" 분류 기준의 소분류(연도) 근거. non-nullable이라 이 기준엔 미분류
  /// 카드가 생기지 않는다(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md` §3.2).
  final DateTime createdAt;
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
  /// material/deletedAt 5개(`docs/history/TechnicalDebt.md` 원 버그 항목 참고).
  static const Object _unset = Object();

  ClothingItem copyWith({
    String? id,
    String? name,
    Object? category = _unset,
    Object? color = _unset,
    Object? season = _unset,
    Object? material = _unset,
    String? imagePath,
    DateTime? createdAt,
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
      color: identical(color, _unset) ? this.color : color as String?,
      season: identical(season, _unset) ? this.season : season as Season?,
      material: identical(material, _unset) ? this.material : material as ClothingMaterial?,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
