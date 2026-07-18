import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/editor_header.dart';

void main() {
  testWidgets('EditorHeader는 취소 버튼과 도움말 버튼을 함께 렌더링하고 각각의 콜백을 호출한다', (tester) async {
    var cancelled = false;
    var helpTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EditorHeader(
            onCancel: () => cancelled = true,
            onHelpTap: () => helpTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('취소'), findsOneWidget);
    expect(find.byTooltip('도움말'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pump();
    expect(cancelled, isTrue);

    await tester.tap(find.byTooltip('도움말'));
    await tester.pump();
    expect(helpTapped, isTrue);
  });
}
