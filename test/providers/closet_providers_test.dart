import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('softDelete한 아이템은 filteredClosetItemsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final beforeCount = container.read(filteredClosetItemsProvider).length;
    container.read(closetItemsProvider.notifier).softDelete('c01');
    final afterCount = container.read(filteredClosetItemsProvider).length;

    expect(afterCount, beforeCount - 1);
  });
}
