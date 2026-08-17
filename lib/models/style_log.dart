import 'enums.dart';

class StyleLog {
  const StyleLog({
    required this.id,
    required this.coverImagePath,
    required this.createdAt,
    this.wornDate,
    this.linkedCompositionId,
    this.wornItemIds = const [],
    this.additionalImagePaths = const [],
    this.season,
    this.weather,
    this.location = '',
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String coverImagePath;

  /// 이 스타일일지를 앱에 등록(작성)한 시각. 실제 착용일([wornDate])과 다를 수 있어
  /// 별도 필드다 — `ClothingItem.createdAt`/`acquiredAt`과 같은 구분이다.
  ///
  /// 휴지통의 "제작일" 표기가 이 필드를 쓴다([wornDate]가 아니다 —
  /// `docs/reference/data/00_DataSchema.md` §5, Open Question #18).
  final DateTime createdAt;

  /// 실제로 착용한 날짜. 오래된 사진을 등록하며 날짜를 모르거나 비워둘 수 있어 nullable이다.
  ///
  /// null인 항목의 정렬 위치는 "맨 뒤"로 확정했다 —
  /// `filteredStyleLogsProvider`(`lib/providers/style_log_providers.dart`)가 정본이다.
  final DateTime? wornDate;

  final String? linkedCompositionId;

  /// "착용 옷" — 이 스타일일지에 바인딩된 [ClothingItem.id] 리스트("옷 종류" 필터의
  /// 파생 기준). 예전엔 이미지 경로 문자열 일치로 옷을 역추적했으나(취약 — 경로가 바뀌면
  /// 매칭이 깨짐), 실제 ID 참조로 교체했다.
  final List<String> wornItemIds;

  /// 카드 슬롯 3~10번에 들어가는 실제 업로드 사진 경로(대표사진=1번/코디=2번은 고정이라
  /// 나머지 최대 8장). [wornItemIds]와는 별개 필드다 — 저쪽은 옷 레코드 참조고, 이쪽은
  /// 업로드된 이미지다. 슬롯 상한 근거는 `docs/reference/plan/03_화면별UX명세서/03_스타일 일지.md`.
  final List<String> additionalImagePaths;

  final Season? season;
  final Weather? weather;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;
  final DateTime? deletedAt;

  /// `copyWith`의 nullable 필드용 sentinel — "안 넘김"과 "명시적으로 null 넘김"을 구분한다.
  /// 리스트업: wornDate/linkedCompositionId/season/weather/deletedAt 5개.
  static const Object _unset = Object();

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? createdAt,
    Object? wornDate = _unset,
    Object? linkedCompositionId = _unset,
    List<String>? wornItemIds,
    List<String>? additionalImagePaths,
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
      createdAt: createdAt ?? this.createdAt,
      wornDate: identical(wornDate, _unset) ? this.wornDate : wornDate as DateTime?,
      linkedCompositionId: identical(linkedCompositionId, _unset)
          ? this.linkedCompositionId
          : linkedCompositionId as String?,
      wornItemIds: wornItemIds ?? this.wornItemIds,
      additionalImagePaths: additionalImagePaths ?? this.additionalImagePaths,
      season: identical(season, _unset) ? this.season : season as Season?,
      weather: identical(weather, _unset) ? this.weather : weather as Weather?,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
