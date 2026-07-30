import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

/// Tester 검증 — 스타일일지 "착용 옷" ID 참조 리팩터(`additionalImagePaths` 문자열 경로
/// 매칭 → `wornItemIds` ID 참조, `lib/models/style_log.dart`/`lib/screens/
/// style_log_viewer_screen.dart`)에서 Review가 코드로만 확인한 방어 코드(purge된 옷을
/// 참조하는 경우) 실측.
///
/// mock 데이터상 log01은 `wornItemIds: ['c11', 'c07']`을 실제로 참조한다. c07을 실제
/// 휴지통 UI 플로우(더보기/다중선택→영구 삭제→확인)로 완전히 purge한 뒤, log01 열람으로
/// 돌아와 크래시 없이 placeholder로 처리되는지 확인한다(지금까지 아무도 실제로 안 돌려본
/// 시나리오, Review는 코드 리딩으로만 확인함).
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
    'log01이 착용 옷으로 참조하는 c07을 실제 휴지통 UI로 영구삭제(purge)한 뒤 log01을 다시 '
    '열람해도 크래시 없이 회색 placeholder로 처리되고("삭제됨" 배지도 탭도 없음), 살아있는 '
    'c11은 여전히 정상 렌더링+탭으로 옷 상세 이동된다',
    (tester) async {
      final container = await pumpApp(tester);

      // ── 1) 실제 휴지통 UI로 c07을 완전히 purge (설정→휴지통, 2단계 push) ───────
      await goToCategory(tester, '설정');
      await tester.tap(find.text('휴지통'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashMainScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('c07')), findsOneWidget, reason: 'mock 기준 c07은 이미 휴지통에 있어야 한다');

      await tester.longPress(find.byKey(const ValueKey('c07')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.text('영구 삭제').first);
      await tester.pumpAndSettle();
      expect(find.text('영구 삭제'), findsWidgets, reason: '확인 다이얼로그가 실제로 떠야 한다');

      await tester.tap(find.text('영구 삭제').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('c07')), findsNothing, reason: '휴지통 그리드에서도 사라져야 한다');
      expect(
        container.read(closetItemsProvider).where((i) => i.id == 'c07'),
        isEmpty,
        reason: 'c07이 closetItemsProvider에서 완전히(soft-delete가 아니라 purge) 사라져야 한다',
      );

      // ── 2) 실제 탭 네비게이션으로 log01 열람으로 돌아간다 — 휴지통은 설정 위에
      //     push되어 있으므로(설정→휴지통), 옷장 메인까지 뒤로가기 2번이 필요하다. ─────
      await tester.tap(find.byTooltip('뒤로가기')); // 휴지통 → 설정
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('뒤로가기')); // 설정 → 옷장 메인
      await tester.pumpAndSettle();
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget, reason: '옷 참조가 깨져도 화면 자체는 크래시 없이 열려야 한다');

      // ── 3) "착용 옷" 섹션 — c11은 정상, c07(purge됨) 슬롯은 크래시 없이 회색 ───
      //     placeholder로 대체되고 탭도 배지도 없어야 한다.
      expect(find.text('착용 옷'), findsOneWidget, reason: 'wornItemIds가 여전히 2개라 섹션 자체는 계속 보여야 한다');

      final wornRow = find.byWidgetPredicate((w) => w is SizedBox && w.height == 96).first;
      final wornTiles = find.descendant(of: wornRow, matching: find.byType(GestureDetector));
      expect(wornTiles, findsNWidgets(2), reason: 'wornItemIds 2개 그대로 슬롯 2개가 렌더링되어야 한다(하나가 사라지면 안 됨)');

      // c11(살아있음) 슬롯 — 정상 이미지 + 탭 시 옷 상세 이동.
      final c11Image = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4262_preview_rev_1.png',
      );
      expect(c11Image, findsOneWidget, reason: 'c11은 살아있으니 정상 이미지로 렌더링되어야 한다');
      await tester.ensureVisible(c11Image);
      await tester.tap(c11Image);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('그래픽 맨투맨'), findsOneWidget, reason: 'c11 탭은 여전히 정상적으로 옷 상세로 이동해야 한다');

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // c07(purge됨) 슬롯 — 더 이상 실제 이미지가 없어야 하고(gray200 placeholder로 대체),
      // "삭제됨" 배지도 없어야 한다(item==null이라 isDeleted 배지 조건 자체가 적용 안 됨 —
      // "존재하지 않음"과 "소프트삭제됨"은 다른 상태이므로 서로 다른 배지 로직).
      final purgedImage = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4275.PNG',
      );
      expect(purgedImage, findsNothing, reason: 'purge된 c07의 원래 이미지가 더 이상 렌더링되면 안 된다');
      expect(find.widgetWithText(StatusBadge, '삭제됨'), findsNothing, reason: 'purge(완전삭제)는 소프트삭제 배지 대상이 아니다');

      final wornTilesAfter = find.descendant(of: wornRow, matching: find.byType(GestureDetector));
      final placeholderTile = wornTilesAfter.evaluate().last;
      Container? placeholderContainer;
      for (final element in find
          .descendant(of: find.byWidget(placeholderTile.widget), matching: find.byType(Container))
          .evaluate()) {
        final c = element.widget as Container;
        if (c.color != null) {
          placeholderContainer = c;
          break;
        }
      }
      expect(placeholderContainer, isNotNull, reason: '빈 슬롯 안에 색이 채워진 Container(placeholder)가 있어야 한다');
      expect(placeholderContainer!.color, AppSemanticColors.light.gray200, reason: '빈 슬롯은 gray200 회색 placeholder여야 한다');

      // purge된 슬롯은 탭해도 아무 일도 안 일어난다(onTap이 null이라 이동 자체가 없음).
      final placeholderGesture = placeholderTile.widget as GestureDetector;
      expect(placeholderGesture.onTap, isNull, reason: 'item을 못 찾으면 onTap 자체가 null로 배선되어야 한다');
      expect(tester.takeException(), isNull);
    },
  );
}
