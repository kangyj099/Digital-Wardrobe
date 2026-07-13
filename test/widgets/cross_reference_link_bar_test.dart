import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';

void main() {
  testWidgets('CrossReferenceLinkBar는 높이 64로 고정되고, 항목이 있으면 라벨을 렌더링하며 탭 시 콜백을 호출한다',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CrossReferenceLinkBar(
            entries: [
              CrossReferenceLinkEntry(label: '코디 3개', onTap: () => tapped = true),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CrossReferenceLinkBar));
    expect(size.height, CrossReferenceLinkBar.height);
    expect(find.text('코디 3개'), findsOneWidget);

    await tester.tap(find.text('코디 3개'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('항목이 비어있으면 크래시 없이 빈 영역만 렌더링한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CrossReferenceLinkBar(entries: [])),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
  });
}
