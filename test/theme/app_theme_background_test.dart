import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';

void main() {
  test('Light theme scaffoldBackgroundColor matches Brand Guide Background (#F7F6F3)', () {
    expect(AppTheme.light.scaffoldBackgroundColor, const Color(0xFFF7F6F3));
  });

  test('Dark theme scaffoldBackgroundColor matches Brand Guide Background (#1D262D), distinct from Surface', () {
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF1D262D));
    expect(AppTheme.dark.scaffoldBackgroundColor, isNot(AppTheme.dark.colorScheme.surface));
  });
}
