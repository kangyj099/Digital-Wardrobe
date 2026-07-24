import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import 'classification_models.dart';
import 'closet_providers.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);

  void softDeleteMany(Set<String> ids) {
    final now = DateTime.now();
    state = [
      for (final c in state)
        if (ids.contains(c.id)) c.copyWith(isDeleted: true, deletedAt: now) else c,
    ];
  }

  void restoreMany(Set<String> ids) {
    state = [
      for (final c in state)
        if (ids.contains(c.id)) c.copyWith(isDeleted: false, deletedAt: null) else c,
    ];
  }

  void purgeMany(Set<String> ids) {
    state = [for (final c in state) if (!ids.contains(c.id)) c];
  }
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>((ref) => CompositionsNotifier());

/// 코디 메인 헤더 캡슐의 중분류 값. 순서가 곧 캡슐 드롭다운 항목 순서(스펙 §3.2).
enum CompositionSortCriterion { all, dateTime, season, weather }

extension CompositionSortCriterionX on CompositionSortCriterion {
  /// 캡슐 중분류 드롭다운 라벨 — `ClosetSortCriterionX.label`과 동일 패턴(Review 지적 P1).
  String get label => switch (this) {
        CompositionSortCriterion.all => '전체보기',
        CompositionSortCriterion.dateTime => '날짜·시간',
        CompositionSortCriterion.season => '계절',
        CompositionSortCriterion.weather => '날씨',
      };

  /// 코디는 "전체보기"만 소분류가 없다(스펙 §3.3 — 옷장의 "착용빈도"에 대응하는 게 없음).
  bool get hasSubClassification => this != CompositionSortCriterion.all;

  String get subClassificationHint => switch (this) {
        CompositionSortCriterion.dateTime => '연도',
        CompositionSortCriterion.season => '계절',
        CompositionSortCriterion.weather => '날씨',
        CompositionSortCriterion.all => throw StateError('소분류 없는 기준: $this'),
      };
}

final compositionSortCriterionProvider =
    StateProvider<CompositionSortCriterion>((ref) => CompositionSortCriterion.all);

/// 전역 단순 규칙(사용자 확정, 2026-07-19) — `lib/providers/closet_providers.dart`의
/// `closetSortAscendingProvider` 주석과 동일: true=모든 기준 index/날짜 오름차순, false=
/// 내림차순. 계절/날씨 기본 표시는 스펙 §3.2 표와 반대 방향이 되는 tradeoff를 사용자가
/// 명시적으로 선택함(`docs/work/TO_사용자결정.md` 참고).
final compositionSortAscendingProvider = StateProvider<bool>((ref) => false);

final compositionDrilledYearProvider = StateProvider<int?>((ref) => null);
final compositionDrilledSeasonProvider = StateProvider<DrilledValue<Season>?>((ref) => null);
final compositionDrilledWeatherProvider = StateProvider<DrilledValue<Weather>?>((ref) => null);

enum CompositionGridDisplayState { flat, groupOverview, drilledIn }

final compositionGridDisplayStateProvider = Provider<CompositionGridDisplayState>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  if (!criterion.hasSubClassification) return CompositionGridDisplayState.flat;
  final isDrilledIn = switch (criterion) {
    CompositionSortCriterion.season => ref.watch(compositionDrilledSeasonProvider) != null,
    CompositionSortCriterion.weather => ref.watch(compositionDrilledWeatherProvider) != null,
    CompositionSortCriterion.dateTime => ref.watch(compositionDrilledYearProvider) != null,
    CompositionSortCriterion.all => false,
  };
  return isDrilledIn ? CompositionGridDisplayState.drilledIn : CompositionGridDisplayState.groupOverview;
});

/// 삭제되지 않고, 현재 중분류의 소분류 필터에 맞는 코디를 현재 정렬 기준+방향으로 정렬.
final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  final ascending = ref.watch(compositionSortAscendingProvider);

  Iterable<Composition> items = ref.watch(compositionsProvider).where((c) => !c.isDeleted);

  switch (criterion) {
    case CompositionSortCriterion.season:
      final drilled = ref.watch(compositionDrilledSeasonProvider);
      if (drilled != null) {
        items = items.where((c) => c.season == drilled.value);
      }
    case CompositionSortCriterion.weather:
      final drilled = ref.watch(compositionDrilledWeatherProvider);
      if (drilled != null) {
        items = items.where((c) => c.weather == drilled.value);
      }
    case CompositionSortCriterion.dateTime:
      final year = ref.watch(compositionDrilledYearProvider);
      if (year != null) {
        items = items.where((c) => c.createdAt.year == year);
      }
    case CompositionSortCriterion.all:
      break;
  }

  final result = items.toList();
  if (criterion == CompositionSortCriterion.all) return result;

  result.sort((a, b) => switch (criterion) {
        CompositionSortCriterion.dateTime =>
          ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt),
        CompositionSortCriterion.season =>
          compareNullableIndexLast(a.season?.index, b.season?.index, ascending: ascending),
        CompositionSortCriterion.weather =>
          compareNullableIndexLast(a.weather?.index, b.weather?.index, ascending: ascending),
        CompositionSortCriterion.all => 0, // 도달하지 않음
      });
  return result;
});

