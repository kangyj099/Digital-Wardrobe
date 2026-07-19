import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/trash_entry.dart';
import '../providers/trash_providers.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_gallery_grid.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_pill.dart';
import '../widgets/trash_gallery_tile.dart';

/// Step⑥(나머지 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준
/// Main-플랫+필터형(휴지통), 뒤로가기=O/카테고리 토글=X라 `showCategoryToggle: false`로
/// 기본값(true)을 오버라이드한다(그룹형 드릴다운 슬롯 자체는 2026-07-19 삭제됨 —
/// `AppMainScaffold` 참고). 그룹형이 아니므로 그리드 밀도 토글도 두지 않는다
/// (`docs/history/Decision.md` "그리드 밀도 토글은 그룹형 Main 화면 전용" — 스타일일지
/// 메인과 같은 근거).
///
/// `current`([AppMainScaffold]의 필수 파라미터)는 휴지통이 [AppCategory]의 옷장/코디/
/// 스타일일지 어디에도 속하지 않아 원래 무관하지만, `showCategoryToggle: false`라
/// 실제로 렌더링되지 않으므로 임의로 [AppCategory.closet]을 고정값으로 채운다.
///
/// 본문은 `00_페이지 타입 정의.md`의 Main형 공통 요소("우상단 [선택] 버튼 → 다중 선택
/// 모드") + "휴지통의 추가 확장 요소"를 함께 따른다: 제목 없이 이미지 중심인 순수
/// 썸네일 그리드([TrashGalleryTile]), 헤더의 "선택"(다중 선택, no-op 스텁 — 다른 3개
/// Main형과 동일한 패턴)과 "비우기"(강한 확인 모달 스텁) 버튼, 타일 탭 시 상세 페이지
/// 전환 대신 정보 팝업(복원/영구삭제 버튼은 스텁).
///
/// 목록은 [trashEntriesProvider]([lib/providers/trash_providers.dart])로 노출되는
/// [TrashEntry] 목록을 그대로 쓴다 — 다른 도메인(`ClothingItem`/`Composition`/
/// `StyleLog`)과 동일하게 mock 인스턴스는 `lib/mock/mock_data.dart`, provider는
/// `lib/providers/`에 둔다(화면 파일 로컬 mock을 두지 않음). 실제로는 위 세 도메인
/// provider를 `isDeleted`로 필터링한 집계 뷰가 되어야 하지만, 그 집계 로직 자체는
/// Step⑦(기능 구현) 몫이라 지금은 [TrashEntry] mock 값만 노출한다. 실제 복원/영구삭제/
/// 비우기 실행도 Step⑦ 몫.
class TrashMainScreen extends ConsumerWidget {
  const TrashMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(trashEntriesProvider);
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: AppCategory.closet,
      showCategoryToggle: false,
      headerActions: [
        GlassPill(
          child: TextButton(
            onPressed: () {}, // Step⑦에서 다중 선택 모드 진입 연결(다른 Main형과 동일)
            child: const Text('선택', style: AppTypography.actionMinimal),
          ),
        ),
        GlassPill(
          child: TextButton(
            onPressed: () => _confirmEmptyTrash(context),
            child: const Text('비우기', style: AppTypography.actionMinimal),
          ),
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => AppGalleryGrid(
          itemCount: entries.length,
          density: AppDensity.mid,
          controller: controller,
          topSpacing: contentTopSpacing,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return TrashGalleryTile(
              key: ValueKey(entry.id),
              imagePath: entry.imagePath,
              category: entry.category,
              remainingDays: entry.remainingDays,
              onTap: () => _showTrashItemInfo(context, entry),
            );
          },
        ),
      ),
    );
  }

  /// "비우기" — 파괴적 액션이라 강한 확인 모달 필요(`00_페이지 타입 정의.md`).
  /// 확인을 눌러도 실제 삭제는 실행하지 않는다(Step⑦ 몫).
  void _confirmEmptyTrash(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('휴지통 비우기'),
        content: const Text('정말 비우시겠습니까? 휴지통의 모든 항목이 영구 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Step⑦에서 실제 비우기 실행
            child: const Text('비우기'),
          ),
        ],
      ),
    );
  }

  /// 타일 탭 → 상세 페이지 전환이 아니라 정보 팝업(`00_페이지 타입 정의.md`).
  /// 복원/영구삭제 버튼은 있지만 onPressed는 no-op(Step⑦ 몫).
  void _showTrashItemInfo(BuildContext context, TrashEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.category.label} · 영구 삭제까지 ${entry.remainingDays}일',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {}, // Step⑦에서 실제 복원 로직 연결
                      child: const Text('복원'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {}, // Step⑦에서 실제 영구삭제 로직 연결
                      child: const Text('영구 삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
