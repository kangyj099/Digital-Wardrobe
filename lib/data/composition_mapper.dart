import '../models/composition.dart';
import '../models/enums.dart';
import 'firestore_codec.dart';

/// `users/{uid}/compositions/{compositionId}` 문서 ↔ [Composition].
///
/// 필드 목록의 정본은 `docs/reference/data/00_DataSchema.md` §4다.
///
/// `items`는 별도 서브컬렉션이 아니라 **문서 안에 박힌 맵 배열**이다. 코디당 15개 상한이
/// 확정돼 있어(`docs/history/Decision.md`) 문서 크기 한계와 무관하게 안전하다.
///
/// **미완성 지점 — `tags`**: §4는 `tags`(자유 텍스트 배열)를 규정하지만 `Composition`
/// 모델엔 아직 그 필드가 없다. 여기서 키를 임의로 채우면 실제 쓰기에서 서버의 기존 값을
/// 지워버리므로 의도적으로 뺐다. 모델에 `tags`가 추가되면 이 매퍼도 같이 고쳐야 한다.
/// 그때까지 이 매퍼로 문서 전체를 덮어쓰지 말 것(`docs/work/BACKLOG.md` 참고).
class CompositionMapper {
  const CompositionMapper._();

  static Map<String, Object?> toFirestore(Composition composition) {
    return {
      'name': composition.name,
      'items': [for (final placement in composition.items) _placementToMap(placement)],
      'createdAt': composition.createdAt,
      'season': enumToName(composition.season),
      'weather': enumToName(composition.weather),
      'coverImagePath': composition.coverImagePath,
      'backgroundColor': enumToName(composition.backgroundColor),
      'isIncomplete': composition.isIncomplete,
      'isDeleted': composition.isDeleted,
      'deletedAt': composition.deletedAt,
    };
  }

  static Composition fromFirestore(String id, Map<String, Object?> data) {
    return Composition(
      id: id,
      name: stringOr(data['name'], ''),
      items: _placementsFrom(data['items']),
      createdAt: requiredDateTime(data['createdAt'], field: 'createdAt', documentId: id),
      season: enumFromName(Season.values, data['season']),
      weather: enumFromName(Weather.values, data['weather']),
      coverImagePath:
          data['coverImagePath'] is String ? data['coverImagePath'] as String : null,
      backgroundColor:
          enumFromName(ArtboardBackgroundColor.values, data['backgroundColor']),
      isIncomplete: boolOr(data['isIncomplete'], false),
      isDeleted: boolOr(data['isDeleted'], false),
      deletedAt: dateTimeFromFirestore(data['deletedAt']),
    );
  }

  static Map<String, Object?> _placementToMap(CompositionItemPlacement placement) {
    return {
      'clothingItemId': placement.clothingItemId,
      'x': placement.x,
      'y': placement.y,
      'scale': placement.scale,
      'rotation': placement.rotation,
      'zIndex': placement.zIndex,
    };
  }

  /// `clothingItemId`가 없는 원소는 버린다. 어느 옷을 가리키는지 모르는 배치는
  /// 아트보드에 그릴 수도, 정리할 수도 없다.
  static List<CompositionItemPlacement> _placementsFrom(Object? raw) {
    if (raw is! List) return const [];
    final placements = <CompositionItemPlacement>[];
    for (final element in raw) {
      if (element is! Map) continue;
      final itemId = element['clothingItemId'];
      if (itemId is! String) continue;
      placements.add(
        CompositionItemPlacement(
          clothingItemId: itemId,
          x: doubleOr(element['x'], 0.0),
          y: doubleOr(element['y'], 0.0),
          scale: doubleOr(element['scale'], 1.0),
          rotation: doubleOr(element['rotation'], 0.0),
          zIndex: intOr(element['zIndex'], 0),
        ),
      );
    }
    return placements;
  }
}
