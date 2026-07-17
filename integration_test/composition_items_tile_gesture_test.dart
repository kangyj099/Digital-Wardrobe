import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_items_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';

/// Tester 검증 — Task 10("옷 상세 '연결된 코디' 캐러셀 타일을 사용된 옷 스트립으로 교체",
/// commit `5a4c704`) Review 통과 후 남은 P2 갭 + 자체 보고된 제스처 경합 리스크 실측.
///
/// `closet_item_detail_data_binding_test.dart`가 이미 다룬 것(코디 이름 라벨 탭 → comp01
/// 상세로 정확히 이동, 연결된 코디가 없는 아이템의 빈 렌더링)과 `detail_thumbnail_square_
/// unification_test.dart`가 이미 다룬 것(정사각 비율, 짧은 뷰포트 스크롤 회귀, 2페이지 캐러셀
/// dot/드래그)은 다시 만들지 않는다. 이 파일은:
/// 1) 타일 안 "다른" 옷 이미지(c11) 탭 → 그 옷 자신의 상세로(comp01 상세가 아님) — Review의
///    P2(신규 탭 대상 미검증) 커버. comp01의 4개 아이템 썸네일이 실제로 (스크롤을 포함해) 전부
///    렌더링/식별 가능한지도 함께 확인한다.
/// 2) 자체 보고된 제스처 경합 리스크 실측 — 옷 이미지 위에서 드래그를 시작하면 캐러셀이 안
///    넘어가고 안쪽 스트립만 스크롤되는지, 라벨 영역에서 시작하면 실제로 캐러셀이 넘어가는지를
///    각각 확정한다(mock엔 다중 코디 연결 케이스가 없어 c01을 두 번째 코디에 임시로 더 연결).
/// 3) 비정형 조작 회귀 — 옷 이미지를 빠르게 연속으로 두 번 탭해도 상세 화면이 중복으로 쌓이지
///    않는지, 스트립을 스크롤한 채로 화면을 완전히 스크롤해도 예외/오버플로가 없는지.
///
/// 구현 메모(Tester): `ClothingItemsRow`의 각 썸네일은 `LayoutBuilder`가 계산한 `tileSize`가
/// 정사각 카드 너비(≈298px)에 육박할 만큼 커서, 스크롤 오프셋 0에서는 두 번째 아이템(c11)이
/// 전체 폭의 극히 일부(≈40px)만 노출된다 — `tester.getRect`로 얻는 위젯 전체 사각형의 중심은
/// 이 잘려나간 비가시 영역까지 포함하므로, 그 중심 좌표를 그대로 탭/드래그 시작점으로 쓰면 화면
/// 밖(혹은 클리핑된 영역 밖)을 때리는 잘못된 좌표가 된다. 그래서 이 파일은 (a) 탭 대상은 먼저
/// 스크롤로 완전히 노출시킨 뒤에 탭하고, (b) 드래그 시작점은 항상 이미 화면에 온전히 보이는
/// 아이템(첫 번째, c01 자신)을 쓴다 — 실제 사용자가 반쯤 잘린 아이템 위에서 제스처를 시작할
/// 가능성 자체는 별개 관찰 사항으로 아래 보고에 남긴다.
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

  Finder assetImageIn(Finder ancestor, String assetPath) => find.descendant(
        of: ancestor,
        matching: find.byWidgetPredicate(
          (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == assetPath,
        ),
      );

  bool hasAssetImage(String assetPath) => find
      .byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == assetPath,
      )
      .evaluate()
      .isNotEmpty;

  // ── 1) 타일 안 "다른" 옷 이미지 탭 → 그 옷 자신의 상세 (Review P2 커버) ───────

  group('연결된 코디 타일 — 다른 옷 이미지(c11) 탭 → c11 자신의 상세로', () {
    testWidgets(
      'c01 상세 진입 시 comp01 타일에 c01/c11/c07/c03 실제 썸네일이 모두(스크롤 포함) 렌더링되고, '
      'c11 이미지를 스크롤로 노출시켜 탭하면 comp01 상세가 아니라 c11(그래픽 맨투맨) 자신의 상세로 '
      '이동한다. 이어서 뒤로가기 → 코디 이름 라벨("데일리 룩") 탭 → comp01 상세로 이동한다',
      (tester) async {
        await pumpApp(tester);
        await tapItemById(tester, 'c01');

        final tileFinder = find.byType(CompositionItemsTile);
        expect(tileFinder, findsOneWidget);

        // 스크롤 오프셋 0에서 이미 보이는 첫 두 아이템(c01, c11 일부)이 실제 렌더링된다.
        expect(hasAssetImage('assets/images/mock/IMG_4259_preview_rev_1.png'), isTrue, reason: 'c01');
        expect(hasAssetImage('assets/images/mock/IMG_4262_preview_rev_1.png'), isTrue, reason: 'c11');
        expect(tester.takeException(), isNull);

        final c01ImageInTile = assetImageIn(tileFinder, 'assets/images/mock/IMG_4259_preview_rev_1.png');
        final c01Size = tester.getSize(c01ImageInTile);
        expect(c01Size.width, greaterThan(100), reason: '식별 가능한 크기로 렌더링돼야 한다');
        expect(c01Size.height, greaterThan(100));

        // 안쪽 스트립을 끝까지 스크롤해 c07/c03(뒤쪽 아이템)도 실제로 렌더링되는지 확인한다.
        final innerScrollableFinder =
            find.descendant(of: tileFinder, matching: find.byType(Scrollable));
        expect(innerScrollableFinder, findsOneWidget);
        final innerScrollable = tester.state<ScrollableState>(innerScrollableFinder);

        innerScrollable.position.jumpTo(innerScrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(hasAssetImage('assets/images/mock/IMG_4275.PNG'), isTrue, reason: 'c07 (스크롤 후)');
        expect(hasAssetImage('assets/images/mock/IMG_4261_preview_rev_1.png'), isTrue,
            reason: 'c03 (스크롤 후)');

        // c11을 화면에 완전히(잘리지 않게) 노출시킨 뒤 탭한다 — 아이템 1개 폭(≈298+8)만큼 스크롤.
        innerScrollable.position.jumpTo(306);
        await tester.pumpAndSettle();
        final c11ImageInTile = assetImageIn(tileFinder, 'assets/images/mock/IMG_4262_preview_rev_1.png');
        expect(c11ImageInTile, findsOneWidget);

        await tester.tap(c11ImageInTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsNothing,
            reason: '옷 이미지를 탭했으니 코디 상세가 아니라 그 옷 자신의 상세로 가야 한다');
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('그래픽 맨투맨'), findsOneWidget);

        // 뒤로가기 → c01 상세 복귀 → 이번엔 라벨(코디 이름)을 탭 → comp01 상세로.
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('플로럴 원피스'), findsOneWidget);

        final label = find.descendant(of: tileFinder, matching: find.text('데일리 룩'));
        expect(label, findsOneWidget);
        await tester.tap(label);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.byType(ClosetItemDetailScreen), findsNothing);
      },
    );
  });

  // ── 2) 제스처 경합 실측 — 옷 이미지 위 드래그 vs 라벨 영역 드래그 ───────────

  group('제스처 경합 실측 — 옷 이미지 위 드래그 vs 라벨 영역 드래그', () {
    testWidgets(
      'c01을 두 번째 코디에도 연결(임시 주입)한 뒤 — (a) 화면에 온전히 보이는 옷 이미지(c01 자신) '
      '위에서 드래그를 시작하면 캐러셀 페이지는 그대로고 안쪽 스트립만 스크롤된다. (b) 코디 이름 '
      '라벨 위에서 드래그를 시작하면 캐러셀이 실제로 다음 페이지로 넘어간다',
      (tester) async {
        final container = await pumpApp(tester);

        const extraComposition = Composition(
          id: 'test-comp-multi-item',
          name: '테스트 추가 코디',
          items: [
            CompositionItemPlacement(clothingItemId: 'c05', x: 0, y: 0),
            CompositionItemPlacement(clothingItemId: 'c06', x: 0, y: 0),
            CompositionItemPlacement(clothingItemId: 'c07', x: 0, y: 0),
            CompositionItemPlacement(clothingItemId: 'c08', x: 0, y: 0),
            CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0),
          ],
        );
        container.read(compositionsProvider.notifier).state = [
          ...container.read(compositionsProvider),
          extraComposition,
        ];

        final context = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c01'));
        await tester.pumpAndSettle();

        final tileFinder = find.byType(CompositionItemsTile);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(tileFinder, findsOneWidget);
        expect(find.textContaining('데일리 룩'), findsOneWidget, reason: '페이지 0은 comp01이어야 한다');

        double currentPage() => tester.widget<PageView>(find.byType(PageView)).controller!.page!;

        // (a) 화면에 온전히 보이는 옷 이미지(스트립 첫 아이템, c01 자신) 위에서 드래그 시작.
        final c01ImageInTile = assetImageIn(tileFinder, 'assets/images/mock/IMG_4259_preview_rev_1.png');
        expect(c01ImageInTile, findsOneWidget);
        final itemStart = tester.getRect(c01ImageInTile).center;

        final innerScrollableFinder =
            find.descendant(of: tileFinder, matching: find.byType(Scrollable));
        final innerScrollable = tester.state<ScrollableState>(innerScrollableFinder.first);
        final innerPixelsBefore = innerScrollable.position.pixels;

        await tester.dragFrom(itemStart, const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(currentPage(), closeTo(0, 0.05),
            reason: '옷 이미지 위에서 시작한 드래그는 캐러셀을 넘기지 못해야 한다(알려진 제스처 경합)');
        expect(find.textContaining('데일리 룩'), findsOneWidget, reason: '여전히 페이지 0(comp01)이어야 한다');
        final innerPixelsAfter = innerScrollable.position.pixels;
        expect(innerPixelsAfter, greaterThan(innerPixelsBefore),
            reason: '캐러셀 대신 안쪽 옷 스트립이 스크롤됐어야 한다');

        // (b) 라벨 영역 위에서 드래그 시작 — 실제로 캐러셀이 다음 페이지로 넘어가야 한다.
        final labelFinder = find.descendant(of: tileFinder, matching: find.text('데일리 룩'));
        expect(labelFinder, findsOneWidget);

        await tester.drag(labelFinder, const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(currentPage(), closeTo(1, 0.05),
            reason: '라벨 영역에서 시작한 드래그는 캐러셀을 다음 페이지로 넘겨야 한다');
        expect(find.textContaining('테스트 추가 코디'), findsOneWidget);
      },
    );
  });

  // ── 3) 비정형 조작/일반 회귀 ────────────────────────────────────────────────

  group('비정형 조작 — 옷 이미지 빠른 연속 탭', () {
    testWidgets('c11 이미지를 빠르게 두 번 연속 탭해도 상세 화면이 중복으로 쌓이지 않는다', (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      final tileFinder = find.byType(CompositionItemsTile);
      final innerScrollableFinder = find.descendant(of: tileFinder, matching: find.byType(Scrollable));
      final innerScrollable = tester.state<ScrollableState>(innerScrollableFinder);
      innerScrollable.position.jumpTo(306);
      await tester.pumpAndSettle();

      final c11ImageInTile = assetImageIn(tileFinder, 'assets/images/mock/IMG_4262_preview_rev_1.png');
      expect(c11ImageInTile, findsOneWidget);

      // settle을 기다리지 않고 곧바로 두 번 연속 탭 — 전환 애니메이션 도중 두 번째 탭이
      // 겹치는 비정형 조작.
      await tester.tap(c11ImageInTile);
      await tester.pump();
      await tester.tap(c11ImageInTile, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // c11 상세가 정확히 1개만 스택에 쌓여야 한다(중복 push 없음).
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('플로럴 원피스'), findsOneWidget,
          reason: '두 번째 탭이 중복 push였다면 뒤로가기 한 번으로는 c01로 못 돌아왔을 것이다');
    });
  });

  group('일반 회귀 — 짧은 뷰포트에서 타일 스크롤 + 화면 전체 스크롤 동시', () {
    testWidgets('아이템 스트립을 스크롤한 채로 화면 전체를 끝까지 스크롤해도 예외/오버플로가 없다', (tester) async {
      await pumpApp(tester, size: const Size(390, 500));
      await tapItemById(tester, 'c01');
      expect(tester.takeException(), isNull);

      final tileFinder = find.byType(CompositionItemsTile);
      expect(find.byType(CompositionPreviewCarousel), findsOneWidget);
      final innerScrollableFinder = find.descendant(of: tileFinder, matching: find.byType(Scrollable));
      final innerScrollable = tester.state<ScrollableState>(innerScrollableFinder);
      innerScrollable.position.jumpTo(innerScrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final galleryFinder = find.byType(StyleLogCrossReferenceGallery);
      expect(galleryFinder, findsOneWidget);
      final galleryBottom = tester.getBottomLeft(galleryFinder).dy;
      final viewportHeight = tester.getSize(find.byType(Scaffold).first).height;
      expect(viewportHeight - galleryBottom, lessThan(80),
          reason: '타일 내부 스크롤 상태와 무관하게 화면 전체 스크롤은 정상적으로 끝까지 도달해야 한다');
    });
  });
}
