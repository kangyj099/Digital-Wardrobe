import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/settings_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/app_scroll_container.dart';
import 'package:digittal_wardrobe/widgets/bottom_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/glass_pill.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/top_gradient_overlay.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Step⑥-A(설정/휴지통 화면 공용 셸 적용) Tester 검증.
///
/// `closet_main_screen_test.dart`의 23/28번 테스트는 두 화면이 실제로 렌더링되는지 정도만
/// 확인한다(대형 회귀축 파일이라 중복 작성 방지). 이 파일은 이번 변경으로 새로 생긴 실제
/// 동작(뒤로가기, 헤더 액션 독립성/Pinned Rule, 파괴적 액션 확인 다이얼로그, 휴지통 타일 탭
/// 정보 팝업, 스크롤 힌트 그래디언트)을 다룬다.
///
/// 두 화면 모두 정상 UI 플로우로는 아직 도달 불가능해(카테고리 드롭다운/설정 진입 버튼 등
/// 진입 UI가 없음, 플랜에 명시된 의도된 상태), 옷장 메인 위에 `GoRouter.push`로 인위적으로
/// 진입한다(`closet_main_screen_test.dart`와 동일한 패턴) — 이 push 자체가 두 화면 모두
/// `canPop()==true` 상태를 만들어주므로 뒤로가기 버튼 검증도 이 pump 헬퍼 하나로 겸한다.
///
/// [갱신, 2026-07-15] 최초 작성 시 `SettingsScreen`의 알림/다크모드 `Switch`가
/// `value` 하드코딩 + `onChanged: (_) {}`라 탭해도 전혀 반응하지 않는 것을 발견해
/// "값이 안 바뀐다"를 단언하는 테스트로 남겼었다. Worker가 `SettingsScreen`을
/// `StatefulWidget` + 로컬 `bool` state로 승격해 탭하면 실제로 토글되도록 고쳤고(영속화 자체는
/// 여전히 Step⑦ 몫), 아래 테스트를 새 동작("탭하면 실제로 반전되고, 두 스위치는 독립적으로
/// 반응한다") 기준으로 갱신한다.
///
/// [갱신, 2026-07-15] Audit이 "전체 데이터 삭제" 로우가 승인된 `04_설정.md` 스펙에 없는
/// 항목임을 지적해 Worker가 `SettingsScreen`에서 해당 로우/확인 다이얼로그를 완전히
/// 제거했다. 기존에 이 로우의 확인/취소 다이얼로그를 검증하던 테스트 2개는 대상 자체가
/// 사라져 아래 회귀 테스트 1개(로우가 실제로 없음을 확인)로 교체한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 800);
  // Content Spacer(64) + 화면 콘텐츠가 확실히 스크롤 가능해지도록 세로를 짧게 잡은 뷰포트
  // (`detail_screens_header_hud_test.dart`의 scrollableDetailSize와 같은 접근).
  const shortSize = Size(390, 260);

  Future<ProviderContainer> pumpAppAndPush(
    WidgetTester tester,
    String route, {
    Size size = defaultSize,
  }) async {
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

    final context = tester.element(find.byType(SelectableGalleryTile).first);
    GoRouter.of(context).push(route);
    await tester.pumpAndSettle();
    return container;
  }

  Finder backButtonFinder() => find.byTooltip('뒤로가기');

  double topOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(TopGradientOverlay),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  double bottomOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(BottomGradientOverlay),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  // ── SettingsScreen ──────────────────────────────────────────────────────

  group('SettingsScreen', () {
    testWidgets(
      '카테고리 토글은 렌더링되지 않고(Utility형, showCategoryToggle:false, current 더미값이 '
      '실제로 영향 없음), 뒤로가기 버튼은 나타나며 탭하면 실제 pop되어 옷장 메인으로 돌아간다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        expect(tester.takeException(), isNull);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.byType(CategoryToggleDropdown), findsNothing);

        expect(backButtonFinder(), findsOneWidget);
        await tester.tap(backButtonFinder());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(SelectableGalleryTile), findsWidgets);
      },
    );

    testWidgets(
      '알림/다크모드 Switch를 탭하면 로컬 state가 실제로 토글되고(영속화 자체는 여전히 '
      'Step⑦ 몫), 두 번째 탭으로 원래 값으로 되돌아오며, 서로 독립적으로 반응한다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        final switches = find.byType(Switch);
        expect(switches, findsNWidgets(2));

        for (var i = 0; i < 2; i++) {
          final initial = tester.widget<Switch>(switches.at(i)).value;

          await tester.tap(switches.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.widget<Switch>(switches.at(i)).value,
            !initial,
            reason: '탭하면 로컬 state가 실제로 반전되어야 한다(StatefulWidget 승격 이후 동작).',
          );

          // 왕복 확인 — 다시 탭하면 원래 값으로 복원되어야 한다.
          await tester.tap(switches.at(i));
          await tester.pumpAndSettle();
          expect(
            tester.widget<Switch>(switches.at(i)).value,
            initial,
            reason: '두 번째 탭으로 원래 값으로 되돌아와야 한다.',
          );
        }

        // 두 스위치가 서로 독립적인 state인지: 알림 스위치를 탭해도 다크모드 스위치 값은
        // 영향받지 않아야 한다.
        final darkModeBefore = tester.widget<Switch>(switches.at(1)).value;
        await tester.tap(switches.at(0));
        await tester.pumpAndSettle();

        expect(
          tester.widget<Switch>(switches.at(1)).value,
          darkModeBefore,
          reason: '알림 스위치를 탭해도 다크모드 스위치 값에는 영향이 없어야 한다(독립된 state).',
        );
      },
    );

    testWidgets(
      '"전체 데이터 삭제" 로우는 승인된 스펙(`04_설정.md`)에 없어 제거되었다 — 텍스트/다이얼로그 '
      '모두 존재하지 않고, 나머지 화면은 크래시 없이 정상 렌더링된다(회귀 확인)',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        expect(tester.takeException(), isNull);
        expect(find.text('전체 데이터 삭제'), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('알림'), findsOneWidget);
        expect(find.text('다크 모드'), findsOneWidget);
        expect(find.text('프로필 편집'), findsOneWidget);
      },
    );

    testWidgets('"프로필 편집" 로우를 탭해도 크래시 없이 같은 화면에 남아있다(진입 로직 no-op, Step⑦ 몫)', (tester) async {
      await pumpAppAndPush(tester, AppRoute.settingsMain);

      await tester.tap(find.text('프로필 편집'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      '짧은 뷰포트에서 리스트가 스크롤 가능하고, 상단/하단 힌트 그래디언트가 스크롤 위치에 '
      '따라 크래시 없이 전환된다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain, size: shortSize);

        expect(find.byType(AppScrollContainer), findsOneWidget);
        final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
        expect(
          scrollable.position.maxScrollExtent,
          greaterThan(0),
          reason: '이 시나리오는 실제로 스크롤 가능해야 의미가 있다(뷰포트 높이 전제 확인)',
        );

        expect(topOpacity(tester), 0);

        await tester.drag(find.byType(ListView), const Offset(0, -80));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, greaterThan(0));
        expect(topOpacity(tester), closeTo(0.85, 0.001));
      },
    );
  });

  // ── TrashMainScreen ─────────────────────────────────────────────────────

  group('TrashMainScreen', () {
    testWidgets(
      'mock 4개 항목이 크래시 없이 썸네일 그리드로 렌더링되고("N일" 오버레이 포함), 카테고리 '
      '토글은 렌더링되지 않으며(Main-플랫+필터형, showCategoryToggle:false, current 더미값이 실제로 '
      '영향 없음), 뒤로가기 버튼은 나타나며 탭하면 실제 pop되어 옷장 메인으로 돌아간다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.trashMain);

        expect(tester.takeException(), isNull);
        expect(find.byType(TrashMainScreen), findsOneWidget);
        expect(find.byType(CategoryToggleDropdown), findsNothing);
        expect(find.byType(TrashGalleryTile), findsNWidgets(4));
        expect(find.text('12일'), findsOneWidget);
        expect(find.text('5일'), findsOneWidget);
        expect(find.text('27일'), findsOneWidget);
        expect(find.text('1일'), findsOneWidget);

        expect(backButtonFinder(), findsOneWidget);
        await tester.tap(backButtonFinder());
        await tester.pumpAndSettle();

        expect(find.byType(TrashMainScreen), findsNothing);
        expect(find.byType(SelectableGalleryTile), findsWidgets);
      },
    );

    testWidgets(
      '"선택"과 "비우기"는 물리적으로 독립된 GlassPill 2개이며(Header/HUD Pinned Rule), 각각 '
      '독립적으로 탭 가능하다 — "선택"(no-op 스텁)을 먼저 탭해도 "비우기"의 확인 다이얼로그 '
      '동작에 영향을 주지 않는다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.trashMain);

        expect(find.byType(GlassPill), findsNWidgets(2));

        await tester.tap(find.text('선택'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TrashGalleryTile), findsNWidgets(4));

        await tester.tap(find.text('비우기'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      '"비우기" 탭 시 강한 확인 다이얼로그가 뜨고, 확인을 눌러도 실제 삭제 없이 그리드 4개 '
      '항목이 그대로 남는다(no-op)',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.trashMain);

        await tester.tap(find.text('비우기'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('정말 비우시겠습니까? 휴지통의 모든 항목이 영구 삭제됩니다.'), findsOneWidget);

        await tester.tap(find.text('비우기').last); // 다이얼로그 내부 확인 버튼
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TrashGalleryTile), findsNWidgets(4));
      },
    );

    testWidgets('"비우기" 다이얼로그에서 취소를 누르면 아무 변화 없이 닫히고 그리드는 그대로다', (tester) async {
      await pumpAppAndPush(tester, AppRoute.trashMain);

      await tester.tap(find.text('비우기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(TrashGalleryTile), findsNWidgets(4));
    });

    testWidgets(
      '그리드 타일 탭 시 상세 페이지 전환이 아니라 정보 바텀시트가 뜨고, 복원/영구삭제 버튼을 '
      '눌러도 항목이 그리드에서 사라지지 않으며 어떤 상세 화면으로도 전환되지 않는다(no-op)',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.trashMain);

        // t1(closet, 12일)이 첫 타일.
        await tester.tap(find.byType(TrashGalleryTile).first);
        await tester.pumpAndSettle();

        expect(find.text('옷장 · 영구 삭제까지 12일'), findsOneWidget);
        expect(find.text('복원'), findsOneWidget);
        expect(find.text('영구 삭제'), findsOneWidget);

        await tester.tap(find.text('복원'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // no-op이라 시트가 닫히지 않고 그대로 열려 있어야 한다.
        expect(find.text('영구 삭제'), findsOneWidget);

        await tester.tap(find.text('영구 삭제'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 바텀시트를 닫고(모달 라우트 pop) 그리드가 4개 그대로인지, 어떤 상세 화면으로도
        // 전환되지 않았는지 확인한다.
        Navigator.of(tester.element(find.text('복원'))).pop();
        await tester.pumpAndSettle();

        expect(find.byType(TrashGalleryTile), findsNWidgets(4));
        expect(find.byType(ClosetItemDetailScreen), findsNothing);
        expect(find.byType(CompositionDetailScreen), findsNothing);
        expect(find.byType(StyleLogViewerScreen), findsNothing);
      },
    );

    testWidgets(
      '짧은 뷰포트에서 그리드가 스크롤 가능하고, 상단/하단 힌트 그래디언트가 스크롤 위치에 '
      '따라 크래시 없이 전환된다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.trashMain, size: shortSize);

        expect(find.byType(AppScrollContainer), findsOneWidget);
        final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
        expect(
          scrollable.position.maxScrollExtent,
          greaterThan(0),
          reason: '이 시나리오는 실제로 스크롤 가능해야 의미가 있다(뷰포트 높이 전제 확인)',
        );

        expect(topOpacity(tester), 0);

        await tester.drag(find.byType(GridView), const Offset(0, -80));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, greaterThan(0));
        expect(topOpacity(tester), closeTo(0.85, 0.001));
      },
    );
  });
}
