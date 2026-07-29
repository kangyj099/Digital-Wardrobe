import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 9("옷장 상세 정사각형 통일 + crossReferenceEntries/CrossReferenceLinkBar
/// 폐기", commit `732c57b`, 9-Task 플랜의 마지막 Task). **Task 11(`CompositionPreviewCarousel`을
/// `PageView`+점 인디케이터에서 "착용 옷"과 동일한 연속 스크롤 리스트로 교체, `docs/history/
/// Decision.md` 참고)에서 그룹 1/5의 캐러셀 관련 assertion을 새 동작 기준으로 다시 작성했다** —
/// 그룹 2/3/4는 스타일일지 정사각/2:1 분기·회귀 스윕이라 영향 없음(탭 대상만 컨테이너에서 실제
/// 카드로 보정).
///
/// `detail_cross_reference_visuals_test.dart`/`detail_screens_header_hud_test.dart`가 이미
/// 확인한 것(위젯 존재, 빈 상태 0 높이, comp01/comp02의 2:1 타일)은 다시 만들지 않는다. 이
/// 파일은 그 스위트들이 다루지 않는 핵심 동작만 확인한다:
/// 1) 옷 상세(c01)의 코디 캐러셀이 고정 96×96 타일의 연속 스크롤 리스트로 렌더링되는가(더 이상
///    페이지 단위 AspectRatio(1) 풀블리드 정사각형이 아님, Task 11).
/// 2) 옷 상세(c01)의 스타일일지 타일이 (연결 1개뿐인데도) 정사각형인가.
/// 3) 코디 상세(comp01/comp02)의 스타일일지 타일도 이제 정사각형인가(Task 12 — "1개면
///    2칸 확대" 규칙 폐기, `expandSingle` 파라미터 자체가 제거되어 두 화면이 더 이상 다르게
///    보이지 않는다).
/// 4) 양쪽 Detail 화면 회귀 스윕 — 예외/오버플로 없음, `CrossReferenceLinkBar` 삭제 이후 잔여
///    빈 공간이 없음(마지막 콘텐츠 위젯이 화면 하단 근처에 온다).
/// 5) mock엔 없는 "옷 1개가 코디 5개/스타일일지 2개에 연결된" 상태를 임시로 구성해 캐러셀의
///    연속 스크롤 오버플로(페이지 스냅 없이 여러 카드가 동시 표시 + 드래그로 뒤쪽 카드 도달)와
///    스타일일지 2열 그리드가 정상 동작하는지 확인.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 844);

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

  Future<void> tapItemById(WidgetTester tester, String itemId) async {
    final tile = find.byWidgetPredicate((w) => w is SelectableGalleryTile && w.item.id == itemId);
    expect(tile, findsOneWidget, reason: '아이템 $itemId 타일을 옷장 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapCompositionById(WidgetTester tester, String compositionId) async {
    final tile = find.byWidgetPredicate(
      (w) => w is CompositionGalleryTile && w.composition.id == compositionId,
    );
    expect(tile, findsOneWidget, reason: '코디 $compositionId 타일을 코디 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  // ── 1) 옷 상세(c01) — 코디 캐러셀은 고정 타일 크기의 연속 스크롤 리스트 ──────

  group(
      '옷 상세(c01) — 코디 캐러셀은 "착용 옷"과 동일한 고정 96×96 타일의 연속 스크롤 리스트'
      '(Task 11 — 더 이상 페이지 단위 AspectRatio(1) 풀블리드 정사각형이 아님)', () {
    testWidgets('CompositionPreviewCarousel 컨테이너 높이는 고정 타일 크기(96)이고, 내부 카드도 96×96 정사각형이다',
        (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      final carouselFinder = find.byType(CompositionPreviewCarousel);
      expect(carouselFinder, findsOneWidget);
      final size = tester.getSize(carouselFinder);

      expect(
        size.height,
        closeTo(96, 0.5),
        reason: '"착용 옷" 타일과 동일한 스케일의 고정 타일 높이(96)여야 한다(Task 9의 고정 200px과도 다름)',
      );
      expect(
        size.width,
        isNot(closeTo(size.height, 0.5)),
        reason: '더 이상 AspectRatio(1) 풀블리드 정사각형이 아니다 — 위젯 너비는 화면 콘텐츠 폭(패딩 제외) 전체다',
      );

      final cardFinder = find.byType(CompositionPreviewCard);
      expect(cardFinder, findsOneWidget);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, closeTo(96, 0.5));
      expect(cardSize.height, closeTo(96, 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  // ── 2) 옷 상세(c01) — 스타일일지 타일도 정사각형(1개뿐이어도 확대 안 함) ──────

  group('옷 상세(c01) — 스타일일지 타일은 1개뿐이어도 정사각형', () {
    testWidgets('StyleLogGalleryTile 1개가 2:1 와이드가 아니라 실제로 정사각(비율 ≈ 1)으로 렌더링된다',
        (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);

      expect(
        size.width / size.height,
        closeTo(1, 0.05),
        reason: '옷 상세는 1개여도 정사각 타일이어야 한다(2:1 와이드가 아님)',
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── 3) 코디 상세(comp01/comp02) — 스타일일지 타일도 이제 정사각형(Task 12) ──

  group('코디 상세 — 스타일일지 타일은 연결 1개뿐이어도 이제 정사각형(Task 12, "1개면 2칸 확대" 규칙 폐기)', () {
    testWidgets('CompositionDetailScreen(comp01)의 StyleLogGalleryTile은 더 이상 2:1이 아니라 정사각(비율 ≈ 1)으로 렌더링된다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);

      expect(
        size.width / size.height,
        closeTo(1, 0.05),
        reason: 'Task 12 이후로는 옷 상세와 동일하게 코디 상세도 연결 개수와 무관하게 항상 정사각형이어야 '
            '한다(expandSingle 파라미터 자체가 제거됨)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      // [갱신, Task 7 이후 comp02 소프트삭제] 원래 comp02(log02 직접 연결)로 검증했으나 comp02가
      // 코디 메인에서 더 이상 보이지 않는다 — comp03에 런타임 주입 스타일일지 1장으로 "다른 코디도
      // 동일하게 정사각인가"라는 동일 의도를 재현한다.
      'CompositionDetailScreen(comp03, 런타임 주입 스타일일지)의 StyleLogGalleryTile도 동일하게 '
      '정사각(비율 ≈ 1)으로 렌더링된다',
      (tester) async {
        final container = await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp03');

        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          StyleLog(
            id: 'test-comp03-log-square-unif',
            coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
            wornDate: DateTime(2026, 1, 10),
            linkedCompositionId: 'comp03',
          ),
        ];
        await tester.pumpAndSettle();

        final tileFinder = find.byType(StyleLogGalleryTile);
        expect(tileFinder, findsOneWidget);
        final size = tester.getSize(tileFinder);

        expect(size.width / size.height, closeTo(1, 0.05));
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── 4) 회귀 스윕 — 양쪽 Detail 화면, 예외/오버플로/잔여 빈 공간 없음 ──────────

  group('회귀 스윕 — 옷 상세/코디 상세, CrossReferenceLinkBar 삭제 이후 잔여 빈 공간 없음', () {
    testWidgets('옷 상세(c01) 짧은 뷰포트 — 끝까지 스크롤해도 예외 없고, 마지막 콘텐츠(스타일일지 갤러리) '
        '바로 아래에 큰 빈 공간이 남지 않는다', (tester) async {
      await pumpApp(tester, size: const Size(390, 500));
      await tapItemById(tester, 'c01');
      expect(tester.takeException(), isNull);

      final scrollableFinder = find
          .descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable))
          .first;
      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));

      final galleryFinder = find.byType(StyleLogCrossReferenceGallery);
      expect(galleryFinder, findsOneWidget);
      final galleryBottom = tester.getBottomLeft(galleryFinder).dy;
      final viewportHeight = tester.getSize(find.byType(Scaffold).first).height;
      expect(
        viewportHeight - galleryBottom,
        lessThan(80),
        reason: '갤러리 하단과 화면 하단 사이에 옛 CrossReferenceLinkBar(64px 고정)급 빈 공간이 '
            '남아있지 않아야 한다',
      );
    });

    testWidgets('코디 상세(comp01) 짧은 뷰포트 — 끝까지 스크롤해도 예외 없고, 잔여 빈 공간이 남지 않는다',
        (tester) async {
      await pumpApp(tester, size: const Size(390, 500));
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');
      expect(tester.takeException(), isNull);

      final scrollableFinder = find
          .descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable))
          .first;
      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));

      final galleryFinder = find.byType(StyleLogCrossReferenceGallery);
      expect(galleryFinder, findsOneWidget);
      final galleryBottom = tester.getBottomLeft(galleryFinder).dy;
      final viewportHeight = tester.getSize(find.byType(Scaffold).first).height;
      expect(viewportHeight - galleryBottom, lessThan(80));
    });

    testWidgets('비정형 흐름 — 옷 상세 ↔ 코디 상세를 빠르게 오가도 크래시/잔상 없다', (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      final compositionCard = find.byType(CompositionPreviewCard);
      expect(compositionCard, findsOneWidget);
      // 빠르게 연속으로 탭 → 뒤로가기 → 다시 탭(사용자가 빠르게 오가는 비정형 조작).
      // 연속 스크롤 리스트가 되면서 캐러셀 컨테이너 자체는 화면 폭 전체를 차지하므로(실제
      // 카드는 그 안의 96×96 타일 하나뿐), 탭은 반드시 실제 카드(CompositionPreviewCard)를
      // 대상으로 해야 한다 — 컨테이너 중앙을 탭하면 카드 밖 빈 스크롤 영역을 맞출 수 있다.
      await tester.tap(compositionCard);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pump();
      await tester.tap(find.byType(CompositionPreviewCard));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
    });
  });

  // ── 5) 임시 구성 — 옷 1개가 코디 여러 개/스타일일지 2개에 연결된 경우 ─────────

  group(
      '임시 구성(mock 데이터엔 없음) — 코디 캐러셀 연속 스크롤 오버플로(Task 11) + 스타일일지 2열 그리드', () {
    testWidgets(
      'c01을 코디 5개(comp01 + 임시 4개)에 포함시키면 여러 코디 카드가 스크롤 없이 동시에 보이고, '
      '타일 총 폭이 화면 폭을 넘어 실제로 가로 스크롤이 가능해지며, 드래그로 뒤쪽 카드까지 탭할 수 '
      '있다(페이지 스냅 없는 연속 스크롤 — PageView가 아님). 스타일일지도 comp01에 하나 더 연결하면 '
      '2열 그리드(정사각 2칸)로 바뀐다',
      (tester) async {
        final container = await pumpApp(tester);

        final extraCompositions = [
          for (var i = 1; i <= 4; i++)
            Composition(
              id: 'test-extra-comp-$i-for-c01',
              name: '임시 추가 코디 $i',
              createdAt: DateTime(2025, 1, 1),
              items: const [CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0)],
            ),
        ];
        container.read(compositionsProvider.notifier).state = [
          ...container.read(compositionsProvider),
          ...extraCompositions,
        ];

        final extraStyleLog = StyleLog(
          id: 'test-extra-log-for-comp01',
          coverImagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png',
          wornDate: DateTime(2026, 3, 1),
          linkedCompositionId: 'comp01',
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          extraStyleLog,
        ];

        final context = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c01'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

        // 캐러셀 — 더 이상 PageView가 아니라 연속 스크롤 리스트다. 여러 카드가 드래그 없이도
        // 동시에 보인다(코디 상세로 진입해 하나만 보이는 옛 PageView 방식과의 결정적 차이).
        final carouselFinder = find.byType(CompositionPreviewCarousel);
        expect(carouselFinder, findsOneWidget);
        expect(
          find.descendant(of: carouselFinder, matching: find.byType(PageView)),
          findsNothing,
          reason: 'Task 11 이후로는 페이지 개념 자체가 없다',
        );
        expect(find.textContaining('데일리 룩'), findsOneWidget); // comp01, 1번째 타일
        expect(find.textContaining('임시 추가 코디 1'), findsOneWidget); // 2번째 타일, 드래그 없이 동시 표시

        // 타일 5개(96×5 + separator 4×8)가 화면 콘텐츠 폭을 넘어 실제로 스크롤 가능해야 한다.
        final scrollableFinder =
            find.descendant(of: carouselFinder, matching: find.byType(Scrollable));
        expect(scrollableFinder, findsOneWidget);
        final scrollable = tester.state<ScrollableState>(scrollableFinder);
        expect(
          scrollable.position.maxScrollExtent,
          greaterThan(0),
          reason: '5개 타일 총 폭이 화면 폭을 넘어야 이 시나리오가 의미가 있다',
        );

        // 실제 드래그(페이지 스냅 없는 연속 스크롤)로 더 뒤쪽 카드까지 이동한다.
        await tester.drag(carouselFinder, const Offset(-400, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, greaterThan(0));
        expect(find.textContaining('임시 추가 코디 4'), findsOneWidget);

        // 드래그로 도달한 마지막 카드도 실제로 탭 가능하고 정확한 코디 상세로 이동한다.
        await tester.tap(find.textContaining('임시 추가 코디 4'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('임시 추가 코디 4'), findsOneWidget);

        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

        // 스타일일지 — 2개가 되었으니 이제 2열 그리드(정사각 타일 2개), 더 이상 단일 확대가 아니다.
        final tiles = find.byType(StyleLogGalleryTile);
        expect(tiles, findsNWidgets(2));
        for (final element in tiles.evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(
            size.width / size.height,
            closeTo(1, 0.05),
            reason: '2개 이상이면 옷 상세든 코디 상세든 항상 정사각 2열이어야 한다',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  });
}
