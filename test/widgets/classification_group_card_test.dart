import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/classification_group_card.dart';

void main() {
  testWidgets('라벨과 개수를 함께 표시하고, Semantics 라벨로도 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ClassificationGroupCard(
          summary: const ClassificationGroupSummary(
            label: '상의',
            thumbnailPaths: [],
            count: 5,
            value: 'top',
          ),
          onTap: () {},
        ),
      ),
    ));

    expect(find.textContaining('상의'), findsOneWidget);
    expect(find.textContaining('5'), findsOneWidget);
    expect(find.bySemanticsLabel('상의, 5개'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('탭하면 onTap이 호출된다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ClassificationGroupCard(
          summary: const ClassificationGroupSummary(label: '미분류', thumbnailPaths: [], count: 1, value: null),
          onTap: () => tapped = true,
        ),
      ),
    ));

    await tester.tap(find.byType(ClassificationGroupCard));
    expect(tapped, isTrue);
  });
}
