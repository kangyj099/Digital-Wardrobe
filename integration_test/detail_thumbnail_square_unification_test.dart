import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 9("옷장 상세 정사각형 통일 + crossReferenceEntries/CrossReferenceLinkBar
/// 폐기", commit `732c57b`, 9-Task 플랜의 마지막 Task).
///
/// `detail_cross_reference_visuals_test.dart`/`detail_screens_header_hud_test.dart`가 이미
/// 확인한 것(위젯 존재, 빈 상태 0 높이, comp01/comp02의 2:1 타일)은 다시 만들지 않는다. 이
/// 파일은 그 스위트들이 다루지 않는, Task 9가 실제로 바꾼 핵심 동작만 확인한다:
/// 1) 옷 상세(c01)의 코디 캐러셀이 실제로 정사각형(고정 200px/0.82 peek 아님)으로 렌더링되는가.
/// 2) 옷 상세(c01)의 스타일일지 타일이 (연결 1개뿐인데도) 정사각형인가 — `expandSingle: false`
///    오버라이드가 실제로 반영되는지.
/// 3) 코디 상세(comp01)의 스타일일지 타일은 여전히 2:1 와이드인가 — 두 화면이 "연결 1개"
///    케이스에서 실제로 다르게 보인다는 분기 증거.
/// 4) 양쪽 Detail 화면 회귀 스윕 — 예외/오버플로 없음, `CrossReferenceLinkBar` 삭제 이후 잔여
///    빈 공간이 없음(마지막 콘텐츠 위젯이 화면 하단 근처에 온다).
/// 5) mock엔 없는 "옷 1개가 코디 2개/스타일일지 2개에 연결된" 상태를 임시로 구성해 캐러셀
///    다중 페이지(dot 2개)와 스타일일지 2열 그리드가 정상 동작하는지 확인.
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
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>));
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

  // ── 1) 옷 상세(c01) — 코디 캐러셀 실제 정사각형 렌더링 ──────────────────────

  group('옷 상세(c01) — 코디 캐러셀 실제 정사각형 렌더링(고정 200px/0.82 peek 아님)', () {
    testWidgets('CompositionPreviewCarousel의 실제 렌더 크기가 width == height(AspectRatio(1))다',
        (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      final carouselFinder = find.byType(CompositionPreviewCarousel);
      expect(carouselFinder, findsOneWidget);
      final size = tester.getSize(carouselFinder);

      expect(size.height, isNot(200), reason: 'Task 9 이전의 고정 200px 카드 높이가 남아있으면 안 된다');
      expect(
        size.width,
        closeTo(size.height, 0.5),
        reason: 'AspectRatio(1) 풀블리드 정사각형이어야 한다(옛 0.82 viewport-peek 형태가 아님)',
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── 2) 옷 상세(c01) — 스타일일지 타일도 정사각형(1개뿐이어도 확대 안 함) ──────

  group('옷 상세(c01) — 스타일일지 타일은 1개뿐이어도 정사각형(expandSingle: false)', () {
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
        reason: '옷 상세는 expandSingle: false라 1개여도 정사각 타일이어야 한다(2:1 와이드가 아님)',
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── 3) 코디 상세(comp01) — 스타일일지 타일은 여전히 2:1(승인된 스펙, 변경 없음) ──

  group('코디 상세(comp01) — 스타일일지 타일은 여전히 2:1 와이드(회귀 확인, 변경 없어야 함)', () {
    testWidgets('CompositionDetailScreen의 StyleLogGalleryTile은 여전히 가로 2칸 확대 비율(≈2)로 렌더링된다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);

      expect(
        size.width / size.height,
        closeTo(2, 0.05),
        reason: '코디 상세는 expandSingle 기본값(true)이 유지되어 여전히 2:1이어야 한다 — 옷 상세와 '
            '달라야 이번 Task의 의도한 분기다',
      );
      expect(tester.takeException(), isNull);
    });
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

      final compositionCard = find.byType(CompositionPreviewCarousel);
      expect(compositionCard, findsOneWidget);
      // 빠르게 연속으로 탭 → 뒤로가기 → 다시 탭(사용자가 빠르게 오가는 비정형 조작).
      // 코디 이름 라벨(배경 영역)을 탭한다 — 옷 이미지 영역을 탭하면 개별 옷 상세로 가는
      // onItemTap이 대신 발동하므로(Task 10, 두 탭 대상 분리), 코디 상세로 가려면 반드시
      // 라벨/배경을 탭해야 한다. 캐러셀 안으로 범위를 좁혀 찾는다 — 뒤로가기 전환 애니메이션
      // 도중엔 CompositionDetailScreen의 headlineSmall 제목("데일리 룩")도 동시에 트리에
      // 남아있어 범위를 안 좁히면 findText가 모호해진다.
      final compositionLabel =
          find.descendant(of: compositionCard, matching: find.text('데일리 룩'));
      await tester.tap(compositionLabel);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pump();
      await tester.tap(compositionLabel);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
    });
  });

  // ── 5) 임시 구성 — 옷 1개가 코디 2개/스타일일지 2개에 연결된 경우 ────────────

  group('임시 구성(mock 데이터엔 없음) — 코디 2개 캐러셀 다중 페이지 + 스타일일지 2열 그리드', () {
    testWidgets(
      'c01을 두 번째 코디에도 포함시키면 캐러셀이 2페이지가 되어 실제 드래그로 페이지 전환이 된다. '
      '스타일일지도 comp01에 하나 더 연결하면 2열 그리드(정사각 2칸)로 바뀐다',
      (tester) async {
        final container = await pumpApp(tester);

        const extraComposition = Composition(
          id: 'test-extra-comp-for-c01',
          name: '임시 추가 코디',
          items: [
            CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0),
          ],
        );
        container.read(compositionsProvider.notifier).state = [
          ...container.read(compositionsProvider),
          extraComposition,
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

        // 캐러셀 — 2페이지.
        expect(find.byType(CompositionPreviewCarousel), findsOneWidget);
        final pageViewSize = tester.getSize(find.byType(PageView));
        expect(pageViewSize.width, closeTo(pageViewSize.height, 0.5));
        expect(find.textContaining('데일리 룩'), findsOneWidget);

        // 코디 이름 라벨 위에서 드래그를 시작한다 — 옷 이미지 스트립(ClothingItemsRow) 위에서
        // 시작하면 같은 가로축 제스처 경합으로 안쪽 리스트가 드래그를 먼저 가져가 캐러셀
        // 페이지가 안 넘어갈 수 있다(Task 10 설계 노트의 알려진 리스크 — 라벨 영역이
        // 스와이프 시작 여지로 남겨둔 non-list 표면).
        await tester.drag(find.text('데일리 룩'), const Offset(-400, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('임시 추가 코디'), findsOneWidget);

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
