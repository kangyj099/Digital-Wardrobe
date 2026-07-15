import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import 'frosted_close_button.dart';
import 'glass_pill.dart';

/// Main 화면 3종(옷장/코디/스타일일지)의 `AppMainScaffold.headerActions` 슬롯이
/// `selectionMode` 여부에 따라 갈리는 분기를 모아둔 헬퍼 — `closet_main_screen.dart`/
/// `composition_main_screen.dart`/`style_log_main_screen.dart` 3곳에 동일하게 반복됐다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목, Step⑥-B 5번째 사례).
///
/// 선택 모달([selectionMode]==true)에서는 닫기(X) 버튼([FrostedCloseButton])을,
/// 아니면 "선택"(다중 선택 진입) 버튼을 [GlassPill]로 감싸 보여준다. "선택" 버튼은 아직
/// 동작이 없다(`onPressed: () {}`) — 실제 다중 선택 기능은 Step⑦(기능 구현) 몫이라 그대로
/// 유지한다.
List<Widget> buildSelectionAwareHeaderActions({
  required bool selectionMode,
  required VoidCallback onClose,
}) {
  return [
    if (selectionMode)
      FrostedCloseButton(onTap: onClose)
    else
      GlassPill(
        child: TextButton(
          onPressed: () {}, // Step⑦(기능 구현)에서 다중 선택 진입 동작 연결 예정
          child: const Text('선택', style: AppTypography.actionMinimal),
        ),
      ),
  ];
}
