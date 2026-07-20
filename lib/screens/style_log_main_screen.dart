import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/selection_aware_header_actions.dart';
import '../widgets/style_log_gallery_grid.dart';

/// Main-플랫+필터형 — 그룹 드릴다운 없음(기존 스펙대로 날짜 기준 최신순 고정). FAB는
/// `closet_main_screen.dart`의 2-옵션 팝업 패턴을 그대로 이식.
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

    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.styleLog,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      // 이 화면이 스타일일지의 메인이라는 신호 — `closet_main_screen.dart`와 동일 이유로
      // 헤더 드롭다운 재선택 시 네비게이션 없이 처리되게 한다. 이 화면은 플랫+필터형이라
      // 초기화할 중분류/소분류 상태 자체가 없어 콜백 본문은 비워둔다(그래도 "메인에 있다"는
      // 신호로서 non-null이어야 재선택 시 메인으로의 불필요한 재이동을 막는다).
      onReselectCurrentCategory: () {},
      secondaryControlsRight: [
        GlassCircleButton(icon: Icons.sort, tooltip: '정렬 기준', onTap: () {}),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => StyleLogGalleryGrid(
          logs: logs,
          controller: controller,
          topSpacing: contentTopSpacing,
          onItemTap: (l) {
            if (widget.selectionMode) {
              context.pop(l.id);
            } else {
              context.push(AppRoute.styleLogViewer.replaceFirst(':id', l.id));
            }
          },
        ),
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(
                  label: '1카드 추가',
                  onTap: () => context.push(AppRoute.styleLogAdd),
                ),
                ExpandableAddFabOption(
                  label: '여러카드에 분할 추가',
                  onTap: () => context.push(AppRoute.styleLogAdd),
                ),
              ],
            ),
    );
  }
}
