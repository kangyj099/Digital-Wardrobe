import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/composition_draft.dart';
import 'package:digittal_wardrobe/providers/composition_editor_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_background_color.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_item.dart';

void main() {
  final closetItems = [
    ClothingItem(
      id: 'c01',
      name: '테스트 옷',
      imagePath: 'assets/images/mock/test.png',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  group('compositionPlacementToArtboardItem', () {
    test('매칭되는 ClothingItem이 있으면 ArtboardItem으로 변환한다', () {
      const placement = CompositionItemPlacement(
        clothingItemId: 'c01',
        x: 0.3,
        y: 0.4,
        scale: 1.2,
        rotation: 0.5,
        zIndex: 2,
      );

      final item = compositionPlacementToArtboardItem(placement, closetItems);

      expect(item, isNotNull);
      expect(item!.id, 'c01');
      expect(item.imagePath, 'assets/images/mock/test.png');
      expect(item.x, 0.3);
      expect(item.y, 0.4);
      expect(item.scale, 1.2);
      expect(item.rotation, 0.5);
      expect(item.zIndex, 2);
    });

    test('매칭되는 ClothingItem이 없으면 null을 반환한다', () {
      const placement = CompositionItemPlacement(clothingItemId: 'nonexistent', x: 0.1, y: 0.1);

      final item = compositionPlacementToArtboardItem(placement, closetItems);

      expect(item, isNull);
    });
  });

  test('artboardItemToCompositionPlacement은 ArtboardItem을 CompositionItemPlacement으로 역변환한다', () {
    const item = ArtboardItem(
      id: 'c01',
      imagePath: 'assets/images/mock/test.png',
      x: 0.6,
      y: 0.7,
      scale: 0.9,
      rotation: 1.1,
      zIndex: 4,
    );

    final placement = artboardItemToCompositionPlacement(item);

    expect(placement.clothingItemId, 'c01');
    expect(placement.x, 0.6);
    expect(placement.y, 0.7);
    expect(placement.scale, 0.9);
    expect(placement.rotation, 1.1);
    expect(placement.zIndex, 4);
  });

  group('compositionDraftProvider', () {
    test('compositionId가 있으면 compositionsProvider의 해당 Record items로 초기화된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final draft = container.read(compositionDraftProvider('comp01'));

      expect(draft.compositionId, 'comp01');
      final expectedItems =
          container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').items;
      expect(draft.items, expectedItems);
      expect(draft.backgroundColor, ArtboardBackgroundColor.white);
    });

    test('Record에 backgroundColor가 저장돼 있으면 그 값으로 Draft가 초기화된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(compositionsProvider.notifier).updateItems(
            'comp01',
            container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').items,
            backgroundColor: ArtboardBackgroundColor.black,
          );

      final draft = container.read(compositionDraftProvider('comp01'));

      expect(draft.backgroundColor, ArtboardBackgroundColor.black);
    });

    test('compositionId가 null이면 빈 Draft로 초기화된다(신규 생성)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final draft = container.read(compositionDraftProvider(null));

      expect(draft.compositionId, isNull);
      expect(draft.items, isEmpty);
      expect(draft.backgroundColor, ArtboardBackgroundColor.white);
    });

    test('Draft 초기화 이후 Record가 다른 경로로 바뀌어도 Draft는 자동 재동기화되지 않는다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final draftBefore = container.read(compositionDraftProvider('comp01'));
      container.read(compositionsProvider.notifier).updateItems('comp01', const [
        CompositionItemPlacement(clothingItemId: 'c99', x: 0.9, y: 0.9),
      ]);
      final draftAfter = container.read(compositionDraftProvider('comp01'));

      expect(draftAfter.items, draftBefore.items, reason: 'Draft는 독립 편집 버퍼라 Record 변경에 반응하면 안 됨');
    });

    test('CompositionDraftNotifier.updateItems/deleteItem/updateBackgroundColor가 Draft 상태를 갱신한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(compositionDraftProvider(null).notifier);

      const newItems = [
        CompositionItemPlacement(clothingItemId: 'c01', x: 0.2, y: 0.2),
        CompositionItemPlacement(clothingItemId: 'c02', x: 0.5, y: 0.5),
      ];
      notifier.updateItems(newItems);
      expect(container.read(compositionDraftProvider(null)).items, newItems);

      notifier.deleteItem('c01');
      final afterDelete = container.read(compositionDraftProvider(null)).items;
      expect(afterDelete.length, 1);
      expect(afterDelete.first.clothingItemId, 'c02');

      notifier.updateBackgroundColor(ArtboardBackgroundColor.darkGray);
      expect(container.read(compositionDraftProvider(null)).backgroundColor, ArtboardBackgroundColor.darkGray);
    });

    test('ref.invalidate 후 다시 읽으면 compositionsProvider 최신 상태로 새로 초기화된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(compositionDraftProvider('comp01').notifier);

      notifier.updateItems(const [CompositionItemPlacement(clothingItemId: 'c99', x: 0.1, y: 0.1)]);
      container.invalidate(compositionDraftProvider('comp01'));

      final freshDraft = container.read(compositionDraftProvider('comp01'));
      final recordItems =
          container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').items;
      expect(freshDraft.items, recordItems, reason: '폐기 후 재읽기는 Record 최신 상태를 반영해야 함');
    });
  });

  test('CompositionDraft.copyWith가 지정한 필드만 교체한다', () {
    const original = CompositionDraft(
      compositionId: 'comp01',
      items: [],
      backgroundColor: ArtboardBackgroundColor.white,
    );

    final updated = original.copyWith(backgroundColor: ArtboardBackgroundColor.black);

    expect(updated.compositionId, 'comp01');
    expect(updated.items, isEmpty);
    expect(updated.backgroundColor, ArtboardBackgroundColor.black);
  });
}
