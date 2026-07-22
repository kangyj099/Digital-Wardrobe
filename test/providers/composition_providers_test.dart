import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('삭제된 코디는 filteredCompositionsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredCompositionsProvider).length;
    expect(before, container.read(compositionsProvider).length);
  });

  test('CompositionsNotifier.softDeleteMany/restoreMany/purgeMany가 동작한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);

    notifier.softDeleteMany({'comp01'});
    var comp01 = container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
    expect(comp01.isDeleted, isTrue);
    expect(comp01.deletedAt, isNotNull);

    notifier.restoreMany({'comp01'});
    comp01 = container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
    expect(comp01.isDeleted, isFalse);
    expect(comp01.deletedAt, isNull);

    final before = container.read(compositionsProvider).length;
    notifier.purgeMany({'comp01'});
    final after = container.read(compositionsProvider);
    expect(after.length, before - 1);
    expect(after.any((c) => c.id == 'comp01'), isFalse);
  });
}
