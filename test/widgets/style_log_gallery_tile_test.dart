import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

void main() {
  testWidgets('location이 있으면 날짜와 장소를 함께 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    final styleLog = StyleLog(
      id: 'log01',
      coverImagePath: '',
      wornDate: DateTime(2026, 1, 5),
      location: '집',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StyleLogGalleryTile(styleLog: styleLog, onTap: () {})),
      ),
    );

    expect(find.text('2026-01-05 · 집'), findsOneWidget);
    expect(find.bySemanticsLabel('2026-01-05 · 집'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('location이 빈 문자열이면 날짜만 노출한다', (tester) async {
    final handle = tester.ensureSemantics();
    final styleLog = StyleLog(
      id: 'log02',
      coverImagePath: '',
      wornDate: DateTime(2026, 2, 10),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: StyleLogGalleryTile(styleLog: styleLog, onTap: () {})),
      ),
    );

    expect(find.text('2026-02-10'), findsOneWidget);
    expect(find.bySemanticsLabel('2026-02-10'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('탭하면 onTap이 호출된다', (tester) async {
    var tapped = false;
    final styleLog = StyleLog(id: 'log03', coverImagePath: '', wornDate: DateTime(2026, 3, 1));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StyleLogGalleryTile(styleLog: styleLog, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(StyleLogGalleryTile));
    expect(tapped, isTrue);
  });
}
