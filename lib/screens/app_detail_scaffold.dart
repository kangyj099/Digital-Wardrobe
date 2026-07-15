import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';
import 'skeleton_region.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 공용 셸 — `closet_item_detail_screen.dart`/
/// `composition_detail_screen.dart`/`style_log_viewer_screen.dart`에 카테고리/id/placeholder
/// 라벨/상호 참조 라벨만 다르고 거의 동일하게 반복됐던 구조(`_placeholderContentHeight`,
/// "⋯더보기" 단일 `headerActions`, `AppScrollContainer`+`SingleChildScrollView`+`Column`
/// 래퍼, placeholder entry 1개짜리 `CrossReferenceLinkBar`)를 추출했다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목). `AppMainScaffold`와
/// 이름이 겹치지 않게 `AppDetailScaffold`로 명명.
///
/// `skeletonRegion`(`lib/screens/skeleton_region.dart`)에 의존하기 때문에 `lib/widgets/`가
/// 아니라 이 파일과 같은 `lib/screens/`에 둔다 — 이 코드베이스는 `widgets/`가 `screens/`를
/// 참조하지 않는 단방향 의존을 유지한다.
///
/// 본문(상세 정보)과 하단 상호 참조 링크 데이터 연동은 Step⑦(기능 구현) 몫이라 이번
/// 라운드는 정적 배치만 담당한다.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({
    super.key,
    required this.category,
    required this.placeholderLabel,
    required this.crossReferenceLabel,
  });

  /// 헤더 카테고리 토글에 넘길 현재 카테고리([AppMainScaffold.current]로 그대로 전달).
  final AppCategory category;

  /// 본문 skeletonRegion에 표시할 라벨(화면마다 다른 placeholder 설명 문구).
  final String placeholderLabel;

  /// 하단 [CrossReferenceLinkBar]의 단일 placeholder entry 라벨.
  final String crossReferenceLabel;

  /// 본문 skeletonRegion의 placeholder 높이 — `AppScrollContainer`의 `SingleChildScrollView`가
  /// 세로로 무한 높이를 주기 때문에 명시적 높이가 필요하다. 실제 데이터 바인딩(Step⑦) 전까지
  /// 쓰는 임시값이라 engineering-principles의 "명시적으로 표시된 임시 placeholder" 예외에 해당한다.
  static const double _placeholderContentHeight = 400;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: category,
      headerActions: [
        GlassCircleButton(
          icon: Icons.more_horiz,
          tooltip: '더보기 메뉴',
          onTap: () {}, // Step⑦(기능 구현)에서 실제 메뉴(수정/삭제 등) 연결 예정
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing),
          child: Column(
            children: [
              skeletonRegion(context, placeholderLabel, height: _placeholderContentHeight),
              CrossReferenceLinkBar(
                entries: [
                  CrossReferenceLinkEntry(label: crossReferenceLabel, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
