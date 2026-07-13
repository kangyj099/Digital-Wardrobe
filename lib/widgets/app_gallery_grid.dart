import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 순수 그리드 레이아웃 메커니즘(패딩, density→crossAxisCount 매핑, gap, aspectRatio)만
/// 담당하는 그리드 위젯 — 타일 콘텐츠는 몰라도 된다(제네릭 `itemBuilder`).
///
/// 원래 `GroupedGalleryGrid`가 `List<ClothingItem>` 타입에 고정된 `GridView.builder`였던
/// 것에서 레이아웃 부분만 분리한 것 — `GroupedGalleryGrid`는 이제 이 위 얇은 어댑터로 남는다
/// (`docs/reference/design/00_DesignPrinciples/06_Component Strategy.md` C2가 구현하는
/// L4/T6 "3단계 density" 규칙은 이 위젯이 실제로 구현한다).
class AppGalleryGrid extends StatelessWidget {
  const AppGalleryGrid({
    super.key,
    required this.itemCount,
    required this.density,
    required this.itemBuilder,
  });

  final int itemCount;

  /// `AppDensity.min/mid/max` 중 하나 — 이 값이 그대로 그리드 열 개수(crossAxisCount)로
  /// 쓰인다(현재 density 토큰 자체가 열 개수로 정의돼 있어 매핑이 항등함수).
  final int density;

  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: density,
        crossAxisSpacing: AppSpacing.galleryGap,
        mainAxisSpacing: AppSpacing.galleryGap,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
