import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
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
}
