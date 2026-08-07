// lib/providers/composition_editor_providers.dart
import 'package:flutter_riverpod/legacy.dart';
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/composition_draft.dart';
import '../models/enums.dart';
import '../widgets/interactive_artboard/artboard_item.dart';
import 'composition_providers.dart';

/// 코디 편집기 화면에서 현재 선택된 아이템의 `ArtboardItem.id`(=`clothingItemId`,
/// 아래 변환 함수 참고). `InteractiveArtboard`의 `selectedItemId`/`onSelectionChanged`
/// controlled 계약(`docs/superpowers/specs/2026-07-19-composition-artboard-isolated-widget-design.md`
/// §5/§9)을 화면 레벨에서 소유하는 단일 소스 — family가 필요 없다(화면 하나에
/// 에디터도 하나, §9 SelectionManager 설계 의도).
final selectedArtboardItemIdProvider = StateProvider<String?>((ref) => null);

/// `CompositionItemPlacement` → `ArtboardItem` 변환(스펙 §9 후속 통합 메모).
///
/// `ArtboardItem.id`는 `clothingItemId`를 그대로 재사용한다 — `CompositionItemPlacement`엔
/// 별도 식별자가 없고, 코디 하나에 동일 옷이 두 번 배치되는 시나리오는 현재 데이터
/// 모델도 전제하지 않는다.
///
/// 매칭되는 [ClothingItem]이 [closetItems]에 없으면(예: 완전 삭제된 옷) `null`을
/// 반환한다 — 호출부가 걸러낸다.
ArtboardItem? compositionPlacementToArtboardItem(
  CompositionItemPlacement placement,
  List<ClothingItem> closetItems,
) {
  final matches = closetItems.where((item) => item.id == placement.clothingItemId);
  if (matches.isEmpty) return null;
  return ArtboardItem(
    id: placement.clothingItemId,
    imagePath: matches.first.imagePath,
    x: placement.x,
    y: placement.y,
    scale: placement.scale,
    rotation: placement.rotation,
    zIndex: placement.zIndex,
  );
}

/// `ArtboardItem` → `CompositionItemPlacement` 역변환(저장 시점, 위 함수의 역).
CompositionItemPlacement artboardItemToCompositionPlacement(ArtboardItem item) {
  return CompositionItemPlacement(
    clothingItemId: item.id,
    x: item.x,
    y: item.y,
    scale: item.scale,
    rotation: item.rotation,
    zIndex: item.zIndex,
  );
}

/// 코디 편집기의 편집 버퍼(`CompositionDraft`) notifier — Editor Draft/Commit/Cancel
/// 모델(`docs/history/Decision.md` "Editor 저장 모델 전환"). 제스처가 끝날 때마다
/// 이 Draft에만 반영되고, `compositionsProvider`(Record)는 화면이 명시적으로 Commit할
/// 때만 건드린다.
class CompositionDraftNotifier extends StateNotifier<CompositionDraft> {
  CompositionDraftNotifier(super.initial);

  void updateItems(List<CompositionItemPlacement> items) {
    state = state.copyWith(items: items);
  }

  void deleteItem(String clothingItemId) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.clothingItemId != clothingItemId) item,
      ],
    );
  }

  void updateBackgroundColor(ArtboardBackgroundColor color) {
    state = state.copyWith(backgroundColor: color);
  }
}

/// family key = 편집 대상 Composition id(`null`이면 신규 생성). `autoDispose`가 아니다 —
/// 화면을 나갔다가 취소/완료를 거치지 않고(예: 시스템 뒤로가기) 다시 들어오면 같은
/// key의 기존 인스턴스를 그대로 재사용해 진행 중이던 편집이 남아있어야 한다(Decision.md
/// "기존 미커밋 Draft가 있으면 재사용"). 취소(✕)/완료(✔) 시에만 화면이 명시적으로
/// `ref.invalidate`로 이 인스턴스를 폐기한다.
///
/// 진입 시 [compositionsProvider]에서 해당 Record를 **한 번만**(`ref.read` — `ref.watch`가
/// 아님) 읽어 `items`/`backgroundColor`로 초기화한다. Draft는 독립 편집 버퍼라 초기화
/// 이후 Record가 다른 경로로 바뀌어도 자동 재동기화되면 안 된다. Record의
/// `backgroundColor`가 `null`이면(아직 한 번도 저장된 적 없음) 기본값(흰색)으로
/// 시작한다.
final compositionDraftProvider =
    StateNotifierProvider.family<CompositionDraftNotifier, CompositionDraft, String?>(
  (ref, compositionId) {
    if (compositionId == null) {
      return CompositionDraftNotifier(
        const CompositionDraft(items: [], backgroundColor: ArtboardBackgroundColor.white),
      );
    }
    final composition =
        ref.read(compositionsProvider).where((c) => c.id == compositionId).firstOrNull;
    return CompositionDraftNotifier(
      CompositionDraft(
        compositionId: compositionId,
        items: composition?.items ?? const [],
        backgroundColor: composition?.backgroundColor ?? ArtboardBackgroundColor.white,
      ),
    );
  },
);
