import 'package:flutter/material.dart';
import 'frosted_close_button.dart';

/// Main 화면 3종(옷장/코디/스타일일지)의 재호출 피커 모달(`selectionMode`) 전용 헤더
/// 액션 — 피커 모달일 때만 닫기(X) 버튼을 반환한다. "선택"(다중선택 진입) 버튼은 더 이상
/// 이 헬퍼의 책임이 아니다 — `GalleryMainScreen`이 `selectionMode==false`일 때 자기
/// 헤더 조립 로직 안에서 직접 렌더링한다(두 책임이 겹치면 "선택" 버튼이 중복 렌더링됨 —
/// 실제로 그랬던 버그를 Audit이 잡음, 2026-07-21).
List<Widget> buildSelectionAwareHeaderActions({
  required bool selectionMode,
  required VoidCallback onClose,
}) {
  return [
    if (selectionMode) FrostedCloseButton(onTap: onClose),
  ];
}
