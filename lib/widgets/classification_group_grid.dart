import 'package:flutter/material.dart';
import '../providers/classification_models.dart';
import 'app_gallery_grid.dart';
import 'classification_group_card.dart';

/// `List<ClassificationGroupSummary>` + [ClassificationGroupCard] 매핑 전용 어댑터 —
/// `GroupedGalleryGrid`/`CompositionGalleryGrid`와 동일한 얇은 어댑터 패턴.
class ClassificationGroupGrid extends StatelessWidget {
  const ClassificationGroupGrid({
    super.key,
    required this.groups,
    required this.density,
    required this.onGroupTap,
    this.controller,
    this.topSpacing = 0,
  });

  final List<ClassificationGroupSummary> groups;
  final int density;
  final void Function(ClassificationGroupSummary group) onGroupTap;
  final ScrollController? controller;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: groups.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final group = groups[index];
        return ClassificationGroupCard(
          key: ValueKey(group.label),
          summary: group,
          onTap: () => onGroupTap(group),
        );
      },
    );
  }
}
