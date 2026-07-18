import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('selectedCompositionSeasonFilterProvider를 설정하면 filteredCompositionsProvider가 걸러진다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredCompositionsProvider).length;
    container.read(selectedCompositionSeasonFilterProvider.notifier).state = Season.springFall;
    final after = container.read(filteredCompositionsProvider);

    expect(after.length, lessThanOrEqualTo(before));
    expect(after.every((c) => c.season == Season.springFall), isTrue);
  });
}
