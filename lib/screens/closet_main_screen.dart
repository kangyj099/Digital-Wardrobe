import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/overlay_header.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>()!;

    final singleLabel = season == null ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = season == null ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, semanticColors.gray100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 우상단 세이지 틴트 — 장식용 배경 오버레이(스크롤/상호작용에 반응하지 않는 정적 레이어).
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // 디버그 빌드에서만 목업 상태바를 그린다. 릴리즈에서도 동일한 높이를 예약해
                // 레이아웃(children 개수)이 빌드 모드에 따라 흔들리지 않게 한다.
                SizedBox(
                  height: 24,
                  child: kDebugMode ? _buildDebugStatusBar(context) : null,
                ),
                OverlayHeader(
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('선택')),
                  ],
                  child: Row(
                    children: [
                      _buildCategoryDropdown(context),
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
                ),
                Expanded(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.06],
                    ).createShader(rect),
                    child: GroupedGalleryGrid(
                      items: items,
                      density: density,
                      onItemTap: (item) =>
                          context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButton<AppCategory>(
      value: AppCategory.closet,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      items: AppCategory.values
          .map(
            (c) => DropdownMenuItem<AppCategory>(
              value: c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c == AppCategory.closet) ...[
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Text(c.label),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        switch (value) {
          case AppCategory.composition:
            context.go(AppRoute.compositionMain);
          case AppCategory.styleLog:
            context.go(AppRoute.styleLogMain);
          case AppCategory.closet:
          case null:
            // '옷장' 선택은 이미 이 화면이므로 아무 동작도 하지 않는다.
            break;
        }
      },
    );
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

  Widget _buildDebugStatusBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('9:41', style: TextStyle(fontSize: 12)),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 14),
              SizedBox(width: AppSpacing.xxs),
              Icon(Icons.wifi, size: 14),
              SizedBox(width: AppSpacing.xxs),
              Icon(Icons.battery_full, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  IconData _densityIcon(int density) {
    if (density == AppDensity.max) return Icons.grid_view;
    if (density == AppDensity.mid) return Icons.view_comfy;
    return Icons.crop_square;
  }
}
