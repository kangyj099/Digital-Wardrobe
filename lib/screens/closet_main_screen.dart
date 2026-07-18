import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/glass_pill.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/selection_aware_header_actions.dart';
import 'skeleton_region.dart';

/// [selectionMode]가 true면 별도 화면을 새로 만들지 않고 이 Main 화면을 "선택 모달"로
/// 재호출한다 — 기능 재사용 원칙(`_공통 규칙.md`), 표는
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 "선택 모달(옷장/
/// 코디 재호출)" 행. 뒤로가기/카테고리 토글/FAB은 숨기고 헤더 우상단은 "선택"(다중선택)
/// 대신 닫기(X) 버튼으로 바뀐다. 그룹형 드릴다운(`groupingBar`)은 원 화면과 동일 사양으로
/// 유지된다(표에 명시된 예외).
class ClosetMainScreen extends ConsumerStatefulWidget {
  const ClosetMainScreen({super.key, this.selectionMode = false, this.onItemSelected});

  /// true면 선택 모달로 동작 — 실제 호출부(Composition Editor 등) 연결은 Step⑦ 몫.
  final bool selectionMode;

  /// [selectionMode]일 때 타일 탭 시 호출되는 선택 콜백(선택된 항목 id). 실제 바인딩
  /// 로직(go_router result 반환 등)은 아직 없음 — Step⑦ 위임.
  final ValueChanged<String>? onItemSelected;

  @override
  ConsumerState<ClosetMainScreen> createState() => _ClosetMainScreenState();
}

class _ClosetMainScreenState extends ConsumerState<ClosetMainScreen> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(filteredClosetItemsProvider);
    final season = ref.watch(selectedSeasonFilterProvider);
    final density = ref.watch(closetDensityProvider);

    final singleLabel = season == null ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = season == null ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    // Content Spacer(스펙 §4) — Row1(카테고리 토글/선택) + Row2(계절/밀도/◎ 스텁) +
    // groupingBar(skeleton) 밴드 높이를 합산해, 아래 AppScrollContainer의 스크롤 콘텐츠
    // 상단 padding으로 그대로 넘긴다(`AppMainScaffold`가 Positioned하는 밴드 높이와
    // 반드시 일치해야 하는 값이라 이 상수 헬퍼를 통해서만 계산한다).
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(
      hasSecondaryRow: true,
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
    );

    return AppMainScaffold(
      current: AppCategory.closet,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      // 두 번째 툴바 행 — 옷장 메인 하이파이 디자인 주문서 기준(계절 세그먼트/밀도 버튼/
      // 우측 원형 버튼 3개가 각각 독립 floating, Header/HUD Pinned Rule).
      secondaryControlsLeft: [
        GlassPill(
          child: DropdownButton<Season?>(
            value: season,
            hint: const Text('계절'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<Season?>(value: null, child: Text('전체')),
              ...Season.values.map(
                (s) => DropdownMenuItem<Season?>(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (value) => ref.read(selectedSeasonFilterProvider.notifier).state = value,
          ),
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(closetDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0
                ? AppDensity.levels.length - 1
                : currentIndex - 1;
            final next = AppDensity.levels[previousIndex];
            ref.read(closetDensityProvider.notifier).state = next;
          },
        ),
        // 기능 미정 스텁(디자인 주문서 "최우측 원형 버튼 ◎") — 자리만 확보, onPressed 없음.
        GlassCircleButton(icon: Icons.adjust, tooltip: '(미정)', onTap: () {}),
      ],
      groupingBar: skeletonRegion(
        context,
        '분류 선택 바 (그룹형 드릴다운) — Step⑦(기능 구현)에서 실제 드릴다운으로 대체 예정',
        height: AppMainScaffold.defaultGroupingBarHeight,
      ),
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => GroupedGalleryGrid(
          items: items,
          density: density,
          controller: controller,
          topSpacing: contentTopSpacing,
          onItemTap: (item) {
            if (widget.selectionMode) {
              widget.onItemSelected?.call(item.id);
            } else {
              context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id));
            }
          },
          // selectionMode에서만 미완성 항목 탭을 되살려 완성 화면으로 이동시킨다
          // (네이티브 진입 시에는 null → 기존처럼 비활성화 유지).
          onIncompleteTap: widget.selectionMode
              ? (item) {
                  // TODO(Step⑦): closetAdd가 기존 미완성 레코드(item.id)를 이어서
                  // 열도록 확장되면 여기서 id를 넘긴다. 지금은 화면 자체가 그 기능이
                  // 없어(스켈레톤 상태) 새 추가 화면으로만 이동.
                  context.push(AppRoute.closetAdd);
                }
              : null,
        ),
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(
                  label: singleLabel,
                  onTap: () => context.push(AppRoute.closetAdd),
                ),
                ExpandableAddFabOption(
                  label: multiLabel,
                  onTap: () => context.push(AppRoute.closetAdd),
                ),
              ],
            ),
    );
  }
}
