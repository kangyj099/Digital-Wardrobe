import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/glass_pill.dart';
import '../widgets/selection_aware_header_actions.dart';
import 'skeleton_region.dart';

/// Main-그룹형(옷장 메인과 동일 페이지 타입) — `closet_main_screen.dart` 패턴을 그대로 이식.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(코디 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(composition.id)`로 결과를 반환한다. 호출부는
/// `context.push<String>(AppRoute.compositionSelect)`로 열고 반환값을 기다리면 된다
/// (`lib/screens/style_log_viewer_screen.dart` 사용례 참고).
class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key, this.selectionMode = false});

  /// true면 선택 모달로 동작 — 타일 탭 시 상세 화면 대신 `context.pop(id)`로 결과 반환.
  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositions = ref.watch(filteredCompositionsProvider);
    final season = ref.watch(selectedCompositionSeasonFilterProvider);
    final density = ref.watch(compositionDensityProvider);

    // Content Spacer(스펙 §4) — closet_main_screen.dart와 동일 계산(Row1+Row2+groupingBar).
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(
      hasSecondaryRow: true,
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
    );

    return AppMainScaffold(
      current: AppCategory.composition,
      showBackButton: !selectionMode,
      showCategoryToggle: !selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: selectionMode,
        onClose: () => context.pop(),
      ),
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
            onChanged: (value) =>
                ref.read(selectedCompositionSeasonFilterProvider.notifier).state = value,
          ),
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(compositionDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0
                ? AppDensity.levels.length - 1
                : currentIndex - 1;
            final next = AppDensity.levels[previousIndex];
            ref.read(compositionDensityProvider.notifier).state = next;
          },
        ),
        GlassCircleButton(icon: Icons.sort, tooltip: '정렬 기준', onTap: () {}),
      ],
      groupingBar: skeletonRegion(
        context,
        '분류 선택 바 (그룹형 드릴다운) — Step⑦(기능 구현)에서 실제 드릴다운으로 대체 예정',
        height: AppMainScaffold.defaultGroupingBarHeight,
      ),
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => CompositionGalleryGrid(
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
        ),
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoute.compositionEditor),
              child: const Icon(Icons.add),
            ),
    );
  }
}
