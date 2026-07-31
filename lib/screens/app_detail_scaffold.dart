import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_effects.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_inset_highlight.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 공용 셸 — `AppMainScaffold` 위에
/// Detail 전용 스크롤 콘텐츠 구조(본문)를 얹는다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목).
///
/// Step⑦ 1라운드(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`)에서
/// `placeholderLabel`(단일 문자열) 계약을 `body`(임의 위젯)로 넓혔고, 이후 `crossReferenceEntries`/
/// `CrossReferenceLinkBar`(Task 9)는 3개 Detail 화면 전부가 각자 실제 크로스 레퍼런스 위젯
/// (`CompositionPreviewCarousel`/`StyleLogCrossReferenceGallery`)을 `body`에 직접 배치하게
/// 되어 계약에서 폐기됐다 — 이제 `category`/`body`/`onDelete` 계약이다.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({
    super.key,
    required this.category,
    required this.body,
    required this.onDelete,
  });

  /// 헤더 카테고리 토글에 넘길 현재 카테고리([AppMainScaffold.current]로 그대로 전달).
  final AppCategory category;

  /// 본문 콘텐츠 — 화면마다 실제 상세 정보를 자유롭게 채운다.
  final Widget body;

  /// "더보기" 메뉴의 유일한 항목 — [삭제] 탭 시 호출. 호출부가 자기 도메인의
  /// `softDeleteMany({id})` + `context.pop()` + `GlassToast.show(...)`를 책임진다
  /// (이 Scaffold는 도메인을 모름).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: category,
      headerActions: [
        _MoreMenuButton(onDelete: onDelete),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing),
          child: body,
        ),
      ),
    );
  }
}

/// [GlassCircleButton]과 동일한 글래스 데코레이션을 유지하되, 내부를 `IconButton` 대신
/// `PopupMenuButton`으로 바꿔 [삭제] 1항목 메뉴를 연다.
class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            BackdropFilter(
              filter: AppGlassEffect.backdropFilter(),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
                child: PopupMenuButton<String>(
                  tooltip: '더보기 메뉴',
                  icon: const Icon(Icons.more_horiz),
                  // 메뉴 서페이스를 같은 헤더 행의 `CategoryToggleDropdown`
                  // (`category_toggle_dropdown.dart:41-57`)과 동일한 글래스 톤으로 맞춘다 —
                  // 그대로 두면 Flutter 기본 Material 팝업 카드로 렌더링돼 옆 커스텀 메뉴와
                  // 시각적으로 어긋난다(Review P2 지적). 바깥 Container가 이미 48x48로
                  // 고정돼 있어(GlassCircleButton과 동일), PopupMenuButton 기본 padding(8)까지
                  // 겹치면 아이콘이 불필요하게 눌린다 — category_toggle_dropdown.dart와
                  // 동일하게 0으로 비운다.
                  padding: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  clipBehavior: Clip.antiAlias,
                  // `PopupMenuButton.showButtonMenu`는 선택된 값이 null이면 "취소"로 취급해
                  // onSelected를 호출하지 않는다 — 항목 값은 반드시 null이 아니어야 한다.
                  onSelected: (_) => onDelete(),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      // 기본 아이템 padding(가로만 16)을 0으로 비우고 아래 Container가 전부
                      // 대체한다 — `category_toggle_dropdown.dart`의 항목 패턴과 동일.
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: double.infinity,
                        height: kMinInteractiveDimension,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text('삭제', style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const GlassInsetHighlight(),
          ],
        ),
      ),
    );
  }
}
