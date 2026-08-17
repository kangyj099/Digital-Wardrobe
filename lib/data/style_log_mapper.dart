import '../models/enums.dart';
import '../models/style_log.dart';
import 'firestore_codec.dart';

/// `users/{uid}/styleLogs/{styleLogId}` 문서 ↔ [StyleLog].
///
/// 필드 목록의 정본은 `docs/reference/data/00_DataSchema.md` §5다.
///
/// `createdAt`(등록일)과 `wornDate`(착용일)는 별개 필드다. `wornDate`만 nullable이다 —
/// 오래된 사진을 등록하며 날짜를 모를 수 있기 때문이다.
class StyleLogMapper {
  const StyleLogMapper._();

  static Map<String, Object?> toFirestore(StyleLog log) {
    return {
      'coverImagePath': log.coverImagePath,
      'createdAt': log.createdAt,
      'wornDate': log.wornDate,
      'linkedCompositionId': log.linkedCompositionId,
      'wornItemIds': log.wornItemIds,
      'additionalImagePaths': log.additionalImagePaths,
      'season': enumToName(log.season),
      'weather': enumToName(log.weather),
      'location': log.location,
      'isIncomplete': log.isIncomplete,
      'isDeleted': log.isDeleted,
      'deletedAt': log.deletedAt,
    };
  }

  static StyleLog fromFirestore(String id, Map<String, Object?> data) {
    return StyleLog(
      id: id,
      coverImagePath: stringOr(data['coverImagePath'], ''),
      createdAt: requiredDateTime(data['createdAt'], field: 'createdAt', documentId: id),
      wornDate: dateTimeFromFirestore(data['wornDate']),
      linkedCompositionId:
          data['linkedCompositionId'] is String ? data['linkedCompositionId'] as String : null,
      wornItemIds: stringListFrom(data['wornItemIds']),
      additionalImagePaths: stringListFrom(data['additionalImagePaths']),
      season: enumFromName(Season.values, data['season']),
      weather: enumFromName(Weather.values, data['weather']),
      location: stringOr(data['location'], ''),
      isIncomplete: boolOr(data['isIncomplete'], false),
      isDeleted: boolOr(data['isDeleted'], false),
      deletedAt: dateTimeFromFirestore(data['deletedAt']),
    );
  }
}
