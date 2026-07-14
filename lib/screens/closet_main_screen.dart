import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/glass_pill.dart';
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
      headerActions: [
        GlassPill(
          child: TextButton(
            onPressed: () {},
            child: const Text('선택', style: AppTypography.actionMinimal),
          ),
        ),
      ],
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
          icon: _densityIcon(density),
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
