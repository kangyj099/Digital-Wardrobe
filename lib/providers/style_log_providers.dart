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

  void softDeleteMany(Set<String> ids) {
    final now = DateTime.now();
    state = [
      for (final log in state)
        if (ids.contains(log.id)) log.copyWith(isDeleted: true, deletedAt: now) else log,
    ];
  }

  void restoreMany(Set<String> ids) {
    state = [
      for (final log in state)
        if (ids.contains(log.id)) log.copyWith(isDeleted: false, deletedAt: null) else log,
    ];
  }

  void purgeMany(Set<String> ids) {
    state = [for (final log in state) if (!ids.contains(log.id)) log];
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
///
/// **의도적으로 `compositionsContainingItemProvider(itemId)`를 watch하지 않고, 그 필터
/// 로직(`!c.isDeleted && c.items.any(...)`)을 아래에 그대로 인라인한다** — provider가
/// 다른 provider를 `ref.watch`하는 provider-to-provider 의존은 Riverpod 내부적으로
/// `invalidateSelf()`(재귀적 무효화) 경로를 타는데, `compositionsProvider`가 바뀐 직후
/// (같은 itemId의 옷 상세를 pop 없이 스택에 남긴 채 다른 경로로 또 push하는 등, 리스너가
/// 계속 살아있는 상황 포함) 새 위젯의 첫 build가 `compositionsContainingItemProvider(itemId)`를
/// 동기적으로 flush하면서 **이미 살아있던 이 provider의 구독이 자기 자신을
/// `invalidateSelf()`하고 그게 `UncontrolledProviderScope.setState()`를 빌드 도중 호출**하는
/// `FlutterError: setState() ... during build` 크래시가 실제로 재현됐다(`docs/history/
/// TechnicalDebt.md` 최상단 버그 항목, VS Code 디버그 세션 + 통합테스트 양쪽에서 스택트레이스
/// 동일하게 확인). `.autoDispose`만으로는 리스너가 0으로 안 떨어지는 경로(같은 itemId 중복
/// push 등)에서 여전히 재현됨 — provider-to-provider watch 자체를 없애야
/// `ProviderElement.invalidateSelf`/`Ref._invalidateSelf` 경로가 원천 차단된다(위젯의
/// `ref.watch`는 단순 `markNeedsBuild()`만 하므로 안전, `consumer.dart` 확인됨). `.autoDispose`는
/// 화면 이탈 시 정리를 위해 그대로 유지.
final styleLogsLinkedToItemProvider =
    Provider.autoDispose.family<List<StyleLog>, String>((ref, itemId) {
  final compositionIds = ref
      .watch(compositionsProvider)
      .where((c) => !c.isDeleted && c.items.any((p) => p.clothingItemId == itemId))
      .map((c) => c.id)
      .toSet();
  return ref
      .watch(styleLogsProvider)
      .where((l) => !l.isDeleted && compositionIds.contains(l.linkedCompositionId))
      .toList();
});
