import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppDetailScaffold], `AppMainScaffold` 위에
/// 얹은 Detail 3화면 공용 구조)에 연결됨. `docs/superpowers/specs/
/// 2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준 뒤로가기=O/카테고리 토글=O/
/// 그룹형 드릴다운=X는 [AppMainScaffold] 기본값과 그대로 일치해 별도 플래그 조정이 필요
/// 없다. 헤더의 "⋯더보기"는 이전에 `DetailHeaderActions`(카테고리 드롭다운+더보기를 하나의
/// 스타일 없는 `Row`로 묶어 Header/HUD Pinned Rule을 위반하던 위젯,
/// `docs/history/TechnicalDebt.md`)가 담당했으나, 카테고리 드롭다운은 [AppMainScaffold]가
/// `showCategoryToggle`로 이미 자동 처리하므로 이 화면은 남은 "⋯더보기" 하나만
/// [AppDetailScaffold]가 공통으로 처리한다.
///
/// 본문(옷 상세 정보)과 하단 상호 참조 링크 데이터 연동은 Step⑦(기능 구현) 몫이라
/// 이번 라운드는 정적 배치만 담당한다.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.closet,
      placeholderLabel: '옷 상세 정보 (id: $itemId) — 이미지/메타데이터/착용 이력',
      crossReferenceLabel: '연결된 코디/스타일일지 — Step⑦에서 연동 예정',
    );
  }
}
