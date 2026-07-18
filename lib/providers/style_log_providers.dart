import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/style_log.dart';
import '../mock/mock_data.dart';
import 'composition_providers.dart';

class StyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  StyleLogsNotifier() : super(mockStyleLogs);

  /// [logId]인 StyleLog의 [linkedCompositionId]를 [compositionId]로 갱신한다.
  /// `Composition`은 변경하지 않는다 — 연결 참조는 항상 StyleLog → Composition 단방향.
  void linkToComposition(String logId, String compositionId) {
    state = [
      for (final log in state)
        if (log.id == logId) log.copyWith(linkedCompositionId: compositionId) else log,
    ];
  }
}

final styleLogsProvider =
    StateNotifierProvider<StyleLogsNotifier, List<StyleLog>>(
        (ref) => StyleLogsNotifier());

final filteredStyleLogsProvider = Provider<List<StyleLog>>((ref) {
  final logs = ref.watch(styleLogsProvider).where((l) => !l.isDeleted).toList();
  logs.sort((a, b) => b.wornDate.compareTo(a.wornDate));
  return logs;
});

/// [compositionId]에 연결된(삭제되지 않은) StyleLog 목록 — 코디 상세 화면의
/// "연결된 스타일일지" 크로스 레퍼런스 근거.
final styleLogsLinkedToCompositionProvider =
    Provider.family<List<StyleLog>, String>((ref, compositionId) {
  return ref
      .watch(styleLogsProvider)
      .where((l) => !l.isDeleted && l.linkedCompositionId == compositionId)
      .toList();
});

/// [itemId]를 포함하는 코디에 연결된(삭제되지 않은) StyleLog 목록 — 옷 상세 화면의
/// "간접 연결된 스타일일지"(코디를 거쳐 연결) 크로스 레퍼런스 근거.
final styleLogsLinkedToItemProvider =
    Provider.family<List<StyleLog>, String>((ref, itemId) {
  final compositionIds =
      ref.watch(compositionsContainingItemProvider(itemId)).map((c) => c.id).toSet();
  return ref
      .watch(styleLogsProvider)
      .where((l) => !l.isDeleted && compositionIds.contains(l.linkedCompositionId))
      .toList();
});
