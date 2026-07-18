import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_spacing.dart';
import 'package:digittal_wardrobe/widgets/app_gallery_grid.dart';

void main() {
  testWidgets('AppGalleryGrid는 itemCount만큼 itemBuilder를 호출하고 density를 crossAxisCount로 그대로 매핑한다',
      (tester) async {
    // 기본 테스트 뷰포트(800x600)로는 2컬럼×5아이템(3행)이 전부 lazy-build 되지 않아
    // 뷰포트를 넉넉히 키운다(GroupedGalleryGrid 통합테스트와 동일한 이유).
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGalleryGrid(
            itemCount: 5,
            density: AppDensity.mid,
            itemBuilder: (context, index) => Container(key: ValueKey('tile-$index')),
          ),
        ),
      ),
    );

    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('tile-$i')), findsOneWidget);
    }

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, AppDensity.mid);
  });

  testWidgets('itemCount가 0이면 크래시 없이 빈 그리드를 렌더링한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppGalleryGrid(
            itemCount: 0,
            density: AppDensity.min,
            itemBuilder: (context, index) => Container(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
  });
}
