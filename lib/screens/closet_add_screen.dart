import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/editor_header.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형 — 뒤로가기 없음(자체 취소
/// 버튼이 대체), 카테고리 토글 없음. AppMainScaffold를 아예 쓰지 않는 화면군이라
/// Step②/③ 이후에도 자체 헤더를 유지한다.
///
/// Step⑤(Editor 적용) 산출물 — 헤더가 [EditorHeader]로 연결됨. 본문/저장 버튼은
/// 아직 skeleton placeholder 상태(Step⑦ 몫).
class ClosetAddScreen extends StatelessWidget {
  const ClosetAddScreen({super.key});

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
            '이미지 촬영/업로드 + AI 배경제거·자동태깅 진행 상태 + 메타데이터 폼',
          ),
          skeletonRegion(
            context,
            '저장 버튼 (상시 저장 원칙 — 진입 즉시 레코드 생성, 위치는 화면 구조에 따라 다름)',
            height: 56,
          ),
        ],
      ),
    );
  }
}
