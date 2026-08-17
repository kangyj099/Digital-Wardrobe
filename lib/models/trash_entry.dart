import 'enums.dart';

/// 휴지통 타일 1건을 표현하는 집계용 모델(파생 값 — `trashEntriesProvider`가 3도메인
/// provider를 watch해 실시간으로 만들어낸다, 별도 상태로 저장하지 않음).
class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.category,
    required this.imagePath,
    required this.createdAt,
    required this.daysUntilPurge,
  });

  final String id;
  final AppCategory category;
  final String imagePath;

  /// 제작(생성)일 — 삭제일이 아니다(`ClothingItem.createdAt`/`Composition.createdAt`/
  /// `StyleLog.createdAt`을 그대로 매핑). 휴지통 정보 팝업의 "제작된 날짜/시간" 표기 근거.
  ///
  /// 스타일일지는 예전에 `wornDate`(착용일)를 매핑했으나 그 필드가 nullable이 되면서
  /// 날짜를 안 적은 항목의 "제작일"이 빈칸이 되는 문제가 있어 `createdAt`으로 옮겼다
  /// (`docs/reference/data/00_DataSchema.md` §5, Open Question #18).
  final DateTime createdAt;

  /// 영구 삭제(purge)까지 남은 일수 — `deletedAt` 기준 매번 다시 계산됨.
  final int daysUntilPurge;
}
