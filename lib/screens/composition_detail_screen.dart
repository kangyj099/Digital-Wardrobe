import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/style_log_cross_reference_gallery.dart';
import 'app_detail_scaffold.dart';

/// 코디 상세 — 사용된 옷 목록과 연결된 스타일일지를 실제 mock 데이터로 표시한다.
/// 연결된 스타일일지가 없으면 크로스 레퍼런스 바에 "+" 바인딩 항목이 뜨고, 탭하면
/// 스타일일지 선택 모달(`AppRoute.styleLogSelect`)을 열어 기존 스타일일지를 골라
/// 연결한다(신규 생성 바인딩/아트보드 실제 렌더링은 스코프 밖 — `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class CompositionDetailScreen extends ConsumerWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  Future<void> _bindStyleLog(BuildContext context, WidgetRef ref) async {
    final selectedLogId = await context.push<String>(AppRoute.styleLogSelect);
    if (selectedLogId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(selectedLogId, compositionId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
    final closetItems = ref.watch(closetItemsProvider);
    final usedItems = [
      for (final placement in composition.items)
        closetItems.firstWhere((item) => item.id == placement.clothingItemId),
    ];
    final linkedStyleLogs = ref.watch(styleLogsLinkedToCompositionProvider(compositionId));

    return AppDetailScaffold(
      category: AppCategory.composition,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(composition.name, style: Theme.of(context).textTheme.headlineSmall),
            if (composition.season != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(composition.season!.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('사용된 옷', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: usedItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = usedItems[index];
                  return GestureDetector(
                    key: ValueKey(item.id),
                    onTap: () =>
                        context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.asset(item.imagePath, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('연결된 스타일일지', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            StyleLogCrossReferenceGallery(
              logs: linkedStyleLogs,
              onTap: (log) => context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
              onAddTap: () => _bindStyleLog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
