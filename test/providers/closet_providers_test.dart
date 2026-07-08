import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('selectedSeasonFilterProvider를 설정하면 filteredClosetItemsProvider가 걸러진다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredClosetItemsProvider).length;
    container.read(selectedSeasonFilterProvider.notifier).state = '사계절';
    final after = container.read(filteredClosetItemsProvider);

    expect(after.length, lessThan(before));
    expect(after.every((item) => item.season == '사계절'), isTrue);
  });

  test('softDelete한 아이템은 filteredClosetItemsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final beforeCount = container.read(filteredClosetItemsProvider).length;
    container.read(closetItemsProvider.notifier).softDelete('c01');
    final afterCount = container.read(filteredClosetItemsProvider).length;

    expect(afterCount, beforeCount - 1);
  });
}
