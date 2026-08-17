import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/enums.dart';
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
    final item = ClothingItem(
      id: 'c01',
      name: 'padding jacket',
      category: ClothingCategory.outer,
      color: ClothingColor.navy,
      season: Season.winter,
      material: ClothingMaterial.padding,
      imagePath: '',
      wearCount: 5,
      createdAt: DateTime(2025, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: SelectableGalleryTile(item: item, onTap: () {}))),
    );
    // 색상이 폐쇄 어휘 enum이 되면서 스크린리더가 읽는 값도 enum명이 아니라 한글 라벨이
    // 됐다(category/season/material이 이미 쓰던 `.label` 방식과 통일).
    expect(find.bySemanticsLabel('padding jacket, 네이비, 착용 5회'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('SelectableGalleryTile marks incomplete items via Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final item = ClothingItem(
      id: 'c06',
      name: 'fleece pants',
      category: ClothingCategory.bottom,
      color: ClothingColor.gray,
      season: Season.winter,
      material: ClothingMaterial.fleece,
      imagePath: '',
      isIncomplete: true,
      createdAt: DateTime(2025, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: SelectableGalleryTile(item: item, onTap: () {}))),
    );
    expect(find.bySemanticsLabel('fleece pants, 그레이, 착용 0회, 미완성'), findsOneWidget);
    handle.dispose();
  });
}
