import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('coverImagePath가 있으면 그 값을 그대로 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart에는 coverImagePath가 설정된 코디가 없으므로, 우선순위 분기(명시값이
    // 폴백보다 우선한다)를 검증하기 위해 CompositionsNotifier에 직접 add해서 만든다.
    // items를 비워두지 않고 c01을 포함시켜, 아이템이 있어도 폴백(첫 옷 이미지)이 아니라
    // coverImagePath가 그대로 반환되는지까지 함께 확인한다.
    const withCover = Composition(
      id: 'test-with-cover',
      name: '커버 이미지 지정 코디',
      items: [CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0)],
      coverImagePath: 'assets/mock/cover_test.png',
    );
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      withCover,
    ];

    final result = container.read(compositionCoverImageProvider('test-with-cover'));
    final firstItemFallback =
        container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').imagePath;

    expect(result, 'assets/mock/cover_test.png');
    expect(result, isNot(firstItemFallback));
  });

  test('coverImagePath가 null이면 코디에 포함된 첫 번째 옷의 이미지로 폴백한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: comp01.coverImagePath == null, items.first.clothingItemId == 'c01'.
    final result = container.read(compositionCoverImageProvider('comp01'));
    final expectedFallback =
        container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').imagePath;

    expect(result, expectedFallback);
  });

  test('아이템이 하나도 없고 coverImagePath도 null이면 null을 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart에 아이템 0개짜리 코디가 없으므로, 이 케이스는 CompositionsNotifier에
    // 직접 add해서 만든다.
    const empty = Composition(id: 'test-empty', name: '빈 코디', items: []);
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      empty,
    ];

    final result = container.read(compositionCoverImageProvider('test-empty'));
    expect(result, isNull);
  });
}
