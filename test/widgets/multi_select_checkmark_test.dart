import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';

void main() {
  testWidgets('selected=false면 체크 아이콘이 없다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MultiSelectCheckmark(selected: false)),
    );
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('selected=true면 체크 아이콘이 보인다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MultiSelectCheckmark(selected: true)),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
