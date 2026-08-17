import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../models/composition.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_editor_providers.dart';
import '../providers/composition_providers.dart';
import '../services/composition_snapshot_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/editor_header.dart';
import '../widgets/interactive_artboard/artboard_item.dart';
import '../widgets/interactive_artboard/composition_snapshot_capture.dart';
import '../widgets/interactive_artboard/interactive_artboard.dart';

/// 코디 만들기(편집) 화면. `compositionId`가 있으면 기존 코디를 열어 편집, 없으면
/// 빈 아트보드로 시작한다.
///
/// Editor Draft/Commit/Cancel 모델을 따른다(`docs/history/Decision.md` "Editor 저장
/// 모델 전환" 확정, `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md` §레코드 저장
/// 원칙) — 제스처가 끝날 때마다 `compositionDraftProvider`(편집 버퍼)에만 반영되고,
/// `compositionsProvider`(Record)는 건드리지 않는다. 완료(✔)를 눌러야 Draft가 Record에
/// Commit되고, 취소(✕)를 누르면 Draft가 폐기돼 Record는 진입 이전 상태 그대로 유지된다
/// (Rollback). `CompositionItemPlacement` ↔ `ArtboardItem` 변환은
/// `composition_editor_providers.dart`가 담당한다(`docs/superpowers/specs/
/// 2026-07-19-composition-artboard-isolated-widget-design.md` §9 후속 통합 메모).
class CompositionEditorScreen extends ConsumerStatefulWidget {
  const CompositionEditorScreen({super.key, this.compositionId});

  final String? compositionId;

  @override
  ConsumerState<CompositionEditorScreen> createState() => _CompositionEditorScreenState();
}

class _CompositionEditorScreenState extends ConsumerState<CompositionEditorScreen> {
  /// `dispose()` 시점엔 `ref`(`ref.read`/`ref.watch` 전부 포함) 자체가 unsafe하다 —
  /// `State.dispose()`가 호출될 땐 위젯이 이미 unmount 진행 중이라 Riverpod이
  /// `ref` 사용을 막는다(Bad state: Using "ref" when a widget is about to or has
  /// been unmounted is unsafe.). 그래서 아직 `ref`가 안전한 `initState()` 시점에
  /// notifier 인스턴스 자체를 필드에 미리 저장해둔다(Riverpod 표준 패턴).
  late final StateController<String?> _selectedArtboardItemIdNotifier;

