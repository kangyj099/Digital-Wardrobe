import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import 'classification_models.dart';

class ClosetItemsNotifier extends StateNotifier<List<ClothingItem>> {
  ClosetItemsNotifier() : super(mockClothingItems);

  void softDelete(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isDeleted: true) else item,
    ];
  }
}

final closetItemsProvider =
    StateNotifierProvider<ClosetItemsNotifier, List<ClothingItem>>((ref) => ClosetItemsNotifier());

/// 옷장 메인 헤더 캡슐의 중분류 값. 순서가 곧 캡슐 드롭다운 항목 순서(스펙 §3.2).
enum ClosetSortCriterion { all, dateTime, clothingType, season, wearFrequency }

extension ClosetSortCriterionX on ClosetSortCriterion {
  /// 캡슐 중분류 드롭다운에 표시할 라벨 — 다른 폐쇄 어휘 enum(`ClothingCategory` 등)과
  /// 동일하게 `.label` getter 패턴을 따른다(화면이 인덱스로 하드코딩된 라벨 리스트를 따로 들면
  /// enum과 동기화가 깨질 수 있음).
  String get label => switch (this) {
        ClosetSortCriterion.all => '전체보기',
        ClosetSortCriterion.dateTime => '날짜·시간',
        ClosetSortCriterion.clothingType => '옷 종류',
        ClosetSortCriterion.season => '계절',
        ClosetSortCriterion.wearFrequency => '착용빈도',
      };

  /// 소분류 세그먼트가 붙는 기준인지 — false면 캡슐이 첫 세그먼트 크기로 줄어든다(스펙 §3.3).
  bool get hasSubClassification => switch (this) {
        ClosetSortCriterion.all => false,
        ClosetSortCriterion.wearFrequency => false,
        _ => true,
      };

  /// 소분류 미선택(그룹 개요) 상태에서 캡슐에 보여줄 플레이스홀더(스펙 §3.1 표).
  /// [hasSubClassification]이 false인 기준은 호출되지 않는다.
  String get subClassificationHint => switch (this) {
        ClosetSortCriterion.dateTime => '연도',
        ClosetSortCriterion.clothingType => '종류',
        ClosetSortCriterion.season => '계절',
        _ => throw StateError('소분류 없는 기준: $this'),
      };
}

final closetSortCriterionProvider = StateProvider<ClosetSortCriterion>((ref) => ClosetSortCriterion.all);

/// 전역 단순 규칙(사용자 확정, 2026-07-19): true=모든 기준에서 항상 index/날짜/착용빈도
/// 오름차순, false=내림차순 — 기준마다 의미를 다르게 해석하지 않는다. 기본값 false이므로
/// 옷종류/계절/날씨의 기본 표시는 스펙 §3.2 표(머리→발 등)와 **반대** 방향(발→머리 등)이다
/// — 이 tradeoff는 `docs/work/TO_사용자결정.md`에서 사용자가 "전역 단순 규칙"을 명시적으로
/// 선택해 확정됨(§3.2 표와 항상 일치시키는 대안은 폐기).
final closetSortAscendingProvider = StateProvider<bool>((ref) => false);

/// `createdAt`이 non-nullable이라 [DrilledValue] wrapper가 필요 없다 — null=미선택뿐.
final closetDrilledYearProvider = StateProvider<int?>((ref) => null);

final closetDrilledCategoryProvider = StateProvider<DrilledValue<ClothingCategory>?>((ref) => null);
final closetDrilledSeasonProvider = StateProvider<DrilledValue<Season>?>((ref) => null);

/// 3가지 그리드 상태(스펙 §3.1) — 별도 상태 저장 없이 위 provider들의 조합에서 파생된다.
enum ClosetGridDisplayState { flat, groupOverview, drilledIn }

final closetGridDisplayStateProvider = Provider<ClosetGridDisplayState>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  if (!criterion.hasSubClassification) return ClosetGridDisplayState.flat;
  final isDrilledIn = switch (criterion) {
    ClosetSortCriterion.clothingType => ref.watch(closetDrilledCategoryProvider) != null,
    ClosetSortCriterion.season => ref.watch(closetDrilledSeasonProvider) != null,
    ClosetSortCriterion.dateTime => ref.watch(closetDrilledYearProvider) != null,
    ClosetSortCriterion.all || ClosetSortCriterion.wearFrequency => false,
  };
  return isDrilledIn ? ClosetGridDisplayState.drilledIn : ClosetGridDisplayState.groupOverview;
});

