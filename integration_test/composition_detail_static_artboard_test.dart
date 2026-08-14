// integration_test/composition_detail_static_artboard_test.dart
//
// Tester가 직접 설계한 런타임 검증 — Task B(코디 상세에 `StaticArtboard` 정적 렌더 아트보드
// 추가). Review는 정적으로만 확인했고, 특히 mock 데이터(comp01 등)엔 아이템이 겹치는 코디가
// 없어 겹침 팝업 경로가 실제 위젯 트리로 한 번도 실행돼본 적이 없다고 지적했다 — 이 파일의
// "겹침 + 스크롤 강제" 그룹이 그 갭을 메운다(로컬로 직접 구성한 겹치는 배치의 코디,
// `test/screens/composition_detail_screen_test.dart`가 이미 쓰는 로컬 데이터 격리 패턴을
// 그대로 통합테스트 레벨로 옮김).
//
// `interactive_artboard_test.dart`가 이미 다루는 것(Hit Area 판정식, 팝업 재배열/앵커링
// 자체의 세부 동작)은 다시 만들지 않는다 — `StaticArtboard`는 그 판정 로직을 그대로
// 복제했을 뿐이라 판정식 자체의 정밀도는 이미 커버됨. 여기서는 이 화면 고유의 결선
// (아트보드 탭 → "사용된 옷" 목록 스크롤+강조, 롱프레스 → 편집 라우트, dispose 안전성,
// 기존 "사용된 옷" 목록 회귀)만 확인한다.
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
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_item_view.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_overlap_popup.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/static_artboard.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const screenSize = Size(390, 844);

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = screenSize;
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

  Finder artboardKey(String id) => find.byKey(ValueKey('static-artboard-item-$id'));

  /// 겹치는 배치를 가진 로컬 코디를 구성해 밀어넣는다(mock_data.dart는 손대지 않음,
  /// Worker/Review 밖 파일). c01/c02를 캔버스 정중앙에 서로 다른 zIndex로 겹쳐 두고,
  /// 나머지 7개(c03,c04,c05,c06,c08,c09,c11)를 겹치지 않게 흩뿌린다. 겹치는 쌍을
  /// `items` 리스트 맨 뒤(인덱스 7/8)에 둬서 "사용된 옷" 목록에서 큰 스크롤 오프셋이
  /// 실제로 필요한 상황(총 9개 타일, 뷰포트 폭보다 넓음)까지 함께 검증한다.
  void pushOverlapComposition(ProviderContainer container, WidgetTester tester, {required String id}) {
    final composition = Composition(
      id: id,
      name: '겹침 테스트 코디',
      items: const [
        CompositionItemPlacement(clothingItemId: 'c03', x: 0.15, y: 0.15),
        CompositionItemPlacement(clothingItemId: 'c04', x: 0.85, y: 0.15),
        CompositionItemPlacement(clothingItemId: 'c05', x: 0.15, y: 0.85),
        CompositionItemPlacement(clothingItemId: 'c06', x: 0.85, y: 0.85),
        CompositionItemPlacement(clothingItemId: 'c08', x: 0.15, y: 0.5),
        CompositionItemPlacement(clothingItemId: 'c09', x: 0.85, y: 0.5),
        CompositionItemPlacement(clothingItemId: 'c11', x: 0.5, y: 0.1),
        CompositionItemPlacement(clothingItemId: 'c01', x: 0.5, y: 0.5, zIndex: 2),
        CompositionItemPlacement(clothingItemId: 'c02', x: 0.5, y: 0.5, zIndex: 1),
      ],
      createdAt: DateTime(2025, 1, 1),
    );
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      composition,
    ];
    final context = tester.element(find.byType(ClosetMainScreen));
    GoRouter.of(context).push(AppRoute.compositionDetail.replaceFirst(':id', id));
  }

  group('1) comp01 — 실제 아이템 배치대로 정적 아트보드가 렌더링된다(위치/개수)', () {
    testWidgets('4개 아이템이 모두 렌더링되고, 각 중심 좌표가 정규화 좌표(x/y)와 일치한다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      expect(tester.takeException(), isNull);
      expect(find.byType(StaticArtboard), findsOneWidget);
      expect(
        find.descendant(of: find.byType(StaticArtboard), matching: find.byType(ArtboardItemView)),
        findsNWidgets(4),
        reason: 'comp01은 c01/c11/c07/c03 4개 배치를 갖는다',
      );

      final canvasTopLeft = tester.getTopLeft(find.byType(StaticArtboard));
      final canvasSize = tester.getSize(find.byType(StaticArtboard));

      void expectCenter(String id, double x, double y) {
        final expected = canvasTopLeft + Offset(canvasSize.width * x, canvasSize.height * y);
        final actual = tester.getCenter(artboardKey(id));
        expect(actual.dx, closeTo(expected.dx, 1.0), reason: '$id의 x 위치가 배치값과 어긋남');
        expect(actual.dy, closeTo(expected.dy, 1.0), reason: '$id의 y 위치가 배치값과 어긋남');
      }

      expectCenter('c01', 0.3, 0.25);
      expectCenter('c11', 0.7, 0.25);
      expectCenter('c07', 0.3, 0.65);
      expectCenter('c03', 0.7, 0.65);
      expect(tester.takeException(), isNull);
    });
  });

  group('2) 겹치지 않는 단일 아이템 탭 — 사용된 옷 목록 스크롤+강조', () {
    testWidgets('c11(안 겹침)을 탭하면 "사용된 옷" 목록의 c11 타일에 잠깐 강조 테두리가 생겼다 사라진다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final primary = Theme.of(tester.element(find.byType(CompositionDetailScreen))).colorScheme.primary;

      Finder usedTileContainer(String id) => find.descendant(
            of: find.byKey(ValueKey(id)),
            matching: find.byType(Container),
          );

      BoxDecoration? decorationOf(String id) =>
          tester.widget<Container>(usedTileContainer(id)).decoration as BoxDecoration?;

      expect(decorationOf('c11')?.border, isNull, reason: '탭 이전엔 강조 테두리가 없어야 함');

      await tester.tap(artboardKey('c11'));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull, reason: '단일 아이템 탭 시 화면 전환 없이 예외도 없어야 함');
      expect(find.byType(CompositionDetailScreen), findsOneWidget, reason: '단일 탭은 편집/상세로 이동시키면 안 됨');

      final highlightedBorder = decorationOf('c11')?.border as Border?;
      expect(highlightedBorder, isNotNull, reason: '탭 직후 강조 테두리가 보여야 함');
      expect(highlightedBorder!.top.color, primary);
      expect(highlightedBorder.top.width, 2);

      // 강조 지속시간(1500ms) 경과 후엔 원래대로 돌아가야 한다.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(decorationOf('c11')?.border, isNull, reason: '강조 지속시간 경과 후 테두리가 사라져야 함');
    });
  });

  group('3) [갭 메우기] 로컬 겹침 배치 코디 — 겹침 팝업 실제 실행 + 재배열 UI 숨김 + 선택 후 스크롤/강조',
      () {
    testWidgets(
        '겹친 영역 탭 → 팝업이 뜨고(재배열 드래그핸들 없음) → 하나 선택 → 팝업 닫힘 + 사용된 옷 목록이 큰 오프셋으로 스크롤+강조',
        (tester) async {
      final container = await pumpApp(tester);
      pushOverlapComposition(container, tester, id: 'test-overlap-1');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(
        find.descendant(of: find.byType(StaticArtboard), matching: find.byType(ArtboardItemView)),
        findsNWidgets(9),
      );

      // c01(zIndex2)/c02(zIndex1)이 같은 좌표(0.5,0.5)에 겹쳐 있다 — c01의 렌더 위치를
      // 좌표로 삼아 탭하면 두 아이템 모두 히트해야 한다.
      final overlapPoint = tester.getCenter(artboardKey('c01'));
      await tester.tapAt(overlapPoint);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '겹친 영역 탭이 팝업으로 이어지지 않음(갭)');

      final rows = find.byType(ListTile);
      expect(rows, findsNWidgets(2), reason: '겹친 2개(c01/c02)만 팝업에 나열돼야 함');
      final topRow = tester.widget<ListTile>(rows.first);
      final topLabel =
          (((topRow.title! as Row).children.last as Flexible).child as Text).data;
      expect(topLabel, 'c01', reason: 'zIndex가 큰 c01이 먼저 나열돼야 함');

      // 읽기 전용 화면이므로 재배열 드래그핸들이 보이면 안 된다(reorderable:false).
      expect(find.byIcon(Icons.drag_handle), findsNothing, reason: '코디 상세 겹침 팝업엔 재배열 핸들이 없어야 함');

      // c02(하위 아이템)를 팝업에서 선택.
      await tester.tap(find.byKey(const ValueKey('c02')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ArtboardOverlapPopup), findsNothing, reason: '선택 후 팝업이 닫혀야 함');

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
      );
      // c02는 items 리스트의 마지막(인덱스 8)이라 목표 오프셋(8*80=640)이 실제 스크롤
      // 가능 범위를 넘는다 — clamp되어 maxScrollExtent에 도달해야 한다(실제 스크롤이
      // 발생했다는 뜻, 0에 머물러 있으면 안 됨).
      expect(scrollable.position.maxScrollExtent, greaterThan(0), reason: '9개 타일이면 뷰포트를 넘어야 함');
      expect(
        scrollable.position.pixels,
        closeTo(scrollable.position.maxScrollExtent, 1.0),
        reason: '겹침 팝업에서 선택한 c02 위치로 실제 스크롤이 이동해야 함',
      );

      final c02Decoration =
          tester.widget<Container>(find.descendant(of: find.byKey(const ValueKey('c02')), matching: find.byType(Container)))
              .decoration as BoxDecoration?;
      expect(c02Decoration?.border, isNotNull, reason: '팝업에서 선택한 c02 타일이 강조돼야 함');

      final c01Decoration =
          tester.widget<Container>(find.descendant(of: find.byKey(const ValueKey('c01')), matching: find.byType(Container)))
              .decoration as BoxDecoration?;
      expect(c01Decoration?.border, isNull, reason: '선택하지 않은 c01은 강조되면 안 됨');
    });
  });

  group('4) 아이템 롱프레스(~1.5초) — 편집 화면 진입', () {
    // comp01은 c07(삭제됨)을 포함하므로(그룹 6 참고), 편집 진입 시 §13.2(b) "삭제된 옷 자동
    // 정리" 확인 다이얼로그가 먼저 뜬다(`docs/reference/data/00_DataSchema.md`,
    // `confirmAndCleanUpDeletedItemsBeforeEditing`) — 진행을 선택해야 실제로 편집 화면으로
    // 넘어간다.
    testWidgets(
        'c01을 1.5초 이상 눌렀다 떼면 삭제된 옷 정리 확인 다이얼로그가 뜨고, 진행을 선택하면 compositionEditorWithId 라우트로 이동한다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final point = tester.getCenter(artboardKey('c01'));
      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '롱프레스 타이머 발동 자체에서 예외가 없어야 함');
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('삭제된 옷이 포함돼 있어요'), findsOneWidget, reason: '정리 대상(c07)이 있으므로 확인 다이얼로그가 떠야 함');
      expect(find.text('삭제된 옷 1개 포함, 편집 시작 시 자동 제거돼요.'), findsOneWidget);
      expect(find.byType(CompositionEditorScreen), findsNothing, reason: '다이얼로그 확인 전엔 아직 편집 화면으로 넘어가면 안 됨');

      await tester.tap(find.text('진행'));
      await tester.pumpAndSettle();
      // [Tester 수정] 정리 write-back은 오프스크린 캡처(`toImage`)와 PNG 파일 쓰기라는,
      // 프레임을 스케줄하지 않는 비동기 구간을 지나므로 `pumpAndSettle()`만으로는 완료를
      // 기다리지 못한다(실기기 실행에서 확인 — 편집 화면 진입 전에 단언이 먼저 실행돼
      // 실패했고, 테스트 종료 후에야 뒤늦게 이어지던 커밋이 컨테이너 dispose 예외를 냈다).
      // 실제 시간을 흘려보내며 편집 화면 진입을 기다린다.
      for (var i = 0; i < 100 && find.byType(CompositionEditorScreen).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '정리(캡처+저장+write-back) 자체에서 예외가 없어야 함');
      expect(find.byType(CompositionEditorScreen), findsOneWidget, reason: '진행 선택 후 편집 화면으로 이어져야 함');
      expect(
        tester.widget<CompositionEditorScreen>(find.byType(CompositionEditorScreen)).compositionId,
        'comp01',
      );

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
    });

    // comp02는 삭제/purge된 옷이 없는 코디(그룹 1~3이 쓰는 comp01과 달리 검증된 바 없어
    // mock_data.dart를 직접 재확인하기보다, 정리 대상이 없는 코디를 로컬로 구성해 no-op
    // 경로(다이얼로그 없이 즉시 진입)를 검증한다.
    testWidgets('정리 대상이 없는 코디는 다이얼로그 없이 즉시 편집 화면으로 이동한다', (tester) async {
      final container = await pumpApp(tester);
      final clean = Composition(
        id: 'test-clean-edit-entry',
        name: '정리 대상 없음',
        createdAt: DateTime(2026, 1, 1),
        items: const [CompositionItemPlacement(clothingItemId: 'c01', x: 0.5, y: 0.5)],
      );
      container.read(compositionsProvider.notifier).state = [
        ...container.read(compositionsProvider),
        clean,
      ];
      final context = tester.element(find.byType(ClosetMainScreen));
      GoRouter.of(context).push(AppRoute.compositionDetail.replaceFirst(':id', clean.id));
      await tester.pumpAndSettle();

      final point = tester.getCenter(artboardKey('c01'));
      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('삭제된 옷이 포함돼 있어요'), findsNothing, reason: '정리 대상이 없으면 다이얼로그가 뜨면 안 됨');
      expect(find.byType(CompositionEditorScreen), findsOneWidget, reason: '즉시 편집 화면으로 넘어가야 함');
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
    });
  });

  group('5) 화면 이탈 시 크래시 없음 — 하이라이트 타이머 / 롱프레스 타이머 / 겹침 팝업 오버레이 정리', () {
    testWidgets('강조 타이머가 아직 살아있는 상태로 뒤로가기 해도, 그 타이머가 나중에 실제로 발동할 때까지도 예외가 없다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      await tester.tap(artboardKey('c03'));
      await tester.pump(); // 강조 타이머(1500ms) 시작, 아직 발동 전

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '타이머가 살아있는 채로 나가도 dispose 시점엔 예외 없어야 함');

      // 원래 타이머가 실제 발동했을 시점까지 기다려도(위젯은 이미 unmount) 예외가 없어야
      // 한다 — `if (!mounted) return;` 가드가 실제로 동작하는지 확인.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'unmount 후 지연 발동된 타이머 콜백에서 예외가 나면 안 됨');
      expect(find.byType(CompositionMainScreen), findsOneWidget);
    });

    testWidgets('겹침 팝업이 열린 채로 뒤로가기(프로그램적 pop, 하드웨어 백 시뮬레이션)해도 예외가 없고 팝업이 남지 않는다',
        (tester) async {
      final container = await pumpApp(tester);
      pushOverlapComposition(container, tester, id: 'test-overlap-2');
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(artboardKey('c01')));
      await tester.pumpAndSettle();
      expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

      // 팝업의 전체화면 배리어가 화면 내 탭을 가로채므로, 하드웨어/제스처 back과
      // 동등한 프로그램적 pop으로 시뮬레이션한다(배리어를 거치지 않는 경로).
      final detailContext = tester.element(find.byType(CompositionDetailScreen));
      GoRouter.of(detailContext).pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '팝업이 열린 채로 화면을 나가도 예외가 없어야 함');
      expect(find.byType(ArtboardOverlapPopup), findsNothing, reason: '팝업 오버레이가 새 화면 위에 남아있으면 안 됨(누수)');
      expect(find.byType(ClosetMainScreen), findsOneWidget);
    });

    testWidgets('코디 상세를 빠르게 반복 진입/이탈해도 누적 예외가 없다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      for (var i = 0; i < 3; i++) {
        await tapCompositionById(tester, 'comp01');
        // 강조 타이머까지 살짝 건드려 상태를 남긴 채로 빠르게 빠져나간다.
        await tester.tap(artboardKey('c01'));
        await tester.pump();
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '빠른 반복 진입/이탈 후 누적된 예외가 없어야 함');
      expect(find.byType(CompositionMainScreen), findsOneWidget);
    });
  });

  group('6) 회귀 — 기존 "사용된 옷" 목록(삭제 배지/탭 차단)은 아트보드 추가와 무관하게 그대로 동작한다', () {
    testWidgets('comp01의 삭제된 c07은 배지가 보이고 탭해도 이동하지 않으며, 정상 c11은 그대로 탭 이동된다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      expect(find.widgetWithText(StatusBadge, '삭제됨'), findsOneWidget, reason: 'c07 타일에만 삭제 배지가 있어야 함');

      await tester.tap(find.byKey(const ValueKey('c07')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget, reason: '삭제된 옷 탭은 아무 이동도 없어야 함');
      expect(find.byType(ClosetItemDetailScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey('c11')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget, reason: '정상 옷은 여전히 탭으로 이동해야 함');

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
    });
  });
}
