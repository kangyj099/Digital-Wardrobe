import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';

/// Step⑥(나머지 화면 적용) 산출물 — 공용 셸([AppMainScaffold])에 연결됨.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준
/// Utility형(설정), 뒤로가기=O/카테고리 토글=X/그룹형 드릴다운=X라 `showCategoryToggle:
/// false`로 기본값(true)을 오버라이드하고 `groupingBar`는 비워둔다(둘 다 기본값 자체가
/// null/true라 groupingBar는 별도 지정 불필요).
///
/// `current`([AppMainScaffold]의 필수 파라미터)는 설정이 [AppCategory]의 옷장/코디/
/// 스타일일지 어디에도 속하지 않아 원래 무관하지만, `showCategoryToggle: false`라
/// 실제로 렌더링되지 않으므로 임의로 [AppCategory.closet]을 고정값으로 채운다.
///
/// 본문은 `00_페이지 타입 정의.md`의 Utility형 규칙(리스트-로우 패턴, 파괴적 액션은
/// 별도 확인 절차로 한 단계 더 진입)을 따른다. 실제 설정 값 저장/영속화(Provider/DB
/// 연동)는 Step⑦(기능 구현) 몫이라 알림/다크모드 `Switch`는 이 화면 로컬 `bool` state로만
/// 토글된다(`closet_main_screen.dart`의 밀도 버튼·FAB 확장처럼, 탭하면 화면에 바로
/// 반영되는 수준 — Tester가 "값이 항상 false로 고정돼 탭해도 반응 없음"을 지적해
/// `StatelessWidget`에서 이 상태를 갖는 `StatefulWidget`으로 승격).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

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
                value: _darkModeEnabled,
                onChanged: (value) => setState(() => _darkModeEnabled = value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SettingsSectionLabel('계정'),
            _SettingsRow(
              title: '프로필 편집',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Step⑦에서 실제 진입 연결
            ),
            _SettingsRow(
              title: '전체 데이터 삭제',
              trailing: const Icon(Icons.chevron_right),
              destructive: true,
              // 파괴적 액션 — 즉시 실행하지 않고 별도 확인 절차로 한 단계 더 진입시킨다.
              onTap: () => _confirmDestructiveAction(
                context,
                title: '전체 데이터 삭제',
                message: '정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDestructiveAction(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Step⑦에서 실제 실행 연결
            child: Text(title),
          ),
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

/// 설정 리스트-로우 1개 — 제목 + trailing(토글/체브론). `destructive`는 파괴적 액션
/// 행임을 시각적으로 표시(제목 텍스트를 `colorScheme.error`로).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: destructive ? colorScheme.error : null),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
