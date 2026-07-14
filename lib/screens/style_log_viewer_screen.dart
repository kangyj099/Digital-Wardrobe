import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';
import 'skeleton_region.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨. 자세한 배경은
/// `lib/screens/closet_item_detail_screen.dart`의 클래스 주석 참고(동일 패턴).
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  /// [ClosetItemDetailScreen]과 동일한 근거의 본문 placeholder 높이.
  static const double _placeholderContentHeight = 400;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: AppCategory.styleLog,
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
              skeletonRegion(
                context,
                '스타일일지 카드 (id: $styleLogId) — 대표→코디→추가사진 슬라이드 + 날짜/장소',
                height: _placeholderContentHeight,
              ),
              CrossReferenceLinkBar(
                entries: [
                  CrossReferenceLinkEntry(
                    label: '연결된 코디 — Step⑦에서 연동 예정',
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
