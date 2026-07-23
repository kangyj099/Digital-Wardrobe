import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/classification_drilldown_capsule.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/selection_aware_header_actions.dart';

/// [selectionMode]가 true면 별도 화면을 새로 만들지 않고 이 Main 화면을 "선택 모달"로
/// 재호출한다 — 기능 재사용 원칙(`_공통 규칙.md`), 표는
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 "선택 모달(옷장/
/// 코디 재호출)" 행. 뒤로가기/카테고리 토글/FAB은 숨기고 헤더 우상단은 "선택"(다중선택)
/// 대신 닫기(X) 버튼으로 바뀐다. 분류 기준 캡슐은 원 화면과 동일 사양으로 유지된다(표에
/// 명시된 예외).
class ClosetMainScreen extends ConsumerStatefulWidget {
  const ClosetMainScreen({super.key, this.selectionMode = false, this.onItemSelected});

  final bool selectionMode;
  final ValueChanged<String>? onItemSelected;

  @override
  ConsumerState<ClosetMainScreen> createState() => _ClosetMainScreenState();
}

class _ClosetMainScreenState extends ConsumerState<ClosetMainScreen> {
  @override
  Widget build(BuildContext context) {
    final criterion = ref.watch(closetSortCriterionProvider);
    // 전역 단순 규칙(Task 3/4에서 확정) — ascending은 모든 기준에서 그대로 "화면에 보이는
    // 방향"과 같다(기준별 반전 없음), 그래서 버튼 아이콘/툴팁도 이 값을 그대로 쓴다.
    final ascending = ref.watch(closetSortAscendingProvider);
    final displayState = ref.watch(closetGridDisplayStateProvider);
    final density = ref.watch(closetDensityProvider);

    final singleLabel = criterion == ClosetSortCriterion.all ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = criterion == ClosetSortCriterion.all ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    // Content Spacer(스펙 §4) — Row1(카테고리 토글/선택) + Row2(캡슐/밀도/◎ 스텁) 높이만
    // 합산한다(groupingBar 밴드는 삭제됨 — 캡슐은 Row2 안의 floating pill이라 별도 밴드가
    // 필요 없음).
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.closet,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      // 이 화면이 옷장의 메인이라는 신호 — 헤더 드롭다운에서 "옷장"을 다시 골라도
      // 네비게이션 없이 이 콜백만 호출된다(사용자 지시, 2026-07-20).
      onReselectCurrentCategory: () {
        ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.all;
        _resetAllDrilldowns(ref);
      },
      secondaryControlsLeft: [
        ClassificationDrilldownCapsule(
          criterionLabels: [for (final c in ClosetSortCriterion.values) c.label],
          selectedCriterionIndex: criterion.index,
          onCriterionChanged: (index) {
            ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.values[index];
            _resetAllDrilldowns(ref);
          },
          hasSubClassification: criterion.hasSubClassification,
          subHint: criterion.hasSubClassification ? criterion.subClassificationHint : null,
          subOptionLabels: _subOptionLabels(ref, criterion),
          selectedSubOptionIndex: _selectedSubOptionIndex(ref, criterion),
          onSubOptionSelected: (index) => _drillInto(ref, criterion, index),
          onClearSubSelection: () => _clearDrilldown(ref, criterion),
        ),
        GlassCircleButton(
          icon: ascending ? Icons.arrow_upward : Icons.arrow_downward,
          tooltip: ascending ? '오름차순' : '내림차순',
          onTap: () => ref.read(closetSortAscendingProvider.notifier).state = !ascending,
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(closetDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
            ref.read(closetDensityProvider.notifier).state = AppDensity.levels[previousIndex];
          },
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) {
          if (displayState == ClosetGridDisplayState.groupOverview) {
            final groups = ref.watch(closetGroupSummariesProvider);
            return ClassificationGroupGrid(
              groups: groups,
              density: density,
              controller: controller,
              topSpacing: contentTopSpacing,
              onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
            );
          }
          final items = ref.watch(filteredClosetItemsProvider);
          return GroupedGalleryGrid(
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
            onIncompleteTap: widget.selectionMode ? (item) => context.push(AppRoute.closetAdd) : null,
          );
        },
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: singleLabel, onTap: () => context.push(AppRoute.closetAdd)),
                ExpandableAddFabOption(label: multiLabel, onTap: () => context.push(AppRoute.closetAdd)),
              ],
            ),
    );
  }

  // 날짜·시간의 소분류(연도)는 고정 옵션이 아니라 실제 데이터에서 나온 그룹 목록이라,
  // closetGroupSummariesProvider를 그대로 라벨 소스로 쓴다 — 그룹 카드 탭과 드롭다운 직접
  // 선택이 정확히 같은 순서/값 집합을 참조하게 되어(스펙 §3.1 "두 진입 경로가 같은 상태로
  // 수렴한다") 드릴인 후 캡슐 텍스트도 자동으로 맞아떨어진다(Review 지적 P0 해결).
  List<String> _subOptionLabels(WidgetRef ref, ClosetSortCriterion criterion) {
    return switch (criterion) {
      ClosetSortCriterion.clothingType => [
          for (final category in ClothingCategory.values) category.label,
          '미분류',
        ],
      ClosetSortCriterion.season => [
          for (final season in Season.values) season.label,
          '미분류',
        ],
      ClosetSortCriterion.dateTime => [
          for (final group in ref.watch(closetGroupSummariesProvider)) group.label,
        ],
      _ => const [],
    };
  }

  int? _selectedSubOptionIndex(WidgetRef ref, ClosetSortCriterion criterion) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        final drilled = ref.watch(closetDrilledCategoryProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified
            ? ClothingCategory.values.length
            : ClothingCategory.values.indexOf(drilled.value as ClothingCategory);
      case ClosetSortCriterion.season:
        final drilled = ref.watch(closetDrilledSeasonProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Season.values.length : Season.values.indexOf(drilled.value as Season);
      case ClosetSortCriterion.dateTime:
        final year = ref.watch(closetDrilledYearProvider);
        if (year == null) return null;
        final groups = ref.watch(closetGroupSummariesProvider);
        final index = groups.indexWhere((g) => g.value == year);
        return index == -1 ? null : index;
      default:
        return null;
    }
  }

  void _drillInto(WidgetRef ref, ClosetSortCriterion criterion, int optionIndex) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state = optionIndex == ClothingCategory.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(ClothingCategory.values[optionIndex]);
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state = optionIndex == Season.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Season.values[optionIndex]);
      case ClosetSortCriterion.dateTime:
        final groups = ref.read(closetGroupSummariesProvider);
        ref.read(closetDrilledYearProvider.notifier).state = groups[optionIndex].value as int;
      default:
        break;
    }
  }

  /// 그룹 카드를 직접 탭했을 때 — [group.value]가 이미 실제 enum 값(또는 미분류=null)이라
  /// `_drillInto`의 인덱스 변환 없이 바로 세팅한다(스펙 §3.1 "두 진입 경로가 같은 상태로
  /// 수렴한다").
  void _drillIntoValue(WidgetRef ref, ClosetSortCriterion criterion, Object? value) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as ClothingCategory);
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Season);
      case ClosetSortCriterion.dateTime:
        ref.read(closetDrilledYearProvider.notifier).state = value as int?;
      default:
        break;
    }
  }

  /// 중분류를 바꿀 때마다 모든 소분류 드릴인 상태를 초기화한다 — 그러지 않으면 "옷 종류"
  /// 에서 "하의"로 드릴인한 뒤 "계절"로 갔다가 다시 "옷 종류"로 돌아왔을 때, 그룹 개요가
  /// 아니라 이전에 골랐던 "하의" 드릴인 상태가 곧장 다시 나타나는 문제가 있었다(사용자
  /// 지시, 2026-07-20 — "이전에 동일 중분류에서 선택한 소분류를 기억하고 있음"). 3개
  /// provider 전부를 무조건 초기화하는 이유: 지금 중분류가 뭐든 상관없이 항상 깨끗한
  /// 상태에서 시작해야 하고, 관련 없는 provider를 null로 되돌리는 건 부작용이 없다.
  void _resetAllDrilldowns(WidgetRef ref) {
    ref.read(closetDrilledCategoryProvider.notifier).state = null;
    ref.read(closetDrilledSeasonProvider.notifier).state = null;
    ref.read(closetDrilledYearProvider.notifier).state = null;
  }

  void _clearDrilldown(WidgetRef ref, ClosetSortCriterion criterion) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state = null;
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state = null;
      case ClosetSortCriterion.dateTime:
        ref.read(closetDrilledYearProvider.notifier).state = null;
      default:
        break;
    }
  }
}
