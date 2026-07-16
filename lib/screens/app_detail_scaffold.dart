import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_circle_button.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 공용 셸 — `AppMainScaffold` 위에
/// Detail 전용 스크롤 콘텐츠 구조(본문)를 얹는다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목).
///
/// Step⑦ 1라운드(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`)에서
/// `placeholderLabel`(단일 문자열) 계약을 `body`(임의 위젯)로 넓혔고, 이후 `crossReferenceEntries`/
/// `CrossReferenceLinkBar`(Task 9)는 3개 Detail 화면 전부가 각자 실제 크로스 레퍼런스 위젯
/// (`CompositionPreviewCarousel`/`StyleLogCrossReferenceGallery`)을 `body`에 직접 배치하게
/// 되어 계약에서 폐기됐다 — 이제 `category`/`body` 2-파라미터 계약뿐이다.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({super.key, required this.category, required this.body});

  /// 헤더 카테고리 토글에 넘길 현재 카테고리([AppMainScaffold.current]로 그대로 전달).
  final AppCategory category;

  /// 본문 콘텐츠 — 화면마다 실제 상세 정보를 자유롭게 채운다.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: category,
      headerActions: [
        GlassCircleButton(
          icon: Icons.more_horiz,
          tooltip: '더보기 메뉴',
          onTap: () {}, // 실제 메뉴(수정/삭제 등) 연결은 이번 라운드 스코프 밖(Global Constraints 참고)
        ),
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
