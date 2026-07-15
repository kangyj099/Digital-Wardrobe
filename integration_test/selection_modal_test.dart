import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_add_screen.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Step⑥-B(선택 모달 — 옷장/코디/스타일일지 Main 화면을 selectionMode로 재호출) Tester
/// 검증. Review 통과분(`app_router.dart`에 `/closet/select`, `/composition/select`,
/// `/style-log/select` 3개 라우트 신설) 대상. 이 Step은 정적 구조 검증 단계(실제 선택 결과
/// 바인딩·go_router result 반환은 Step⑦ 몫)라, 여기서는 (1) 닫기 버튼으로 교체, (2) 카테고리
/// 토글/FAB 미노출, (3) groupingBar 유지(스타일일지는 원래도 없음), (4) 타일 탭 시 상세 화면
/// 미이동 + 콜백 트리거, (5) 옷장 미완성 항목 탭 시 완성 화면 이동, (6) 네이티브 진입 경로
/// 회귀 없음까지만 확인한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
  }

  Finder closeButtonFinder() => find.byTooltip('닫기');
  Finder backButtonFinder() => find.byTooltip('뒤로가기');

  // ── 옷장 선택 모달(/closet/select) ────────────────────────────────────────

  testWidgets(
    '옷장 선택 모달(/closet/select) 진입 시 닫기 버튼만 나타나고, canPop==true인 상황에서도 '
    '뒤로가기 버튼은 나타나지 않으며, 카테고리 토글/FAB도 없고 groupingBar는 그대로 노출된다',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.closetSelect);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(closeButtonFinder(), findsOneWidget);
      expect(backButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('분류 선택 바'), findsOneWidget);
      // 그리드 자체는 그대로 12개 렌더링(선택 모달도 콘텐츠는 동일).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    },
  );

  testWidgets(
    '옷장 선택 모달에서 닫기 버튼을 탭하면 context.pop()으로 이전 화면(네이티브 옷장 메인)으로 '
    '돌아가고, 돌아간 화면에는 카테고리 토글/FAB가 다시 나타난다(선택 모달 상태가 남지 않음)',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.closetSelect);
      await tester.pumpAndSettle();
      expect(closeButtonFinder(), findsOneWidget);

      await tester.tap(closeButtonFinder());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(closeButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    },
  );

  testWidgets(
    '옷장 선택 모달에서 완성된 항목(c01)을 탭해도 상세 화면(/closet/:id)으로 이동하지 않고 '
    '선택 화면에 그대로 머무른다(실제 선택 결과 바인딩은 Step⑦ 몫이라 콜백이 null이어도 '
    '크래시나 잘못된 네비게이션이 없어야 한다)',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.closetSelect);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    },
  );

  testWidgets(
    '옷장 선택 모달에서 미완성 항목(c06)을 탭하면 완성 화면(/closet/add)으로 이동한다',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.closetSelect);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('c06')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetAddScreen), findsOneWidget);
    },
  );

  // ── 코디 선택 모달(/composition/select) ───────────────────────────────────

  testWidgets(
    '코디 선택 모달(/composition/select)도 닫기 버튼으로 교체되고, 카테고리 토글/FAB는 '
    '없으며 groupingBar는 그대로 노출된다. 타일 탭 시 context.pop(id)로 결과를 반환한다',
    (tester) async {
      await pumpApp(tester);

      String? poppedResult;
      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push<String>(AppRoute.compositionSelect).then((value) {
        poppedResult = value;
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(closeButtonFinder(), findsOneWidget);
      expect(backButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('분류 선택 바'), findsOneWidget);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(poppedResult, 'comp01');
    },
  );

  // ── 스타일일지 선택 모달(/style-log/select) ───────────────────────────────

  testWidgets(
    '스타일일지 선택 모달(/style-log/select)도 닫기 버튼으로 교체되고, 카테고리 토글/FAB는 '
    '없으며, 원래도 그룹형이 아니라 groupingBar는 (변화 없이) 여전히 없다. 타일 탭 시 '
    'context.pop(id)로 결과를 반환한다',
    (tester) async {
      await pumpApp(tester);

      String? poppedResult;
      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push<String>(AppRoute.styleLogSelect).then((value) {
        poppedResult = value;
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(closeButtonFinder(), findsOneWidget);
      expect(backButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('분류 선택 바'), findsNothing);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(poppedResult, 'log01');
    },
  );

  // ── onItemSelected 콜백 실제 트리거 확인 ───────────────────────────────────
  //
  // 실제 앱 라우터(`app_router.dart`)의 `/closet/select` 등은 아직 `onItemSelected`를
  // 연결하지 않는다(Step⑦ 몫). 콜백 자체가 실제로 호출되는지는 그 화면 위젯을 직접
  // 콜백과 함께 구동해서만 확인 가능 — 최소한의 호스트 라우터로 실제 위젯을 그대로 구동한다.

  testWidgets(
    'ClosetMainScreen(selectionMode: true)에 onItemSelected를 연결해 직접 구동하면, '
    '완성된 항목 탭 시 콜백이 정확한 id로 실제 호출되고 화면 전환은 일어나지 않는다',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 4600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? selectedId;
      final router = GoRouter(
        initialLocation: '/select',
        routes: [
          GoRoute(
            path: '/select',
            builder: (context, state) => ClosetMainScreen(
              selectionMode: true,
              onItemSelected: (id) => selectedId = id,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(selectedId, isNull);

      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(selectedId, 'c01');
      // 콜백만 실행되고 화면은 그대로(같은 라우트에 머무름).
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
    },
  );
}
