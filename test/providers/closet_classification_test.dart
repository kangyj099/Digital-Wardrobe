import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('중분류가 옷종류면 미선택 상태에서 groupOverview, 카테고리 드릴인 시 drilledIn', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.groupOverview);

    container.read(closetDrilledCategoryProvider.notifier).state =
        const DrilledValue.value(ClothingCategory.top);
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.drilledIn);
    expect(
      container.read(filteredClosetItemsProvider).every((item) => item.category == ClothingCategory.top),
      isTrue,
    );
  });

  test('전체보기/착용빈도는 소분류 없이 항상 flat', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.all;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.flat);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.wearFrequency;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.flat);
  });

  test('옷종류 미분류로 드릴인하면 category가 null인 아이템만 남는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    container.read(closetDrilledCategoryProvider.notifier).state = const DrilledValue.unclassified();

    final result = container.read(filteredClosetItemsProvider);
    expect(result, isNotEmpty);
    expect(result.every((item) => item.category == null), isTrue);
  });

  test('그룹 개요 카드는 빈 그룹을 만들지 않고, 미분류 카드는 값이 있는 아이템이 있을 때만 나타난다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    final summaries = container.read(closetGroupSummariesProvider);

    expect(summaries.every((s) => s.count > 0), isTrue);
    expect(summaries.any((s) => s.label == '미분류'), isTrue); // mock c12가 category null
  });

  test('옷종류 그룹 카드는 기본(ascending=false)일 때 머리→발 순서(ClothingCategory index 오름차순)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    final summaries = container.read(closetGroupSummariesProvider);
    final classified = summaries.where((s) => s.value != null).toList();

    for (var i = 1; i < classified.length; i++) {
      final prevIndex = (classified[i - 1].value as ClothingCategory).index;
      final currIndex = (classified[i].value as ClothingCategory).index;
      expect(prevIndex, lessThan(currIndex));
    }
  });

  test('날짜 기준 기본 정렬은 최신순(내림차순)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.dateTime;
    final result = container.read(filteredClosetItemsProvider);

    for (var i = 1; i < result.length; i++) {
      expect(
        result[i - 1].createdAt.isAfter(result[i].createdAt) ||
            result[i - 1].createdAt.isAtSameMomentAs(result[i].createdAt),
        isTrue,
      );
    }
  });
}
