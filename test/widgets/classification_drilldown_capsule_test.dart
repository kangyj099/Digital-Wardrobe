import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/classification_drilldown_capsule.dart';

void main() {
  testWidgets('소분류가 없으면 두 번째 세그먼트가 렌더링되지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationDrilldownCapsule(
          criterionLabels: const ['전체보기', '착용빈도'],
          selectedCriterionIndex: 0,
          onCriterionChanged: (_) {},
          hasSubClassification: false,
        ),
      ),
    ));

    expect(find.text('전체보기'), findsOneWidget);
    expect(find.byType(DropdownButton<int?>), findsNothing);
  });

  testWidgets('소분류가 있으면 hint가 표시된다(미선택=그룹 개요 상태)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationDrilldownCapsule(
          criterionLabels: const ['전체보기', '옷 종류'],
          selectedCriterionIndex: 1,
          onCriterionChanged: (_) {},
          hasSubClassification: true,
          subHint: '종류',
          subOptionLabels: const ['상의', '하의', '미분류'],
        ),
      ),
    ));

    expect(find.text('종류'), findsOneWidget);
  });
}