/// 삭제되지 않고, 현재 중분류의 소분류 필터에 맞는 아이템을 현재 정렬 기준+방향으로 정렬.
final filteredClosetItemsProvider = Provider<List<ClothingItem>>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  final ascending = ref.watch(closetSortAscendingProvider);

  Iterable<ClothingItem> items = ref.watch(closetItemsProvider).where((item) => !item.isDeleted);

  switch (criterion) {
    case ClosetSortCriterion.clothingType:
      final drilled = ref.watch(closetDrilledCategoryProvider);
      if (drilled != null) {
        items = items.where((item) => item.category == drilled.value);
      }
    case ClosetSortCriterion.season:
      final drilled = ref.watch(closetDrilledSeasonProvider);
      if (drilled != null) {
        items = items.where((item) => item.season == drilled.value);
      }
    case ClosetSortCriterion.dateTime:
      final year = ref.watch(closetDrilledYearProvider);
      if (year != null) {
        items = items.where((item) => item.createdAt.year == year);
      }
    case ClosetSortCriterion.all:
    case ClosetSortCriterion.wearFrequency:
      break;
  }

  final result = items.toList();
  if (criterion == ClosetSortCriterion.all) return result; // 정렬 없음(기존 동작 유지)

  result.sort((a, b) => switch (criterion) {
        ClosetSortCriterion.dateTime =>
          ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt),
        ClosetSortCriterion.clothingType =>
          compareNullableIndexLast(a.category?.index, b.category?.index, ascending: ascending),
        ClosetSortCriterion.season =>
          compareNullableIndexLast(a.season?.index, b.season?.index, ascending: ascending),
        ClosetSortCriterion.wearFrequency =>
          ascending ? a.wearCount.compareTo(b.wearCount) : b.wearCount.compareTo(a.wearCount),
        ClosetSortCriterion.all => 0, // 위에서 이미 return, 도달하지 않음(exhaustive switch용)
      });
  return result;
});

/// 그룹 개요 상태에서 그릴 카드 목록 — 소분류 필터 적용 **전** 단계 값을 기준으로 묶는다
/// (그룹 개요는 항상 전체 그룹을 보여줘야 하므로, 스펙 §3.7).
final closetGroupSummariesProvider = Provider<List<ClassificationGroupSummary>>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  final ascending = ref.watch(closetSortAscendingProvider);
  final items = ref.watch(closetItemsProvider).where((item) => !item.isDeleted).toList();

  switch (criterion) {
    case ClosetSortCriterion.clothingType:
      return _summarize<ClothingCategory>(
        items,
        keyOf: (item) => item.category,
        labelOf: (category) => category.label,
        indexOf: (category) => category.index,
        ascending: ascending,
      );
    case ClosetSortCriterion.season:
      return _summarize<Season>(
        items,
        keyOf: (item) => item.season,
        labelOf: (season) => season.label,
        indexOf: (season) => season.index,
        ascending: ascending,
      );
    case ClosetSortCriterion.dateTime:
      return _summarizeByYear(items, ascending: ascending);
    case ClosetSortCriterion.all:
    case ClosetSortCriterion.wearFrequency:
      return const [];
  }
});

/// 옷장/코디가 공유하는 "값별로 묶어 카드 목록 만들기" 로직 — [K]는 분류 기준의 소분류
/// 타입(`ClothingCategory`/`Season`/`Weather`), null 키는 미분류 카드가 된다.
List<ClassificationGroupSummary> _summarize<K>(
  List<ClothingItem> items, {
  required K? Function(ClothingItem) keyOf,
  required String Function(K) labelOf,
  required int Function(K) indexOf,
  required bool ascending,
}) {
  final groups = <K?, List<ClothingItem>>{};
  for (final item in items) {
    groups.putIfAbsent(keyOf(item), () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      if (entry.value.isNotEmpty)
        ClassificationGroupSummary(
          label: entry.key == null ? '미분류' : labelOf(entry.key as K),
          thumbnailPaths: entry.value.take(4).map((item) => item.imagePath).toList(),
          count: entry.value.length,
          value: entry.key,
        ),
  ];
  summaries.sort((a, b) => compareNullableIndexLast(
        a.value == null ? null : indexOf(a.value as K),
        b.value == null ? null : indexOf(b.value as K),
        ascending: ascending,
      ));
  return summaries;
}

List<ClassificationGroupSummary> _summarizeByYear(List<ClothingItem> items, {required bool ascending}) {
  final groups = <int, List<ClothingItem>>{};
  for (final item in items) {
    groups.putIfAbsent(item.createdAt.year, () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      ClassificationGroupSummary(
        label: '${entry.key}년',
        thumbnailPaths: entry.value.take(4).map((item) => item.imagePath).toList(),
        count: entry.value.length,
        value: entry.key,
      ),
  ];
  summaries.sort((a, b) {
    final ay = a.value as int;
    final by = b.value as int;
    return ascending ? ay.compareTo(by) : by.compareTo(ay);
  });
  return summaries;
}

/// 옷장 메인 그리드 밀도 — `AppDensity.min/mid/max` 중 하나.
final closetDensityProvider = StateProvider<int>((ref) => AppDensity.mid);
