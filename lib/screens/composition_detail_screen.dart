import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_editor_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_toast.dart';
import '../widgets/interactive_artboard/artboard_item.dart';
import '../widgets/interactive_artboard/static_artboard.dart';
import '../widgets/status_badge.dart';
import '../widgets/style_log_cross_reference_gallery.dart';
import 'app_detail_scaffold.dart';

/// "사용된 옷" 가로 목록 타일 1개의 너비(논리픽셀) — 이미지/이름 `SizedBox` 폭과 동일한
/// 값을 여기 명명 상수로도 둬서, 아트보드 탭→스크롤 시 목표 오프셋(`index * 타일폭`)
/// 계산에 재사용한다(매직넘버 중복 방지).
const double _usedItemTileWidth = 72;

/// 타일 사이 가로 간격 — 아래 `ListView.separated`의 `separatorBuilder`와 동일 값
/// (`AppSpacing.xs`)을 그대로 참조.
const double _usedItemGap = AppSpacing.xs;

const double _usedItemExtent = _usedItemTileWidth + _usedItemGap;

/// 아트보드에서 아이템을 탭했을 때 "사용된 옷" 목록에 거는 강조 테두리의 지속 시간
/// (스펙 §코디 상세 "하단 옷 목록에서 해당 옷 위치로 스크롤 + 강조 표시", 정확한 수치는
/// Worker 재량).
const Duration _highlightDuration = Duration(milliseconds: 1500);

/// 코디 상세 — 상단 정적 아트보드(스펙 §코디 상세, `StaticArtboard`)와 사용된 옷 목록,
/// 연결된 스타일일지를 실제 mock 데이터로 표시한다. 연결된 스타일일지가 없으면 크로스
/// 레퍼런스 바에 "+" 바인딩 항목이 뜨고, 탭하면 스타일일지 선택 모달
/// (`AppRoute.styleLogSelect`)을 열어 기존 스타일일지를 골라 연결한다(신규 생성 바인딩은
/// 스코프 밖 — `docs/superpowers/plans/2026-07-15-step7-detail-binding.md` Global
/// Constraints 참고).
class CompositionDetailScreen extends ConsumerStatefulWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  ConsumerState<CompositionDetailScreen> createState() => _CompositionDetailScreenState();
}

class _CompositionDetailScreenState extends ConsumerState<CompositionDetailScreen> {
  final ScrollController _usedItemsScrollController = ScrollController();
  String? _highlightedItemId;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _usedItemsScrollController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _bindStyleLog(BuildContext context, WidgetRef ref) async {
    final selectedLogId = await context.push<String>(AppRoute.styleLogSelect);
    if (selectedLogId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(selectedLogId, widget.compositionId);
    }
  }

  /// 아트보드 아이템 탭(단일 또는 겹침 팝업에서 선택) 공통 핸들러 — [usedItems] 안에서
  /// 같은 id를 찾아 그 위치로 스크롤하고 잠깐 테두리로 강조한다(스펙 §코디 상세).
  void _handleArtboardItemTap(String itemId, List<ClothingItem> usedItems) {
    final index = usedItems.indexWhere((item) => item.id == itemId);
    if (index != -1 && _usedItemsScrollController.hasClients) {
      final targetOffset = (index * _usedItemExtent).clamp(
        0.0,
        _usedItemsScrollController.position.maxScrollExtent,
      );
      _usedItemsScrollController.animateTo(
        targetOffset,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
      );
    }
    _highlightTimer?.cancel();
    setState(() => _highlightedItemId = itemId);
    _highlightTimer = Timer(_highlightDuration, () {
      if (!mounted) return;
      setState(() => _highlightedItemId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final compositionId = widget.compositionId;
    final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
    final closetItems = ref.watch(closetItemsProvider);
    final usedItems = <ClothingItem>[
      for (final placement in composition.items)
        ...closetItems.where((item) => item.id == placement.clothingItemId),
    ];
    final artboardItems = composition.items
        .map((placement) => compositionPlacementToArtboardItem(placement, closetItems))
        .whereType<ArtboardItem>()
        .toList();
    final linkedStyleLogs = ref.watch(styleLogsLinkedToCompositionProvider(compositionId));

    return AppDetailScaffold(
      category: AppCategory.composition,
      onDelete: () {
        // [Review P0 수정] `context.pop()` 이후 팝된 화면의 element는 dispose되고, `ref`는
        // 그 element에 묶여 있어 나중(토스트 액션 탭 시점)에 `ref.read(...)`를 호출하면
        // `ConsumerStatefulElement._assertNotDisposed()`가 release 빌드에서도 `StateError`를
        // 던진다(`ref`가 화면보다 오래 산다는 가정이 틀렸음 — Review가 `flutter_riverpod`
        // 실제 소스로 확인). `ref`가 아니라 notifier 객체 자체를 pop 이전에 미리 캡처해
        // 재사용한다 — `StateNotifier`는 위젯과 독립적으로 살아있다.
        final notifier = ref.read(compositionsProvider.notifier);
        notifier.softDeleteMany({compositionId});
        context.pop();
        // 스펙(`05_삭제 & 휴지통.md` "동작") "휴지통으로 이동됨 · 실행취소" — 메인 갤러리
        // 다중선택 삭제(`composition_main_screen.dart`)와 동일한 실행취소 패턴을 상세 화면
        // 단일삭제 진입점에도 적용한다.
        GlassToast.show(
          context,
          message: '휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => notifier.restoreMany({compositionId}),
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(composition.name, style: Theme.of(context).textTheme.headlineSmall),
            if (composition.season != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(composition.season!.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: 1,
              child: StaticArtboard(
                items: artboardItems,
                backgroundColor: composition.backgroundColor ?? ArtboardBackgroundColor.white,
                onItemTap: (itemId) => _handleArtboardItemTap(itemId, usedItems),
                onEditRequested: () => context.push(
                  AppRoute.compositionEditorWithId.replaceFirst(':id', compositionId),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('사용된 옷', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 96,
              child: ListView.separated(
                controller: _usedItemsScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: usedItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: _usedItemGap),
                itemBuilder: (context, index) {
                  final item = usedItems[index];
                  final isHighlighted = item.id == _highlightedItemId;
                  return GestureDetector(
                    key: ValueKey(item.id),
                    onTap: item.isDeleted
                        ? null
                        : () =>
                            context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: _usedItemTileWidth,
                          height: _usedItemTileWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: isHighlighted
                                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: Image.asset(item.imagePath, fit: BoxFit.cover),
                                ),
                              ),
                              if (item.isDeleted)
                                const Positioned(
                                  top: AppSpacing.xxs,
                                  left: AppSpacing.xxs,
                                  child: StatusBadge(label: '삭제됨'),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: _usedItemTileWidth,
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('연결된 스타일일지', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            StyleLogCrossReferenceGallery(
              logs: linkedStyleLogs,
              onTap: (log) => context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
              onAddTap: () => _bindStyleLog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
