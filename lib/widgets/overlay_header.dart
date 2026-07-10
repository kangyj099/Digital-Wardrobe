import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class OverlayHeader extends StatelessWidget {
  const OverlayHeader({super.key, required this.child, this.actions = const []});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    // 보더/그림자는 ClipRect 바깥의 Container에서 그린다 — ClipRect는 자기 크기(Offset.zero & size)로
    // 클립하기 때문에, BackdropFilter 안쪽 Container에 boxShadow를 두면 박스 바깥으로 번지는 그림자가
    // 클립 경계에서 잘려 보이지 않는다. 블러(BackdropFilter)만 ClipRect로 범위를 제한하고,
    // 배경색은 안쪽 Container가, 보더/그림자는 바깥쪽 Container가 담당하도록 분리한다.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
            child: Row(
              children: [
                Expanded(child: child),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
