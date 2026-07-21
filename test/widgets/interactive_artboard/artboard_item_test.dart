// test/widgets/interactive_artboard/artboard_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_item.dart';

void main() {
  group('ArtboardItem.copyWith', () {
    test('overrides only the specified fields', () {
      const original = ArtboardItem(
        id: 'item-1',
        imagePath: 'assets/mock/item1.png',
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        zIndex: 0,
      );

      final updated = original.copyWith(x: 0.7, scale: 1.5);

      expect(updated.id, 'item-1');
      expect(updated.imagePath, 'assets/mock/item1.png');
      expect(updated.x, 0.7);
      expect(updated.y, 0.5);
      expect(updated.scale, 1.5);
      expect(updated.rotation, 0.0);
      expect(updated.zIndex, 0);
    });

    test('keeps all fields unchanged when called with no arguments', () {
      const original = ArtboardItem(
        id: 'item-2',
        imagePath: 'assets/mock/item2.png',
        x: 0.2,
        y: 0.3,
        scale: 0.8,
        rotation: 1.2,
        zIndex: 3,
      );

      final updated = original.copyWith();

      expect(updated.x, original.x);
      expect(updated.y, original.y);
      expect(updated.scale, original.scale);
      expect(updated.rotation, original.rotation);
      expect(updated.zIndex, original.zIndex);
    });
  });
}
