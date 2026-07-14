import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';
import 'skeleton_region.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준
/// 뒤로가기=O/카테고리 토글=O/그룹형 드릴다운=X는 [AppMainScaffold] 기본값과 그대로
/// 일치해 별도 플래그 조정이 필요 없다. 헤더의 "⋯더보기"는 이전에 `DetailHeaderActions`
/// (카테고리 드롭다운+더보기를 하나의 스타일 없는 `Row`로 묶어 Header/HUD Pinned Rule을
/// 위반하던 위젯, `docs/history/TechnicalDebt.md`)가 담당했으나, 카테고리 드롭다운은
/// [AppMainScaffold]가 `showCategoryToggle`로 이미 자동 처리하므로 이 화면은 남은
/// "⋯더보기" 하나만 [GlassCircleButton]으로 감싸 `headerActions`에 직접 넘긴다.
///
/// 본문(옷 상세 정보)과 하단 상호 참조 링크 데이터 연동은 Step⑦(기능 구현) 몫이라
/// 이번 라운드는 정적 배치만 담당한다.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  /// 본문 skeletonRegion의 placeholder 높이 — `AppScrollContainer`의 `SingleChildScrollView`가
  /// 세로로 무한 높이를 주기 때문에(Step① 당시의 `Expanded`는 더 이상 쓸 수 없음)
  /// 명시적 높이가 필요하다. 실제 데이터 바인딩(Step⑦) 전까지 쓰는 임시값이라
  /// engineering-principles의 "명시적으로 표시된 임시 placeholder" 예외에 해당한다.
  static const double _placeholderContentHeight = 400;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: AppCategory.closet,
      headerActions: [
        GlassCircleButton(
          icon: Icons.more_horiz,
          tooltip: '더보기 메뉴',
          onTap: () {}, // Step⑦(기능 구현)에서 실제 메뉴(수정/삭제 등) 연결 예정
        ),
      ],
      body: AppScrollContainer(
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing),
          child: Column(
            children: [
              skeletonRegion(
                context,
                '옷 상세 정보 (id: $itemId) — 이미지/메타데이터/착용 이력',
                height: _placeholderContentHeight,
              ),
              CrossReferenceLinkBar(
                entries: [
                  CrossReferenceLinkEntry(
                    label: '연결된 코디/스타일일지 — Step⑦에서 연동 예정',
                    onTap: () {},
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
