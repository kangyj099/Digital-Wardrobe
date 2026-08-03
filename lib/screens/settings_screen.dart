import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/theme_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/undoable_action_toast.dart';

/// Step⑥(나머지 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준
/// Utility형(설정), 뒤로가기=O/카테고리 토글=X라 `showCategoryToggle: false`로 기본값
/// (true)을 오버라이드한다(그룹형 드릴다운 슬롯 자체는 2026-07-19 삭제됨 — `AppMainScaffold`
/// 참고).
///
/// `current`([AppMainScaffold]의 필수 파라미터)는 설정이 [AppCategory]의 옷장/코디/
/// 스타일일지 어디에도 속하지 않아 원래 무관하지만, `showCategoryToggle: false`라
/// 실제로 렌더링되지 않으므로 임의로 [AppCategory.closet]을 고정값으로 채운다.
///
/// 본문은 `00_페이지 타입 정의.md`의 Utility형 규칙(리스트-로우 패턴)을 따른다. 다크 모드
/// `Switch`는 전역 [themeModeProvider]([ThemeMode.light]/[ThemeMode.dark] 세션 내
/// 메모리 상태, 영속화는 범위 밖)를 읽고 써 `MaterialApp.themeMode`를 실제로 바꾼다. 알림
/// `Switch`는 대응하는 실제 기능이 없어 여전히 이 화면 로컬 `bool` state로만 토글된다
/// (`closet_main_screen.dart`의 밀도 버튼·FAB 확장처럼, 탭하면 화면에 바로 반영되는 수준 —
/// Tester가 "값이 항상 false로 고정돼 탭해도 반응 없음"을 지적해 `StatelessWidget`에서 이
/// 상태를 갖는 `StatefulWidget`으로 승격).
///
/// 최종 로우 구성(4개: 알림 토글/다크모드 토글/휴지통 진입/계정)은
/// `04_설정.md`(2026-07-27 확정)를 따른다 — "프로필 편집"은 이 앱에 프로필 엔티티 자체가
/// 없어 채택하지 않는다. 계정 로우는 로그인 상태에 따라 "로그아웃"/"로그인" 중 하나로만
/// 표시된다(`_isLoggedIn`). 로그아웃 로우는 파괴적 스타일(Error 색상)이지만 confirm 모달(C11)
/// 대신 즉시 실행 + Toast+Undo(C7, `UndoableActionToast`)를 쓴다(같은 문서 §3 근거) — 재로그인
/// 으로 완전히 되돌릴 수 있는 가역 액션이라 I6의 confirm 대상(비가역 액션)에 해당하지 않는다.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;

  /// 세션/로그인 시스템 부재(§5) — 앱이 Anonymous Auth 기반이라 항상 "로그인된" 상태로
  /// 시작한다. 로그아웃 로우의 Toast+Undo(C7) Undo 창이 만료되는 시점에만 실제로
  /// `false`로 전환된다(아래 `_handleLogout`의 `onExpire` 참고).
  bool _isLoggedIn = true;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AppMainScaffold(
      current: AppCategory.closet,
      showCategoryToggle: false,
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing, bottom: AppSpacing.lg),
          children: [
            const _SettingsSectionLabel('일반'),
            _SettingsRow(
              title: '알림',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
            ),
            _SettingsRow(
              title: '다크 모드',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) => ref.read(themeModeProvider.notifier).set(value),
              ),
            ),
            _SettingsRow(
              title: '휴지통',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoute.trashMain),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsSectionLabel('계정'),
            _isLoggedIn
                ? _SettingsRow(
                    title: '로그아웃',
                    leadingIcon: Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => _handleLogout(context),
                  )
                : _SettingsRow(
                    title: '로그인',
                    leadingIcon: Icons.login,
                    onTap: () => _handleLoginPlaceholder(context),
                  ),
          ],
        ),
      ),
    );
  }

  /// 로그아웃 로우 탭 핸들러 — `04_설정.md` §3(C11 미사용, C7 Toast+Undo 채택) 동작 정의를
  /// 그대로 구현한다: 탭 즉시 낙관적으로 로그아웃 상태 전환, Undo 시 로그인 상태 복원, 창
  /// 만료 시는 이미 적용된 전환을 그냥 확정하는 것뿐이라 추가 동작 없음(no-op). 이 화면 전용
  /// [_isLoggedIn] 상태는 C7의 기존 삭제-항목 상태 스토어와는 별개의 독립 스토어다 — 동일한
  /// optimistic-immediate + undo-reverses 패턴을 쓰는 `closet_main_screen.dart`의
  /// `softDeleteMany`/`restoreMany` 선례와 타이밍을 맞춘다.
  void _handleLogout(BuildContext context) {
    setState(() => _isLoggedIn = false);
    UndoableActionToast.show(
      context,
      message: '로그아웃되었습니다',
      actionLabel: '실행취소',
      onUndo: () {
        if (mounted) setState(() => _isLoggedIn = true);
      },
      onExpire: () {},
    );
  }

  /// 로그인 로우 탭 핸들러 — 실제 로그인 화면/플로우는 Post-MVP(§5, 이 태스크 범위 밖)라
  /// "준비 중" 안내만 하고 상태는 바꾸지 않는다.
  void _handleLoginPlaceholder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('기능 준비 중입니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('확인')),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxs),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// 설정 리스트-로우 1개 — 제목 + 선택적 leading 아이콘 + 선택적 trailing(토글/체브론).
///
/// [color]를 지정하면 leading 아이콘과 제목 텍스트 모두에 적용된다 — 로그아웃 로우처럼
/// destructive 스타일을 색상 단독이 아니라 아이콘+텍스트 병기로 표현할 때 쓴다(A2).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.leadingIcon,
    this.trailing,
    this.color,
    this.onTap,
  });

  final String title;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(color: color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: color),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(child: Text(title, style: titleStyle)),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
