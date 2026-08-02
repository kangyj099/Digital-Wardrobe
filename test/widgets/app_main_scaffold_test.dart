import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/app_main_scaffold.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';

/// `AppMainScaffold` 플래그별 렌더링 검증 — Stack 기반 재설계(2026-07-13,
/// `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`) 이후
/// 계약(headerActions/secondaryControlsLeft/secondaryControlsRight) 기준. `groupingBar`
/// 슬롯은 2026-07-19 삭제됨(화면별 `ClassificationDrilldownCapsule`로 대체).
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
    'headerActions를 주면 렌더링되고, 비어있으면(기본값) 그 Positioned 자리를 차지하지 않는다',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => const AppMainScaffold(
          current: AppCategory.closet,
          body: SizedBox.shrink(),
        ),
      );
      expect(find.text('선택'), findsNothing);

      await pumpAt(
        tester,
        mainBuilder: (context) => AppMainScaffold(
          current: AppCategory.closet,
          headerActions: [TextButton(onPressed: () {}, child: const Text('선택'))],
          body: const SizedBox.shrink(),
        ),
      );
      expect(find.text('선택'), findsOneWidget);
    },
  );

  testWidgets(
    'secondaryControlsLeft/Right를 주면 각각 독립 위젯으로 렌더링되고, 하나의 공유 Container로 '
    '병합되지 않는다(Header/HUD Pinned Rule)',
    (tester) async {
      await pumpAt(
        tester,
        mainBuilder: (context) => AppMainScaffold(
          current: AppCategory.closet,
          secondaryControlsLeft: [const Text('왼쪽 컨트롤')],
          secondaryControlsRight: [const Text('오른쪽 컨트롤 A'), const Text('오른쪽 컨트롤 B')],
          body: const SizedBox.shrink(),
        ),
      );

      expect(find.text('왼쪽 컨트롤'), findsOneWidget);
      expect(find.text('오른쪽 컨트롤 A'), findsOneWidget);
      expect(find.text('오른쪽 컨트롤 B'), findsOneWidget);

      // 왼쪽 컨트롤과 오른쪽 컨트롤 그룹은 서로 다른 Positioned에 속해야 한다(같은 밴드를
      // 공유하는 단일 Bar가 아니라 좌/우 독립 배치).
      final leftPositioned = tester.widget<Positioned>(
        find.ancestor(of: find.text('왼쪽 컨트롤'), matching: find.byType(Positioned)).first,
      );
      final rightPositioned = tester.widget<Positioned>(
        find.ancestor(of: find.text('오른쪽 컨트롤 A'), matching: find.byType(Positioned)).first,
      );
      expect(leftPositioned.left, isNotNull);
      expect(rightPositioned.right, isNotNull);
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

  group('contentSpacerHeight', () {
    test('Row1만 있을 때(secondary 없음) 가장 작은 값을 반환한다', () {
      final onlyRow1 = AppMainScaffold.contentSpacerHeight();
      final withSecondary = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

      expect(onlyRow1, lessThan(withSecondary));
    });
  });

  testWidgets('bottomFloatingActions에 넘긴 위젯들이 하단에 렌더링된다', (tester) async {
    await pumpAt(
      tester,
      mainBuilder: (context) => AppMainScaffold(
        current: AppCategory.closet,
        bottomFloatingActions: const [Text('삭제')],
        body: const SizedBox.shrink(),
      ),
    );
    expect(find.text('삭제'), findsOneWidget);
  });
}
