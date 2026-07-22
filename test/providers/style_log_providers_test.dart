import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';

void main() {
  test('StyleLogsNotifier.softDeleteMany/restoreMany/purgeMany가 동작한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(styleLogsProvider.notifier);

    notifier.softDeleteMany({'log01'});
    var log01 = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01');
    expect(log01.isDeleted, isTrue);
    expect(log01.deletedAt, isNotNull);

    notifier.restoreMany({'log01'});
    log01 = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01');
    expect(log01.isDeleted, isFalse);
    expect(log01.deletedAt, isNull);

    final before = container.read(styleLogsProvider).length;
    notifier.purgeMany({'log01'});
    final after = container.read(styleLogsProvider);
    expect(after.length, before - 1);
    expect(after.any((l) => l.id == 'log01'), isFalse);
  });
}
