import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import 'glass_pill.dart';

/// 다중선택 모드 진입 버튼("선택") — [GlassPill]+[TextButton]+
/// `AppTypography.actionMinimal` 조합을 옷장/코디/스타일일지 메인(`GalleryMainScreen`)과
/// 휴지통(`TrashMainScreen`)이 각각 손으로 반복하다, 한쪽에서만 `style:` 지정이 누락되는
/// 드리프트가 실제로 발생했다(Audit P1, `GalleryMainScreen` 추출 시 실수로 빠짐). 값 하나가
/// 두 곳에 흩어지지 않도록 공용 위젯으로 추출한다 — [FrostedCloseButton]이
/// [GlassCircleButton]을 감싸는 것과 동일한 "primitive 위에 얇은 의미론적 어댑터" 패턴.
class SelectionEntryButton extends StatelessWidget {
  const SelectionEntryButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      child: TextButton(
        onPressed: onTap,
        child: const Text('선택', style: AppTypography.actionMinimal),
      ),
    );
  }
}
