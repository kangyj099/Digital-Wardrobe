/// Allowed values for [ClothingItem.material] — a closed, perception-based
/// vocabulary (how a person would describe the fabric at a glance), not a
/// fiber-composition breakdown. See Decision.md for the taxonomy decision.
const List<String> kClothingMaterials = [
  '면',
  '스판',
  '데님',
  '니트',
  '플리스',
  '리넨',
  '모달·레이온',
  '실크·새틴',
  '시어서커',
  '코듀로이',
  '벨벳',
  '패딩',
  '나일론(바스락)',
  '가죽',
  '퍼·무스탕',
  '캔버스·패브릭',
  '스웨이드',
  '고무·러버',
];

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    required this.material,
    required this.imagePath,
    this.location = '',
    this.memo = '',
    this.wearCount = 0,
    this.isIncomplete = false,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final String season;

  /// One of [kClothingMaterials].
  final String material;
  final String imagePath;
  final String location;
  final String memo;
  final int wearCount;
  final bool isIncomplete;
  final bool isDeleted;

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? color,
    String? season,
    String? material,
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
