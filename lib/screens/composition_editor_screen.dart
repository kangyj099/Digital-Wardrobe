import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../models/composition.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_editor_providers.dart';
import '../providers/composition_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/editor_header.dart';
import '../widgets/interactive_artboard/artboard_item.dart';
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

  /// 완료(✔) — Draft의 최종 items/backgroundColor를 Record에 반영(Commit)하고
  /// Draft를 정리한다.
  void _handleCommit() {
    final draft = ref.read(compositionDraftProvider(widget.compositionId));
    final compositionId = draft.compositionId;
    if (compositionId != null) {
      ref.read(compositionsProvider.notifier).updateItems(
            compositionId,
            draft.items,
            backgroundColor: draft.backgroundColor,
          );
    } else {
      final newId = 'comp_${DateTime.now().microsecondsSinceEpoch}';
      ref.read(compositionsProvider.notifier).add(
            Composition(
              id: newId,
              name: '새 코디',
              items: draft.items,
              createdAt: DateTime.now(),
              backgroundColor: draft.backgroundColor,
            ),
          );
    }
    ref.invalidate(compositionDraftProvider(widget.compositionId));
    context.pop();
  }

  /// 취소(✕) — Record는 손대지 않고 Draft만 폐기한다(진짜 Rollback).
  void _handleCancel() {
    ref.invalidate(compositionDraftProvider(widget.compositionId));
    context.pop();
  }
}
