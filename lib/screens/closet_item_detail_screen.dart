import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형 — 공용 네비게이션(헤더 드롭다운 +
/// 뒤로가기)은 Step②/③에서 AppMainScaffold로 대체될 예정이라 리전만 표시한다.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (옷장 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '옷 상세 정보 (id: $itemId) — 이미지/메타데이터/착용 이력',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 코디/스타일일지)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
