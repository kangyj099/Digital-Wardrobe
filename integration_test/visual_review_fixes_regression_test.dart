import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Tester 검증 — "사용자 실사용 Visual Review" 버그 3건 + 시각수정 2건 보강.
///
/// Worker가 이미 수정한 4개 integration_test 파일(closet_multi_select_test.dart,
/// style_log_carousel_gesture_test.dart, trash_scenarios_test.dart)과 기존
/// glass_toast_hitbox_regression_test.dart가 다루지 않는 두 축만 추가한다:
/// 1) `tester.drag`(단일 점프)가 아니라, 실제 마우스 다운→여러 단계 이동→업으로 구성된
///    수동 제스처로도 `AppScrollBehavior`가 반응하는지(Threshold/슬롭 관련 미묘한 차이를
///    단일 점프 드래그는 가릴 수 있음).
/// 2) [비정형 흐름] 휴지통에서 다중선택 모드와 필터칩 다중선택을 동시에 조작해도 두 상태가
///    서로 오염되지 않는지(필터로 안 보이게 된 항목이 선택 대상에서 조용히 빠지거나, 필터
///    변경이 기존 선택을 건드리지 않는지).
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
    '수동 마우스 제스처(다운→여러 단계 이동→업, tester.drag 단일 점프가 아님)로도 스타일일지 '
    '열람의 대표이미지→코디 슬롯 스와이프가 동작한다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      final pageViewRect = tester.getRect(find.byType(PageView));
      final pageViewCenter = pageViewRect.center;
      // PageView 실제 폭의 60%를 왼쪽으로 이동 — fling 속도 threshold에 기대지 않고
      // 이동 거리 자체만으로도 다음 페이지로 넘어가는 게 보장되는 실사용 드래그 거리.
      final totalDx = -pageViewRect.width * 0.6;
      const steps = 8;
      final stepDx = totalDx / steps;

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: pageViewCenter);
      await tester.pump();
      await gesture.down(pageViewCenter);
      await tester.pump(const Duration(milliseconds: 16));
      // 마우스 다운 후 여러 단계에 걸쳐 왼쪽으로 이동 — 실제 사용자가 마우스 버튼을 누른 채
      // 손을 이동시키는 것과 동일한 형태(한 번에 점프가 아니라 여러 단계로 나눠서).
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(Offset(stepDx, 0));
        if (i < steps - 1) await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1.0, 0.01),
        reason: '단계적 마우스 드래그로도 코디 슬롯(페이지 2)까지 완전히 스냅되어야 한다',
      );
      expect(find.byType(CompositionPreviewCard), findsOneWidget);
    },
  );

  testWidgets(
    '[비정형 흐름] 휴지통 — 필터칩으로 "옷장"만 보이게 좁힌 뒤 다중선택으로 2개를 고르고, '
    '선택 모드를 유지한 채 필터칩에 "코디"를 추가로 켜서 화면에 새 항목(comp02)이 나타나도 '
    '기존 선택(2개)은 그대로 유지되고 새로 보인 항목은 자동 선택되지 않으며, 그 상태로 '
    '[복원]하면 원래 선택했던 2개만 정확히 복원된다',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      expect(find.byType(TrashMainScreen), findsOneWidget);
      // mock 기본 삭제 항목: c07/c08(옷장), comp02(코디) — 3개.
      expect(find.byType(TrashGalleryTile), findsNWidgets(3));

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(2), reason: '옷장 필터로 c07/c08만 보여야 한다');

      await tester.longPress(find.byKey(const ValueKey('c07')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c08')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      // 다중선택 모드를 유지한 채 필터칩에 "코디"를 추가(다중선택 필터) — comp02가 화면에
      // 새로 나타나야 하지만, 기존 선택 개수(2개)는 영향받지 않아야 한다.
      await tester.tap(find.text('코디'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TrashGalleryTile), findsNWidgets(3), reason: '옷장+코디 합집합 3개가 보여야 한다');
      expect(find.text('2개 선택'), findsOneWidget, reason: '필터 변경만으로 기존 선택 개수가 바뀌면 안 된다');

      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final closetItems = container.read(closetItemsProvider);
      final compositions = container.read(compositionsProvider);
      expect(closetItems.firstWhere((i) => i.id == 'c07').isDeleted, isFalse,
          reason: '선택했던 c07은 복원되어야 한다');
      expect(closetItems.firstWhere((i) => i.id == 'c08').isDeleted, isFalse,
          reason: '선택했던 c08은 복원되어야 한다');
      expect(compositions.firstWhere((c) => c.id == 'comp02').isDeleted, isTrue,
          reason: '선택하지 않은 comp02는 필터에 새로 보였다는 이유만으로 함께 복원되면 안 된다');
    },
  );
}
