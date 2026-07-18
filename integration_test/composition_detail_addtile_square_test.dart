import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 12(코디 상세 "연결된 스타일일지" 썸네일 정사각(1:1) 통일, commit
/// `424e84f`) 후속 확인.
///
/// `detail_cross_reference_visuals_test.dart`/`detail_thumbnail_square_unification_test.dart`
/// /`composition_detail_data_binding_test.dart`가 이미 확인한 것(comp01/comp02의 연결된
/// 스타일일지 타일이 정사각으로 렌더링되는지, 탭 시 실제 스타일일지 열람으로 이동하는지,
/// "+" 타일 탭 → 선택 모달 → 복귀 후 바인딩되는 엔드투엔드 흐름 자체)은 다시 만들지 않는다.
/// 이 파일은 그 스위트들이 놓친 것만 확인한다:
/// 1) 연결이 0개인 코디의 "+" 타일이 실제로 정사각(1:1) 비율로, 단일 타일로만, 다른 요소와
///    겹치지 않고 렌더링되는가(2:1 → 1:1 전환으로 타일이 더 커졌으니 레이아웃이 깨지지 않는지).
/// 2) 그 "+" 타일이 있는 화면을 짧은 뷰포트에서 스크롤해도(타일이 더 커졌으므로) 오버플로/
///    예외가 없는가.
/// 3) 옷 상세와 코디 상세가 동일한 연결 스타일일지 타일 시각 처리(정사각 비율)를 공유하는가
///    (두 화면을 같은 세션에서 오가며 직접 비교).
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

  ProviderContainer pushUnlinkedComposition(WidgetTester tester, ProviderContainer container,
      {required String id, required String name}) {
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      Composition(id: id, name: name, items: const []),
    ];
    final context = tester.element(find.byType(ClosetMainScreen));
    GoRouter.of(context).push(AppRoute.compositionDetail.replaceFirst(':id', id));
    return container;
  }

  group('연결 0개 코디 — "+" 타일은 정사각형, 단일 타일, 겹침 없음', () {
    testWidgets(
      '"+" 타일이 AspectRatio(1)로 렌더링되고, 아이콘/라벨은 정확히 하나씩만 존재하며, '
      '"사용된 옷" 섹션과 겹치지 않는다',
      (tester) async {
        final container = await pumpApp(tester);
        pushUnlinkedComposition(tester, container, id: 'test-square-empty', name: '빈 연결 코디');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);

        // 단일 타일만 존재 — 아이콘/라벨이 중복 렌더링되지 않는다.
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('스타일일지 연결하기'), findsOneWidget);
        expect(find.byType(StyleLogGalleryTile), findsNothing);

        final addTileAspectRatio = find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(AspectRatio),
        );
        expect(addTileAspectRatio, findsOneWidget);
        final aspectRatioWidget = tester.widget<AspectRatio>(addTileAspectRatio);
        expect(
          aspectRatioWidget.aspectRatio,
          1,
          reason: 'Task 12 이후 "+" 타일도 항상 정사각(1:1)이어야 한다(과거 2:1에서 전환)',
        );

        final renderedSize = tester.getSize(addTileAspectRatio);
        expect(renderedSize.width, greaterThan(0));
        expect(renderedSize.height, greaterThan(0));
        expect(
          renderedSize.width / renderedSize.height,
          closeTo(1, 0.05),
          reason: '선언된 aspectRatio뿐 아니라 실제 렌더 크기도 정사각이어야 한다',
        );

        // "사용된 옷" 섹션(가로 스크롤 리스트, height: 96) 아래에 "+" 타일이 오고, 서로
        // 겹치지 않아야 한다(2:1 → 1:1 전환으로 타일이 더 커지면서 위 섹션을 침범할 수 있음).
        final usedItemsSectionBottom =
            tester.getBottomLeft(find.text('사용된 옷')).dy;
        final addTileTop = tester.getTopLeft(addTileAspectRatio).dy;
        expect(
          addTileTop,
          greaterThanOrEqualTo(usedItemsSectionBottom),
          reason: '"+" 타일이 위 섹션과 겹치면 안 된다',
        );

        // 렌더링 과정에서 RenderFlex 오버플로 등 예외가 없어야 한다.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('"+" 타일을 탭하면 여전히 선택 모달이 열리고, log02를 골라 복귀하면 실제로 정사각 타일로 바뀐다',
        (tester) async {
      final container = await pumpApp(tester);
      pushUnlinkedComposition(tester, container, id: 'test-square-bind', name: '빈 연결 코디 바인딩');
      await tester.pumpAndSettle();

      await tester.tap(find.text('스타일일지 연결하기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);

      final log02Tile = find.byKey(const ValueKey('log02'));
      expect(log02Tile, findsOneWidget);
      await tester.tap(log02Tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text('스타일일지 연결하기'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);
      expect(
        size.width / size.height,
        closeTo(1, 0.05),
        reason: '바인딩 직후 실제 타일도 정사각으로 렌더링돼야 한다(과거 2:1 확대 규칙 없음)',
      );

      final updatedLog = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02');
      expect(updatedLog.linkedCompositionId, 'test-square-bind');
    });
  });

  group('스크롤 회귀 — "+" 타일이 있는 짧은 뷰포트에서도 오버플로/예외 없음', () {
    testWidgets('짧은 뷰포트에서 "+" 타일까지 스크롤해 내려도 예외가 없고, 끝까지 스크롤된다',
        (tester) async {
      final container = await pumpApp(tester, size: const Size(390, 480));
      pushUnlinkedComposition(tester, container, id: 'test-square-scroll', name: '빈 연결 코디 스크롤');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      final scrollableFinder = find
          .descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable))
          .first;
      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));

      // 위로 다시 스크롤 — 빠르게 왕복해도 예외 없어야 한다(비정형 조작).
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(scrollable.position.pixels, closeTo(0, 1));
    });
  });

  group('옷 상세 vs 코디 상세 — 연결된 스타일일지 타일의 정사각 비율 시각적 일관성', () {
    testWidgets('같은 세션에서 옷 상세(c01→log01)와 코디 상세(comp01→log01)를 오가도 두 타일의 '
        '가로세로 비율이 서로 동일하게 정사각형이다', (tester) async {
      await pumpApp(tester);

      await tapItemById(tester, 'c01');
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      final closetTileSize = tester.getSize(find.byType(StyleLogGalleryTile));

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();

      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      final compositionTileSize = tester.getSize(find.byType(StyleLogGalleryTile));

      final closetRatio = closetTileSize.width / closetTileSize.height;
      final compositionRatio = compositionTileSize.width / compositionTileSize.height;
      expect(closetRatio, closeTo(1, 0.05));
      expect(compositionRatio, closeTo(1, 0.05));
      expect(
        closetRatio,
        closeTo(compositionRatio, 0.05),
        reason: '옷 상세/코디 상세가 동일한 위젯(StyleLogCrossReferenceGallery)을 공유하므로 '
            '두 화면의 타일 비율이 서로 달라 보이면 안 된다',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
