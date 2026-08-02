import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../models/style_log.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/gallery_main_screen.dart';
import '../widgets/glass_toast.dart';
import '../widgets/selection_aware_header_actions.dart';
import '../widgets/style_log_gallery_grid.dart';

/// Main-플랫+필터형 — 그룹 드릴다운 없음(기존 스펙대로 날짜 기준 최신순 고정). `classification`을
/// 아예 넘기지 않아 `GalleryMainScreen`의 기본값(null)을 그대로 쓴다 — 이 화면이
/// `classification: null` 경로(캡슐/밀도 UI 없음)의 첫 실사용례.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 참고.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(스타일일지 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(log.id)`로 결과를 반환한다. 호출부는 `context.push<String>(AppRoute.styleLogSelect)`로
/// 열고 반환값을 기다리면 된다(`lib/screens/composition_detail_screen.dart` 사용례 참고).
class StyleLogMainScreen extends ConsumerStatefulWidget {
  const StyleLogMainScreen({super.key, this.selectionMode = false});

  /// true면 선택 모달로 동작 — 타일 탭 시 상세 화면 대신 `context.pop(id)`로 결과 반환.
  final bool selectionMode;

  @override
  ConsumerState<StyleLogMainScreen> createState() => _StyleLogMainScreenState();
}

class _StyleLogMainScreenState extends ConsumerState<StyleLogMainScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(filteredStyleLogsProvider);

    return GalleryMainScreen<StyleLog>(
      current: AppCategory.styleLog,
      items: logs,
      itemId: (log) => log.id,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      selectionMode: widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      // 이 화면이 스타일일지의 메인이라는 신호 — `closet_main_screen.dart`와 동일 이유로
      // 헤더 드롭다운 재선택 시 네비게이션 없이 처리되게 한다. 이 화면은 플랫+필터형이라
      // 초기화할 중분류/소분류 상태 자체가 없어 콜백 본문은 비워둔다(그래도 "메인에 있다"는
      // 신호로서 non-null이어야 재선택 시 메인으로의 불필요한 재이동을 막는다).
      onReselectCurrentCategory: () {},
      onItemTap: (log) {
        if (widget.selectionMode) {
          context.pop(log.id);
        } else {
          context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id));
        }
      },
      onDeleteSelected: (ids) {
        ref.read(styleLogsProvider.notifier).softDeleteMany(ids);
        GlassToast.show(
          context,
          message: '${ids.length}개 항목이 휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(styleLogsProvider.notifier).restoreMany(ids),
        );
      },
      gridBuilder: ({
        required density,
        required controller,
        required topSpacing,
        required multiSelectMode,
        required selectedIds,
        required onItemTap,
        required onItemLongPress,
      }) {
        return StyleLogGalleryGrid(
          logs: logs,
          controller: controller,
          topSpacing: topSpacing,
          multiSelectMode: multiSelectMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      },
      fab: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: '1카드 추가', onTap: () => context.push(AppRoute.styleLogAdd)),
                ExpandableAddFabOption(
                  label: '여러카드에 분할 추가',
                  onTap: () => context.push(AppRoute.styleLogAdd),
                ),
              ],
            ),
    );
  }
}
