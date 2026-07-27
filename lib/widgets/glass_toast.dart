import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// GlassPill 스타일 Toast — Glass 셸 화면(옷장/코디/스타일일지 메인+Detail)의 다중선택
/// 삭제/더보기 삭제에 쓰는 C7 패턴의 Glass 시각 변형. `UndoableActionToast`(SnackBar 기반,
/// Settings 같은 plain Utility 화면용)와 같은 상호작용 계약(메시지+액션+자동소멸)을 두
/// 화면군에 맞는 다른 시각 언어로 각각 구현한 것 — 의도적 공존, 중복 아님(근거:
/// `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` §5, 스펙 작성
/// 시점엔 SnackBar 패턴 자체가 없었음).
class GlassToast {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.toastDefault,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    // Future.delayed 대신 취소 가능한 Timer를 쓴다 — 액션 버튼을 눌러 entry를 조기
    // 제거할 때 auto-remove 타이머도 함께 취소하지 않으면, 위젯 트리 폐기 후에도
    // 타이머가 남아 `flutter_test`의 "pending timer" 불변조건 검사에 걸린다.
    Timer? autoRemoveTimer;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
        child: Material(
          color: Colors.transparent,
          child: GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A13(WCAG 4.1.3 Status Messages): 토스트는 상태 변경 알림이므로 스크린리더에
                // 라이브 리전으로 전달되어야 한다(`UndoableActionToast`와 동일한 처리).
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(message, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: () {
                      autoRemoveTimer?.cancel();
                      onAction?.call();
                      entry.remove();
                    },
                    child: Text(actionLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    autoRemoveTimer = Timer(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}
