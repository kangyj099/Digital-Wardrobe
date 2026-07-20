import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/classification_drilldown_capsule.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/selection_aware_header_actions.dart';

/// Main-그룹형(옷장 메인과 동일 페이지 타입) — `closet_main_screen.dart` 패턴을 그대로 이식.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(코디 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(composition.id)`로 결과를 반환한다.
class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criterion = ref.watch(compositionSortCriterionProvider);
    // closet_main_screen.dart와 동일 — 전역 단순 규칙이라 반전 없이 그대로 쓴다.
    final ascending = ref.watch(compositionSortAscendingProvider);
    final displayState = ref.watch(compositionGridDisplayStateProvider);
    final density = ref.watch(compositionDensityProvider);

    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.composition,
      showBackButton: !selectionMode,
      showCategoryToggle: !selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: selectionMode,
        onClose: () => context.pop(),
      ),
      // 이 화면이 코디의 메인이라는 신호 — `closet_main_screen.dart`와 동일 이유.
      onReselectCurrentCategory: () {
        ref.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.all;
        _resetAllDrilldowns(ref);
      },
      secondaryControlsLeft: [
        ClassificationDrilldownCapsule(
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
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(compositionDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
            ref.read(compositionDensityProvider.notifier).state = AppDensity.levels[previousIndex];
          },
        ),
        GlassCircleButton(
          icon: ascending ? Icons.arrow_upward : Icons.arrow_downward,
          tooltip: ascending ? '오름차순' : '내림차순',
          onTap: () => ref.read(compositionSortAscendingProvider.notifier).state = !ascending,
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) {
          if (displayState == CompositionGridDisplayState.groupOverview) {
            final groups = ref.watch(compositionGroupSummariesProvider);
            return ClassificationGroupGrid(
              groups: groups,
              density: density,
              controller: controller,
              topSpacing: contentTopSpacing,
              onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
            );
          }
          final compositions = ref.watch(filteredCompositionsProvider);
          return CompositionGalleryGrid(
            compositions: compositions,
            density: density,
            controller: controller,
            topSpacing: contentTopSpacing,
            onItemTap: (c) {
              if (selectionMode) {
                context.pop(c.id);
              } else {
                context.push(AppRoute.compositionDetail.replaceFirst(':id', c.id));
              }
            },
          );
        },
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoute.compositionEditor),
              child: const Icon(Icons.add),
            ),
    );
  }

  // closet_main_screen.dart와 동일한 이유로 날짜·시간(연도)은 closetGroupSummariesProvider의
  // 코디 버전(compositionGroupSummariesProvider)을 라벨/인덱스 소스로 공유한다.
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

  /// `closet_main_screen.dart`의 `_resetAllDrilldowns`와 동일한 이유(사용자 지시,
  /// 2026-07-20) — 중분류를 바꿀 때마다 모든 소분류 드릴인 상태를 초기화해, 이전에
  /// 같은 중분류에서 드릴인했던 값이 그대로 남아 있지 않게 한다.
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
