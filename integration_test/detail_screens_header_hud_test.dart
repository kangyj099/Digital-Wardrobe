import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/app_scroll_container.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Step④(DetailHeaderActions 재작업 + Detail 3화면 AppMainScaffold 연결) Tester 검증.
///
/// 기존 대형 회귀축(계절/밀도/FAB/카테고리 이동 등, `closet_main_screen_test.dart`
/// `composition_style_log_main_screen_test.dart` `header_hud_stack_architecture_test.dart`)는
/// 중복 작성하지 않는다. 이 파일은 이번 변경으로 새로 생긴 위험만 다룬다:
/// 1) Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 실제 진입 가능 여부.
/// 2) Header/HUD Pinned Rule — 카테고리 드롭다운과 "더보기" 버튼이 물리적으로 독립된
///    위젯으로 겹치지 않고 각자 반응하는지.
/// 3) FrostedBackButton이 Detail 3화면 전부에서 실제로 나타나고 pop이 동작하는지.
/// 4) Detail 화면 skeleton body(Task 3~5 전까지 임시 문구)가 실제로 렌더링되는지.
/// 6) Detail 화면에서 카테고리 드롭다운으로 다른 메인 화면 이동이 실제로 동작하는지.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 800);
  const scrollableDetailSize = Size(390, 450);

  Future<ProviderContainer> pumpApp(WidgetTester tester, {Size size = defaultSize}) async {
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
      find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>);

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  // ── 1) Detail 3화면 실제 진입 ─────────────────────────────────────────────

  group('Detail 3화면 진입', () {
    testWidgets('옷장 메인에서 아이템 탭 → ClosetItemDetailScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      final tile = find.byType(SelectableGalleryTile).first;
      final item = tester.widget<SelectableGalleryTile>(tile).item;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text(item.name), findsOneWidget);
    });

    testWidgets('코디 메인에서 코디 탭 → CompositionDetailScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);

      final tile = find.byType(CompositionGalleryTile).first;
      final composition = tester.widget<CompositionGalleryTile>(tile).composition;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text(composition.name), findsOneWidget);
    });

    testWidgets('스타일일지 메인에서 카드 탭 → StyleLogViewerScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      expect(find.byType(StyleLogMainScreen), findsOneWidget);

      final tile = find.byType(StyleLogGalleryTile).first;
      final log = tester.widget<StyleLogGalleryTile>(tile).styleLog;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.textContaining('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'),
          findsOneWidget);
    });
  });

  // ── 2) Header/HUD Pinned Rule ────────────────────────────────────────────

  group('Header/HUD Pinned Rule — 카테고리 토글 + 더보기 버튼', () {
    testWidgets(
      '옷 상세 화면에서 카테고리 드롭다운과 더보기 버튼이 서로 독립된 위젯으로 겹치지 않게 배치되고, '
      '각자 탭에 반응한다(더보기 탭 → 화면 전환 없이 예외 없이 처리, 드롭다운 탭 → 메뉴 열림)',
      (tester) async {
        await pumpApp(tester);
        await tester.tap(find.byType(SelectableGalleryTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

        expect(categoryDropdownFinder(), findsOneWidget);
        final moreButton = find.byTooltip('더보기 메뉴');
        expect(moreButton, findsOneWidget);

        final dropdownRect = tester.getRect(categoryDropdownFinder());
        final moreButtonRect = tester.getRect(moreButton);
        expect(
          dropdownRect.overlaps(moreButtonRect),
          isFalse,
          reason: 'dropdown=$dropdownRect, more=$moreButtonRect',
        );

        // 더보기 탭 — onTap이 빈 함수라도 예외 없이 처리되고 화면 전환은 없어야 한다.
        await tester.tap(moreButton);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

        // 카테고리 드롭다운 탭 — 패널이 열려야 한다.
        await tester.tap(categoryDropdownFinder());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('코디'), findsWidgets);

        // 옵션을 고르지 않고 바깥을 탭해 닫아도 예외가 없어야 한다.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      },
    );

    testWidgets('코디 상세 화면에서도 카테고리 드롭다운과 더보기 버튼이 겹치지 않고 각각 존재하며 더보기 탭이 예외 없이 처리된다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(CompositionGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      final dropdownRect = tester.getRect(categoryDropdownFinder());
      final moreButtonRect = tester.getRect(find.byTooltip('더보기 메뉴'));
      expect(dropdownRect.overlaps(moreButtonRect), isFalse);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
    });

    testWidgets('스타일일지 상세 화면에서도 카테고리 드롭다운과 더보기 버튼이 겹치지 않고 각각 존재하며 더보기 탭이 예외 없이 처리된다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      final dropdownRect = tester.getRect(categoryDropdownFinder());
      final moreButtonRect = tester.getRect(find.byTooltip('더보기 메뉴'));
      expect(dropdownRect.overlaps(moreButtonRect), isFalse);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
    });

    testWidgets(
      '[비정형 흐름] 더보기 버튼을 pumpAndSettle 없이 연속으로 두 번 빠르게 탭해도 크래시 없이 처리된다',
      (tester) async {
        await pumpApp(tester);
        await tester.tap(find.byType(SelectableGalleryTile).first);
        await tester.pumpAndSettle();

        final moreButton = find.byTooltip('더보기 메뉴');
        await tester.tap(moreButton);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      },
    );
  });

  // ── 3) 뒤로가기 버튼 ──────────────────────────────────────────────────────

  group('뒤로가기 버튼 — Detail 3화면', () {
    testWidgets('옷 상세 화면에서 FrostedBackButton 탭 → 옷장 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SelectableGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
    });

    testWidgets('코디 상세 화면에서 FrostedBackButton 탭 → 코디 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(CompositionGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(CompositionDetailScreen), findsNothing);
    });

    testWidgets('스타일일지 상세 화면에서 FrostedBackButton 탭 → 스타일일지 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.byType(StyleLogViewerScreen), findsNothing);
    });
  });

  // ── 4) Detail 화면 skeleton body 렌더링 ──────────────────────────────────

  group('Detail 화면 skeleton body 렌더링(Task 3~5 전까지)', () {
    testWidgets('옷 상세 화면 하단에 연결된 코디/스타일일지 크로스 레퍼런스가 실제로 보인다(빈 화면처럼 보이지 않음)',
        (tester) async {
      await pumpApp(tester);
      final tile = find.byType(SelectableGalleryTile).first;
      final item = tester.widget<SelectableGalleryTile>(tile).item;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(item.id, 'c01'); // mock_data.dart 첫 항목은 comp01에 포함되어 크로스 레퍼런스가 비지 않음을 전제.
      expect(find.textContaining('데일리 룩'), findsOneWidget); // comp01.name
    });

    testWidgets('코디 상세 화면 하단에 연결된 스타일일지 크로스 레퍼런스가 보인다(mock 기준 comp01은 log01에 연결됨)',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(CompositionGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(find.textContaining('2026.1.5'), findsOneWidget); // log01.wornDate
    });

    testWidgets('스타일일지 상세 화면 하단에 연결된 코디 크로스 레퍼런스가 보인다(mock 기준 log01은 comp01에 연결됨)',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(find.textContaining('데일리 룩'), findsOneWidget); // comp01.name
    });
  });

  group('스크롤 동작', () {
    testWidgets(
      '옷 상세 화면 콘텐츠(이미지+메타데이터+크로스 레퍼런스)가 짧은 뷰포트에서 스크롤 가능하고, '
      'TopGradientOverlay/BottomGradientOverlay가 스크롤 위치에 따라 크래시 없이 전환된다',
      (tester) async {
        await pumpApp(tester, size: scrollableDetailSize);
        await tester.tap(find.byType(SelectableGalleryTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.byType(AppScrollContainer), findsOneWidget);

        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          scrollable.position.maxScrollExtent,
          greaterThan(0),
          reason: '이 시나리오는 실제로 스크롤 가능해야 의미가 있다',
        );

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, greaterThan(0));

        await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -2000), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
        expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));
      },
    );
  });

  // ── 6) Detail 화면에서 카테고리 드롭다운으로 다른 메인 이동 ─────────────────

  group('Detail 화면에서 카테고리 드롭다운으로 다른 메인 이동', () {
    testWidgets('옷 상세 화면에서 카테고리 드롭다운으로 "코디"를 선택하면 코디 메인으로 이동한다', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SelectableGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('코디').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
    });

    testWidgets('스타일일지 상세 화면에서 카테고리 드롭다운으로 "옷장"을 선택하면 옷장 메인으로 이동한다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷장').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsWidgets);
    });
  });
}
