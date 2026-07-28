import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — "삭제된 옷 배지+탭차단"(2026-07-29) P2 버그 수정.
///
/// Worker/Review는 격리된 `ProviderScope` override + `onTap` 콜백 직접 호출(위젯테스트,
/// `test/screens/composition_detail_screen_test.dart`/`style_log_viewer_screen_test.dart`)로만
/// 검증했다 — `AppMainScaffold` 헤더 오버레이가 widget-test 서페이스의 hitTest를 방해하는
/// 기존 환경 이슈(`docs/history/TechnicalDebt.md` 최상단) 때문에 물리 탭을 우회했다고 보고함.
/// 이 파일은 실제 device 바인딩(`integration_test`)에서 **진짜 물리 탭**(`tester.tap`)으로
/// 같은 동작을 재확인해, 1) 우회책이 감춘 실제 hitTest 결과가 맞는지, 2) mock 데이터
/// 그대로(런타임 조작 없이 comp01의 c07="리넨 반바지"가 이미 isDeleted:true, log01의
/// "착용 옷" 2번째 이미지도 c07과 동일 경로)로도 같은 화면 두 곳(코디 상세/스타일일지 열람)
/// 모두에서 배지+탭차단이 일관되는지 확인한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
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

  testWidgets(
    '코디 상세(comp01) — 삭제된 옷(c07)은 배지와 함께 그대로 보이고 실제 탭으로도 이동하지 '
    '않는다, 삭제 안 된 옷(c01/c11)은 실제 탭으로 정상 이동한다(회귀 없음)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text('데일리 룩'), findsOneWidget);

      // 사용된 옷 4개 전부 목록에서 제외되지 않고 그대로 보인다(삭제 여부와 무관).
      expect(find.text('플로럴 원피스'), findsOneWidget); // c01, 정상
      expect(find.text('그래픽 맨투맨'), findsOneWidget); // c11, 정상
      expect(find.text('리넨 반바지'), findsOneWidget); // c07, 삭제됨
      expect(find.text('그래픽 와이드팬츠'), findsOneWidget); // c03, 정상

      // 삭제된 c07 타일에만 "삭제됨" 배지가 실제로 그려진다.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('c07')),
          matching: find.widgetWithText(StatusBadge, '삭제됨'),
        ),
        findsOneWidget,
      );
      // 화면 전체로 봐도 배지는 정확히 1개(다른 3개 정상 아이템엔 없음).
      expect(find.widgetWithText(StatusBadge, '삭제됨'), findsOneWidget);

      // 삭제된 c07을 실제로 탭해도 옷 상세로 넘어가지 않는다.
      await tester.tap(find.byKey(const ValueKey('c07')), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // [비정형 흐름] settle 없이 빠르게 두 번 연속 탭해도(조급한 중복 탭) 크래시 없이
      // 여전히 아무 곳으로도 이동하지 않는다.
      await tester.tap(find.byKey(const ValueKey('c07')), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('c07')), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // 삭제 안 된 c01은 기존대로 실제 탭으로 옷 상세로 이동한다(회귀 없음).
      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('플로럴 원피스'), findsOneWidget);
      // 삭제 안 된 옷 상세엔 "삭제됨" 배지가 없다(옷 상세 화면 자체 헤더 배지는 별도 관심사 —
      // 여기선 상세 페이지 진입 성공 자체만 확인).

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // 삭제 안 된 c11도 기존대로 실제 탭으로 이동한다.
      await tester.tap(find.byKey(const ValueKey('c11')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);
    },
  );

  testWidgets(
    '스타일일지 열람(log01) — "착용 옷" 중 삭제된 옷(c07 이미지)은 배지와 함께 그대로 보이고 '
    '실제 탭으로도 이동하지 않는다, 삭제 안 된 옷(c11 이미지)은 실제 탭으로 정상 이동한다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // comp01 상세에서 연결된 스타일일지(log01) 타일을 실제 탭해 열람으로 이동.
      final logTile = find.byType(StyleLogGalleryTile);
      expect(logTile, findsOneWidget);
      await tester.ensureVisible(logTile);
      await tester.tap(logTile);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.text('착용 옷'), findsOneWidget);

      // "착용 옷" 첫 번째(c11, 정상) / 두 번째(c07, 삭제됨) 이미지를 실제 asset 경로로 찾는다.
      final normalImage = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4262_preview_rev_1.png',
      );
      final deletedImage = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4275.PNG',
      );
      expect(normalImage, findsOneWidget);
      expect(deletedImage, findsOneWidget);

      // 삭제된 이미지의 타일에만 "삭제됨" 배지가 실제로 그려진다.
      expect(
        find.descendant(
          of: find.ancestor(of: deletedImage, matching: find.byType(GestureDetector)),
          matching: find.widgetWithText(StatusBadge, '삭제됨'),
        ),
        findsOneWidget,
      );
      // 화면 전체로 봐도 배지는 정확히 1개.
      expect(find.widgetWithText(StatusBadge, '삭제됨'), findsOneWidget);

      // 삭제된 c07 이미지를 실제로 탭해도 옷 상세로 넘어가지 않는다.
      await tester.ensureVisible(deletedImage);
      await tester.tap(deletedImage, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // [비정형 흐름] settle 없이 빠르게 두 번 연속 탭해도 크래시 없이 여전히 이동하지 않는다.
      await tester.tap(deletedImage, warnIfMissed: false);
      await tester.pump();
      await tester.tap(deletedImage, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // 삭제 안 된 c11 이미지는 기존대로 실제 탭으로 옷 상세로 이동한다(회귀 없음).
      await tester.ensureVisible(normalImage);
      await tester.tap(normalImage);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);
    },
  );

  testWidgets(
    '스타일일지 열람(log01) — 연결된 코디(comp01)가 삭제(휴지통 이동)되면 "삭제됨" 배지가 실제로 '
    '보이고, 실제 탭으로도 코디 상세로 넘어가지 않는다(2026-07-29 P1: 기존엔 삭제 여부와 무관하게 '
    '정상 카드처럼 탭되어 코디 상세로 진입했음)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      // comp01을 실제 더보기→삭제 플로우로 소프트삭제한다(코디는 확인 팝업 없이 바로 삭제).
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);

      // log01은 comp01에 연결돼 있다 — 스타일일지 탭으로 이동해 log01을 직접 열람한다.
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // 코디 슬롯은 대표이미지 다음 페이지(2번) — 기본 PageView(viewportFraction 1.0)는
      // 인접 페이지를 미리 빌드해두지 않으므로, 실제로 보려면 컨트롤러로 명시적으로 넘겨야
      // 한다(다른 Detail PageView 테스트들과 동일 관례).
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
      await tester.pumpAndSettle();

      // 목록/슬롯에서 제외되지 않고("코디 연결하기" 자리로 폴백하지 않고) 그대로 보이며,
      // "삭제됨" 배지가 실제로 그려진다. log01의 "착용 옷"(c07, mock 데이터상 이미 삭제됨)에도
      // 별개의 "삭제됨" 배지가 있으므로, 화면 전체가 아니라 PageView(코디 슬롯) 범위로 좁혀
      // 확인한다.
      expect(find.text('코디 연결하기'), findsNothing);
      expect(find.text('데일리 룩'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.widgetWithText(StatusBadge, '삭제됨'),
        ),
        findsOneWidget,
      );

      // 실제로 탭해도 코디 상세로 넘어가지 않는다.
      final cardText = find.text('데일리 룩');
      await tester.tap(cardText, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.byType(CompositionDetailScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // [비정형 흐름] settle 없이 빠르게 두 번 연속 탭해도 크래시 없이 여전히 이동하지 않는다.
      await tester.tap(cardText, warnIfMissed: false);
      await tester.pump();
      await tester.tap(cardText, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
    },
  );
}
