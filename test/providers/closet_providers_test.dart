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

  test('softDeleteMany는 대상 id들만 isDeleted:true, deletedAt 세팅한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(closetItemsProvider.notifier);
    notifier.softDeleteMany({'c01', 'c02'});
    final items = container.read(closetItemsProvider);
    final c01 = items.firstWhere((i) => i.id == 'c01');
    final c03 = items.firstWhere((i) => i.id == 'c03');
    expect(c01.isDeleted, isTrue);
    expect(c01.deletedAt, isNotNull);
    expect(c03.isDeleted, isFalse);
  });

  test('restoreMany는 isDeleted를 false로, deletedAt을 null로 되돌린다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(closetItemsProvider.notifier);
    notifier.softDeleteMany({'c01'});
    notifier.restoreMany({'c01'});
    final c01 = container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01');
    expect(c01.isDeleted, isFalse);
    expect(c01.deletedAt, isNull);
  });

  test('purgeMany는 리스트에서 완전히 제거한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(closetItemsProvider.notifier);
    final before = container.read(closetItemsProvider).length;
    notifier.purgeMany({'c01'});
    final items = container.read(closetItemsProvider);
    expect(items.length, before - 1);
    expect(items.any((i) => i.id == 'c01'), isFalse);
  });
}
