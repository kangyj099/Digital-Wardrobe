import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
        // `left`+`right`를 동시에 지정하면 이 서브트리에 화면 폭 전체의 TIGHT 폭
        // 제약이 걸린다. `Center` 하나만으로는 부족하다 — `Center`(=`Align`)는 min
        // 제약만 0으로 풀 뿐 max는 그대로 유지하는데, `GlassPill` 내부 `Container`가
        // `alignment: Alignment.center`를 쓰는 순간(`Container.build()`가 이를
        // 내부 `Align`으로 구현) 그 `Align`은 "들어온 max가 유한하면(설령 loose여도)
        // 그 max까지 확장"하는 방향으로 동작해 폭 전체로 다시 늘어난다(`Align`이 진짜
        // shrink-wrap하는 건 max가 정확히 `double.infinity`일 때뿐). 그래서
        // `IntrinsicWidth`로 Material의 실제 콘텐츠(Row mainAxisSize.min) 자연 폭을
        // 먼저 측정해 그 값으로 TIGHT 제약(min==max)을 만들어 내려보낸다 — 제약이
        // tight면 내부 Align의 "확장" 성향과 무관하게 `constrain()`이 그 값으로 강제
        // 고정되므로 GlassPill이 진짜로 콘텐츠 크기만큼만 그려진다. 이게 없으면
        // Material의 렌더 오브젝트가 화면 폭 전체를 차지해, 알약(pill) 바깥의 투명한
        // 빈 공간까지 히트테스트를 가로채 그 아래(예: 뒤로가기 버튼)의 탭을 먹어버린다.
        child: Center(
          child: IntrinsicWidth(
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
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: TextButton(
                          // 메시지 영역과 구분되도록 옅은 배경을 준다 — `trash_main_screen.dart`의
                          // 필터 선택 상태 하이라이트와 같은 `primaryLight` pill 패턴 재사용
                          // (Visual Review 피드백: 실행취소 버튼이 탭 가능한 요소로 안 보임).
                          // `primary500`(기본 TextButton 전경색) on `primaryLight` 대비비
                          // ~6.3:1로 WCAG AA(4.5:1) 충족.
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).extension<AppSemanticColors>()!.primaryLight,
                          ),
                          onPressed: () {
                            autoRemoveTimer?.cancel();
                            onAction?.call();
                            entry.remove();
                          },
                          child: Text(actionLabel),
                        ),
                      ),
                  ],
                ),
              ),
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
