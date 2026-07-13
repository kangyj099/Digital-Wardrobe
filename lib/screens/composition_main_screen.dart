import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-그룹형(옷장 메인과 동일 페이지 타입).
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1/§3 참고.
class CompositionMainScreen extends StatelessWidget {
  const CompositionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (코디 ▾ + 선택 버튼) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '분류 선택 바 (그룹형 드릴다운) — Step②에서 AppMainScaffold groupingBar 슬롯으로 대체 예정',
            height: 48,
          ),
          skeletonRegion(context, '코디 갤러리 그리드 (그룹형)'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