final compositionGroupSummariesProvider = Provider<List<ClassificationGroupSummary>>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  final ascending = ref.watch(compositionSortAscendingProvider);
  final items = ref.watch(compositionsProvider).where((c) => !c.isDeleted).toList();

  switch (criterion) {
    case CompositionSortCriterion.season:
      return _summarizeCompositions<Season>(
        items,
        keyOf: (c) => c.season,
        labelOf: (season) => season.label,
        indexOf: (season) => season.index,
        ascending: ascending,
      );
    case CompositionSortCriterion.weather:
      return _summarizeCompositions<Weather>(
        items,
        keyOf: (c) => c.weather,
        labelOf: (weather) => weather.label,
        indexOf: (weather) => weather.index,
        ascending: ascending,
      );
    case CompositionSortCriterion.dateTime:
      return _summarizeCompositionsByYear(items, ascending: ascending);
    case CompositionSortCriterion.all:
      return const [];
  }
});

/// 대표 이미지 — `coverImagePath`가 있으면 그대로, 없으면 첫 옷 이미지로 폴백
/// (`compositionCoverImageProvider`와 동일 폴백 규칙을 그룹 카드 썸네일에도 적용).
List<ClassificationGroupSummary> _summarizeCompositions<K>(
  List<Composition> items, {
  required K? Function(Composition) keyOf,
  required String Function(K) labelOf,
  required int Function(K) indexOf,
  required bool ascending,
}) {
  final groups = <K?, List<Composition>>{};
  for (final item in items) {
    groups.putIfAbsent(keyOf(item), () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      if (entry.value.isNotEmpty)
        ClassificationGroupSummary(
          label: entry.key == null ? '미분류' : labelOf(entry.key as K),
          thumbnailPaths: entry.value
              .take(4)
              .map((c) => c.coverImagePath ?? '')
              .where((path) => path.isNotEmpty)
              .toList(),
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

List<ClassificationGroupSummary> _summarizeCompositionsByYear(
  List<Composition> items, {
  required bool ascending,
}) {
  final groups = <int, List<Composition>>{};
  for (final item in items) {
    groups.putIfAbsent(item.createdAt.year, () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      ClassificationGroupSummary(
        label: '${entry.key}년',
        thumbnailPaths: entry.value
            .take(4)
            .map((c) => c.coverImagePath ?? '')
            .where((path) => path.isNotEmpty)
            .toList(),
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

/// 코디 메인 그리드 밀도 — `AppDensity.min/mid/max` 중 하나.
final compositionDensityProvider = StateProvider<int>((ref) => AppDensity.mid);

/// [itemId]를 포함하는(삭제되지 않은) Composition 목록 — 옷 상세 화면의
/// "연결된 코디" 크로스 레퍼런스 근거.
final compositionsContainingItemProvider = Provider.family<List<Composition>, String>((ref, itemId) {
  return ref
      .watch(compositionsProvider)
      .where((c) => !c.isDeleted && c.items.any((p) => p.clothingItemId == itemId))
      .toList();
});

/// [compositionId]의 표시용 커버 이미지 경로 — `Composition.coverImagePath`가 있으면 그대로,
/// 없으면 코디에 포함된 첫 번째 옷의 이미지로 폴백한다(둘 다 없으면 null).
final compositionCoverImageProvider = Provider.family<String?, String>((ref, compositionId) {
  final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
  if (composition.coverImagePath != null) return composition.coverImagePath;
  final closetItems = ref.watch(closetItemsProvider);
  for (final placement in composition.items) {
    final matches = closetItems.where((item) => item.id == placement.clothingItemId);
    if (matches.isNotEmpty) return matches.first.imagePath;
  }
  return null;
});
