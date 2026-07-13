import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형. 드래그/회전/z-index 제스처는
/// 스코프 밖(Global Constraints) — 정적 배치만 표시.
class CompositionEditorScreen extends StatelessWidget {
  const CompositionEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (취소 버튼 + "?" 코치마크 도움말)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '코디 아트보드 (정적 배치만 — 드래그/회전/z-index는 스코프 밖)',
          ),
          skeletonRegion(
            context,
            '저장 버튼 (상시 저장 원칙 — 진입 즉시 레코드 생성)',
            height: 56,
          ),
        ],
      ),
    );
  }
}
