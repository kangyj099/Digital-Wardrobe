import 'enums.dart';

/// 휴지통 타일 1건을 표현하는 집계용 모델 — 어느 도메인(옷/코디/스타일일지)에서
/// 삭제됐는지는 이미 있는 [AppCategory](closet/composition/styleLog)로 표현한다.
/// `ClothingItem`/`Composition`/`StyleLog` 모두 이미 `isDeleted` 필드를 갖고 있어,
/// 실제로는 이 세 provider를 `isDeleted`로 필터링한 집계 뷰가 되어야 하지만
/// (Step⑦ 기능 구현 몫), 지금은 이 화면 전용 mock 데이터([lib/mock/mock_data.dart]의
/// `mockTrashEntries`)만 채운다.
class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.category,
    required this.imagePath,
    required this.remainingDays,
  });

  final String id;
  final AppCategory category;
  final String imagePath;

  /// 영구 삭제까지 남은 일수.
  final int remainingDays;
}
