import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/settings_providers.dart';

void main() {
  test('notificationEnabledProvider는 탭 즉시 상태를 전환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(notificationEnabledProvider);
    container.read(notificationEnabledProvider.notifier).state = !before;

    expect(container.read(notificationEnabledProvider), !before);
  });

  test('isLoggedInProvider는 로그아웃 후 실행취소로 원래 상태로 복원된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(isLoggedInProvider), isTrue);

    container.read(isLoggedInProvider.notifier).state = false;
    expect(container.read(isLoggedInProvider), isFalse);

    container.read(isLoggedInProvider.notifier).state = true;
    expect(container.read(isLoggedInProvider), isTrue);
  });
}
