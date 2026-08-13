import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_background_color.dart';

class _FixedCompositionsNotifier extends CompositionsNotifier {
  _FixedCompositionsNotifier(List<Composition> initial) {
    state = initial;
  }
}

class _FixedClosetItemsNotifier extends ClosetItemsNotifier {
  _FixedClosetItemsNotifier(List<ClothingItem> initial) {
    state = initial;
  }
}

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

  test('CompositionsNotifier.updateItems가 coverImagePath를 넘기면 반영하고, 안 넘기면 기존 값을 유지한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);
    const someItems = [CompositionItemPlacement(clothingItemId: 'c99', x: 0.1, y: 0.1)];

    notifier.updateItems('comp01', someItems, coverImagePath: '/tmp/new_snapshot.png');
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').coverImagePath,
      '/tmp/new_snapshot.png',
    );

    // §13.3 실패 처리 — coverImagePath를 안 넘기면(캡처/저장 실패 등) 기존 값을 유지해야 함.
    notifier.updateItems('comp01', someItems);
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').coverImagePath,
      '/tmp/new_snapshot.png',
      reason: 'coverImagePath를 안 넘기면 기존 값이 유지돼야 함',
    );
  });

  test('CompositionsNotifier.updateItems는 §13.5에 따라 매 호출마다 isIncomplete를 items.isEmpty로 재계산한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(compositionsProvider.notifier);

    notifier.updateItems('comp01', const []);
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isIncomplete,
      isTrue,
      reason: '정리 후 0개 남으면 기존 미완성 처리를 재사용해야 함',
    );

    notifier.updateItems(
      'comp01',
      const [CompositionItemPlacement(clothingItemId: 'c99', x: 0.1, y: 0.1)],
    );
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isIncomplete,
      isFalse,
      reason: '항목이 다시 채워져 재커밋되면 isIncomplete가 원복돼야 함',
    );
  });

  group('compositionDeletedItemPlacementsProvider / compositionHasDeletedItemsProvider', () {
    ProviderContainer buildContainer({
      required List<Composition> compositions,
      required List<ClothingItem> closetItems,
    }) {
      final container = ProviderContainer(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier(compositions)),
          closetItemsProvider.overrideWith((ref) => _FixedClosetItemsNotifier(closetItems)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    final activeItem = ClothingItem(
      id: 'active',
      name: '정상 옷',
      imagePath: 'assets/images/mock/active.png',
      createdAt: DateTime(2025, 1, 1),
    );
    final softDeletedItem = ClothingItem(
      id: 'soft-deleted',
      name: '휴지통 옷',
      imagePath: 'assets/images/mock/soft.png',
      createdAt: DateTime(2025, 1, 1),
      isDeleted: true,
    );

    test('§13.4(a) 완전 삭제(purge)된 옷(closetItems에 아예 없음)도 정리 대상으로 판정한다', () {
      final composition = Composition(
        id: 'comp-purged',
        name: '테스트',
        createdAt: DateTime(2025, 1, 1),
        items: const [
          CompositionItemPlacement(clothingItemId: 'active', x: 0.1, y: 0.1),
          CompositionItemPlacement(clothingItemId: 'purged', x: 0.2, y: 0.2),
        ],
      );
      final container =
          buildContainer(compositions: [composition], closetItems: [activeItem]);

      final placements =
          container.read(compositionDeletedItemPlacementsProvider('comp-purged'));
      expect(placements.map((p) => p.clothingItemId), ['purged']);
      expect(container.read(compositionHasDeletedItemsProvider('comp-purged')), isTrue);
    });

    test('§13.4(b) 휴지통(소프트 삭제) 상태인 옷도 정리 대상으로 판정한다', () {
      final composition = Composition(
        id: 'comp-soft',
        name: '테스트',
        createdAt: DateTime(2025, 1, 1),
        items: const [
          CompositionItemPlacement(clothingItemId: 'active', x: 0.1, y: 0.1),
          CompositionItemPlacement(clothingItemId: 'soft-deleted', x: 0.2, y: 0.2),
        ],
      );
      final container = buildContainer(
        compositions: [composition],
        closetItems: [activeItem, softDeletedItem],
      );

      final placements = container.read(compositionDeletedItemPlacementsProvider('comp-soft'));
      expect(placements.map((p) => p.clothingItemId), ['soft-deleted']);
      expect(container.read(compositionHasDeletedItemsProvider('comp-soft')), isTrue);
    });

    test('정리 대상이 없으면 빈 리스트/false를 반환한다', () {
      final composition = Composition(
        id: 'comp-clean',
        name: '테스트',
        createdAt: DateTime(2025, 1, 1),
        items: const [CompositionItemPlacement(clothingItemId: 'active', x: 0.1, y: 0.1)],
      );
      final container =
          buildContainer(compositions: [composition], closetItems: [activeItem]);

      expect(container.read(compositionDeletedItemPlacementsProvider('comp-clean')), isEmpty);
      expect(container.read(compositionHasDeletedItemsProvider('comp-clean')), isFalse);
    });
  });
}
