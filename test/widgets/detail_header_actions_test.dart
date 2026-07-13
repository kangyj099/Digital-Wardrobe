import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/detail_header_actions.dart';

void main() {
  testWidgets('DetailHeaderActions는 카테고리 드롭다운과 더보기 메뉴 버튼을 함께 렌더링한다', (tester) async {
    var menuTapped = false;
    final router = GoRouter(
      initialLocation: AppRoute.closetMain,
      routes: [
        GoRoute(
          path: AppRoute.closetMain,
          builder: (context, state) => Scaffold(
            body: DetailHeaderActions(
              current: AppCategory.closet,
              onMenuTap: () => menuTapped = true,
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryToggleDropdown), findsOneWidget);
    expect(find.byTooltip('더보기 메뉴'), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pump();

    expect(menuTapped, isTrue);
  });
}
