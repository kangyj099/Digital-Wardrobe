// lib/providers/composition_editor_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/composition_draft.dart';
import '../models/enums.dart';
import '../services/composition_snapshot_service.dart';
import '../widgets/interactive_artboard/artboard_item.dart';
import '../widgets/interactive_artboard/composition_snapshot_capture.dart';
import 'closet_providers.dart';
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

/// 코디 편집 진입 시 "삭제된 옷 자동 정리" 확인/실행 가드
/// (`docs/reference/data/00_DataSchema.md` §13.2(b), `docs/history/Decision.md` "코디
/// 스냅샷 캡처/로컬 저장 아키텍처 확정"). 편집 화면이 아니라 **네비게이션 호출부**(코디
/// 상세의 편집 진입 지점)에서 `context.push`보다 먼저 호출돼야 한다 — `compositionDraftProvider`의
/// `create`가 `compositionsProvider`를 한 번만 읽으므로, Draft가 초기화되기 전에 이미
/// 정리된 Record 상태여야 한다.
///
/// 정리할 게 없으면(§13.4 판정에 걸리는 placement가 하나도 없으면) 다이얼로그 없이 즉시
/// `true`를 반환한다(캐스케이드 정리가 없다는 뜻이라 Draft를 건드릴 이유가 없다). 있으면
/// 확인 다이얼로그를 띄우고, 사용자가 취소하면 `false`(호출부는 네비게이션하지 않는다),
/// 진행을 선택하면: 정리된 items로 새 스냅샷을 캡처+저장 → `updateItems`로 Record에
/// write-back(`backgroundColor`는 그대로 유지) → **실제로 정리를 실행한 이 경로에서만**
/// `compositionDraftProvider(compositionId)`를 invalidate한다(Stale-Draft carve-out,
/// §13.2(b) — `compositionDraftProvider`가 `autoDispose`가 아니라서 방치된 기존 Draft가
/// 있으면 이 정리를 무시한 채 재사용될 수 있기 때문. "정리할 게 없는" no-op 경로는 이
/// invalidate를 절대 호출하지 않는다 — 기존 "방치 Draft 재사용" 결정을 뒤집지 않는 좁은
/// 예외).
Future<bool> confirmAndCleanUpDeletedItemsBeforeEditing(
  BuildContext context,
  WidgetRef ref,
  String compositionId,
) async {
  final deletedPlacements = ref.read(compositionDeletedItemPlacementsProvider(compositionId));
  if (deletedPlacements.isEmpty) return true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('삭제된 옷이 포함돼 있어요'),
      content: Text('삭제된 옷 ${deletedPlacements.length}개 포함, 편집 시작 시 자동 제거돼요.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('진행')),
      ],
    ),
  );
  if (confirmed != true) return false;
  if (!context.mounted) return false;

  final composition = ref.read(compositionsProvider).firstWhere((c) => c.id == compositionId);
  final deletedIds = deletedPlacements.map((p) => p.clothingItemId).toSet();
  final cleanedItems = [
    for (final item in composition.items)
      if (!deletedIds.contains(item.clothingItemId)) item,
  ];

  final closetItems = ref.read(closetItemsProvider);
  final artboardItems = cleanedItems
      .map((placement) => compositionPlacementToArtboardItem(placement, closetItems))
      .whereType<ArtboardItem>()
      .toList();

  String? newCoverImagePath;
  try {
    final pngBytes = await captureCompositionSnapshot(
      context,
      items: artboardItems,
      backgroundColor: composition.backgroundColor ?? ArtboardBackgroundColor.white,
    );
    newCoverImagePath = await saveCompositionSnapshot(
      compositionId: compositionId,
      pngBytes: pngBytes,
      previousCoverImagePath: composition.coverImagePath,
    );
  } catch (_) {
    // §13.3 실패 처리 — 캡처/저장 실패는 non-fatal, 기존 coverImagePath를 유지한 채
    // 정리(items write-back)는 그대로 진행한다.
    newCoverImagePath = null;
  }

  ref.read(compositionsProvider.notifier).updateItems(
        compositionId,
        cleanedItems,
        coverImagePath: newCoverImagePath,
      );
  // Stale-Draft carve-out — 실제로 정리를 실행한 이 경로에서만 호출한다(위 함수 문서
  // 참고). no-op 경로("정리할 게 없음")는 이 줄에 도달하지 않는다.
  ref.invalidate(compositionDraftProvider(compositionId));

  return true;
}
