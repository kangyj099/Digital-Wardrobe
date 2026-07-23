import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Add/Create 3화면 하단의 "상시 저장 원칙" 표시 — `03_화면별UX명세서.md` §공통 규칙 "상시 저장(드래프트 없음)":
/// 편집 화면 진입 즉시 레코드가 생성되고 이후 변경이 계속 저장되므로, 이 위젯은 일반적인
/// "저장" 버튼이 아니라 **"이미 저장됨" 상태를 알리는 인디케이터**다 — 탭 가능한 액션이 아니다.
///
/// 화면 연결은 Step⑤ 몫, 이번 라운드는 위젯만 만든다.
class AutoSaveIndicator extends StatelessWidget {
  const AutoSaveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      label: '자동 저장됨',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: AppSpacing.md, color: semantic.success),
          const SizedBox(width: AppSpacing.xxs),
          Text('자동 저장됨', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
