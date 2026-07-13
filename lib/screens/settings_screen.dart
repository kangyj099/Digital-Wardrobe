import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Utility형 — 카테고리 토글 없음.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (설정) — Step②에서 AppMainScaffold로 대체 예정(카테고리 토글은 미노출)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '리스트-로우 (토글/체브론), 파괴적 액션은 스와이프 또는 별도 확인 절차로 한 단계 더 진입',
          ),
        ],
      ),
    );
  }
}
