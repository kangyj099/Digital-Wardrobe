import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('삭제된 코디는 filteredCompositionsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredCompositionsProvider).length;
    expect(before, container.read(compositionsProvider).length);
  });
}
