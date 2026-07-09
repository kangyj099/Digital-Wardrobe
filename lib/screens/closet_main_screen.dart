import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/overlay_header.dart';

class ClosetMainScreen extends ConsumerWidget {
  const ClosetMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredClosetItemsProvider);
    final season = ref.watch(selectedSeasonFilterProvider);
    final density = ref.watch(closetDensityProvider);

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(
            actions: [
              TextButton(onPressed: () {}, child: const Text('선택')),
            ],
            child: Row(
              children: [
                DropdownButton<String>(
                  value: '옷장',
                  underline: const SizedBox.shrink(),
                  items: const [DropdownMenuItem(value: '옷장', child: Text('옷장'))],
                  onChanged: (_) {},
                ),
                const SizedBox(width: AppSpacing.md),
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
                      ref.read(selectedSeasonFilterProvider.notifier).state = value,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  tooltip: '그리드 밀도 전환',
                  onPressed: () {
                    final currentIndex = AppDensity.levels.indexOf(density);
                    final next =
                        AppDensity.levels[(currentIndex + 1) % AppDensity.levels.length];
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
          ),
          Expanded(
            child: GroupedGalleryGrid(
              items: items,
              density: density,
              onItemTap: (item) =>
                  context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoute.closetAdd),
        child: const Icon(Icons.add),
      ),
    );
  }
}
