import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('전체보기는 항상 flat, 나머지 3개 기준은 소분류를 갖는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.all;
    expect(container.read(compositionGridDisplayStateProvider), CompositionGridDisplayState.flat);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    expect(container.read(compositionGridDisplayStateProvider), CompositionGridDisplayState.groupOverview);
  });

  test('계절 미분류로 드릴인하면 season이 null인 코디만 남는다(mock comp02)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.season;
    container.read(compositionDrilledSeasonProvider.notifier).state = const DrilledValue.unclassified();

    final result = container.read(filteredCompositionsProvider);
    expect(result, isNotEmpty);
    expect(result.every((c) => c.season == null), isTrue);
  });

  test('날씨 기준으로 드릴인하면 해당 Weather 값만 남는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    container.read(compositionDrilledWeatherProvider.notifier).state =
        const DrilledValue.value(Weather.rain);

    final result = container.read(filteredCompositionsProvider);
    expect(result, isNotEmpty);
    expect(result.every((c) => c.weather == Weather.rain), isTrue);
  });

  test('그룹 카드는 빈 그룹을 만들지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    final summaries = container.read(compositionGroupSummariesProvider);

    expect(summaries.every((s) => s.count > 0), isTrue);
    expect(summaries.any((s) => s.label == '눈'), isFalse); // mock 데이터에 snow 없음
  });
}
