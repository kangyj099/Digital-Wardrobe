import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/cross_reference_link_bar.dart';
import 'app_detail_scaffold.dart';

/// 스타일일지 열람 — 대표이미지/추가사진/날짜/장소를 실제 mock 데이터로 표시한다.
/// 연결된 코디가 없으면 크로스 레퍼런스 바에 "+" 바인딩 항목이 뜨고, 탭하면 코디 선택
/// 모달(`AppRoute.compositionSelect`)을 열어 기존 코디를 골라 연결한다(신규 생성
/// 바인딩/착용 옷 목록 자유 편집은 스코프 밖 — `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class StyleLogViewerScreen extends ConsumerWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  Future<void> _bindComposition(BuildContext context, WidgetRef ref) async {
    final selectedCompositionId = await context.push<String>(AppRoute.compositionSelect);
    // Task 4의 `_bindStyleLog`에 없던 mounted 가드를 여기서는 추가한다 — async 갭 이후
    // ref를 쓰기 전에 위젯이 여전히 살아있는지 확인(Review가 Task 4에서 지적한 TechDebt,
    // `docs/history/TechnicalDebt.md` 참고. `_bindStyleLog` 쪽은 별도로 정리 예정이라
    // 이 Task에서 함께 고치지 않는다 — 이 함수만 새로 작성하므로 처음부터 바르게 작성).
    if (!context.mounted) return;
    if (selectedCompositionId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(styleLogId, selectedCompositionId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(styleLogsProvider).firstWhere((l) => l.id == styleLogId);
    final linkedComposition = log.linkedCompositionId == null
        ? null
        : ref.watch(compositionsProvider).firstWhere((c) => c.id == log.linkedCompositionId);

    return AppDetailScaffold(
      category: AppCategory.styleLog,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(log.coverImagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'
              '${log.location.isEmpty ? '' : '  ${log.location}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (log.additionalImagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('추가 사진', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: log.additionalImagePaths.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      log.additionalImagePaths[index],
                      width: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      crossReferenceEntries: [
        if (linkedComposition != null)
          CrossReferenceLinkEntry(
            label: linkedComposition.name,
            icon: Icons.checkroom,
            onTap: () =>
                context.push(AppRoute.compositionDetail.replaceFirst(':id', linkedComposition.id)),
          )
        else
          CrossReferenceLinkEntry(
            label: '코디 연결하기',
            icon: Icons.add,
            onTap: () => _bindComposition(context, ref),
          ),
      ],
    );
  }
}
