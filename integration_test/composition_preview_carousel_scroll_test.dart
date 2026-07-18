import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 11(`CompositionPreviewCarousel`을 `PageView`+점 인디케이터에서
/// "착용 옷"과 동일한 연속 스크롤 리스트로 교체, commit `5540dd4`). 이 기능 3번째 시도(2회
/// 되돌림 이력)라 특히 꼼꼼히 확인한다.
///
/// `detail_thumbnail_square_unification_test.dart`(Review가 이미 확인·통과)가 이미 다룬 것
/// (96×96 고정 크기, PageView 부재, 첫/마지막 카드 탭 내비게이션, 회귀 스윕, 임시 5개 코디
/// 오버플로+드래그)은 다시 만들지 않는다. 이 파일은 그 스위트가 다루지 않은 것만 확인한다:
/// 1) c01의 실제(mock 그대로, 주입 없음) 단일 링크(comp01) 카드에 이미지가 실제로 렌더링되는가.
/// 2) 5개 중 "중간" 카드(처음도 끝도 아닌)를 탭해도 정확히 그 코디로 이동하는가 — 첫/끝만
///    확인하면 index 매핑 버그를 놓칠 수 있다.
/// 3) 임의 픽셀만큼 드래그했을 때, 타일 폭(96+separator 8=104) 배수 근처로 스냅되지 않고
///    드래그한 만큼(제스처 인식 slop 오차 감안) 그대로 멈추는가.
/// 4) `style_log_viewer_screen.dart`의 "착용 옷" 행과 실제로 같은 스크롤 물리(physics)를
///    쓰는가 — 이번 라운드가 요구한 "동일한 메커니즘"의 정량적 근거.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 844);

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = defaultSize;
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

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  // ── 1) c01(주입 없는 실제 mock 상태) — 단일 카드에 이미지가 실제로 보인다 ──────

  testWidgets('c01(comp01에만 연결된 실제 mock 상태) — 코디 카드에 이미지가 실제로 렌더링되고 탭하면 '
      'comp01 상세로 정확히 이동한다', (tester) async {
    await pumpApp(tester);

    final tile = find.byWidgetPredicate((w) => w is SelectableGalleryTile && w.item.id == 'c01');
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
    final cardFinder = find.byType(CompositionPreviewCard);
    expect(cardFinder, findsOneWidget, reason: 'c01은 comp01 하나에만 연결되어 카드가 1개여야 한다');

    // 실제 이미지가 (플레이스홀더 배경색만이 아니라) 렌더링되었는지 확인.
    final imageFinder = find.descendant(of: cardFinder, matching: find.byType(Image));
    expect(imageFinder, findsOneWidget, reason: 'compositionCoverImageProvider 폴백으로 실제 썸네일이 보여야 한다');
    expect(find.textContaining('데일리 룩'), findsOneWidget, reason: 'comp01.name이 카드에 라벨로 보여야 한다');
    expect(tester.takeException(), isNull);

    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionDetailScreen), findsOneWidget);
    expect(find.text('데일리 룩'), findsOneWidget);
  });

  // ── 2) "중간" 카드 탭 — index 매핑 정확성 ────────────────────────────────────

  testWidgets('c01을 코디 5개에 연결한 뒤, 처음도 끝도 아닌 "중간" 카드(3번째)를 탭해도 정확히 그 '
      '코디로 이동한다', (tester) async {
    final container = await pumpApp(tester);

    final extraCompositions = [
      for (var i = 1; i <= 4; i++)
        Composition(
          id: 'test-mid-comp-$i',
          name: '중간확인용 코디 $i',
          items: const [CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0)],
        ),
    ];
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      ...extraCompositions,
    ];

    final context = tester.element(find.byType(ClosetMainScreen));
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c01'));
    await tester.pumpAndSettle();
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

    // 순서: comp01(데일리 룩), 중간확인용 코디 1~4. 3번째 카드 = "중간확인용 코디 2"(index 2).
    await tester.tap(find.textContaining('중간확인용 코디 2'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionDetailScreen), findsOneWidget);
    expect(find.text('중간확인용 코디 2'), findsOneWidget);
    // 다른 코디로 잘못 이동하지 않았는지 함께 확인.
    expect(find.text('중간확인용 코디 1'), findsNothing);
    expect(find.text('중간확인용 코디 3'), findsNothing);
  });

  // ── 3) 페이지 스냅이 없다 — 임의 픽셀 드래그 후 타일 배수로 스냅되지 않는다 ──────

  testWidgets('타일+여백 배수(104px) 근처가 아닌 위치로 드래그하면, 그 배수로 스냅되지 않고 드래그한 '
      '위치 근처(제스처 인식 slop 오차 이내)에서 그대로 멈춘다(PageView 페이지 스냅과의 결정적 차이)',
      (tester) async {
    final container = await pumpApp(tester);

    final extraCompositions = [
      for (var i = 1; i <= 6; i++)
        Composition(
          id: 'test-snap-comp-$i',
          name: '스냅확인용 코디 $i',
          items: const [CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0)],
        ),
    ];
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      ...extraCompositions,
    ];

    final context = tester.element(find.byType(ClosetMainScreen));
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c01'));
    await tester.pumpAndSettle();

    final carouselFinder = find.byType(CompositionPreviewCarousel);
    final scrollableFinder =
        find.descendant(of: carouselFinder, matching: find.byType(Scrollable)).first;
    final scrollable = tester.state<ScrollableState>(scrollableFinder);

    // 타일(96)+separator(AppSpacing.xs=8)=104가 "한 페이지" 단위였다면 스냅 대상이 104/208
    // 이었을 것. 170만큼 드래그를 요청하면(제스처 인식 slop으로 실 이동량은 다소 줄어들 수
    // 있음) 그 결과가 104/208 어느 쪽에도 가깝지 않아야, 스냅이 없다는 게 의미있게 증명된다.
    await tester.drag(carouselFinder, const Offset(-170, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // 스냅 애니메이션이 있다면 끝날 시간을 준다.

    expect(tester.takeException(), isNull);
    expect(
      scrollable.position.pixels,
      closeTo(150, 25), // 제스처 slop(약 18~20px) 감안한 넉넉한 허용치.
      reason: '연속 스크롤 리스트라면 드래그 거리에 (slop 오차 이내로) 비례해 멈춰야 한다',
    );
    expect(
      scrollable.position.pixels,
      isNot(closeTo(104, 15)),
      reason: '타일 1개 폭(104) 근처로 스냅되면 안 된다',
    );
    expect(
      scrollable.position.pixels,
      isNot(closeTo(208, 15)),
      reason: '타일 2개 폭(208) 근처로 스냅되면 안 된다',
    );
  });

  // ── 4) style_log_viewer의 "착용 옷" 행과 동일한 스크롤 물리(physics) ────────────

  testWidgets('코디 캐러셀(옷 상세)과 "착용 옷" 행(스타일일지 열람, log01)이 같은 종류의 '
      'Scrollable/physics를 쓴다(둘 다 PageScrollPhysics가 아니고, 서로 같은 runtimeType)',
      (tester) async {
    final container = await pumpApp(tester);

    final extraCompositions = [
      for (var i = 1; i <= 4; i++)
        Composition(
          id: 'test-phys-comp-$i',
          name: '물리확인용 코디 $i',
          items: const [CompositionItemPlacement(clothingItemId: 'c01', x: 0, y: 0)],
        ),
    ];
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      ...extraCompositions,
    ];

    final closetContext = tester.element(find.byType(ClosetMainScreen));
    GoRouter.of(closetContext).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c01'));
    await tester.pumpAndSettle();

    final carouselFinder = find.byType(CompositionPreviewCarousel);
    final carouselScrollable =
        find.descendant(of: carouselFinder, matching: find.byType(Scrollable)).first;
    final carouselPhysics = tester.widget<Scrollable>(carouselScrollable).physics;

    expect(
      carouselPhysics,
      isNot(isA<PageScrollPhysics>()),
      reason: '더 이상 페이지 스냅 물리를 쓰면 안 된다',
    );

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();

    await goToCategory(tester, '스타일일지');
    // mock은 wornDate 내림차순 정렬이라 log02(1/10)가 log01(1/5)보다 먼저 온다. log02는
    // additionalImagePaths가 비어 "착용 옷" 행 자체가 없으므로, 그 섹션이 실제로 있는
    // log01 타일을 명시적으로 골라 탭한다.
    final log01Tile = find.byWidgetPredicate(
      (w) => w is StyleLogGalleryTile && w.styleLog.id == 'log01',
    );
    expect(log01Tile, findsOneWidget);
    await tester.tap(log01Tile);
    await tester.pumpAndSettle();

    expect(find.text('착용 옷'), findsOneWidget, reason: 'log01은 additionalImagePaths가 있어 이 섹션이 보여야 한다');
    final wornRowFinder = find.byWidgetPredicate((w) => w is SizedBox && w.height == 96).first;
    final wornRowScrollable =
        find.descendant(of: wornRowFinder, matching: find.byType(Scrollable)).first;
    final wornRowPhysics = tester.widget<Scrollable>(wornRowScrollable).physics;

    expect(
      wornRowPhysics.runtimeType,
      carouselPhysics.runtimeType,
      reason: '"착용 옷"과 코디 캐러셀은 동일한 스크롤 메커니즘을 쓰기로 한 것이 이번 Task의 요구사항이다',
    );
    expect(tester.takeException(), isNull);
  });
}
