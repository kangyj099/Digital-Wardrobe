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
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
