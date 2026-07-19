import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 6("코디 프리뷰 캐러셀/카드 + 스타일일지 2열 갤러리 위젯, 옷 상세·코디
/// 상세 재배선", commits `1b4b339` + `4dd8875`).
///
/// `closet_item_detail_data_binding_test.dart`/`composition_detail_data_binding_test.dart`가
/// 이미 다루는 것(탭 → 네비게이션, 기본 텍스트 존재)은 다시 만들지 않는다. 이 파일은 정적
/// 리뷰로는 확인할 수 없는 실제 렌더링 결과만 본다:
/// 1) 코디 프리뷰 카드가 실제로 어떤 이미지 asset을 그리는지(빈 회색 박스가 아님).
/// 2) 스타일일지 갤러리 타일이 실제 이미지+날짜를 그리는지.
/// 3) 연결이 전혀 없는 화면에서 캐러셀/갤러리가 실제로 0 높이인지, 그리고 그 자리에 다른
///    잔여 빈 공간(레이아웃 유령 요소)이 남아있지 않은지.
/// 4) 스타일일지 1개일 때 타일이 실제로 정사각(1:1) 비율로(찌그러지지 않고) 렌더링되는지
///    (Task 12 — "1개면 2칸 확대" 규칙 폐기).
/// 5) mock 데이터엔 없는 "스타일일지 미연결 코디"를 만들어, "+" 타일을 실제로 탭해 선택
///    모달로 이동하고, 로그를 골라 복귀했을 때 실제로 바인딩이 반영되는지(엔드투엔드).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

  group('연결된 코디 프리뷰 카드 — 실제 이미지 렌더링', () {
    testWidgets(
      'c01 상세의 코디 카드(comp01)가 compositionCoverImageProvider 폴백 이미지(첫 아이템 c01 자체 '
      '이미지)를 실제 Image.asset으로 그린다(빈 회색 박스가 아니다)',
      (tester) async {
        await pumpApp(tester);
        await tapItemById(tester, 'c01');

        final cardFinder = find.byType(CompositionPreviewCard);
        expect(cardFinder, findsOneWidget);
        final imageFinder = find.descendant(of: cardFinder, matching: find.byType(Image));
        expect(
          imageFinder,
          findsOneWidget,
          reason: '카드 안에 실제 Image 위젯이 렌더링돼야 한다(comp01의 coverImagePath가 null이라 '
              '첫 아이템 c01 이미지로 폴백해야 함)',
        );
        final image = tester.widget<Image>(imageFinder);
        expect(image.image, isA<AssetImage>());
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/mock/IMG_4259_preview_rev_1.png',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('연결된 스타일일지 갤러리 — 실제 이미지+날짜 타일', () {
    testWidgets('c01 상세의 스타일일지 타일이 log01의 실제 커버 이미지+날짜 라벨을 그린다', (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final imageFinder = find.descendant(of: tileFinder, matching: find.byType(Image));
      expect(imageFinder, findsOneWidget, reason: '빈 회색 박스가 아니라 실제 이미지가 그려져야 한다');
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/mock/IMG_4259_preview_rev_1.png', // log01.coverImagePath
      );
      expect(
        find.descendant(of: tileFinder, matching: find.textContaining('2026-01-05')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('연결이 전혀 없는 화면(c02) — 빈 상태가 실제로 0 높이인지, 잔여 공간은 없는지', () {
    testWidgets(
      'c02 상세 — 연결된 코디/스타일일지가 없어 캐러셀/갤러리는 실제 렌더 높이가 0이다 '
      '(`CrossReferenceLinkBar`는 Task 9에서 폐기됨 — 이제 옷 상세 하단은 이 두 위젯이 전부이고, '
      '둘 다 SizedBox.shrink()라 죽은 공간이 남지 않는다)',
      (tester) async {
        await pumpApp(tester);
        await tapItemById(tester, 'c02');

        final carouselSize = tester.getSize(find.byType(CompositionPreviewCarousel));
        expect(
          carouselSize.height,
          0,
          reason: '연결된 코디가 없으면 캐러셀은 SizedBox.shrink()로 실제 높이 0이어야 한다',
        );
        final gallerySize = tester.getSize(find.byType(StyleLogCrossReferenceGallery));
        expect(
          gallerySize.height,
          0,
          reason: '연결된 스타일일지가 없으면 갤러리도 실제 높이 0이어야 한다',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('단일 스타일일지 타일 — 정사각 레이아웃이 찌그러지지 않는지(Task 12, "1개면 2칸 확대" 규칙 폐기)', () {
    testWidgets('comp01 상세의 log01 타일이 실제로 정사각(비율 ≈ 1)으로 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      expect(
        size.width / size.height,
        closeTo(1, 0.05),
        reason: '1개여도 childAspectRatio: 1 그리드 규칙이 실제로 반영돼야 한다(Task 12)',
      );
    });

    testWidgets('comp02 상세의 log02 타일도 실제로 정사각(비율 ≈ 1)으로 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp02');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);
      expect(size.width / size.height, closeTo(1, 0.05));
    });
  });

  group('스타일일지 미연결 코디 — "+" 타일 실제 탭 → 선택 모달 → 복귀 후 바인딩 반영(엔드투엔드)', () {
    testWidgets(
      'mock 코디는 전부 이미 로그에 연결돼 있어(comp01/comp02), 미연결 상태는 임시 코디를 하나 '
      '추가해 격리한다. "+" 타일을 실제로 탭하면 실제 StyleLogMainScreen(selectionMode:true)이 '
      '열리고, log01을 선택해 복귀하면 "+" 타일이 사라지고 실제로 log01 타일이 보이며, '
      'styleLogsProvider 상태도 실제로 갱신된다',
      (tester) async {
        final container = await pumpApp(tester);
        final unlinkedComposition = Composition(
            id: 'test-unlinked-t6', name: '임시 미연결 코디', items: const [], createdAt: DateTime(2025, 1, 1));
        container.read(compositionsProvider.notifier).state = [
          ...container.read(compositionsProvider),
          unlinkedComposition,
        ];

        final context = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(context)
            .push(AppRoute.compositionDetail.replaceFirst(':id', 'test-unlinked-t6'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('임시 미연결 코디'), findsOneWidget);
        expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);
        expect(find.text('스타일일지 연결하기'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        await tester.tap(find.text('스타일일지 연결하기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogMainScreen), findsOneWidget);
        expect(find.byType(CompositionDetailScreen), findsNothing);

        final log01Tile = find.byKey(const ValueKey('log01'));
        expect(log01Tile, findsOneWidget);
        await tester.tap(log01Tile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('임시 미연결 코디'), findsOneWidget);
        expect(find.text('스타일일지 연결하기'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byType(StyleLogGalleryTile), findsOneWidget);
        expect(find.textContaining('2026-01-05'), findsOneWidget); // log01.wornDate

        final updatedLog = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01');
        expect(updatedLog.linkedCompositionId, 'test-unlinked-t6');
      },
    );
  });

  group('스크롤 동작 — 코디 상세에 추가된 스타일일지 갤러리 섹션', () {
    testWidgets(
      '코디 상세(comp01) 콘텐츠(사용된 옷 목록 + 스타일일지 갤러리)가 짧은 뷰포트에서도 예외 없이 '
      '스크롤되고, 끝까지 내렸을 때 오버플로/클리핑 예외가 없다',
      (tester) async {
        tester.view.physicalSize = const Size(390, 450);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
        );
        await tester.pumpAndSettle();
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp01');

        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        final scrollableFinder = find
            .descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable))
            .first;
        final scrollable = tester.state<ScrollableState>(scrollableFinder);

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -2000), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogGalleryTile), findsOneWidget);
        expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));
      },
    );
  });
}
