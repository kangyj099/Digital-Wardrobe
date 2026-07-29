import 'package:flutter/gestures.dart';
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
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';

/// Task 8("스타일일지 열람 카드 캐러셀 재구현") Tester 검증 — 이 파일은
/// `integration_test/style_log_composition_binding_test.dart`가 이미 다룬 것(썸네일 폴백,
/// 왕복 네비게이션 스택 검증, mock 데이터 실제 렌더링)을 다시 만들지 않고, 그 파일이
/// 전부 `PageController.jumpToPage(1)`로 프로그래밍적으로 페이지를 넘긴 뒤에만 검증했다는
/// 공백을 메운다:
/// 1) 실제 드래그 제스처로 페이지 1→2 전환(스와이프 방향, 제스처 영역이 "착용 옷" 스트립에
///    가로막히지 않는지, 애니메이션이 크래시 없이 끝나는지).
/// 2) 2-dot 페이지 인디케이터가 실제로 활성 페이지를 반영하는지(색상 비교).
/// 3) 코디 카드 탭 → 코디 상세 → 뒤로가기 후 캐러셀 페이지 상태가 유지되는지(같은 위젯
///    인스턴스가 살아있으므로 재진입 없이 페이지 2가 그대로 보여야 한다).
/// 4) "착용 옷" 스트립의 두 번째 이미지(c07) 탭 — 첫 번째 이미지(c11) 탭은 기존 파일이
///    이미 검증했다.
/// 5) 미연결 스타일일지에서도 실제 드래그로 "+" 플레이스홀더 페이지에 도달 → 코디 선택
///    모달로 바인딩 → 화면을 떠나지 않고 캐러셀이 실제 카드로 바뀌는지.
/// 6) 서로 다른 뷰포트 크기에서 캐러셀 정사각 비율이 깨지거나 오버플로가 나지 않는지.
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

  /// 대표이미지/코디 슬롯 캐러셀에서 실제로 손가락을 스와이프하는 것과 동일한 드래그
  /// 제스처를 PageView 위에 직접 가한다(코드로 `jumpToPage`를 부르는 대신).
  Future<void> swipeToNextPage(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  Finder dotFinder(Color color) => find.byWidgetPredicate((w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      (w.decoration! as BoxDecoration).color == color);

  // ── 1) 실제 드래그 제스처로 페이지 전환 + dot 인디케이터 ────────────────────

  group('실제 드래그 제스처 — 대표이미지 → 코디 슬롯', () {
    testWidgets(
      'log01 열람 진입 시 캐러셀은 대표이미지(페이지 1)에서 시작하고 dot 1이 활성 상태다. '
      '왼쪽으로 실제 드래그하면 코디 슬롯(페이지 2, comp01 CompositionPreviewCard)으로 넘어가고 '
      'dot 2가 활성으로 바뀐다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();

        final semantic =
            Theme.of(tester.element(find.byType(StyleLogViewerScreen))).extension<AppSemanticColors>()!;

        // 진입 직후 — 대표이미지가 보이고, 코디 카드는 아직 (인접 페이지 프리빌드 없이는)
        // 안 보인다. dot 1이 활성(gray900), dot 2가 비활성(gray200).
        expect(hasAssetImage('assets/images/mock/IMG_4259_preview_rev_1.png'), isTrue);
        expect(find.byType(CompositionPreviewCard), findsNothing);
        expect(dotFinder(semantic.gray900), findsOneWidget, reason: 'dot 1만 활성 상태여야 한다');
        expect(dotFinder(semantic.gray200), findsOneWidget, reason: 'dot 2는 비활성 상태여야 한다');

        // "착용 옷" 스트립이 캐러셀 아래에 이미 존재하는 상태에서 캐러셀 위에 실제 드래그를
        // 가한다 — 제스처 영역이 그 스트립에 가로막히지 않는지 확인.
        expect(find.text('착용 옷'), findsOneWidget);
        await swipeToNextPage(tester);

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<PageView>(find.byType(PageView)).controller!.page,
          closeTo(1.0, 0.01),
          reason: '실제 드래그로 페이지 2까지 완전히 스냅되어야 한다',
        );
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        expect(find.textContaining('데일리 룩'), findsOneWidget);
        expect(dotFinder(semantic.gray900), findsOneWidget, reason: '드래그 후엔 dot 2가 활성 상태여야 한다');
        expect(dotFinder(semantic.gray200), findsOneWidget, reason: '드래그 후엔 dot 1이 비활성 상태여야 한다');
      },
    );

    testWidgets(
      '마우스 클릭+드래그(Windows 데스크톱 실사용 환경)로도 대표이미지 → 코디 슬롯 스와이프가 동작한다 '
      '(2026-07-29 버그: `tester.drag`의 기본 pointer kind는 touch라 이 회귀를 못 잡았음 — '
      'Flutter 기본 `MaterialScrollBehavior.dragDevices`는 마우스를 포함하지 않아, 마우스로는 '
      'PageView가 전혀 반응하지 않았다. `lib/main.dart`의 `AppScrollBehavior`가 근본 수정)',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(PageView),
          const Offset(-400, 0),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<PageView>(find.byType(PageView)).controller!.page,
          closeTo(1.0, 0.01),
          reason: '마우스 드래그로도 페이지 2까지 완전히 스냅되어야 한다',
        );
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
      },
    );
  });

  // ── 2) 코디 카드 탭 → 코디 상세 → 뒤로가기 후 캐러셀 페이지 상태 유지 ─────────

  group('코디 카드 탭 → 코디 상세 → 뒤로가기 후 캐러셀 상태', () {
    testWidgets(
      '실제 드래그로 코디 슬롯까지 넘긴 뒤 카드를 탭해 comp01 상세로 이동하고, 뒤로가기하면 '
      '크래시 없이 스타일일지 열람으로 돌아오는데 이때 (같은 위젯 인스턴스가 살아있으므로) '
      '다시 스와이프하지 않아도 코디 슬롯이 그대로 보인다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '스타일일지');
        await tester.tap(find.byKey(const ValueKey('log01')));
        await tester.pumpAndSettle();
        await swipeToNextPage(tester);

        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        await tester.tap(find.byType(CompositionPreviewCard));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.byType(StyleLogViewerScreen), findsNothing);

        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.byType(CompositionDetailScreen), findsNothing);
        // 재진입/재스와이프 없이 바로 코디 슬롯(페이지 2)이 그대로 보인다 — 위젯 인스턴스가
        // 유지되어 `_page` 상태가 살아있었다는 방증.
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        expect(find.textContaining('데일리 룩'), findsOneWidget);
      },
    );
  });

  // ── 3) "착용 옷" 두 번째 이미지 탭 ────────────────────────────────────

  group('"착용 옷" 스트립 — 두 번째 이미지 탭', () {
    testWidgets(
      '착용 옷 스트립의 두 번째 이미지를 탭하면 그 옷 상세로 정확히 이동한다(원래 이 테스트는 log01의 '
      'c07을 대상으로 삼았으나, 2026-07-29 세션 초반 커밋 636f58e에서 c07이 소프트삭제로 바뀌어 '
      '탭이 막히는 게 정상 동작이 됨(그건 `deleted_item_badge_tap_block_regression_test.dart`가 '
      '이미 커버) — 이 테스트의 원래 의도인 "정상(비삭제) 아이템 탭 → 이동" 검증을 유지하기 위해 '
      'comp02 drift 수정 때와 동일하게 런타임으로 삭제되지 않은 아이템 2개짜리 로그를 주입한다)',
      (tester) async {
        final container = await pumpApp(tester);
        final wornItemsLog = StyleLog(
          id: 'test-worn-items-log',
          coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
          wornDate: DateTime(2026, 4, 1),
          additionalImagePaths: const [
            'assets/images/mock/IMG_4260_preview_rev_1.png', // c02 데님 팬츠 — 첫 번째, 비삭제
            'assets/images/mock/IMG_4261_preview_rev_1.png', // c03 그래픽 와이드팬츠 — 두 번째, 비삭제
          ],
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          wornItemsLog,
        ];

        final navContext = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(navContext)
            .push(AppRoute.styleLogViewer.replaceFirst(':id', 'test-worn-items-log'));
        await tester.pumpAndSettle();

        await tester.tap(find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4261_preview_rev_1.png',
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('그래픽 와이드팬츠'), findsOneWidget);
        expect(find.byType(StyleLogViewerScreen), findsNothing);
      },
    );
  });

  // ── 4) 미연결 스타일일지 — 실제 드래그로 "+" 플레이스홀더 도달 → 바인딩 E2E ────

  group('미연결 스타일일지 — 실제 드래그로 "+" 슬라이드 도달 후 바인딩', () {
    testWidgets(
      '미연결 로그를 격리 추가 → 실제 드래그로 코디 슬롯까지 넘기면 "+코디 연결하기" 플레이스홀더가 '
      '보이고 → 탭하면 코디 선택 모달이 열리고 → comp01 선택 → 화면을 떠나지 않고 캐러셀이 실제 '
      'CompositionPreviewCard로 바뀐다',
      (tester) async {
        final container = await pumpApp(tester);
        final unlinkedLog = StyleLog(
          id: 'test-unlinked-log-gesture',
          coverImagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png',
          wornDate: DateTime(2026, 2, 5),
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          unlinkedLog,
        ];

        final navContext = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(navContext)
            .push(AppRoute.styleLogViewer.replaceFirst(':id', 'test-unlinked-log-gesture'));
        await tester.pumpAndSettle();

        await swipeToNextPage(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('코디 연결하기'), findsOneWidget);
        expect(find.byType(CompositionPreviewCard), findsNothing);

        await tester.ensureVisible(find.text('코디 연결하기'));
        await tester.tap(find.text('코디 연결하기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionMainScreen), findsOneWidget);
        expect(find.byType(CompositionGalleryTile), findsNWidgets(2));

        await tester.tap(find.byKey(const ValueKey('comp01')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionMainScreen), findsNothing);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.byType(CompositionPreviewCard), findsOneWidget);
        expect(find.textContaining('데일리 룩'), findsOneWidget);
        expect(find.text('코디 연결하기'), findsNothing);

        final updatedLog = container
            .read(styleLogsProvider)
            .firstWhere((l) => l.id == 'test-unlinked-log-gesture');
        expect(updatedLog.linkedCompositionId, 'comp01');
      },
    );
  });

  // ── 5) 서로 다른 뷰포트에서 캐러셀 정사각 비율/오버플로 ──────────────────────

  group('뷰포트 크기별 — 캐러셀 정사각 비율 + 오버플로 없음', () {
    testWidgets('넓은(태블릿급) 뷰포트에서도 캐러셀이 정사각형을 유지하고 크래시가 없다',
        (tester) async {
      await pumpApp(tester, size: const Size(800, 1200));
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final pageViewSize = tester.getSize(find.byType(PageView));
      expect(pageViewSize.width, closeTo(pageViewSize.height, 0.5),
          reason: '넓은 뷰포트에서도 AspectRatio(1)로 캐러셀이 정사각형을 유지해야 한다');

      await swipeToNextPage(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionPreviewCard), findsOneWidget);
    });

    testWidgets('좁은(소형폰) 뷰포트에서도 캐러셀 정사각 비율이 유지되고 오버플로 예외가 없다',
        (tester) async {
      await pumpApp(tester, size: const Size(320, 600));
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final pageViewSize = tester.getSize(find.byType(PageView));
      expect(pageViewSize.width, closeTo(pageViewSize.height, 0.5));

      await swipeToNextPage(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionPreviewCard), findsOneWidget);
    });
  });
}
