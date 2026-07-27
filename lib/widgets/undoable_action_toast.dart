import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// C7 `UndoableActionToast` — "즉시 실행 + Toast + 실행취소" UI 패턴의 재사용 가능한
/// 구현체 (`docs/reference/design/00_DesignPrinciples/06_Component Strategy.md` 참고).
///
/// 이 위젯은 **토스트 UI + undo 콜백 + 타이머**(=`SnackBar`의 `duration`)만 제공한다.
/// "무엇을 취소 가능한 상태로 되돌릴지"에 해당하는 상태 저장소는 절대 갖지 않는다 —
/// 호출부(각 화면)가 자기 자신만의 독립 상태 저장소로 관리해야 한다. C7/C8(레코드 단위
/// 삭제-Toast)이 상태 스토어를 공유하지 않는다는 제약과 동일한 이유로, 이 위젯을 재사용하는
/// 다른 화면들끼리도(예: 코디 삭제 vs 설정 로그아웃) 서로 다른 상태 스토어를 써야 한다.
///
/// 실행취소 여부 판정은 별도 `Timer`를 새로 만들지 않고 `SnackBar`가 이미 제공하는
/// `ScaffoldFeatureController.closed`(닫힌 사유를 담은 `Future<SnackBarClosedReason>`)를
/// 재사용한다 — `SnackBarClosedReason.action`(실행취소 버튼을 눌러 닫힘)이면 [onUndo]가 이미
/// 호출된 상태이므로 [onExpire]를 부르지 않고, 그 외 사유(시간 만료/스와이프/다른 토스트로
/// 교체 등)면 액션이 확정된 것으로 보고 [onExpire]를 부른다.
class UndoableActionToast {
  UndoableActionToast._();

  /// [message] + [actionLabel] 실행취소 액션이 있는 토스트를 띄운다.
  ///
  /// [onUndo]는 실행취소 버튼을 탭했을 때, [onExpire]는 실행취소 없이 토스트가 닫혔을 때
  /// (시간 만료 등 — 액션 확정 시점) 호출된다. [onExpire]는 확정 시점에 취할 실제 동작이
  /// 아직 없는 호출부라면 생략할 수 있다.
  static void show(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onUndo,
    VoidCallback? onExpire,
    Duration duration = AppDurations.toastDefault,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        // A13(WCAG 4.1.3 Status Messages): 토스트는 상태 변경 알림이므로 스크린리더에
        // 라이브 리전으로 전달되어야 한다. `SnackBar`의 기본 announce는 위젯 트리 삽입
        // 시점 알림에 그쳐 텍스트 갱신을 라이브 리전으로 명시적으로 보강한다.
        content: Semantics(
          liveRegion: true,
          child: Text(message),
        ),
        duration: duration,
        action: SnackBarAction(label: actionLabel, onPressed: onUndo),
      ),
    );

    if (onExpire != null) {
      controller.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) {
          onExpire();
        }
      });
    }
  }
}
