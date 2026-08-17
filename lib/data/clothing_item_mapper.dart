import '../models/clothing_item.dart';
import '../models/enums.dart';
import 'firestore_codec.dart';

/// `users/{uid}/clothingItems/{itemId}` 문서 ↔ [ClothingItem].
///
/// 필드 목록의 정본은 `docs/reference/data/00_DataSchema.md` §3이다.
/// 문서 ID는 본문에 중복 저장하지 않고 [fromFirestore]의 [id]로 따로 받는다.
class ClothingItemMapper {
  const ClothingItemMapper._();

  static Map<String, Object?> toFirestore(ClothingItem item) {
    return {
      'name': item.name,
      'category': enumToName(item.category),
      'color': enumToName(item.color),
      'season': enumToName(item.season),
      'material': enumToName(item.material),
      'hasGraphic': item.hasGraphic,
      'hasPattern': item.hasPattern,
      'imagePath': item.imagePath,
      'createdAt': item.createdAt,
      'acquiredAt': item.acquiredAt,
      'location': item.location,
      'memo': item.memo,
      'wearCount': item.wearCount,
      'isIncomplete': item.isIncomplete,
      'isDeleted': item.isDeleted,
      'deletedAt': item.deletedAt,
    };
  }

  static ClothingItem fromFirestore(String id, Map<String, Object?> data) {
    return ClothingItem(
      id: id,
      name: stringOr(data['name'], ''),
      category: enumFromName(ClothingCategory.values, data['category']),
      color: enumFromName(ClothingColor.values, data['color']),
      season: enumFromName(Season.values, data['season']),
      material: enumFromName(ClothingMaterial.values, data['material']),
      hasGraphic: data['hasGraphic'] is bool ? data['hasGraphic'] as bool : null,
      hasPattern: data['hasPattern'] is bool ? data['hasPattern'] as bool : null,
      imagePath: stringOr(data['imagePath'], ''),
      createdAt: requiredDateTime(data['createdAt'], field: 'createdAt', documentId: id),
      acquiredAt: dateTimeFromFirestore(data['acquiredAt']),
      location: stringOr(data['location'], ''),
      memo: stringOr(data['memo'], ''),
      wearCount: intOr(data['wearCount'], 0),
      isIncomplete: boolOr(data['isIncomplete'], false),
      isDeleted: boolOr(data['isDeleted'], false),
      deletedAt: dateTimeFromFirestore(data['deletedAt']),
    );
  }
}
