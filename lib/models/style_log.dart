import 'enums.dart';

class StyleLog {
  const StyleLog({
    required this.id,
    required this.coverImagePath,
    required this.wornDate,
    this.linkedCompositionId,
    this.wornItemIds = const [],
    this.season,
    this.weather,
    this.location = '',
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;

  /// "착용 옷" — 이 스타일일지에 바인딩된 [ClothingItem.id] 리스트("옷 종류" 필터의
  /// 파생 기준). 예전엔 이미지 경로 문자열 일치로 옷을 역추적했으나(취약 — 경로가 바뀌면
  /// 매칭이 깨짐), 실제 ID 참조로 교체했다.
  final List<String> wornItemIds;
  final Season? season;
  final Weather? weather;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;
  final DateTime? deletedAt;

  static const Object _unset = Object();

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? wornDate,
    Object? linkedCompositionId = _unset,
    List<String>? wornItemIds,
    Object? season = _unset,
    Object? weather = _unset,
    String? location,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return StyleLog(
      id: id ?? this.id,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      wornDate: wornDate ?? this.wornDate,
      linkedCompositionId: identical(linkedCompositionId, _unset)
          ? this.linkedCompositionId
          : linkedCompositionId as String?,
      wornItemIds: wornItemIds ?? this.wornItemIds,
      season: identical(season, _unset) ? this.season : season as Season?,
      weather: identical(weather, _unset) ? this.weather : weather as Weather?,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
