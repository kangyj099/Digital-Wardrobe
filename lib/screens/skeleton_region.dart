import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Step①(전체 화면 Skeleton) 전용 임시 헬퍼 — 레이아웃 리전 자리만 표시한다.
/// Step②(Component Library)가 실제 컴포넌트를 도입하면 이 헬퍼를 참조하는
/// 모든 화면이 교체되며, 이 파일 자체도 은퇴한다.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §3 참고.
Widget skeletonRegion(BuildContext context, String label, {double? height}) {
  final box = Container(
    width: double.infinity,
    height: height,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
  return height == null ? Expanded(child: box) : box;
}
