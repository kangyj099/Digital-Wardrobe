import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 순수 그리드 레이아웃 메커니즘(패딩, density→crossAxisCount 매핑, gap, aspectRatio)만
/// 담당하는 그리드 위젯 — 타일 콘텐츠는 몰라도 된다(제네릭 `itemBuilder`).
///
/// 원래 `GroupedGalleryGrid`가 `List<ClothingItem>` 타입에 고정된 `GridView.builder`였던
/// 것에서 레이아웃 부분만 분리한 것 — `GroupedGalleryGrid`는 이제 이 위 얇은 어댑터로 남는다
/// (`docs/reference/design/00_DesignPrinciples.md` §Stage 6 — Component Strategy, C2가 구현하는
/// L4/T6 "3단계 density" 규칙은 이 위젯이 실제로 구현한다).
class AppGalleryGrid extends StatelessWidget {
  const AppGalleryGrid({
    super.key,
    required this.itemCount,
    required this.density,
    required this.itemBuilder,
    this.controller,
    this.topSpacing = 0,
    this.bottomSpacing = AppSpacing.sm,
  });

  final int itemCount;

  /// `AppDensity.min/mid/max` 중 하나 — 이 값이 그대로 그리드 열 개수(crossAxisCount)로
  /// 쓰인다(현재 density 토큰 자체가 열 개수로 정의돼 있어 매핑이 항등함수).
  final int density;

  final Widget Function(BuildContext context, int index) itemBuilder;

  /// [AppScrollContainer]가 전달하는 `ScrollController` — Scroll Edge Hint(스펙 §2)가
  /// 스크롤 위치를 관찰하려면 실제 스크롤 가능 위젯(이 GridView)에 반드시 연결되어야 한다.
  final ScrollController? controller;

  /// Content Spacer(스펙 §4) — Header/HUD가 차지하는 높이만큼 스크롤 콘텐츠 상단에
  /// 확보하는 여백. `GridView.padding`은 스크롤 가능 영역 "안"에 있어 스크롤하면 함께
  /// 밀려 올라간다(고정 여백이 아니다 — Header가 레이아웃 공간을 차지하지 않는다는
  /// 스펙 §1/§5 규칙을 만족하는 핵심 메커니즘).
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
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
