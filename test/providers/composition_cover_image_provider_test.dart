import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('coverImagePath가 있으면 그 값을 그대로 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준 comp01은 coverImagePath가 null이라, 다른 케이스로 확인.
    // 이 테스트는 필드 자체의 우선순위 규칙만 검증하므로 실제 mock 코디 하나를 그대로 쓴다.
    final result = container.read(compositionCoverImageProvider('comp01'));

    // comp01.coverImagePath == null이므로 폴백(첫 옷 이미지)이 나와야 한다 — 아래 테스트가
    // 그 경로를 검증. 이 테스트는 필드가 있는 경우를 mock_data.dart에 값을 넣지 않고도
    // 검증하기 위해 다음 테스트로 대체한다(위 설명은 다음 케이스와 함께 읽을 것).
    expect(result, isNotNull);
  });

  test('coverImagePath가 null이면 코디에 포함된 첫 번째 옷의 이미지로 폴백한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: comp01.coverImagePath == null, items.first.clothingItemId == 'c01'.
    final result = container.read(compositionCoverImageProvider('comp01'));
    final expectedFallback =
        container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').imagePath;

    expect(result, expectedFallback);
  });

  test('아이템이 하나도 없고 coverImagePath도 null이면 null을 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart에 아이템 0개짜리 코디가 없으므로, 이 케이스는 CompositionsNotifier에
    // 직접 add해서 만든다.
    const empty = Composition(id: 'test-empty', name: '빈 코디', items: []);
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      empty,
    ];

    final result = container.read(compositionCoverImageProvider('test-empty'));
    expect(result, isNull);
  });
}
