import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/widgets/gallery_meta_label.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

/// Tester 검증 — `docs/history/Decision.md` "[Decision] ClothingItem의 category/season/
/// color/material 4개 필수 필드를 선택 필드로 전환(nullable화)"(commit `88cbea6`+`92d93ef`).
/// 전역 mock(`mockClothingItems`, 12개)은 전부 값이 채워진 채로 두었으므로(다른 스위트의
/// 하드코딩 12개 assertion 보호), 4개 필드가 전부 null인 케이스는 이 테스트 안에서만
/// `closetItemsProvider`에 임시로 주입해 확인한다
/// (`detail_thumbnail_square_unification_test.dart` 277~295행 패턴 재사용).
///
/// 옷장 메인 그리드는 `GridView.builder`(지연 빌드)라서 목록 끝에 추가된 새 아이템은
/// 처음엔 뷰포트 밖에 있어 트리에 존재하지 않는다 — `tester.scrollUntilVisible`로 실제
/// 스크롤해서 진짜로 빌드된 뒤의 상태를 확인한다(스크롤 없이 "될 것 같다"고 넘기지 않음).
///
/// 확인 대상:
/// 1) 옷장 메인 그리드 — null 필드 아이템 타일이 크래시 없이 렌더링되고 카테고리 라벨
///    자리에 "미분류"가 보이는가.
/// 2) 옷 상세 화면 — 메타데이터 줄(종류·계절·소재·색상)이 4곳 전부 "미분류"인가.
/// 3) 이 아이템 추가로 기존 아이템(c01 등 정상 값)의 렌더링이 깨지지 않는가(회귀 없음).
/// 4) "미분류"(값 비어있음)와 "미완성"(`isIncomplete`) 배지가 서로 혼동되지 않는가 —
///    이 아이템은 `isIncomplete`를 세팅하지 않았으므로 그 배지가 안 뜨는 것만 확인한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 844);

  /// 4개 필드(category/season/color/material) 전부 null — 정상 mock 이미지 경로 재사용
  /// (이미지 자체는 이 결정과 무관, asset 존재 실패로 인한 소음을 피하기 위함).
  const nullFieldsItem = ClothingItem(
    id: 'test-nullable-fields-item',
    name: '미분류 테스트 아이템',
    imagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png',
  );

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

  /// [nullFieldsItem]을 이 테스트의 [container]에만 추가하고 재빌드한다. 전역 mock은
  /// 건드리지 않는다.
  Future<void> injectNullFieldsItem(WidgetTester tester, ProviderContainer container) async {
    container.read(closetItemsProvider.notifier).state = [
      ...container.read(closetItemsProvider),
      nullFieldsItem,
    ];
    await tester.pumpAndSettle();
  }

  Finder tileFinderFor(String itemId) =>
      find.byWidgetPredicate((w) => w is SelectableGalleryTile && w.item.id == itemId);

  /// `GridView.builder`는 지연 빌드라 목록 뒤쪽 아이템은 뷰포트 밖이면 트리에 아예
  /// 존재하지 않는다 — 실제로 스크롤해서 빌드시킨다.
  Future<void> scrollUntilTileVisible(WidgetTester tester, String itemId) async {
    final finder = tileFinderFor(itemId);
    if (finder.evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapItemById(WidgetTester tester, String itemId) async {
    await scrollUntilTileVisible(tester, itemId);
    final tile = tileFinderFor(itemId);
    expect(tile, findsOneWidget, reason: '아이템 $itemId 타일을 옷장 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  group('옷장 메인 그리드 — 4개 필드 전부 null인 아이템', () {
    testWidgets('크래시 없이 렌더링되고 카테고리 라벨 자리에 "미분류"가 보인다', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);
      await scrollUntilTileVisible(tester, nullFieldsItem.id);
      expect(tester.takeException(), isNull);

      final tileFinder = tileFinderFor(nullFieldsItem.id);
      expect(tileFinder, findsOneWidget);

      final metaLabelFinder = find.descendant(
        of: tileFinder,
        matching: find.byWidgetPredicate((w) => w is GalleryMetaLabel && w.label == '미분류'),
      );
      expect(
        metaLabelFinder,
        findsOneWidget,
        reason: 'category가 null이면 GalleryMetaLabel이 "미분류"로 fallback해야 한다',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Semantics 설명에도 색상 자리에 "미분류"가 들어간다(미완성과는 구분됨)', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);
      await scrollUntilTileVisible(tester, nullFieldsItem.id);

      final semanticsFinder = find.bySemanticsLabel(
        RegExp('${RegExp.escape(nullFieldsItem.name)}, 미분류, 착용 0회'),
      );
      expect(
        semanticsFinder,
        findsOneWidget,
        reason: 'color가 null이면 Semantics label도 "미분류"로 fallback해야 하고, isIncomplete를 '
            '세팅하지 않았으므로 ", 미완성" 접미사는 붙지 않아야 한다',
      );
    });

    testWidgets('isIncomplete를 세팅하지 않았으므로 "미완성" 배지는 뜨지 않는다(미분류≠미완성)', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);
      await scrollUntilTileVisible(tester, nullFieldsItem.id);

      final tileFinder = tileFinderFor(nullFieldsItem.id);
      final badgeFinder = find.descendant(of: tileFinder, matching: find.byType(StatusBadge));
      expect(
        badgeFinder,
        findsNothing,
        reason: '값이 비어있는 것("미분류")과 등록 자체가 미완료인 것("미완성")은 다른 개념 — '
            'isIncomplete가 false(기본값)면 배지가 뜨면 안 된다',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('기존 아이템(c01, 정상 값)의 카테고리 라벨은 여전히 실제 값이고, "미분류"가 아니다(회귀 없음)', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);

      // c01은 목록 맨 앞이라 스크롤 없이도 이미 빌드돼 있다.
      final c01TileFinder = tileFinderFor('c01');
      expect(c01TileFinder, findsOneWidget);

      final c01MetaLabelFinder = find.descendant(
        of: c01TileFinder,
        matching: find.byWidgetPredicate((w) => w is GalleryMetaLabel && w.label == '한벌옷'),
      );
      expect(
        c01MetaLabelFinder,
        findsOneWidget,
        reason: 'c01은 category=onePiece(라벨 "한벌옷")로 채워져 있으므로 fallback이 적용되면 안 된다',
      );

      // provider 상태 자체는 기존 12개 + 새 1개 = 13개(전역 mock 개수 자체를 건드리지
      // 않았다는 재확인). 그리드는 GridView.builder라 화면에 동시에 빌드되는 타일 수는
      // 뷰포트에 따라 다르므로 렌더링된 위젯 개수가 아니라 provider 상태로 확인한다.
      expect(container.read(closetItemsProvider).length, 13);

      // 스크롤로 실제 끝까지 내려가면 새 아이템도 크래시 없이 빌드된다(회귀 스윕).
      await scrollUntilTileVisible(tester, nullFieldsItem.id);
      expect(tileFinderFor(nullFieldsItem.id), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('옷 상세 화면 — 4개 필드 전부 null인 아이템', () {
    testWidgets('메타데이터 줄(종류·계절·소재·색상)이 4곳 전부 "미분류"로 표시된다', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);

      await tapItemById(tester, nullFieldsItem.id);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(
        find.text('미분류 · 미분류 · 미분류 · 미분류'),
        findsOneWidget,
        reason: 'category/season/material/color 4개 전부 null이면 메타데이터 줄 전체가 '
            '"미분류 · 미분류 · 미분류 · 미분류"로 렌더링돼야 한다(코드 순서: 종류·계절·소재·색상)',
      );

      expect(find.text(nullFieldsItem.name), findsOneWidget);
      expect(find.textContaining('착용 0회'), findsOneWidget);
    });

    testWidgets('기존 아이템(c01) 상세의 메타데이터 줄은 여전히 실제 값이다(회귀 없음)', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);

      await tapItemById(tester, 'c01');
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      // c01: category=onePiece(한벌옷), season=springFall, material=cotton, color='pink'.
      expect(find.textContaining('한벌옷'), findsWidgets);
      expect(find.textContaining('미분류'), findsNothing,
          reason: 'c01은 4개 필드가 전부 채워져 있으므로 fallback 텍스트가 전혀 나오면 안 된다');
      expect(tester.takeException(), isNull);
    });

    testWidgets('비정형 흐름 — 옷장 메인 ↔ null 필드 아이템 상세를 빠르게 오가도 크래시/잔상 없다', (tester) async {
      final container = await pumpApp(tester);
      await injectNullFieldsItem(tester, container);

      await tapItemById(tester, nullFieldsItem.id);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetMainScreen), findsOneWidget);

      // 빠르게 다시 진입(스크롤 위치가 유지된 채로 남아있을 수 있으므로 다시 스크롤해서
      // 찾는다).
      await tapItemById(tester, nullFieldsItem.id);
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('미분류 · 미분류 · 미분류 · 미분류'), findsOneWidget);
    });
  });
}
