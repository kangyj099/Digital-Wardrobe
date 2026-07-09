import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/mock/mock_data.dart';

void main() {
  test('mock 데이터는 최소 1개 이상의 미완성 아이템을 포함한다', () {
    expect(mockClothingItems.any((item) => item.isIncomplete), isTrue);
  });

  test('모든 Composition의 items는 실제 존재하는 ClothingItem id를 참조한다', () {
    final validIds = mockClothingItems.map((e) => e.id).toSet();
    for (final composition in mockCompositions) {
      for (final placement in composition.items) {
        expect(validIds.contains(placement.clothingItemId), isTrue,
            reason: '${placement.clothingItemId} not found in mockClothingItems');
      }
    }
  });

  test('모든 StyleLog의 linkedCompositionId는 실제 존재하는 Composition id를 참조한다', () {
    final validIds = mockCompositions.map((e) => e.id).toSet();
    for (final log in mockStyleLogs) {
      if (log.linkedCompositionId != null) {
        expect(validIds.contains(log.linkedCompositionId), isTrue);
      }
    }
  });
}
