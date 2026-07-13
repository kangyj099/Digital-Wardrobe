import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// [CrossReferenceLinkBar] 한 항목 — 연결된 코디/스타일일지 하나를 표현.
class CrossReferenceLinkEntry {
  const CrossReferenceLinkEntry({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 하단의 "상호 참조 링크(연결된 코디/
/// 스타일일지)" 바. `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`의
/// Detail 화면 규칙과, 각 화면 Step①  skeletonRegion이 이미 확정해둔 높이(64)를 그대로 승계한다.
///
/// 화면 연결은 Step④(Detail 적용) 몫 — 이번 라운드는 위젯만 만든다.
class CrossReferenceLinkBar extends StatelessWidget {
  const CrossReferenceLinkBar({super.key, required this.entries});

  final List<CrossReferenceLinkEntry> entries;

  /// Step①에서 세 Detail 화면의 skeletonRegion이 못박아 둔 높이. 공식 Design Tokens
  /// (`AppSpacing` 등) 파일 등재는 이번 라운드 Edit 대상 밖이라 로컬 상수로 유지 —
  /// TechnicalDebt 후보(Worker 핸드오프에 기록).
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: entries.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _CrossReferenceLinkChip(entry: entry);
              },
            ),
    );
  }
}

class _CrossReferenceLinkChip extends StatelessWidget {
  const _CrossReferenceLinkChip({required this.entry});

  final CrossReferenceLinkEntry entry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Material(
      color: semantic.gray100,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.icon != null) ...[
                Icon(entry.icon, size: AppSpacing.md),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(entry.label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
