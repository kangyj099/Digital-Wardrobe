import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      label: '$label 상태',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: semantic.warning,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
