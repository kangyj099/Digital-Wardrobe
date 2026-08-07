import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_background_color.dart';

void main() {
  test('삭제된 코디는 filteredCompositionsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);
    final targetId = container.read(compositionsProvider).firstWhere((c) => !c.isDeleted).id;
    notifier.softDeleteMany({targetId});
    final filtered = container.read(filteredCompositionsProvider);
    expect(filtered.any((c) => c.id == targetId), isFalse);
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

  test('CompositionsNotifier.updateItems가 해당 코디의 items만 교체한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);
    const newItems = [CompositionItemPlacement(clothingItemId: 'c99', x: 0.1, y: 0.1)];

    notifier.updateItems('comp01', newItems);

    final compositions = container.read(compositionsProvider);
    final comp01 = compositions.firstWhere((c) => c.id == 'comp01');
    expect(comp01.items, newItems);
    // 다른 레코드는 영향 없음.
    final comp03 = compositions.firstWhere((c) => c.id == 'comp03');
    expect(comp03.items, isNot(newItems));
  });

  test('CompositionsNotifier.updateItems가 backgroundColor를 넘기면 함께 반영하고, 안 넘기면 기존 값을 유지한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);
    const someItems = [CompositionItemPlacement(clothingItemId: 'c99', x: 0.1, y: 0.1)];

    notifier.updateItems('comp01', someItems, backgroundColor: ArtboardBackgroundColor.darkGray);
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').backgroundColor,
      ArtboardBackgroundColor.darkGray,
    );

    notifier.updateItems('comp01', someItems);
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').backgroundColor,
      ArtboardBackgroundColor.darkGray,
      reason: 'backgroundColor를 안 넘기면 기존 값이 유지돼야 함',
    );
  });

  test('CompositionsNotifier.add가 새 코디 레코드를 추가한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);
    final before = container.read(compositionsProvider).length;

    notifier.add(Composition(id: 'comp_new', name: '새 코디', items: const [], createdAt: DateTime(2026, 1, 1)));

    final after = container.read(compositionsProvider);
    expect(after.length, before + 1);
    expect(after.any((c) => c.id == 'comp_new'), isTrue);
  });
}
