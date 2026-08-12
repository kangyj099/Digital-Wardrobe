import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/composition_preview_card.dart';
import '../widgets/glass_toast.dart';
import '../widgets/status_badge.dart';
import 'app_detail_scaffold.dart';

/// 스타일일지 열람 — 카드 구조를 스펙 원문(`03_스타일 일지.md` "대표이미지(1번, 고정) →
/// 코디 슬롯(2번, 고정) → 추가 사진(3번~)") 그대로 따른다: 대표이미지/코디 슬롯을 하나의
/// 정사각형 2페이지 `PageView`로 묶고(하단 별도 카드/칩 방식은 폐기 —
/// `docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정" 참고),
/// 그 아래 날짜/장소, 그 아래 "착용 옷"(추가 사진) 순으로 배치한다. 코디 슬롯은 연결된
/// 코디가 있으면 `CompositionPreviewCard`(탭 → 코디 상세), 없으면 `_CompositionAddSlide`
/// (탭 → 코디 선택 모달을 열어 기존 코디를 골라 연결)를 보여준다. 연결된 코디가 삭제(휴지통
/// 이동)됐으면 `StatusBadge('삭제됨')`를 오버레이하고 탭을 막는다("착용 옷" 섹션과 동일한
/// 소프트삭제 가드 패턴 — 삭제된 코디가 있었다는 사실 자체를 숨기지 않는다).
class StyleLogViewerScreen extends ConsumerStatefulWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  ConsumerState<StyleLogViewerScreen> createState() => _StyleLogViewerScreenState();
}

class _StyleLogViewerScreenState extends ConsumerState<StyleLogViewerScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _bindComposition(BuildContext context, WidgetRef ref, String styleLogId) async {
    final selectedCompositionId = await context.push<String>(AppRoute.compositionSelect);
    // async 갭 이후 ref를 쓰기 전에 위젯이 여전히 살아있는지 확인.
    if (!context.mounted) return;
    if (selectedCompositionId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(styleLogId, selectedCompositionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(styleLogsProvider).firstWhere((l) => l.id == widget.styleLogId);
    final linkedComposition = log.linkedCompositionId == null
        ? null
        : ref
            .watch(compositionsProvider)
            .where((c) => c.id == log.linkedCompositionId)
            .firstOrNull;
    final closetItems = ref.watch(closetItemsProvider);
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return AppDetailScaffold(
      category: AppCategory.styleLog,
      onDelete: () {
        ref.read(styleLogsProvider.notifier).softDeleteMany({widget.styleLogId});
        context.pop();
        // 스펙(`05_삭제 & 휴지통.md` "동작") "휴지통으로 이동됨 · 실행취소" — 메인 갤러리
        // 다중선택 삭제(`style_log_main_screen.dart`)와 동일한 실행취소 패턴을 상세 화면
        // 단일삭제 진입점에도 적용한다. `widget.styleLogId`는 값으로 캡처되고 `ref`는 팝된
        // 화면보다 오래 살아남아 press 시점에 `ref.read(...)`로 안전하게 접근할 수 있다.
        GlassToast.show(
          context,
          message: '휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(styleLogsProvider.notifier).restoreMany({widget.styleLogId}),
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(
                aspectRatio: 1,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    // `style_log_gallery_tile.dart`와 동일 가드 — coverImagePath가 비어
                    // 있으면(미완성 스타일일지 등) Image.asset("")가 예외를 던지므로 회색
                    // placeholder로 대체한다.
                    log.coverImagePath.isEmpty
                        ? Container(color: semantic.gray200)
                        : Image.asset(log.coverImagePath, fit: BoxFit.cover),
                    linkedComposition != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CompositionPreviewCard(
                                composition: linkedComposition,
                                onTap: linkedComposition.isDeleted
                                    ? null
                                    : () => context.push(
                                        AppRoute.compositionDetail
                                            .replaceFirst(':id', linkedComposition.id),
                                      ),
                              ),
                              if (linkedComposition.isDeleted)
                                const Positioned(
                                  top: AppSpacing.xxs,
                                  left: AppSpacing.xxs,
                                  child: StatusBadge(label: '삭제됨'),
                                ),
                            ],
                          )
                        : _CompositionAddSlide(
                            onTap: () => _bindComposition(context, ref, widget.styleLogId),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 2; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? semantic.gray900 : semantic.gray200,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'
              '${log.location.isEmpty ? '' : '  ${log.location}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (log.wornItemIds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('착용 옷', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: log.wornItemIds.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final wornItemId = log.wornItemIds[index];
                    // ID로 직접 옷을 찾는다(예전 이미지 경로 문자열 일치 방식은 취약해
                    // ID 참조로 교체 — `docs/history/Decision.md` 참고).
                    final match = closetItems.where((i) => i.id == wornItemId);
                    final item = match.isEmpty ? null : match.first;
                    return GestureDetector(
                      onTap: (item == null || item.isDeleted)
                          ? null
                          : () =>
                              context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                // 방어적 처리 — 정상 데이터라면 item은 항상 존재해야 하지만,
                                // 못 찾으면(예: 데이터 정합성 깨짐) 회색 placeholder로 대체한다
                                // (파일 상단 coverImagePath 빈 문자열 가드와 동일 패턴).
                                child: item == null
                                    ? Container(color: semantic.gray200)
                                    : Image.asset(item.imagePath, fit: BoxFit.cover),
                              ),
                            ),
                            if (item != null && item.isDeleted)
                              const Positioned(
                                top: AppSpacing.xxs,
                                left: AppSpacing.xxs,
                                child: StatusBadge(label: '삭제됨'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 스타일일지 열람 코디 슬롯(2번 카드)에서, 아직 연결된 코디가 없을 때 보이는 자리 —
/// 탭하면 코디 선택 모달을 열어 기존 코디를 골라 연결한다.
class _CompositionAddSlide extends StatelessWidget {
  const _CompositionAddSlide({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Material(
      color: semantic.gray100,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add),
              Text('코디 연결하기', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