  /// 커밋(✔) 재진입 가드 — [_handleCommit]이 실행 중인 동안 true. 커밋이 `context.pop()`에
  /// 도달했거나 `!mounted`로 중단된 뒤에는 **true로 남는다**(그 State는 곧 버려지므로 영구
  /// 잠김이 성립하지 않는다). 근거와 해제 규칙은 [_handleCommit] 본문 주석 참고.
  ///
  /// `setState`로 리빌드하지 않는 순수 동작 플래그다 — 이 값은 화면에 아무것도 렌더하지
  /// 않으므로(버튼의 비활성 표시/스피너 없음, [_handleCommit] 주석 참고) 리빌드할 이유가
  /// 없다.
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _selectedArtboardItemIdNotifier = ref.read(selectedArtboardItemIdProvider.notifier);
  }

  @override
  void dispose() {
    // 이 provider는 family가 아니라 화면을 나가도 값이 남는다 — 다음에 이 화면을
    // (다른 코디로) 다시 열었을 때 이전 선택이 우연히 같은 clothingItemId로 남아
    // 있는 걸 방지하기 위해 리셋한다.
    //
    // 위에서 미리 저장해둔 notifier 인스턴스를 쓰더라도(=`ref` 재접근 없음), dispose()가
    // 호출되는 시점 자체가 여전히 위젯 트리 unmount(빌드/레이아웃 패스) 도중이라 Riverpod이
    // "Tried to modify a provider while the widget tree was building"로 한 번 더 막는다 —
    // 이건 `ref` unsafe 가드와 별개의 두 번째 보호장치다. Riverpod이 권장하는 해법대로
    // `Future(() {...})`로 감싸 현재 빌드/unmount 패스가 완전히 끝난 다음 프레임에서
    // 대입되도록 지연시킨다(`StateController`는 위젯이 아니라 `ProviderContainer`가 들고
    // 있는 객체라 위젯 dispose 이후에도 유효하게 쓸 수 있다).
    //
    // 이 지연 실행 시점엔 그 `ProviderContainer` 자체가 이미 dispose됐을 수 있다(예:
    // 화면을 열었다 빠르게 닫는 통합테스트가 container를 dispose하고 다음 테스트로
    // 넘어간 뒤에야 이 콜백이 실행되는 경우, Tester 발견) — 그러면 `notifier.state = null`이
    // "Bad state: Tried to use StateController<String?> after `dispose` was called.
    // Consider checking `mounted`."로 새 크래시를 낸다. `StateNotifier`(`StateController`의
    // 상위 클래스)가 노출하는 `mounted` getter로 dispose 여부를 먼저 확인해 안전하게
    // 건너뛴다 — 정상 경로(컨테이너가 살아있는 일반적인 화면 이탈)에서는 여전히
    // `mounted`가 true라 리셋이 그대로 실행된다.
    final notifier = _selectedArtboardItemIdNotifier;
    Future(() {
      if (notifier.mounted) {
        notifier.state = null;
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closetItems = ref.watch(closetItemsProvider);
    final draft = ref.watch(compositionDraftProvider(widget.compositionId));
    final artboardItems = draft.items
        .map((placement) => compositionPlacementToArtboardItem(placement, closetItems))
        .whereType<ArtboardItem>()
        .toList();
    final selectedItemId = ref.watch(selectedArtboardItemIdProvider);

    return Scaffold(
      body: Column(
        children: [
          EditorHeader(
            onCancel: _handleCancel,
            onHelpTap: () {}, // Step⑦(기능 구현)에서 실제 도움말/코치마크 연결 예정
            onCommit: _handleCommit,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AspectRatio(
                aspectRatio: 1,
                child: InteractiveArtboard(
                  items: artboardItems,
                  onItemsChanged: _handleItemsChanged,
                  onItemDeleted: _handleItemDeleted,
                  selectedItemId: selectedItemId,
                  onSelectionChanged: (id) =>
                      ref.read(selectedArtboardItemIdProvider.notifier).state = id,
                  backgroundColor: draft.backgroundColor,
                  onBackgroundColorChanged: (color) => ref
                      .read(compositionDraftProvider(widget.compositionId).notifier)
                      .updateBackgroundColor(color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemsChanged(List<ArtboardItem> items) {
    final newPlacements = items.map(artboardItemToCompositionPlacement).toList();
    ref.read(compositionDraftProvider(widget.compositionId).notifier).updateItems(newPlacements);
  }

  void _handleItemDeleted(String itemId) {
    if (ref.read(selectedArtboardItemIdProvider) == itemId) {
      ref.read(selectedArtboardItemIdProvider.notifier).state = null;
    }
    ref.read(compositionDraftProvider(widget.compositionId).notifier).deleteItem(itemId);
  }

  /// 완료(✔) — Draft의 최종 items/backgroundColor를 Record에 반영(Commit)하기 전에
  /// 평면 렌더 스냅샷을 캡처+저장해 `coverImagePath`도 함께 갱신한다
  /// (`docs/reference/data/00_DataSchema.md` §13.2(a)). `EditorHeader.onCommit`은
  /// `VoidCallback`(`void Function()`)이지만 `Future<void> Function()`은 그 서브타입이라
  /// (Dart의 void-반환 공변) 그대로 할당 가능하다.
  ///
  /// 이 메서드는 [_isCommitting]으로 재진입을 막는다(아래 첫 블록 주석).
  Future<void> _handleCommit() async {
    // [재진입 가드] 아래 캡처+저장은 실측 500~800ms 걸리고, 그동안 완료(✔) 버튼은 계속
    // 눌리는 상태로 남는다 — 가드가 없으면 사람의 평범한 연타 간격(150ms)만으로 이 메서드가
    // 두 번 실행돼 두 가지 잘못된 결과가 조용히(Dart 예외 없이) 남는다(Tester 재현:
    // `integration_test/composition_snapshot_followup_b_test.dart`):
    //  1. 스냅샷 PNG가 2개 저장되는데 Record는 1개만 참조한다 — `saveCompositionSnapshot`의
    //     이전 파일 정리는 `previousCoverImagePath` 기준이라, 같은 "이전 경로"를 들고 출발한
    //     두 호출은 서로가 만든 파일을 지우지 못하고 1개가 고아로 영구 잔존한다.
    //  2. 아래 `context.pop()`이 두 번 실행돼 편집기뿐 아니라 호출부인 코디 상세까지 닫히고
    //     코디 메인으로 튕긴다.
    // 두 증상 다 두 번째 호출 자체를 막으면 함께 사라진다. 서비스 계층(파일 정리 규칙)은
    // 손대지 않는다 — 그쪽을 고치면 다른 캡처 경로(§13.2(b) 삭제된 옷 정리 write-back)까지
    // 영향이 번진다.
    //
    // **`context.pop()`에 도달한 뒤에도 가드를 풀지 않는다.** pop이 재진입을 막아주지
    // 못하기 때문이다: `PointerUpEvent`는 새로 hit test를 하지 않고 pointer-down 시점에
    // 잡아둔 결과(`gestures/binding.dart`의 `_hitTests`)로 라우팅되므로, down이 pop 직전
    // up이 pop 직후인 탭은 라우트가 닫히는 중이어도 그대로 `onTap`을 발화시킨다 — 사람
    // 탭의 down→up 간격이 50~120ms라 이 창은 1프레임이 아니라 100ms 규모다(`ModalRoute`가
    // 라우트 서브트리에 거는 `IgnorePointer`는 이미 진행 중인 탭을 취소하지 못하고, 켜지는
    // 시점 자체도 다음 프레임의 첫 애니메이션 틱 이후다).
    //
    // 그렇게 들어온 두 번째 커밋은 가드가 아예 없던 때보다 나쁜 결과를 만든다: 바로 위에서
    // `ref.invalidate`된 Draft가 방금 커밋된 Record로 재생성되고, 그러면
    // `previousCoverImagePath`가 **방금 저장한 새 커버**가 되어 두 번째
    // `saveCompositionSnapshot`이 Record가 지금 가리키는 파일을 지운다. 그 사이 라우트는
    // 이미 dispose돼 아래 `!mounted`에 걸리므로 Record는 갱신되지 않는다 = 존재하지 않는
    // 파일을 영구히 가리키게 된다(`CompositionCoverImage`의 `Image.file`이 깨진다).
    //
    // 그래서 해제는 "이 화면이 살아남는 경로"에서만 한다 — 아래 `catch` 하나뿐이다. pop에
    // 도달했거나 `!mounted`로 빠져나온 경로는 이 State가 곧 버려지고 dispose된 State는 다시
    // mount되지 않으므로, true로 남겨두는 것이 맞다.
    //
    // 버튼을 비활성으로 그리거나 스피너를 넣지는 않는다(시각적 상태는 별도 판단 대상) —
    // 그래서 이 플래그는 `setState` 없이 순수 동작 가드로만 쓴다.
    if (_isCommitting) return;
    _isCommitting = true;
    try {
      final draft = ref.read(compositionDraftProvider(widget.compositionId));
      final compositionId = draft.compositionId;
      final closetItems = ref.read(closetItemsProvider);
      final artboardItems = draft.items
          .map((placement) => compositionPlacementToArtboardItem(placement, closetItems))
          .whereType<ArtboardItem>()
          .toList();

      final newId = compositionId ?? 'comp_${DateTime.now().microsecondsSinceEpoch}';
      final previousCoverImagePath = compositionId == null
          ? null
          : ref.read(compositionsProvider).firstWhere((c) => c.id == compositionId).coverImagePath;

      String? newCoverImagePath;
      try {
        final pngBytes = await captureCompositionSnapshot(
          context,
          items: artboardItems,
          backgroundColor: draft.backgroundColor,
        );
        newCoverImagePath = await saveCompositionSnapshot(
          compositionId: newId,
          pngBytes: pngBytes,
          previousCoverImagePath: previousCoverImagePath,
        );
      } catch (_) {
        // §13.3 실패 처리 — 캡처/저장 실패는 커밋 자체를 막지 않는다(non-fatal). 기존
        // coverImagePath를 그대로 두고 items/backgroundColor/isIncomplete 갱신은 계속
        // 진행한다.
        newCoverImagePath = null;
      }

      // [§13.2(a)] 위 캡처/저장이 여러 await를 거치는 동안 화면이 이미 unmount됐을 수
      // 있다 — 이후 `ref`/`context` 사용(커밋 반영, pop) 전에 반드시 확인한다. `State.context`를
      // 쓰는 화면이라 `context.mounted`가 아니라 `mounted`(State 자체의 getter)로 가드해야
      // `use_build_context_synchronously` 린트가 뒤이은 `context.pop()`까지 안전하다고
      // 인식한다(`flutter-implementation-conventions` 스킬의 `if (!mounted) return;` 관례).
      if (!mounted) return;

      if (compositionId != null) {
        ref.read(compositionsProvider.notifier).updateItems(
              compositionId,
              draft.items,
              backgroundColor: draft.backgroundColor,
              coverImagePath: newCoverImagePath,
            );
      } else {
        ref.read(compositionsProvider.notifier).add(
              Composition(
                id: newId,
                name: '새 코디',
                items: draft.items,
                createdAt: DateTime.now(),
                backgroundColor: draft.backgroundColor,
                coverImagePath: newCoverImagePath,
                isIncomplete: draft.items.isEmpty,
              ),
            );
      }
      ref.invalidate(compositionDraftProvider(widget.compositionId));
      context.pop();
    } catch (_) {
      // 화면이 그대로 남는 유일한 이탈 경로 — 안쪽 `catch (_)`가 담당하지 않는 예상 밖 예외
      // (Record 조회 실패, 커밋/pop 중 오류 등)다. 여기서 풀어야 사용자가 완료를 다시 누를 수
      // 있다. 캡처/저장 실패 자체는 §13.3대로 안쪽 catch가 삼키고 커밋을 계속 진행하므로 이
      // 경로로 오지 않는다 — 캡처가 실패했다는 이유로 버튼이 잠기는 일은 없다.
      //
      // 예외는 삼키지 않고 그대로 흘려보낸다(rethrow) — 삼키면 이 가드 수정이 §13.3 범위 밖의
      // 실패까지 조용히 감추게 된다(수정 전 동작 유지).
      _isCommitting = false;
      rethrow;
    }
  }

  /// 취소(✕) — Record는 손대지 않고 Draft만 폐기한다(진짜 Rollback).
  void _handleCancel() {
    ref.invalidate(compositionDraftProvider(widget.compositionId));
    context.pop();
  }
}
