import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형.
class StyleLogAddScreen extends StatelessWidget {
  const StyleLogAddScreen({super.key});

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
