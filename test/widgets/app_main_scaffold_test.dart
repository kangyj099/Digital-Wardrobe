import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/app_main_scaffold.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';

/// `AppMainScaffold` 플래그별 렌더링 검증 —
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §4가 요구하는
/// "뒤로가기 유무/카테고리 토글 유무/groupingBar 유무" 자체 위젯 테스트.
void main() {
  const testRoute = '/test-main';
  const pushedRoute = '/test-pushed';

  Future<void> pumpAt(
    WidgetTester tester, {
    required Widget Function(BuildContext context) mainBuilder,
    bool pushOnTop = false,
  }) async {
    final router = GoRouter(
      initialLocation: testRoute,
      routes: [
        GoRoute(path: testRoute, builder: (context, state) => mainBuilder(context)),
        GoRoute(path: pushedRoute, builder: (context, state) => mainBuilder(context)),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();

    if (pushOnTop) {
      final context = tester.element(find.byType(AppMainScaffold).first);
      GoRouter.of(context).push(pushedRoute);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    '스택 최상단(canPop()==false)이면 showBackButton=true여도 FrostedBackButton이 렌더링되지 않는다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          body: SizedBox.shrink(),
        ),
      );

      expect(find.byType(FrostedBackButton), findsNothing);
    },
  );

  testWidgets(
    'canPop()==true이고 showBackButton=true면 FrostedBackButton이 렌더링되고 탭하면 pop된다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          body: SizedBox.shrink(),
        ),
        pushOnTop: true,
      );

      expect(find.byType(FrostedBackButton), findsOneWidget);

      await tester.tap(find.byType(FrostedBackButton));
      await tester.pumpAndSettle();

      // pop 후에는 원래 화면(스택 최하단, canPop()==false)으로 돌아가 다시 버튼이 사라진다.
      expect(find.byType(FrostedBackButton), findsNothing);
    },
  );

  testWidgets(
    'canPop()==true여도 showBackButton=false면 FrostedBackButton이 렌더링되지 않는다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          showBackButton: false,
          body: SizedBox.shrink(),
        ),
        pushOnTop: true,
      );

      expect(find.byType(FrostedBackButton), findsNothing);
    },
  );

  testWidgets(
    'showCategoryToggle=true면 CategoryToggleDropdown이 렌더링되고, false면 렌더링되지 않는다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          body: SizedBox.shrink(),
        ),
      );
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);

      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          showCategoryToggle: false,
          body: SizedBox.shrink(),
        ),
      );
      expect(find.byType(CategoryToggleDropdown), findsNothing);
    },
  );

  testWidgets(
    'groupingBar를 주면 렌더링되고, null이면(기본값) 렌더링되지 않는다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          body: SizedBox.shrink(),
        ),
      );
      expect(find.text('그룹 바 자리'), findsNothing);

      await pumpAt(
        tester,
        mainBuilder: (context) => AppMainScaffold(
          current: AppCategory.closet,
          groupingBar: const Text('그룹 바 자리'),
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.text('그룹 바 자리'), findsOneWidget);
    },
  );

  testWidgets('body가 실제로 렌더링된다', (tester) async {
    await pumpAt(
      tester,
      mainBuilder: (context) => const AppMainScaffold(
        current: AppCategory.closet,
        body: Text('본문 콘텐츠'),
      ),
    );

    expect(find.text('본문 콘텐츠'), findsOneWidget);
  });
}
