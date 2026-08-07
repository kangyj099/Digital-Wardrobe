import 'composition.dart';
import 'enums.dart';

/// 코디 편집기(Editor)의 편집 버퍼(Draft). Record(`Composition`)를 직접 수정하지 않고
/// 이 Draft에만 실시간 반영하다가, 완료(✔) 시점에만 Record에 Commit한다 — 취소(✕)
/// 시엔 Draft만 버려 Record가 Editor 진입 이전 상태 그대로 유지된다(진짜 의미의
/// Rollback). `docs/history/Decision.md` "Editor 저장 모델 전환" 확정,
/// `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md` §레코드 저장 원칙(Editor 세션 —
/// Draft + Commit) 참고.
class CompositionDraft {
  const CompositionDraft({
    this.compositionId,
    required this.items,
    required this.backgroundColor,
  });

  /// 편집 대상 Composition의 id. `null`이면 신규 생성(아직 Record가 없음) — Commit
  /// 시점에 `compositionsProvider.notifier.add`로 새 레코드를 만든다. 편집 도중
  /// 바뀌지 않는다(family key와 동일 값 — `copyWith`에 파라미터 없음).
  final String? compositionId;

  final List<CompositionItemPlacement> items;

  /// `Composition.backgroundColor`(nullable)에 대응하는 편집 중 값 — Draft는 항상
  /// 구체적인 값을 들고 있다(비어있는 상태 없음, 기본값 흰색). Commit 시점에
  /// `compositionsProvider.notifier.updateItems`/`add`를 통해 Record에 반영된다.
  final ArtboardBackgroundColor backgroundColor;

  CompositionDraft copyWith({
    List<CompositionItemPlacement>? items,
    ArtboardBackgroundColor? backgroundColor,
  }) {
    return CompositionDraft(
      compositionId: compositionId,
      items: items ?? this.items,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
