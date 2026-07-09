import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../mock/mock_data.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>(
        (ref) => CompositionsNotifier());

final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  return ref.watch(compositionsProvider).where((c) => !c.isDeleted).toList();
});
