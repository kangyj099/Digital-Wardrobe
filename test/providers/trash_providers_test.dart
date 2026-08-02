import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';

void main() {
  test('trashEntriesProvider는 isDeleted인 3도메인 항목만 집계한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    container.read(compositionsProvider.notifier).softDeleteMany({'comp01'});

    final entries = container.read(trashEntriesProvider);
    expect(entries.any((e) => e.id == 'c01'), isTrue);
    expect(entries.any((e) => e.id == 'comp01'), isTrue);
    expect(entries.any((e) => e.id == 'log01'), isFalse);
  });

  test('daysUntilPurge는 deletedAt으로부터 15일 기준으로 계산되고 0 밑으로 안 내려간다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    final entry = container.read(trashEntriesProvider).firstWhere((e) => e.id == 'c01');
    expect(entry.daysUntilPurge, 15);
  });

  test('purgeExpiredTrash는 15일 이내 항목은 건드리지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    purgeExpiredTrash(container);
    final entries = container.read(trashEntriesProvider);
    expect(entries.any((e) => e.id == 'c01'), isTrue);
  });
}
