import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/theme/app_spacing.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_grid.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';

void main() {
  testWidgets(
      'compositions 개수만큼 CompositionGalleryTile을 렌더링하고 density를 crossAxisCount로 그대로 매핑한다',
      (tester) async {
    // AppGalleryGrid 테스트와 동일한 이유로 뷰포트를 넉넉히 키운다(lazy-build 누락 방지).
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final compositions = [
      Composition(id: 'comp01', name: '데일리 룩', items: const [], createdAt: DateTime(2025, 1, 1)),
      Composition(id: 'comp02', name: '포멀 코디', items: const [], createdAt: DateTime(2025, 1, 2)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        // `CompositionGalleryGrid`가 `ConsumerWidget`으로 전환됨(§13.4,
        // `compositionHasDeletedItemsProvider`를 코디별로 직접 watch하기 위함) — 이 provider가
        // 내부적으로 `compositionsProvider`/`closetItemsProvider`를 참조하므로 `ProviderScope`
        // 없이는 렌더링 자체가 불가능하다.
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CompositionGalleryGrid(
              compositions: compositions,
              density: AppDensity.mid,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CompositionGalleryTile), findsNWidgets(2));

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, AppDensity.mid);
  });

  testWidgets('타일 탭 시 해당 composition으로 onItemTap이 호출된다', (tester) async {
    Composition? tapped;
    final compositions = [
      Composition(id: 'comp01', name: '데일리 룩', items: const [], createdAt: DateTime(2025, 1, 1)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CompositionGalleryGrid(
              compositions: compositions,
              density: AppDensity.mid,
              onItemTap: (c) => tapped = c,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CompositionGalleryTile));
    expect(tapped?.id, 'comp01');
  });
}
