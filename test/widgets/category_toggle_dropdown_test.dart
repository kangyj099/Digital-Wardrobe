import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';

void main() {
  Widget buildAppWithCurrent(AppCategory current) {
    final router = GoRouter(
      initialLocation: switch (current) {
        AppCategory.closet => AppRoute.closetMain,
        AppCategory.composition => AppRoute.compositionMain,
        AppCategory.styleLog => AppRoute.styleLogMain,
      },
      routes: [
        GoRoute(
          path: AppRoute.closetMain,
          builder: (context, state) =>
              Scaffold(body: CategoryToggleDropdown(current: AppCategory.closet)),
        ),
        GoRoute(
          path: AppRoute.compositionMain,
          builder: (context, state) =>
              Scaffold(body: CategoryToggleDropdown(current: AppCategory.composition)),
        ),
        GoRoute(
          path: AppRoute.styleLogMain,
          builder: (context, state) =>
              Scaffold(body: CategoryToggleDropdown(current: AppCategory.styleLog)),
        ),
      ],
    );
    return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  }

  testWidgets('현재 카테고리(옷장)를 다시 선택해도 화면이 그대로 유지된다', (tester) async {
    await tester.pumpWidget(buildAppWithCurrent(AppCategory.closet));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<AppCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('옷장').last);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryToggleDropdown), findsOneWidget);
    final widget = tester.widget<CategoryToggleDropdown>(find.byType(CategoryToggleDropdown));
    expect(widget.current, AppCategory.closet);
  });

  testWidgets('다른 화면(코디)에서 current: composition으로 호출해도 정상 렌더링된다 (재사용 가능성 검증)', (tester) async {
    await tester.pumpWidget(buildAppWithCurrent(AppCategory.composition));
    await tester.pumpAndSettle();

    final widget = tester.widget<CategoryToggleDropdown>(find.byType(CategoryToggleDropdown));
    expect(widget.current, AppCategory.composition);
    expect(find.text('코디'), findsOneWidget);
  });

  testWidgets('코디 화면에서 옷장을 선택하면 옷장 메인 라우트로 실제 이동한다', (tester) async {
    await tester.pumpWidget(buildAppWithCurrent(AppCategory.composition));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<AppCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('옷장').last);
    await tester.pumpAndSettle();

    final widget = tester.widget<CategoryToggleDropdown>(find.byType(CategoryToggleDropdown));
    expect(widget.current, AppCategory.closet);
  });
}
