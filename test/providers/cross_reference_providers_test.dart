import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';

void main() {
  test('compositionsContainingItemProvider는 해당 옷을 포함한 코디만 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: c01은 comp01에만 포함됨.
    final result = container.read(compositionsContainingItemProvider('c01'));

    expect(result.map((c) => c.id), contains('comp01'));
    expect(result.map((c) => c.id), isNot(contains('comp02')));
  });

  test('styleLogsLinkedToCompositionProvider는 해당 코디에 연결된 스타일일지만 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: log01.linkedCompositionId == 'comp01'.
    final result = container.read(styleLogsLinkedToCompositionProvider('comp01'));

    expect(result.map((l) => l.id), contains('log01'));
    expect(result.map((l) => l.id), isNot(contains('log02')));
  });

  test('styleLogsLinkedToItemProvider는 코디를 거쳐 간접 연결된 스타일일지를 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // c01 → comp01 → log01 경로.
    final result = container.read(styleLogsLinkedToItemProvider('c01'));

    expect(result.map((l) => l.id), contains('log01'));
  });

  test('linkToComposition은 대상 로그의 linkedCompositionId만 바꾸고 다른 로그는 그대로 둔다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(styleLogsProvider.notifier).linkToComposition('log02', 'comp01');
    final logs = container.read(styleLogsProvider);

    expect(logs.firstWhere((l) => l.id == 'log02').linkedCompositionId, 'comp01');
    expect(logs.firstWhere((l) => l.id == 'log01').linkedCompositionId, 'comp01');
  });
}
