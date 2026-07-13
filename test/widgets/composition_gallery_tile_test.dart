import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';

void main() {
  testWidgets('season이 있으면 이름과 계절 라벨을 함께 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    const composition = Composition(
      id: 'comp01',
      name: '데일리 룩',
      season: Season.springFall,
      items: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: CompositionGalleryTile(composition: composition, onTap: () {})),
      ),
    );

    expect(find.text('데일리 룩'), findsOneWidget);
    expect(find.text('봄가을'), findsOneWidget);
    expect(find.bySemanticsLabel('데일리 룩, 봄가을'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('season이 없으면 계절 배지를 생략하고 이름만 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    const composition = Composition(id: 'comp02', name: '무계절 코디', items: []);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: CompositionGalleryTile(composition: composition, onTap: () {})),
      ),
    );

    expect(find.text('무계절 코디'), findsOneWidget);
    expect(find.bySemanticsLabel('무계절 코디'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('탭하면 onTap이 호출된다', (tester) async {
    var tapped = false;
    const composition = Composition(id: 'comp03', name: '탭 테스트', items: []);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CompositionGalleryTile(composition: composition, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(CompositionGalleryTile));
    expect(tapped, isTrue);
  });
}
