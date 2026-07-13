import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-플랫+필터형 — 그룹 드릴다운 없음(기존
/// 스펙대로 필터 칩만). `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 참고.
class StyleLogMainScreen extends StatelessWidget {
  const StyleLogMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (스타일 일지 ▾ + 필터 칩) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(context, '스타일일지 갤러리 (플랫 + 필터, 그룹 드릴다운 없음)'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
