import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/editor_header.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형.
///
/// Step⑤(Editor 적용) 산출물 — 헤더가 [EditorHeader]로 연결됨. 본문/저장 버튼은
/// 아직 skeleton placeholder 상태(Step⑦ 몫).
class StyleLogAddScreen extends StatelessWidget {
  const StyleLogAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EditorHeader(
            onCancel: () => context.pop(),
            onHelpTap: () {}, // Step⑦(기능 구현)에서 실제 도움말/코치마크 연결 예정
          ),
          skeletonRegion(
            context,
            '슬롯 카드 입력 (대표 이미지 → 코디 연결 → 추가 사진, 좌우 스와이프)',
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
