import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형.
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (코디 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '코디 상세 (id: $compositionId) — 아트보드 스냅샷 + 사용된 옷 목록',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 스타일일지)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
