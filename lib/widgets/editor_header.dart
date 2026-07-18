import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Add/Create 3화면(옷 추가하기/코디 만들기/스타일 일지 추가) 공용 헤더 —
/// "취소 버튼 + '?' 코치마크 도움말". `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`
/// §1 표: Add/Create 화면은 뒤로가기가 자체 취소 버튼으로 대체되고 카테고리 토글도 없다.
///
/// 이번 라운드는 위젯만 만든다 — 3개 Add/Create 화면에 실제로 연결하는 건 Step⑤ 몫이라
/// 지금은 `skeleton_region.dart` placeholder를 그대로 둔다.
class EditorHeader extends StatelessWidget {
  const EditorHeader({super.key, required this.onCancel, required this.onHelpTap});

  final VoidCallback onCancel;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: onCancel, child: const Text('취소')),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '도움말',
            onPressed: onHelpTap,
          ),
        ],
      ),
    );
  }
}
