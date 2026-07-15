import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import 'closet_providers.dart';

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

/// [itemId]를 포함하는(삭제되지 않은) Composition 목록 — 옷 상세 화면의
/// "연결된 코디" 크로스 레퍼런스 근거.
final compositionsContainingItemProvider =
    Provider.family<List<Composition>, String>((ref, itemId) {
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
  if (composition.items.isEmpty) return null;
  final closetItems = ref.watch(closetItemsProvider);
  final firstItemId = composition.items.first.clothingItemId;
  return closetItems.firstWhere((item) => item.id == firstItemId).imagePath;
});
