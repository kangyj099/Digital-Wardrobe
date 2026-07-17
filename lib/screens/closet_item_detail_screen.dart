import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/composition_preview_carousel.dart';
import '../widgets/style_log_cross_reference_gallery.dart';
import 'app_detail_scaffold.dart';

/// 옷 상세 — 이미지/메타데이터/착용 이력을 실제 mock 데이터로 표시하고, 이 옷을 포함한
/// 코디들과 (코디를 거쳐) 간접 연결된 스타일일지들을 하단 크로스 레퍼런스로 보여준다.
/// 옷↔코디/스타일일지는 읽기 전용 탐색만 지원 — 이 화면에서 바인딩 액션은 없다(코디
/// 상세/스타일일지 열람에서만 코디↔스타일일지 바인딩을 지원, `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class ClosetItemDetailScreen extends ConsumerWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(closetItemsProvider).firstWhere((i) => i.id == itemId);
    final linkedCompositions = ref.watch(compositionsContainingItemProvider(itemId));
    final linkedStyleLogs = ref.watch(styleLogsLinkedToItemProvider(itemId));

    return AppDetailScaffold(
      category: AppCategory.closet,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(item.imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${item.category.label} · ${item.season.label} · ${item.material.label} · ${item.color}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (item.location.isNotEmpty) Text('보관 위치: ${item.location}'),
            if (item.memo.isNotEmpty) Text('메모: ${item.memo}'),
            const SizedBox(height: AppSpacing.xs),
            Text('착용 ${item.wearCount}회', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            CompositionPreviewCarousel(
              compositions: linkedCompositions,
              onTap: (c) => context.push(AppRoute.compositionDetail.replaceFirst(':id', c.id)),
            ),
            const SizedBox(height: AppSpacing.md),
            StyleLogCrossReferenceGallery(
              logs: linkedStyleLogs,
              onTap: (log) => context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
              expandSingle: false,
            ),
          ],
        ),
      ),
    );
  }
}
