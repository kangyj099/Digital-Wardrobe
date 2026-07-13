import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형.
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (스타일 일지 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '스타일일지 카드 (id: $styleLogId) — 대표→코디→추가사진 슬라이드 + 날짜/장소',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 코디)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
