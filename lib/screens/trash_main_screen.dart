import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-플랫+필터형, [+] 버튼 없음(휴지통은
/// 추가 개념이 없는 화면 — `00_페이지 타입 정의.md` 참고).
class TrashMainScreen extends StatelessWidget {
  const TrashMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (휴지통 + 비우기 버튼, 파괴적 액션이라 강한 확인 모달 필요) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '휴지통 썸네일 그리드 (제목 없이 이미지 중심, 유형 배지 + 잔여일수 오버레이)',
          ),
        ],
      ),
    );
  }
}
