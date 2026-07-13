import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>(
        (ref) => CompositionsNotifier());

/// null = 전체 시즌.
final selectedCompositionSeasonFilterProvider = StateProvider<Season?>((ref) => null);

/// 삭제되지 않았고, 선택된 시즌 필터에 맞는 코디만.
final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  final compositions = ref.watch(compositionsProvider);
  final season = ref.watch(selectedCompositionSeasonFilterProvider);
  return compositions
      .where((c) => !c.isDeleted)
      .where((c) => season == null || c.season == season)
      .toList();
});

/// 코디 메인 그리드 밀도 — AppDensity.min/mid/max 중 하나.
final compositionDensityProvider = StateProvider<int>((ref) => AppDensity.mid);
