import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// [ExpandableAddFab] 펼침 메뉴에 뜨는 옵션 하나 — 라벨과 탭 콜백만 갖는다.
class ExpandableAddFabOption {
  const ExpandableAddFabOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// 옷장/스타일일지 메인 화면의 "탭하면 옵션 2개가 펼쳐지는 FAB" 패턴을 추출한 공용
/// StatefulWidget — `closet_main_screen.dart`/`style_log_main_screen.dart`에 텍스트만
/// 다르고 완전히 동일하게 복제됐던 `_fabExpanded`/`_buildFabOption`/`_onFabOptionTap`/
/// `AnimatedSize`/`AnimatedRotation` 블록을 그대로 옮겼다(`docs/history/TechnicalDebt.md`
/// "화면 간 반복 복제된 UI 블록" 항목).
///
/// [options]는 최소 1개부터 표현 가능하지만, 현재 두 호출부(옷장/스타일일지)는 모두 2개
/// 옵션을 넘긴다. 옵션 탭 시 FAB가 먼저 접히고(`setState`), 그 다음 해당 옵션의 [onTap]이
/// 호출된다 — 기존 `_onFabOptionTap`의 순서(접힘 → 네비게이션)를 그대로 보존.
class ExpandableAddFab extends StatefulWidget {
  const ExpandableAddFab({super.key, required this.options});

  final List<ExpandableAddFabOption> options;

  @override
  State<ExpandableAddFab> createState() => _ExpandableAddFabState();
}

class _ExpandableAddFabState extends State<ExpandableAddFab> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: AppMotion.fast,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildOptions(context),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: AppMotion.fast,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      if (i > 0) children.add(const SizedBox(height: AppSpacing.xs));
      children.add(_buildOption(context, widget.options[i]));
    }
    return children;
  }

  Widget _buildOption(BuildContext context, ExpandableAddFabOption option) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () {
          setState(() => _expanded = false);
          option.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(option.label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
    );
  }
}
