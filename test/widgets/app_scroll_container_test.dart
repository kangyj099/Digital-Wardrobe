import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/app_scroll_container.dart';
import 'package:digittal_wardrobe/widgets/bottom_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/top_gradient_overlay.dart';

/// `AppScrollContainer`가 실제 `ScrollController`를 관찰해 스펙 §2 표시 조건
/// (`scrollTop > 2px` / `scrollTop < scrollHeight - clientHeight - 2px`)대로
/// Top/BottomGradientOverlay의 visible을 토글하는지 검증한다.
void main() {
  double opacityOf(WidgetTester tester, Type overlayType) {
    final animatedOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(overlayType),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    return animatedOpacity.opacity;
  }

  testWidgets(
    '스크롤 가능한 콘텐츠에서 최상단일 때는 Top hint가 숨겨지고 아래로 스크롤하면 나타나며, '
    '맨 아래까지 스크롤하면 Bottom hint가 사라진다',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppScrollContainer(
              builder: (context, controller) => ListView.builder(
                controller: controller,
                itemCount: 30,
                itemBuilder: (context, index) => SizedBox(height: 100, child: Text('item $index')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 최상단: top hint 숨김, 아래로 더 스크롤 가능하니 bottom hint는 보임.
      expect(opacityOf(tester, TopGradientOverlay), 0);
      expect(opacityOf(tester, BottomGradientOverlay), greaterThan(0));

      // 조금 스크롤 — top hint가 나타나야 한다(ListView.builder가 재사용/폐기하는
      // 'item 0' 텍스트가 아니라 항상 존재하는 ListView 자체를 드래그 기준으로 삼는다).
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(opacityOf(tester, TopGradientOverlay), greaterThan(0));

      // 맨 아래까지 스크롤 — bottom hint가 사라져야 한다.
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(opacityOf(tester, BottomGradientOverlay), 0);
    },
  );

  testWidgets('스크롤이 아예 불가능한 짧은 콘텐츠에서는 top/bottom hint가 모두 숨겨진다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppScrollContainer(
            builder: (context, controller) => ListView(
              controller: controller,
              children: const [SizedBox(height: 50, child: Text('짧은 콘텐츠'))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(opacityOf(tester, TopGradientOverlay), 0);
    expect(opacityOf(tester, BottomGradientOverlay), 0);
  });
}
