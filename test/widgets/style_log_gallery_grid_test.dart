import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/theme/app_spacing.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_grid.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

void main() {
  testWidgets(
      'logs 개수만큼 StyleLogGalleryTile을 렌더링하고 밀도 토글 UI가 없으므로 항상 AppDensity.mid로 고정한다',
      (tester) async {
    // AppGalleryGrid 테스트와 동일한 이유로 뷰포트를 넉넉히 키운다(lazy-build 누락 방지).
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logs = [
      StyleLog(id: 'log01', coverImagePath: '', wornDate: DateTime(2026, 1, 5)),
      StyleLog(id: 'log02', coverImagePath: '', wornDate: DateTime(2026, 1, 10)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StyleLogGalleryGrid(logs: logs, onItemTap: (_) {})),
      ),
    );

    expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, AppDensity.mid);
  });

  testWidgets('타일 탭 시 해당 styleLog로 onItemTap이 호출된다', (tester) async {
    StyleLog? tapped;
    final logs = [StyleLog(id: 'log01', coverImagePath: '', wornDate: DateTime(2026, 1, 5))];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StyleLogGalleryGrid(logs: logs, onItemTap: (l) => tapped = l)),
      ),
    );

    await tester.tap(find.byType(StyleLogGalleryTile));
    expect(tapped?.id, 'log01');
  });
}
