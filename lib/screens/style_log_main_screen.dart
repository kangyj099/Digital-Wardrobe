import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/fading_scroll_edge.dart';
import '../widgets/style_log_gallery_grid.dart';

/// Main-플랫+필터형 — 그룹 드릴다운 없음(기존 스펙대로 날짜 기준 최신순 고정). FAB는
/// `closet_main_screen.dart`의 2-옵션 팝업 패턴을 그대로 이식.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 참고.
class StyleLogMainScreen extends ConsumerStatefulWidget {
  const StyleLogMainScreen({super.key});

  @override
  ConsumerState<StyleLogMainScreen> createState() => _StyleLogMainScreenState();
}

class _StyleLogMainScreenState extends ConsumerState<StyleLogMainScreen> {
  bool _fabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(filteredStyleLogsProvider);

    return AppMainScaffold(
      current: AppCategory.styleLog,
      headerActions: [
        TextButton(onPressed: () {}, child: const Text('선택')),
      ],
      headerTitle: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '정렬 기준',
            onPressed: () {},
          ),
        ],
      ),
      body: FadingScrollEdge(
        child: StyleLogGalleryGrid(
          logs: logs,
          onItemTap: (l) => context.push(AppRoute.styleLogViewer.replaceFirst(':id', l.id)),
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
                        _buildFabOption(context, label: '1카드 추가', onTap: _onFabOptionTap),
                        const SizedBox(height: AppSpacing.xs),
                        _buildFabOption(context, label: '여러카드에 분할 추가', onTap: _onFabOptionTap),
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
    context.push(AppRoute.styleLogAdd);
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
}
