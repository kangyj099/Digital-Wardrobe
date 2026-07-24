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
import 'app_detail_scaffold.dart';

/// 스타일일지 열람 — 카드 구조를 스펙 원문(`03_스타일 일지.md` "대표이미지(1번, 고정) →
/// 코디 슬롯(2번, 고정) → 추가 사진(3번~)") 그대로 따른다: 대표이미지/코디 슬롯을 하나의
/// 정사각형 2페이지 `PageView`로 묶고(하단 별도 카드/칩 방식은 폐기 —
/// `docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정" 참고),
/// 그 아래 날짜/장소, 그 아래 "착용 옷"(추가 사진) 순으로 배치한다. 코디 슬롯은 연결된
/// 코디가 있으면 `CompositionPreviewCard`(탭 → 코디 상세), 없으면 `_CompositionAddSlide`
/// (탭 → 코디 선택 모달을 열어 기존 코디를 골라 연결)를 보여준다.
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
                        ? CompositionPreviewCard(
                            composition: linkedComposition,
                            onTap: () => context.push(
                              AppRoute.compositionDetail.replaceFirst(':id', linkedComposition.id),
                            ),
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
            if (log.additionalImagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('착용 옷', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: log.additionalImagePaths.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final path = log.additionalImagePaths[index];
                    // `imagePath`가 정확히 일치하는 옷을 역으로 찾아 탭 시 그 옷 상세로
                    // 이동한다(mock_data.dart 기준 log01의 두 경로는 각각 c11/c07의
                    // imagePath와 정확히 일치함이 이미 확인된 데이터 정합성).
                    final match = closetItems.where((i) => i.imagePath == path);
                    final item = match.isEmpty ? null : match.first;
                    return GestureDetector(
                      onTap: item == null
                          ? null
                          : () =>
                              context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.asset(path, width: 96, fit: BoxFit.cover),
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
