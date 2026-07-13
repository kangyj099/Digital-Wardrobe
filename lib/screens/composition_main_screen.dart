import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/fading_scroll_edge.dart';
import 'skeleton_region.dart';

/// Main-그룹형(옷장 메인과 동일 페이지 타입) — `closet_main_screen.dart` 패턴을 그대로 이식.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1/§3 참고.
class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositions = ref.watch(filteredCompositionsProvider);
    final season = ref.watch(selectedCompositionSeasonFilterProvider);
    final density = ref.watch(compositionDensityProvider);

    return AppMainScaffold(
      current: AppCategory.composition,
      headerActions: [
        TextButton(onPressed: () {}, child: const Text('선택')),
      ],
      headerTitle: Row(
        children: [
          DropdownButton<Season?>(
            value: season,
            hint: const Text('계절'),
            items: [
              const DropdownMenuItem<Season?>(value: null, child: Text('전체')),
              ...Season.values.map(
                (s) => DropdownMenuItem<Season?>(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (value) =>
                ref.read(selectedCompositionSeasonFilterProvider.notifier).state = value,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_densityIcon(density)),
            tooltip: '그리드 밀도 전환',
            onPressed: () {
              final current = ref.read(compositionDensityProvider);
              final currentIndex = AppDensity.levels.indexOf(current);
              final previousIndex = currentIndex - 1 < 0
                  ? AppDensity.levels.length - 1
                  : currentIndex - 1;
              final next = AppDensity.levels[previousIndex];
              ref.read(compositionDensityProvider.notifier).state = next;
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '정렬 기준',
            onPressed: () {},
          ),
        ],
      ),
      groupingBar: skeletonRegion(
        context,
        '분류 선택 바 (그룹형 드릴다운) — Step⑦(기능 구현)에서 실제 드릴다운으로 대체 예정',
        height: 48,
      ),
      body: FadingScrollEdge(
        child: CompositionGalleryGrid(
          compositions: compositions,
          density: density,
          onItemTap: (c) =>
              context.push(AppRoute.compositionDetail.replaceFirst(':id', c.id)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.compositionEditor),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _densityIcon(int density) {
    if (density == AppDensity.max) return Icons.grid_view;
    if (density == AppDensity.mid) return Icons.view_comfy;
    return Icons.crop_square;
  }
}
