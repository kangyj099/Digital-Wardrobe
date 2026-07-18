import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/auto_save_indicator.dart';

void main() {
  testWidgets('AutoSaveIndicator는 "자동 저장됨" 상태를 텍스트와 Semantics label로 함께 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const Scaffold(body: AutoSaveIndicator())),
    );

    expect(find.text('자동 저장됨'), findsOneWidget);
    expect(find.bySemanticsLabel('자동 저장됨'), findsOneWidget);
    handle.dispose();
  });
}
