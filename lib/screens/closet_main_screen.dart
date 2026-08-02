import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/gallery_main_screen.dart';
import '../widgets/glass_toast.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/selection_aware_header_actions.dart';

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
    final ascending = ref.watch(closetSortAscendingProvider);
    final displayState = ref.watch(closetGridDisplayStateProvider);
    final density = ref.watch(closetDensityProvider);
    final items = ref.watch(filteredClosetItemsProvider);
    final groups = ref.watch(closetGroupSummariesProvider);

    final singleLabel = criterion == ClosetSortCriterion.all ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = criterion == ClosetSortCriterion.all ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    return GalleryMainScreen<ClothingItem>(
      current: AppCategory.closet,
      items: items,
      itemId: (item) => item.id,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      selectionMode: widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      onReselectCurrentCategory: () {
        ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.all;
        _resetAllDrilldowns(ref);
      },
      classification: ClassificationConfig<ClothingItem>(
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
        density: density,
        // 전달받은 `current` 인자를 그대로 쓰지 않고 여기서 다시 ref.read로 최신값을
        // 조회한다 — `GalleryMainScreen`의 밀도 버튼 onTap이 `widget.classification!.density`
        // (직전 build 시점 스냅샷)를 캡처해 넘기므로, 프레임 반영 없이 연속 탭하면(리빌드가
        // 끼어들지 않으면) 두 번째 탭도 같은 스냅샷을 넘겨받아 순환이 깨진다(stale-closure
        // race, commit 10d3643이 고친 것과 동일한 버그가 GalleryMainScreen 도입으로
        // 재발했었음 — 옷장 메인 회귀테스트가 실제로 이 재발을 잡아냄, 2026-07-28).
        // ref.read로 탭 시점 최신 상태를 직접 조회하면 이 스냅샷 지연과 무관해진다.
        onDensityChanged: (_) {
          final latest = ref.read(closetDensityProvider);
          final currentIndex = AppDensity.levels.indexOf(latest);
          final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
          ref.read(closetDensityProvider.notifier).state = AppDensity.levels[previousIndex];
        },
        ascending: ascending,
        // 위 onDensityChanged와 동일한 이유로 전달받은 `value`(스냅샷 기반 `!ascending`)를
        // 그대로 쓰지 않고, ref.read로 최신 상태를 다시 읽어 반전한다.
        onAscendingChanged: (_) =>
            ref.read(closetSortAscendingProvider.notifier).state = !ref.read(closetSortAscendingProvider),
      ),
      onItemTap: (item) {
        if (widget.selectionMode) {
          widget.onItemSelected?.call(item.id);
        } else {
          context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id));
        }
      },
      onDeleteSelected: (ids) => _confirmAndDelete(context, ref, ids),
      gridBuilder: ({
        required density,
        required controller,
        required topSpacing,
        required multiSelectMode,
        required selectedIds,
        required onItemTap,
        required onItemLongPress,
      }) {
        if (displayState == ClosetGridDisplayState.groupOverview) {
          return ClassificationGroupGrid(
            groups: groups,
            density: density,
            controller: controller,
            topSpacing: topSpacing,
            onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
          );
        }
        return GroupedGalleryGrid(
          items: items,
          density: density,
          controller: controller,
          topSpacing: topSpacing,
          multiSelectMode: multiSelectMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onIncompleteTap: widget.selectionMode ? (item) => context.push(AppRoute.closetAdd) : null,
        );
      },
      fab: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: singleLabel, onTap: () => context.push(AppRoute.closetAdd)),
                ExpandableAddFabOption(label: multiLabel, onTap: () => context.push(AppRoute.closetAdd)),
              ],
            ),
    );
  }

  /// 스펙(`05_삭제 & 휴지통.md` 42행)이 요구하는 사전 경고 — 선택된 옷 중 코디에 쓰이는
  /// 게 있으면 확인을 받는다. "각 코디는 다음 편집 시 자동으로 제거돼요"라는 캐스케이드
  /// 자동정리 약속은 "Editor Draft 구현" 후속 작업 전까지 실제로 없으므로 문구에서 뺀다
  /// (프로젝트 홀리스틱 Audit 지적, 2026-07-21 — 이 단순 경고 자체는 Group B 스코프에 포함).
  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final linkedCount =
        ids.where((id) => ref.read(compositionsContainingItemProvider(id)).isNotEmpty).length;
    if (linkedCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('사용 중인 코디가 있어요'),
          content: Text('선택한 항목 중 $linkedCount개가 사용 중인 코디에 쓰이고 있어요. 삭제하면 휴지통으로 이동해요.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('휴지통으로 이동')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!context.mounted) return;
    ref.read(closetItemsProvider.notifier).softDeleteMany(ids);
    GlassToast.show(
      context,
      message: '${ids.length}개 항목이 휴지통으로 이동됨',
      actionLabel: '실행취소',
      onAction: () => ref.read(closetItemsProvider.notifier).restoreMany(ids),
    );
  }

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
