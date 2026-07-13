import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'category_toggle_dropdown.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 헤더의 "드롭다운 ▾ + ⋯ 메뉴" 액션 부분.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표: Detail 화면은
/// 카테고리 토글은 켜져 있고(O) 그룹형 드릴다운은 없다(X) — 이 위젯이 그 토글 부분을 담당한다.
///
/// Step②-B(다음 라운드, `AppMainScaffold`)의 `actions` 슬롯에 꽂아 쓸 부품이라 이번 라운드에는
/// 실제 Detail 화면에 연결하지 않는다(Step③~④ 몫).
class DetailHeaderActions extends StatelessWidget {
  const DetailHeaderActions({super.key, required this.current, required this.onMenuTap});

  /// 드롭다운용 — [CategoryToggleDropdown]과 동일 패턴 재사용.
  final AppCategory current;

  /// ⋯ 메뉴 탭 콜백.
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryToggleDropdown(current: current),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: '더보기 메뉴',
          onPressed: onMenuTap,
        ),
      ],
    );
  }
}
