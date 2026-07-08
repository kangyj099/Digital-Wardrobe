import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

void main() {
  testWidgets('StatusBadge exposes its label via Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const Scaffold(body: StatusBadge(label: '미완성'))),
    );
    expect(find.bySemanticsLabel('미완성 상태'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('SelectableGalleryTile exposes name/color/wearCount via Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    const item = ClothingItem(
      id: 'c01',
      name: 'padding jacket',
      category: 'outer',
      color: 'navy',
      season: '겨울',
      imagePath: '',
      wearCount: 5,
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: SelectableGalleryTile(item: item, onTap: () {}))),
    );
    expect(find.bySemanticsLabel('padding jacket, navy, 착용 5회'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('SelectableGalleryTile marks incomplete items via Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    const item = ClothingItem(
      id: 'c06',
      name: 'fleece pants',
      category: 'bottom',
      color: 'gray',
      season: '겨울',
      imagePath: '',
      isIncomplete: true,
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: SelectableGalleryTile(item: item, onTap: () {}))),
    );
    expect(find.bySemanticsLabel('fleece pants, gray, 착용 0회, 미완성'), findsOneWidget);
    handle.dispose();
  });
}
