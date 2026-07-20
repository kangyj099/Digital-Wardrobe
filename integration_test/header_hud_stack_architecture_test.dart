import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_spacing.dart';
import 'package:digittal_wardrobe/widgets/bottom_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/top_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/app_main_scaffold.dart';

/// Header/HUD Stack 아키텍처 재설계(`AppMainScaffold` Column→Stack,
/// `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`) Tester
/// 검증. 기존 5개 통합테스트(`app_smoke_test`/`closet_main_screen_test`/
/// `app_main_scaffold_shell_migration_test`/`closet_main_shell_widgets_regression_test`/
/// `composition_style_log_main_screen_test`)가 이미 Column 시절부터 다뤄온 계절/밀도/FAB/
/// 카테고리 이동/뒤로가기 시나리오는 중복 작성하지 않는다. 이 파일은 이번 Stack 전환에서만
/// 새로 생긴 위험만 다룬다: (1) 스크롤 위치 기반 그라디언트 오버레이의 실제 표시/숨김 전이,
/// (2) 콘텐츠가 화면 전체를 차지하는 Stack 구조에서 floating control의 히트테스트 우선순위,
/// (3) 스크롤+플로팅 오버레이 동시 존재 시 크래시 여부. (구 (3) groupingBar 배치 회귀 테스트는
/// 그 밴드 자체가 2026-07-19 삭제되어 더 이상 회귀 대상이 아니므로 제거됨.)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 실제 모바일 폭에 가까우면서, 옷장 메인(mock 12개, 기본 밀도 mid=2컬럼)이 확실히
  // 스크롤 가능해지도록 세로를 짧게 잡은 뷰포트.
  const scrollableSize = Size(390, 800);

  Future<ProviderContainer> pumpApp(WidgetTester tester, {Size size = scrollableSize}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder categoryDropdownFinder() =>
      find.byType(CategoryToggleDropdown);

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  double topOpacity(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          find.descendant(of: find.byType(TopGradientOverlay), matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
  }

  double bottomOpacity(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          find.descendant(
              of: find.byType(BottomGradientOverlay), matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
  }

  // ── 1) 스크롤 위치 기반 그라디언트 실제 동작 ──────────────────────────────────

  group('스크롤 그라디언트', () {
  testWidgets(
  '옷장 메인(스크롤 가능)에서 헤더 영역 높이만큼 내리기 전엔 TopGradientOverlay가 '
  '계속 숨김 상태고, 그 높이를 넘어서야 나타난다. BottomGradientOverlay는 대칭적으로 '
  '아래로 더 스크롤 가능한 동안만 표시된다',
  (tester) async {
    await pumpApp(tester);
    expect(find.byType(ClosetMainScreen), findsOneWidget);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );

    // ClosetMainScreen이 AppScrollContainer에 넘기는 것과 동일한 계산 —
    // 화면 쪽 헤더 구성(Row1+Row2)이 바뀌면 이 값도 같이 따라간다.
    final topThreshold = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    expect(
      scrollable.position.maxScrollExtent,
      greaterThan(topThreshold + 50),
      reason: '이 시나리오는 threshold를 넘어서도 스크롤할 여유가 있어야 의미가 있다',
    );

    // 최상단: Top 숨김, Bottom 표시.
    expect(topOpacity(tester), 0);
    expect(bottomOpacity(tester), closeTo(0.85, 0.001));

    // 헤더 영역 높이보다 적게 스크롤 — 아직 화면 밖으로 진짜 가려진 콘텐츠가 없으므로
    // Top은 계속 숨김이어야 한다(이번 수정의 핵심 시나리오).
    await tester.drag(find.byType(GridView), Offset(0, -(topThreshold - 20)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(topOpacity(tester), 0, reason: '헤더 높이만큼 안 내려갔으면 아직 안 보여야 한다');
    expect(bottomOpacity(tester), closeTo(0.85, 0.001));

    // 헤더 영역 높이를 넘어서 스크롤 — 이제 Top이 나타나야 한다.
    await tester.drag(find.byType(GridView), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(topOpacity(tester), closeTo(0.85, 0.001));
    expect(bottomOpacity(tester), closeTo(0.85, 0.001));

    // 맨 아래까지 강하게 스크롤 — Bottom이 사라져야 한다.
    await tester.fling(find.byType(GridView), const Offset(0, -3000), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));
    expect(topOpacity(tester), closeTo(0.85, 0.001));
    expect(bottomOpacity(tester), 0);

    // 다시 맨 위로 — Top이 사라지고 Bottom이 재등장.
    await tester.fling(find.byType(GridView), const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(scrollable.position.pixels, closeTo(0, 1));
    expect(topOpacity(tester), 0);
    expect(bottomOpacity(tester), closeTo(0.85, 0.001));
  },
);
    testWidgets(
      '콘텐츠가 적어(mock 스타일일지 2개) 애초에 스크롤이 불가능한 화면에서는 '
      'TopGradientOverlay/BottomGradientOverlay가 계속 숨김 상태를 유지하고, '
      '드래그를 시도해도 아무 변화가 없다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        expect(find.byType(StyleLogMainScreen), findsOneWidget);

        final scrollable = tester.state<ScrollableState>(find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)));
        expect(
          scrollable.position.maxScrollExtent,
          lessThanOrEqualTo(0),
          reason: '스타일일지 메인은 mock 2개뿐이라 스크롤 불가능해야 의미가 있다',
        );

        expect(topOpacity(tester), 0);
        expect(bottomOpacity(tester), 0);

        await tester.drag(find.byType(GridView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, 0);
        expect(topOpacity(tester), 0);
        expect(bottomOpacity(tester), 0);
      },
    );
  });

  // ── 2) 독립 floating control들의 히트테스트 우선순위 ──────────────────────────

  group('floating control 히트테스트', () {
    testWidgets(
      '스크롤로 그리드 타일이 Row2(계절/밀도/원형 버튼) 영역까지 올라와 시각적으로 겹쳐도, '
      '그 위치를 탭하면 아래 타일이 아니라 위에 뜬 GlassCircleButton(밀도 버튼)이 반응한다 '
      '(상세 화면 이동 없이 밀도만 바뀜)',
      (tester) async {
        final container = await pumpApp(tester);
        expect(container.read(closetDensityProvider), AppDensity.mid);

        // 타일이 헤더 근처까지 올라오도록 충분히 스크롤.
        await tester.drag(find.byType(GridView), const Offset(0, -150));
        await tester.pumpAndSettle();

        final buttonCenter = tester.getCenter(find.byTooltip('그리드 밀도 전환'));

        // sanity check: 실제로 그 좌표에 타일이 시각적으로 겹쳐 있는지 확인(그렇지 않으면
        // 이 테스트가 검증하려는 "겹침 상황에서의 우선순위"가 애초에 재현되지 않은 것).
        final tileFinder = find.byType(SelectableGalleryTile);
        final tileCount = tester.widgetList(tileFinder).length;
        var overlapFound = false;
        for (var i = 0; i < tileCount; i++) {
          if (tester.getRect(tileFinder.at(i)).contains(buttonCenter)) {
            overlapFound = true;
            break;
          }
        }
        expect(
          overlapFound,
          isTrue,
          reason: '밀도 버튼 좌표(${buttonCenter}) 아래에 그리드 타일이 겹쳐 있어야 이 테스트가 '
              '실제로 히트테스트 우선순위를 검증하는 것이 된다',
        );

        await tester.tapAt(buttonCenter);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // 밀도 버튼이 먼저 반응 — 밀도가 바뀌었고, 상세 화면으로는 이동하지 않았다.
        expect(container.read(closetDensityProvider), isNot(AppDensity.mid));
        expect(find.byType(ClosetMainScreen), findsOneWidget);
        expect(find.byType(ClosetItemDetailScreen), findsNothing);
      },
    );

    testWidgets(
      '동일한 겹침 상황에서 Row1의 카테고리 토글 좌표를 탭해도 아래 타일이 아니라 '
      '카테고리 드롭다운이 반응한다(패널이 열림, 상세 화면 이동 없음)',
      (tester) async {
        await pumpApp(tester);

        await tester.drag(find.byType(GridView), const Offset(0, -150));
        await tester.pumpAndSettle();

        final dropdownCenter = tester.getCenter(categoryDropdownFinder());
        final tileFinder = find.byType(SelectableGalleryTile);
        final tileCount = tester.widgetList(tileFinder).length;
        var overlapFound = false;
        for (var i = 0; i < tileCount; i++) {
          if (tester.getRect(tileFinder.at(i)).contains(dropdownCenter)) {
            overlapFound = true;
            break;
          }
        }
        expect(
          overlapFound,
          isTrue,
          reason: '카테고리 토글 좌표 아래에도 그리드 타일이 겹쳐 있어야 한다',
        );

        await tester.tapAt(dropdownCenter);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // 드롭다운 패널이 열려 다른 카테고리 옵션 텍스트가 보여야 한다(탭이 타일로 새지 않았음).
        expect(find.text('코디'), findsWidgets);
        expect(find.byType(ClosetItemDetailScreen), findsNothing);
      },
    );
  });

  // ── 4) 비정형 흐름: 스크롤 도중 드롭다운 여닫기 ────────────────────────────────

  testWidgets(
    '[비정형 사용 흐름] 스크롤 도중(그라디언트 오버레이가 표시된 상태) 계절 드롭다운을 '
    '열었다가 옵션을 고르지 않고 바깥을 탭해 닫아도 크래시 없이 처리되고, 스크롤 위치는 '
    '그대로 유지된다',
    (tester) async {
      await pumpApp(tester);

      final scrollable = tester.state<ScrollableState>(find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)));
      final topThreshold = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);
      await tester.drag(find.byType(GridView), Offset(0, -(topThreshold + 20)));
      await tester.pumpAndSettle();
      final pixelsBeforeDropdown = scrollable.position.pixels;
      expect(topOpacity(tester), closeTo(0.85, 0.001));

      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('옷 종류'), findsWidgets); // 드롭다운 오버레이 열림 확인(기본 중분류=전체보기)

      // 옵션을 고르지 않고 화면 바깥(좌상단 빈 공간)을 탭해 모달 배리어로 닫는다.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      // 드롭다운을 여닫는 동안 스크롤 위치/그라디언트 상태가 어긋나지 않았어야 한다.
      expect(scrollable.position.pixels, closeTo(pixelsBeforeDropdown, 1));
      expect(topOpacity(tester), closeTo(0.85, 0.001));
    },
  );
}
