import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/gallery_main_screen.dart';
import '../widgets/glass_toast.dart';
import '../widgets/selection_aware_header_actions.dart';

class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criterion = ref.watch(compositionSortCriterionProvider);
    final ascending = ref.watch(compositionSortAscendingProvider);
    final displayState = ref.watch(compositionGridDisplayStateProvider);
    final density = ref.watch(compositionDensityProvider);
    final compositions = ref.watch(filteredCompositionsProvider);
    final groups = ref.watch(compositionGroupSummariesProvider);
    // 스펙("옷 삭제 시 코디 캐스케이드 처리" §"코디 목록: 삭제된 옷 포함 코디는 타일에 작은
    // 배지") — 새 `.family` provider를 만들지 않고, 이 build() 안에서 `closetItemsProvider`를
    // 한 번만 watch해 삭제된 옷 id 집합을 만든다. 실제 코디별 판정(어느 코디가 이 집합에 속한
    // 옷을 참조하는지)은 `CompositionGalleryGrid`가 타일 매핑 시점에 수행한다.
    final deletedClothingItemIds = {
      for (final item in ref.watch(closetItemsProvider))
        if (item.isDeleted) item.id,
    };

    return GalleryMainScreen<Composition>(
      current: AppCategory.composition,
      items: compositions,
      itemId: (c) => c.id,
      showBackButton: !selectionMode,
      showCategoryToggle: !selectionMode,
      selectionMode: selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: selectionMode,
        onClose: () => context.pop(),
      ),
      onReselectCurrentCategory: () {
        ref.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.all;
        _resetAllDrilldowns(ref);
      },
      classification: ClassificationConfig<Composition>(
        criterionLabels: [for (final c in CompositionSortCriterion.values) c.label],
        selectedCriterionIndex: criterion.index,
        onCriterionChanged: (index) {
          ref.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.values[index];
          _resetAllDrilldowns(ref);
        },
        hasSubClassification: criterion.hasSubClassification,
        subHint: criterion.hasSubClassification ? criterion.subClassificationHint : null,
        subOptionLabels: _subOptionLabels(ref, criterion),
        selectedSubOptionIndex: _selectedSubOptionIndex(ref, criterion),
        onSubOptionSelected: (index) => _drillInto(ref, criterion, index),
        onClearSubSelection: () => _clearDrilldown(ref, criterion),
        density: density,
        // [정정, Task 7 Review 2026-07-28] `current`(전달받은 값)를 그대로 쓰면 `10d3643`이
        // 이미 한 번 고친 stale-closure 버그가 재발한다 — 빌드 시점에 고정된 값이라 리빌드
        // 전에 연속 탭하면 두 번째 탭이 낡은 값을 기준으로 계산된다. 옷장 메인(Task 7)이 이미
        // `ref.read(...)`로 매번 새로 읽는 방식으로 우회했다 — 여기도 동일하게 적용.
        onDensityChanged: (_) {
          final latest = ref.read(compositionDensityProvider);
          final currentIndex = AppDensity.levels.indexOf(latest);
          final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
          ref.read(compositionDensityProvider.notifier).state = AppDensity.levels[previousIndex];
        },
        ascending: ascending,
        onAscendingChanged: (_) =>
            ref.read(compositionSortAscendingProvider.notifier).state = !ref.read(compositionSortAscendingProvider),
      ),
      onItemTap: (c) {
        if (selectionMode) {
          context.pop(c.id);
        } else {
          context.push(AppRoute.compositionDetail.replaceFirst(':id', c.id));
        }
      },
      onDeleteSelected: (ids) {
        ref.read(compositionsProvider.notifier).softDeleteMany(ids);
        GlassToast.show(
          context,
          message: '${ids.length}개 항목이 휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(compositionsProvider.notifier).restoreMany(ids),
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
        if (displayState == CompositionGridDisplayState.groupOverview) {
          return ClassificationGroupGrid(
            groups: groups,
            density: density,
            controller: controller,
            topSpacing: topSpacing,
            onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
          );
        }
        return CompositionGalleryGrid(
          compositions: compositions,
          density: density,
          controller: controller,
          topSpacing: topSpacing,
          multiSelectMode: multiSelectMode,
          selectedIds: selectedIds,
          deletedClothingItemIds: deletedClothingItemIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      },
      fab: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoute.compositionEditor),
              child: const Icon(Icons.add),
            ),
    );
  }

  // 아래 6개 메서드는 이 Task 착수 전 `composition_main_screen.dart`에 이미 있던 로직을
  // 그대로 옮긴 것(계절/날씨/날짜 3기준) — 타입/provider만 옷장 대신 코디 것을 쓴다.
  List<String> _subOptionLabels(WidgetRef ref, CompositionSortCriterion criterion) {
    return switch (criterion) {
      CompositionSortCriterion.season => [for (final season in Season.values) season.label, '미분류'],
      CompositionSortCriterion.weather => [for (final weather in Weather.values) weather.label, '미분류'],
      CompositionSortCriterion.dateTime => [
          for (final group in ref.watch(compositionGroupSummariesProvider)) group.label,
        ],
      CompositionSortCriterion.all => const [],
    };
  }

  int? _selectedSubOptionIndex(WidgetRef ref, CompositionSortCriterion criterion) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        final drilled = ref.watch(compositionDrilledSeasonProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Season.values.length : Season.values.indexOf(drilled.value as Season);
      case CompositionSortCriterion.weather:
        final drilled = ref.watch(compositionDrilledWeatherProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Weather.values.length : Weather.values.indexOf(drilled.value as Weather);
      case CompositionSortCriterion.dateTime:
        final year = ref.watch(compositionDrilledYearProvider);
        if (year == null) return null;
        final groups = ref.watch(compositionGroupSummariesProvider);
        final index = groups.indexWhere((g) => g.value == year);
        return index == -1 ? null : index;
      default:
        return null;
    }
  }

  void _drillInto(WidgetRef ref, CompositionSortCriterion criterion, int optionIndex) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state = optionIndex == Season.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Season.values[optionIndex]);
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state = optionIndex == Weather.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Weather.values[optionIndex]);
      case CompositionSortCriterion.dateTime:
        final groups = ref.read(compositionGroupSummariesProvider);
        ref.read(compositionDrilledYearProvider.notifier).state = groups[optionIndex].value as int;
      default:
        break;
    }
  }

  void _drillIntoValue(WidgetRef ref, CompositionSortCriterion criterion, Object? value) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Season);
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Weather);
      case CompositionSortCriterion.dateTime:
        ref.read(compositionDrilledYearProvider.notifier).state = value as int?;
      case CompositionSortCriterion.all:
        break;
    }
  }

  void _resetAllDrilldowns(WidgetRef ref) {
    ref.read(compositionDrilledSeasonProvider.notifier).state = null;
    ref.read(compositionDrilledWeatherProvider.notifier).state = null;
    ref.read(compositionDrilledYearProvider.notifier).state = null;
  }

  void _clearDrilldown(WidgetRef ref, CompositionSortCriterion criterion) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state = null;
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state = null;
      case CompositionSortCriterion.dateTime:
        ref.read(compositionDrilledYearProvider.notifier).state = null;
      case CompositionSortCriterion.all:
        break;
    }
  }
}
