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

  ClothingItem copyWith({
    String? id,
    String? name,
    ClothingCategory? category,
    String? color,
    Season? season,
    ClothingMaterial? material,
    String? imagePath,
    DateTime? createdAt,
    String? location,
    String? memo,
    int? wearCount,
    bool? isIncomplete,
    bool? isDeleted,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      season: season ?? this.season,
      material: material ?? this.material,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
