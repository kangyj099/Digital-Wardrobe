import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';

void main() {
  testWidgets('multiSelectMode=false면 selected=true여도 체크서클이 안 보인다', (tester) async {
    final item = ClothingItem(
      id: 'c1',
      name: '테스트',
      imagePath: '',
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SelectableGalleryTile(item: item, onTap: () {}, selected: true),
      ),
    );
    expect(find.byType(MultiSelectCheckmark), findsNothing);
  });

  testWidgets('multiSelectMode=true, selected=true면 체크서클이 보이고 롱프레스가 onLongPress를 호출한다', (tester) async {
    var longPressed = false;
    final item = ClothingItem(
      id: 'c1',
      name: '테스트',
      imagePath: '',
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SelectableGalleryTile(
          item: item,
          onTap: () {},
          multiSelectMode: true,
          selected: true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );
    expect(find.byType(MultiSelectCheckmark), findsOneWidget);
    await tester.longPress(find.byType(SelectableGalleryTile));
    expect(longPressed, isTrue);
  });
}
