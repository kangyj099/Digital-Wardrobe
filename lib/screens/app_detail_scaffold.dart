import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 공용 셸 — `AppMainScaffold` 위에
/// Detail 전용 스크롤 콘텐츠 구조(본문 + 하단 크로스 레퍼런스 바)를 얹는다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목).
///
/// Step⑦ 1라운드(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`)에서
/// `placeholderLabel`/`crossReferenceLabel`(단일 문자열) 계약을 `body`(임의 위젯)와
/// `crossReferenceEntries`(리스트)로 넓혔다 — Audit(2026-07-15)이 호출부가 3곳뿐인
/// 지금 넓히는 게 가장 저렴하다고 지적한 항목.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({
    super.key,
    required this.category,
    required this.body,
    this.crossReferenceEntries = const [],
  });

  /// 헤더 카테고리 토글에 넘길 현재 카테고리([AppMainScaffold.current]로 그대로 전달).
  final AppCategory category;

  /// 본문 콘텐츠 — 화면마다 실제 상세 정보를 자유롭게 채운다.
  final Widget body;

  /// 하단 [CrossReferenceLinkBar]에 넘길 항목들. 비어 있으면 빈 바(높이만 차지)를 그린다.
  final List<CrossReferenceLinkEntry> crossReferenceEntries;

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
          child: Column(
            children: [
              body,
              CrossReferenceLinkBar(entries: crossReferenceEntries),
            ],
          ),
        ),
      ),
    );
  }
}
