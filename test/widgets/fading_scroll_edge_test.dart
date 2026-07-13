import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/fading_scroll_edge.dart';

void main() {
  testWidgets('FadingScrollEdge는 child를 그대로 렌더링하면서 ShaderMask로 감싼다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FadingScrollEdge(child: Text('gallery content'))),
      ),
    );

    expect(find.text('gallery content'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('gallery content'), matching: find.byType(ShaderMask)),
      findsOneWidget,
    );
  });
}
