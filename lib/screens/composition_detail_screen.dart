import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';
import 'skeleton_region.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨. 자세한 배경은
/// `lib/screens/closet_item_detail_screen.dart`의 클래스 주석 참고(동일 패턴).
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  /// [ClosetItemDetailScreen]과 동일한 근거의 본문 placeholder 높이.
  static const double _placeholderContentHeight = 400;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: AppCategory.composition,
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
                '코디 상세 (id: $compositionId) — 아트보드 스냅샷 + 사용된 옷 목록',
                height: _placeholderContentHeight,
              ),
              CrossReferenceLinkBar(
                entries: [
                  CrossReferenceLinkEntry(
                    label: '연결된 스타일일지 — Step⑦에서 연동 예정',
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
