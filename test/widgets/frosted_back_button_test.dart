import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';

void main() {
  testWidgets('FrostedBackButton exposes a 뒤로가기 tooltip and invokes onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: FrostedBackButton(onTap: () => tapped = true)),
      ),
    );

    expect(find.byTooltip('뒤로가기'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
