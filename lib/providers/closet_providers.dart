import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';

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
    StateNotifierProvider<ClosetItemsNotifier, List<ClothingItem>>(
        (ref) => ClosetItemsNotifier());

/// null = 전체 시즌.
final selectedSeasonFilterProvider = StateProvider<Season?>((ref) => null);

/// 삭제되지 않았고, 선택된 시즌 필터에 맞는 아이템만.
final filteredClosetItemsProvider = Provider<List<ClothingItem>>((ref) {
  final items = ref.watch(closetItemsProvider);
  final season = ref.watch(selectedSeasonFilterProvider);
  return items
      .where((item) => !item.isDeleted)
      .where((item) => season == null || item.season == season)
      .toList();
});

/// 옷장 메인 그리드 밀도 — AppDensity.min/mid/max 중 하나.
final closetDensityProvider = StateProvider<int>((ref) => AppDensity.mid);
