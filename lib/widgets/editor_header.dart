import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Add/Create 3화면(옷 추가하기/코디 만들기/스타일 일지 추가) 공용 헤더 —
/// "취소 버튼 + '?' 코치마크 도움말". `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`
/// §1 표: Add/Create 화면은 뒤로가기가 자체 취소 버튼으로 대체되고 카테고리 토글도 없다.
///
/// [onCommit]은 Editor Draft/Commit/Cancel 모델(`docs/history/Decision.md` "Editor 저장
/// 모델 전환")의 완료(✔) 버튼 — nullable이라 기본값(null)이면 이전과 동일하게 취소+도움말만
/// 렌더된다. non-null을 넘긴 화면(현재는 코디 편집기)만 우측에 체크 아이콘버튼이 추가로
/// 뜬다 — 다른 2개 Add/Create 스켈레톤 화면은 이 파라미터를 넘기지 않아 영향 없음.
class EditorHeader extends StatelessWidget {
  const EditorHeader({
    super.key,
    required this.onCancel,
    required this.onHelpTap,
    this.onCommit,
  });

  final VoidCallback onCancel;
  final VoidCallback onHelpTap;
  final VoidCallback? onCommit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: onCancel, child: const Text('취소')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onCommit != null)
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: '완료',
                  onPressed: onCommit,
                ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: '도움말',
                onPressed: onHelpTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
