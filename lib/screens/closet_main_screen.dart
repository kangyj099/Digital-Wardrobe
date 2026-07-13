import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/fading_scroll_edge.dart';
import '../widgets/grouped_gallery_grid.dart';
import 'skeleton_region.dart';

class ClosetMainScreen extends ConsumerStatefulWidget {
  const ClosetMainScreen({super.key});

  @override
  ConsumerState<ClosetMainScreen> createState() => _ClosetMainScreenState();
}

class _ClosetMainScreenState extends ConsumerState<ClosetMainScreen> {
  bool _fabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(filteredClosetItemsProvider);
    final season = ref.watch(selectedSeasonFilterProvider);
    final density = ref.watch(closetDensityProvider);

    final singleLabel = season == null ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = season == null ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    return AppMainScaffold(
      current: AppCategory.closet,
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
            onChanged: (value) => ref.read(selectedSeasonFilterProvider.notifier).state = value,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_densityIcon(density)),
            tooltip: '그리드 밀도 전환',
            onPressed: () {
              final current = ref.read(closetDensityProvider);
              final currentIndex = AppDensity.levels.indexOf(current);
              final previousIndex = currentIndex - 1 < 0
                  ? AppDensity.levels.length - 1
                  : currentIndex - 1;
              final next = AppDensity.levels[previousIndex];
              ref.read(closetDensityProvider.notifier).state = next;
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
        '분류 선택 바 (그룹형 드릴다운) — Step②에서 AppMainScaffold groupingBar 슬롯으로 대체 예정',
        height: 48,
      ),
      body: FadingScrollEdge(
        child: GroupedGalleryGrid(
          items: items,
          density: density,
          onItemTap: (item) =>
              context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
            duration: AppMotion.fast,
            child: _fabExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildFabOption(context, label: singleLabel, onTap: _onFabOptionTap),
                        const SizedBox(height: AppSpacing.xs),
                        _buildFabOption(context, label: multiLabel, onTap: _onFabOptionTap),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
            child: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0,
              duration: AppMotion.fast,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _onFabOptionTap() {
    setState(() => _fabExpanded = false);
    context.push(AppRoute.closetAdd);
  }

  Widget _buildFabOption(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
    );
  }

  IconData _densityIcon(int density) {
    if (density == AppDensity.max) return Icons.grid_view;
    if (density == AppDensity.mid) return Icons.view_comfy;
    return Icons.crop_square;
  }
}
