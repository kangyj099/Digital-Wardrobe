import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/theme_providers.dart';

void main() {
  test('초기 상태는 ThemeMode.light이다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('set(true)는 상태를 ThemeMode.dark로 바꾼다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider.notifier).set(true);

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('set(false)는 상태를 ThemeMode.light로 바꾼다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider.notifier).set(true);
    container.read(themeModeProvider.notifier).set(false);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
