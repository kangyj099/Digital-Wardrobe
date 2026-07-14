import 'package:flutter_riverpod/legacy.dart';
import '../models/trash_entry.dart';
import '../mock/mock_data.dart';

/// 휴지통 항목 목록 — 실제로는 옷장/코디/스타일일지 3개 provider를 `isDeleted`로
/// 필터링한 집계 뷰가 되어야 하지만(Step⑦ 기능 구현 몫), 지금은 이 mock 리스트만
/// 노출한다(다른 도메인과 동일하게 `StateNotifierProvider` + mock 초기값 관례를 따름).
class TrashEntriesNotifier extends StateNotifier<List<TrashEntry>> {
  TrashEntriesNotifier() : super(mockTrashEntries);
}

final trashEntriesProvider =
    StateNotifierProvider<TrashEntriesNotifier, List<TrashEntry>>(
        (ref) => TrashEntriesNotifier());
