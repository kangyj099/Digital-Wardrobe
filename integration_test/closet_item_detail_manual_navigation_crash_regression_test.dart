import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_carousel.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — `closet_item_detail_revisit_setstate_during_build_regression_test.dart`/
/// `closet_item_detail_duplicate_push_setstate_during_build_regression_test.dart`(Worker 자체
/// 회귀테스트, GoRouter.push를 직접 호출하는 프로그래매틱 네비게이션)와 별개로, 사용자가
/// 실제로 화면을 손가락으로 탭하며 돌아다니는 관점에서 같은 버그를 재확인한다. 이 파일의
/// 모든 화면 전환은 `tester.tap`으로 실제 위젯(타일/카드/버튼)을 눌러서 발생시킨다 —
/// `GoRouter.of(context).push(...)`를 직접 호출하지 않는다.
///
/// 사용자의 실제 재연 스텝(PM 전달): 1) 코디 2개 이상에 등록된 옷 하나를 삭제 → 2) 그 옷이
/// 포함된 코디 중 하나를 통째로 삭제 → 3) 그 옷이 포함돼 있지만 삭제 안 된 코디의 상세
/// 화면 진입 → 4) 옷 상세/코디 상세/스타일일지 화면들을 무작위 순서로 계속 진입(pop 없이
/// push만) → 5) 뒤로가기 연타.
///
/// mock_data.dart 원본엔 "살아있는 코디 2개 이상에 쓰이는 옷"이 없다(comp02가 c04/c05를
/// comp03과 공유하지만 comp02는 이미 isDeleted:true 상태로 시작한다). `CompositionEditorScreen`이
/// 아직 저장 기능 없는 skeleton이라 코디 생성 자체를 UI로 만들 수 없으므로(스코프 밖),
/// 이 사전조건만 `compositionsProvider` state에 코디 하나를 직접 얹어 만든다(Worker의
/// duplicate_push 회귀테스트가 comp_extra를 만든 것과 동일한 패턴/사유) — 이후의 모든 조작은
/// 실제 탭으로 진행한다.
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
    '실사용 재연: 코디 2개 이상에 쓰인 옷을 옷장에서 탭으로 삭제 → 그 코디 중 하나를 코디 '
    '메인에서 탭으로 삭제 → 살아남은 코디 상세 진입 → 옷/코디/스타일일지 상세를 카드 탭으로 '
    '무작위로 계속 파고듦(pop 없음) → 뒤로가기 연타까지 크래시 없이 완주한다',
    (tester) async {
      final container = await pumpApp(tester);

      // 사전조건 — c11(그래픽 맨투맨)을 comp01 외에 comp_extra_manual에도 쓰이게 만들어
      // "코디 2개 이상에 등록된 옷"이라는 실제 사용자 재연 조건을 충족시킨다.
      final compExtra = Composition(
        id: 'comp_extra_manual',
        name: '테스터 추가 코디',
        createdAt: DateTime(2026, 3, 5),
        items: const [CompositionItemPlacement(clothingItemId: 'c11', x: 40, y: 40, zIndex: 0)],
      );
      container.read(compositionsProvider.notifier).state = [
        ...container.read(compositionsProvider),
        compExtra,
      ];
      await tester.pumpAndSettle();

      // ── 1) 옷장 메인에서 c11을 롱프레스+삭제 탭으로 실제 삭제(휴지통 이동) ──────────
      await tester.longPress(find.byKey(const ValueKey('c11')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // c11이 2개의 살아있는 코디에 쓰이므로 사전 경고 모달이 떠야 한다.
      expect(find.text('사용 중인 코디가 있어요'), findsOneWidget);
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c11').isDeleted,
          isFalse, reason: '아직 확인 모달을 안 눌렀으니 삭제되지 않아야 한다');

      await tester.tap(find.text('휴지통으로 이동'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('1개 선택'), findsNothing);
      expect(
          container.read(closetItemsProvider).firstWhere((i) => i.id == 'c11').isDeleted, isTrue);

      // ── 2) 코디 메인으로 이동해 c11이 쓰인 코디 중 하나(comp_extra_manual)를 탭으로 삭제 ──
      await goToCategory(tester, '코디');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('comp_extra_manual')), findsOneWidget);
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('comp_extra_manual')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('comp_extra_manual')), findsNothing);
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget,
          reason: 'c11이 쓰인 나머지 하나(comp01)는 살아있어야 한다');
      expect(
          container.read(compositionsProvider).firstWhere((c) => c.id == 'comp_extra_manual').isDeleted,
          isTrue);

      // ── 3) 살아남은 코디(comp01) 상세로 진입(탭) — c11이 여전히 "사용된 옷"에 보인다 ──
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text('데일리 룩'), findsOneWidget);
      expect(find.byKey(const ValueKey('c11')), findsOneWidget);

      // ── 4) pop 없이 카드/타일 탭만으로 옷 상세 ↔ 코디 상세 ↔ 스타일일지 열람을 무작위로
      //     계속 파고든다 — 이 구간이 원래 크래시가 실제로 재현됐던 사용자 흐름이다. ──────

      // 4-a) 삭제된 c11 상세로 진입(코디 상세 안의 "사용된 옷" 타일 탭).
      await tester.tap(find.byKey(const ValueKey('c11')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);

      // 4-b) 이 옷 상세에서 연결된 코디 카드(comp01, comp_extra_manual은 삭제되어 제외)를
      //     탭 → comp01 상세로 다시 push(같은 코디를 pop 없이 재진입).
      expect(find.byType(CompositionPreviewCarousel), findsOneWidget);
      final compCard1 = find.byType(CompositionPreviewCard);
      expect(compCard1, findsOneWidget, reason: 'comp_extra_manual 삭제로 comp01만 남아야 한다');
      await tester.tap(compCard1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // 4-c) 이 코디 상세에서 연결된 스타일일지(log01) 타일 탭 → 스타일일지 열람으로 push.
      final logTile = find.byType(StyleLogGalleryTile);
      expect(logTile, findsOneWidget);
      await tester.ensureVisible(logTile);
      await tester.tap(logTile);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      // 4-d) 스타일일지 열람의 "착용 옷" 스트립에서 c11 이미지를 탭 → c11 상세로 또 push
      //     (같은 itemId c11을 pop 없이 다시 push하는, Review가 지적한 바로 그 경로를 실제
      //     탭 제스처로 재현).
      expect(find.text('착용 옷'), findsOneWidget);
      final wornC11Image = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/mock/IMG_4262_preview_rev_1.png',
      );
      await tester.ensureVisible(wornC11Image);
      await tester.tap(wornC11Image);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);

      // 4-e) 다시 comp01 카드를 탭(3번째 comp01 재push) → 사용된 옷 중 c01(다른 옷)을 탭
      //     해 화면을 다양화한다.
      final compCard2 = find.byType(CompositionPreviewCard);
      expect(compCard2, findsOneWidget);
      await tester.tap(compCard2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('플로럴 원피스'), findsOneWidget);

      // 4-f) c01 상세에서 다시 comp01 카드를 탭(4번째 comp01 재push).
      final compCard3 = find.byType(CompositionPreviewCard);
      expect(compCard3, findsOneWidget);
      await tester.tap(compCard3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // 4-g) [비정형 흐름] 이 코디 상세에서 c11 타일을 settle 없이 빠르게 두 번 연속 탭
      //     (사용자가 반응이 느리다고 느껴 조급하게 두 번 누르는 흔한 패턴) → c11 상세로
      //     또 push(3번째 c11 재push, 이번엔 pumpAndSettle 없이 즉시 연속 탭).
      final c11TileInComp = find.byKey(const ValueKey('c11'));
      expect(c11TileInComp, findsOneWidget);
      await tester.tap(c11TileInComp, warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final maybeSecondTap = find.byKey(const ValueKey('c11'));
      if (maybeSecondTap.evaluate().isNotEmpty) {
        await tester.tap(maybeSecondTap, warnIfMissed: false);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('그래픽 맨투맨'), findsOneWidget);

      // ── 5) 뒤로가기를 스택 끝까지 연타(각 pop 사이 pumpAndSettle 없이 pump()만) ─────
      var popCount = 0;
      while (true) {
        final backButtons = find.byTooltip('뒤로가기');
        if (backButtons.evaluate().isEmpty) break;
        await tester.tap(backButtons.first, warnIfMissed: false);
        await tester.pump();
        popCount++;
        final ex = tester.takeException();
        if (ex != null) {
          if (ex.toString().contains('nothing to pop')) break;
          fail('뒤로가기 $popCount번째에서 크래시: $ex');
        }
        if (popCount > 40) fail('뒤로가기가 40번을 넘었다 — 무한루프 의심');
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // context.go 기반 카테고리 이동으로 스택 루트가 코디 메인이었으므로, 끝까지 뒤로가기를
      // 연타하면 코디 메인으로 돌아와야 한다(캡처 안 된 잔여 화면/루프 없음).
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(popCount, greaterThan(0));

      // ── 최종 데이터 정합성 — 깊은 네비게이션 이후에도 상태가 그대로 유지된다 ─────────
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c11').isDeleted, isTrue);
      expect(
          container.read(compositionsProvider).firstWhere((c) => c.id == 'comp_extra_manual').isDeleted,
          isTrue);
      expect(container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isDeleted,
          isFalse);
    },
  );
}
