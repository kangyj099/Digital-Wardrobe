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
import '../widgets/glass_toast.dart';
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
      onDelete: () => _confirmAndDelete(context, ref, itemId, linkedCompositions.length),
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
              '${item.category?.label ?? '미분류'} · ${item.season?.label ?? '미분류'} · ${item.material?.label ?? '미분류'} · ${item.color ?? '미분류'}',
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, String itemId, int linkedCount) async {
    if (linkedCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('사용 중인 코디가 있어요'),
          content: Text('이 옷은 $linkedCount개의 코디에 사용되고 있어요. 삭제하면 휴지통으로 이동해요.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('휴지통으로 이동')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!context.mounted) return;
    ref.read(closetItemsProvider.notifier).softDeleteMany({itemId});
    context.pop();
    // 스펙(`05_삭제 & 휴지통.md` "동작") "휴지통으로 이동됨 · 실행취소" — 메인 갤러리
    // 다중선택 삭제(`closet_main_screen.dart`)와 동일한 실행취소 패턴을 상세 화면 단일삭제
    // 진입점에도 적용한다. `itemId`는 값으로 캡처되고 `ref`는 팝된 화면보다 오래 살아남아
    // press 시점에 `ref.read(...)`로 안전하게 접근할 수 있다.
    GlassToast.show(
      context,
      message: '휴지통으로 이동됨',
      actionLabel: '실행취소',
      onAction: () => ref.read(closetItemsProvider.notifier).restoreMany({itemId}),
    );
  }
}
