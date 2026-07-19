import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Task 7("스타일일지 열람 실데이터 바인딩 + 코디 바인딩") Tester 검증.
///
/// Task 8("카드 캐러셀 재구현")로 대표이미지/코디 슬롯이 하나의 2페이지 `PageView`로
/// 묶이면서 이 파일의 assertion 다수를 그 구조에 맞게 갱신했다(하단 별도 카드/칩 방식은
/// 폐기됨 — `docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정"
/// 참고). 코디 슬롯(페이지 인덱스 1)의 내용을 확인해야 하는 곳은 매번
/// `PageController.jumpToPage(1)`로 명시적으로 넘긴 뒤 검증한다 — 기본 `PageView`
/// (viewportFraction 1.0)는 인접 페이지를 미리 빌드해두지 않는다(실측 확인됨).
///
/// `detail_screens_header_hud_test.dart`/`selection_modal_test.dart`/
/// `test/screens/style_log_viewer_screen_test.dart`가 이미 다룬 것(화면 진입/헤더 HUD/
/// 뒤로가기/CompositionPreviewCard·"+" 슬라이드 존재 자체·ProviderScope override로 격리된
/// 라우트 스텁 기반 미연결 위젯 테스트)은 다시 만들지 않는다. 이 파일은 그 스위트들이
/// 다루지 않는 것만 확인한다:
/// 1) 커버/"착용 옷" 스트립 실제 asset 렌더링(경로까지 정확히), 날짜/장소 텍스트 포맷,
///    "착용 옷" 이미지 탭 → 옷 상세 실제 네비게이션.
/// 2) 연결된 코디 카드의 실제 썸네일(compositionCoverImageProvider 폴백 경로)까지 확인.
/// 3) 코디 상세 ↔ 스타일일지 열람 왕복 네비게이션 — 크래시/스택 누락·중복 없음.
/// 4) 미연결 스타일일지에서 실제 앱 라우터로 코디 선택 모달을 열어 고르는 End-to-End
///    바인딩 흐름(스텁 화면이 아니라 실제 `CompositionMainScreen(selectionMode:true)`).
/// 5) "+코디 연결하기"를 pumpAndSettle 없이 빠르게 두 번 탭하는 비정형 흐름.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 844);
  const scrollableDetailSize = Size(390, 480);

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

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  bool hasAssetImage(String assetPath) => find
      .byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == assetPath,
      )
      .evaluate()
      .isNotEmpty;

  /// 대표이미지/코디 슬롯 캐러셀의 2번째 페이지(코디 슬롯)로 넘긴다 — 기본 PageView는
  /// 인접 페이지를 미리 빌드해두지 않으므로 코디 슬롯 내용을 확인하려면 매번 필요하다.
  Future<void> jumpToCompositionSlide(WidgetTester tester) async {
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
    await tester.pumpAndSettle();
  }

  // ── 1) 커버/추가 사진/날짜/장소 실제 렌더링 ─────────────────────────────

  group('스타일일지 열람 — 실제 이미지/텍스트 렌더링', () {
    testWidgets(
      'log01 열람 — 커버 이미지·추가 사진 2장이 실제 asset 경로로 렌더링되고, 날짜/장소가 '
      '"2026.1.5  집" 포맷으로 한 텍스트에 보인다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);

        // 날짜+장소가 한 Text로 정확한 포맷("연도.월.일  장소")으로 렌더링된다.
        expect(find.text('2026.1.5  집'), findsOneWidget);

        // 커버 이미지 + 추가 사진 2장이 실제 asset 경로로 예외 없이 렌더링된다.
        expect(hasAssetImage('assets/images/mock/IMG_4259_preview_rev_1.png'), isTrue,
            reason: '커버 이미지(log01.coverImagePath)');
        expect(hasAssetImage('assets/images/mock/IMG_4262_preview_rev_1.png'), isTrue,
            reason: '추가 사진 1장(log01.additionalImagePaths[0])');
        expect(hasAssetImage('assets/images/mock/IMG_4275.PNG'), isTrue,
            reason: '추가 사진 2장(log01.additionalImagePaths[1])');
        expect(tester.takeException(), isNull);

        // "착용 옷" 섹션 라벨과 그 가로 스트립(ListView)이 실제로 존재한다(Task 8에서
        // "추가 사진"→"착용 옷"으로 개명, 스펙 원문의 "3번~ 추가 사진" 자리를 유지하되
        // 이제 각 이미지가 실제 옷과 매칭되어 탭 가능해짐).
        expect(find.text('착용 옷'), findsOneWidget);
        final stripFinder = find.byType(ListView);
        expect(stripFinder, findsOneWidget);

        // 가로 드래그해도 크래시 없음(현재 mock 데이터는 2장뿐이라 실제로 넘칠 정도로
        // 스크롤이 필요한 폭은 아니라 — 진짜 오버플로 스크롤 동작 자체는 이 mock 데이터로는
        // 검증 불가. 드래그 자체의 안전성만 확인).
        await tester.drag(stripFinder, const Offset(-80, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // "착용 옷" 첫 이미지(log01.additionalImagePaths[0] == c11.imagePath)를 탭하면
        // 실제로 c11(그래픽 맨투맨) 상세로 이동한다(역방향 매칭 — mock_data.dart 데이터
        // 정합성으로 확인됨).
        await tester.tap(find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/mock/IMG_4262_preview_rev_1.png',
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('그래픽 맨투맨'), findsOneWidget);
        expect(find.byType(StyleLogViewerScreen), findsNothing);
      },
    );

    testWidgets(
      'log02 열람 — 착용 옷이 없으므로 "착용 옷" 섹션 자체가 렌더링되지 않고, '
      '날짜/장소가 "2026.1.10  회사"로 보인다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log02')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('2026.1.10  회사'), findsOneWidget);
        expect(find.text('착용 옷'), findsNothing);
        // log02엔 착용 옷 스트립 ListView가 없다(연결된 코디 카드도 캐러셀도 ListView를
        // 안 쓰므로, 이 화면엔 ListView 자체가 없어야 한다).
        expect(find.byType(ListView), findsNothing);
      },
    );
  });

  // ── 2) 연결된 코디 카드의 실제 썸네일(폴백 경로) ────────────────────────

  group('연결된 코디 카드 — 실제 썸네일(compositionCoverImageProvider 폴백)', () {
    testWidgets(
      'log01 열람의 연결된 코디 카드(comp01)는 coverImagePath가 없어 첫 옷(c01)의 이미지로 '
      '폴백 렌더링되고, 탭하면 comp01 상세로 정확히 이동한다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();
        await jumpToCompositionSlide(tester);

        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        // comp01.coverImagePath == null → items.first(c01) 이미지로 폴백.
        expect(hasAssetImage('assets/images/mock/IMG_4259_preview_rev_1.png'), isTrue);
        expect(find.textContaining('데일리 룩'), findsOneWidget);

        await tester.tap(find.byType(CompositionPreviewCard));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.byType(StyleLogViewerScreen), findsNothing);
        expect(find.text('데일리 룩'), findsOneWidget);
      },
    );
  });

  // ── 3) 코디 상세 ↔ 스타일일지 열람 왕복 네비게이션 ───────────────────────

  group('왕복 네비게이션 — 코디 상세 → 스타일일지 열람 → 코디 상세', () {
    testWidgets(
      '코디 상세(comp01)에서 연결된 스타일일지(log01)로 이동 → 그 열람 화면의 연결된 코디 '
      '카드를 탭해 다시 comp01 상세로 이동 → 뒤로가기를 반복해도 스택이 정확히 줄어들고 '
      '루프·중복 화면 없이 원래 메인으로 돌아온다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tester.tap(find.byKey(const ValueKey('comp01')));
        await tester.pumpAndSettle();
        expect(find.byType(CompositionDetailScreen), findsOneWidget);

        // 코디 상세 → 연결된 스타일일지(log01) 탭.
        expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);
        await tester.tap(find.byType(StyleLogGalleryTile));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.byType(CompositionDetailScreen), findsNothing);
        expect(find.text('2026.1.5  집'), findsOneWidget);

        // 스타일일지 열람 → 코디 슬롯(캐러셀 2페이지)으로 넘겨 연결된 코디 카드 탭 → 다시
        // comp01 상세로.
        await jumpToCompositionSlide(tester);
        await tester.tap(find.byType(CompositionPreviewCard));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.byType(StyleLogViewerScreen), findsNothing);
        expect(find.text('데일리 룩'), findsOneWidget);

        // 뒤로가기 1회 — 스타일일지 열람으로(코디 메인으로 건너뛰거나 루프되면 안 됨).
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.byType(CompositionMainScreen), findsNothing);

        // 뒤로가기 2회째 — 처음 진입했던 comp01 상세로.
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('데일리 룩'), findsOneWidget);

        // 뒤로가기 3회째 — 코디 메인으로.
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionMainScreen), findsOneWidget);
        expect(find.byType(CompositionDetailScreen), findsNothing);
      },
    );
  });

  // ── 4) 미연결 스타일일지 — 실제 앱 라우터로 코디 선택 모달 바인딩 E2E ─────

  group('미연결 스타일일지 — 실제 코디 선택 모달을 통한 바인딩 End-to-End', () {
    testWidgets(
      'mock엔 미연결 로그가 없어 격리 추가한다 — "+코디 연결하기" 탭 → 실제 '
      'CompositionMainScreen(selectionMode:true)가 열리고 → comp02 타일 탭 → pop되어 '
      'CompositionPreviewCard(포멀 코디)로 바뀌고 styleLogsProvider 상태가 실제로 갱신된다',
      (tester) async {
        final container = await pumpApp(tester);
        final unlinkedLog = StyleLog(
          id: 'test-unlinked-log',
          coverImagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
          wornDate: DateTime(2026, 2, 1),
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          unlinkedLog,
        ];

        final navContext = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(navContext)
            .push(AppRoute.styleLogViewer.replaceFirst(':id', 'test-unlinked-log'));
        await tester.pumpAndSettle();
        await jumpToCompositionSlide(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.text('코디 연결하기'), findsOneWidget);
        expect(find.byType(CompositionPreviewCard), findsNothing);

        await tester.ensureVisible(find.text('코디 연결하기'));
        await tester.tap(find.text('코디 연결하기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionMainScreen), findsOneWidget);
        expect(find.byTooltip('닫기'), findsOneWidget); // 선택 모달 — 닫기 버튼으로 교체됨.
        expect(find.byType(CompositionGalleryTile), findsNWidgets(2));

        await tester.tap(find.byKey(const ValueKey('comp02')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionMainScreen), findsNothing);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        expect(find.textContaining('포멀 코디'), findsOneWidget);
        expect(find.text('코디 연결하기'), findsNothing);

        final updatedLog =
            container.read(styleLogsProvider).firstWhere((l) => l.id == 'test-unlinked-log');
        expect(updatedLog.linkedCompositionId, 'comp02');
      },
    );

    testWidgets(
      '[비정형 흐름] "+코디 연결하기"를 pumpAndSettle 없이 빠르게 두 번 탭해도 코디 선택 '
      '모달이 중복 스택되지 않는다',
      (tester) async {
        final container = await pumpApp(tester);
        final unlinkedLog = StyleLog(
          id: 'test-unlinked-log-2',
          coverImagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png',
          wornDate: DateTime(2026, 2, 2),
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          unlinkedLog,
        ];

        final navContext = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(navContext)
            .push(AppRoute.styleLogViewer.replaceFirst(':id', 'test-unlinked-log-2'));
        await tester.pumpAndSettle();
        await jumpToCompositionSlide(tester);

        final chip = find.text('코디 연결하기');
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump(const Duration(milliseconds: 16));
        // 두 번째 탭 시점엔 이미 코디 선택 모달로 전환 중이라, 같은 Finder로는 더 이상
        // 이 칩을 찾지 못할 수도 있다 — 그 자체가 "중복 push 안 됨"의 방증이라 실패시키지
        // 않고 예외 없이 넘어가는지만 확인한다.
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip, warnIfMissed: false);
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // 코디 선택 모달이 정확히 1개만 스택에 쌓여야 한다(2번 탭으로 2개 push되면 회귀).
        expect(find.byType(CompositionMainScreen), findsOneWidget);
      },
    );
  });

  // ── 5) 짧은 뷰포트 스크롤 동작 ────────────────────────────────────────────

  group('스타일일지 열람 — 짧은 뷰포트 스크롤(캐러셀+날짜/장소+착용 옷)', () {
    testWidgets(
      'log01 열람 화면 콘텐츠(대표이미지/코디 슬롯 캐러셀+날짜/장소+착용 옷)가 짧은 뷰포트에서 '
      '스크롤 가능하고 끝까지 스크롤해도 크래시나 콘텐츠 유실이 없다',
      (tester) async {
        await pumpApp(tester, size: scrollableDetailSize);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();
        await jumpToCompositionSlide(tester);

        expect(find.byType(StyleLogViewerScreen), findsOneWidget);

        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0),
            reason: '정사각 캐러셀+날짜/장소+착용 옷 스트립을 합치면 480 높이에선 스크롤이 필요해야 한다');

        await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -2000), 2000);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));
        // 끝까지 스크롤해도 코디 슬롯(캐러셀 2페이지)이 여전히 실제로 보인다(잘려나가지 않음).
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        expect(find.textContaining('데일리 룩'), findsOneWidget);
      },
    );
  });
}
