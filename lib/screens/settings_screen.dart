import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';

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
/// 본문은 `03_화면별UX명세서.md` §0의 Utility형 규칙(리스트-로우 패턴)을 따른다. 현재 이
/// 화면엔 파괴적 액션 로우가 없다. 실제 설정 값 저장/영속화(Provider/DB
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
          ],
        ),
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

/// 설정 리스트-로우 1개 — 제목 + trailing(토글/체브론).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.trailing, this.onTap});

  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
