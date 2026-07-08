import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class OverlayHeader extends StatelessWidget {
  const OverlayHeader({super.key, required this.child, this.actions = const []});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          child: Row(
            children: [
              Expanded(child: child),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
