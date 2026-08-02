import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_typography.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';

/// Tester 검증 — Audit P1 후속(`SelectionEntryButton` 공용 위젯 추출, "선택" 버튼 스타일
/// 누락 버그 수정) 회귀.
///
/// Review가 이미 재확인한 축(`typography_pass3_test.dart`: 옷장/코디/스타일일지 3화면의
/// "선택" 버튼 정적 스타일 일치 + 진입/종료만, `closet_main_screen_test.dart`/
/// `composition_style_log_main_screen_test.dart`: 각 화면 기능 전반)과 겹치지 않게, 이
/// 파일은 그 축들이 다루지 않는 3가지만 다룬다:
/// 1) **휴지통** "선택" 버튼의 실제 렌더 스타일(`typography_pass3_test.dart`는 옷장/코디/
///    스타일일지 3화면만 다루고 휴지통은 대상 밖) + 진입→아이템 실제 선택→닫기 흐름.
/// 2) 4화면 전부에서 "선택" 진입 후 **실제 아이템을 탭으로 선택**해 개수가 늘어나는지
///    (`typography_pass3_test.dart`의 비정형 흐름 테스트는 진입/종료만 확인하고 실제
///    아이템 선택은 안 함).
/// 3) 코디네이터가 요청한 "다중선택 모드에서 헤더 드롭다운으로 카테고리 이동" 비정형
///    흐름 — 실제로 돌려본 결과 `GalleryMainScreen`은 다중선택 모드에서
///    `showCategoryToggle`을 `false`로 강제해(코드 확인: `gallery_main_screen.dart`
///    `showCategoryToggle: widget.showCategoryToggle && !_multiSelectMode`) 카테고리
///    드롭다운 자체가 헤더에서 사라진다 — 즉 "다중선택 모드인 채로 드롭다운을 탭해 카테고리
///    이동"은 UI로 재현 불가능한 시나리오임을 실측으로 확인했다(아래 테스트가 이 부재
///    자체를 확인 대상으로 삼음). 그 대신 이 제약과 맞닿은 realistic한 인접 흐름 —
///    "화면 A에서 다중선택 진입→아이템 선택→닫기로 정상 종료→드롭다운으로 화면 B 이동→
///    거기서도 다중선택 진입→다시 드롭다운으로 화면 A 복귀"—를 검증해 화면 간 다중선택
///    상태(개수/모드)가 서로 누수되지 않는지 확인한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    '휴지통 — "선택" 버튼이 실제로 actionMinimal(11px, w500)로 렌더링되고, 탭→다중선택 '
    '진입→아이템 실제 선택(개수 증가)→닫기→원상복구까지 크래시 없이 동작한다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '설정');
      await tester.tap(find.text('휴지통'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashMainScreen), findsOneWidget);

      final selectText = tester.widget<Text>(find.text('선택'));
      expect(selectText.style, AppTypography.actionMinimal, reason: '휴지통 "선택" 버튼도 옷장/코디/스타일일지와 동일 스타일이어야 한다');

      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('선택'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('c07')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget, reason: '실제 아이템 탭으로 선택 개수가 늘어나야 한다');

      await tester.tap(find.byKey(const ValueKey('c08')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      // 휴지통의 닫기 버튼은 `FrostedCloseButton`(GlassCircleButton, tooltip 있음)이 아니라
      // 평범한 `TextButton(child: Text('닫기'))` — tooltip이 없다.
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2개 선택'), findsNothing);
      final restoredText = tester.widget<Text>(find.text('선택'));
      expect(restoredText.style, AppTypography.actionMinimal, reason: '닫기 후에도 원래 스타일 그대로 복원되어야 한다');
    },
  );

  testWidgets(
    '옷장/코디/스타일일지 — "선택" 진입 후 실제 아이템을 탭으로 선택하면 개수가 정확히 '
    '늘어나고, 닫기로 나가면 선택이 초기화된다(4화면 중 이 3화면, 실제 아이템 선택 축)',
    (tester) async {
      await pumpApp(tester);

      // 옷장.
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);

      // 코디.
      await goToCategory(tester, '코디');
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);

      // 스타일일지.
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[비정형 흐름 실측] 다중선택 모드에서는 카테고리 드롭다운 자체가 헤더에서 사라져 '
    '"다중선택 중 드롭다운으로 카테고리 이동"은 UI로 재현 불가능함을 확인 — 대신 인접한 '
    '실제 가능 흐름(화면A 다중선택 진입→선택→닫기→드롭다운으로 화면B 이동→거기서도 '
    '다중선택 진입)에서 화면 간 선택 상태가 누수되지 않는지 확인한다',
    (tester) async {
      await pumpApp(tester);

      // 옷장에서 다중선택 진입 — 드롭다운이 사라짐을 실측 확인.
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(
        find.byType(CategoryToggleDropdown),
        findsNothing,
        reason: '다중선택 모드에서는 카테고리 드롭다운이 헤더에서 완전히 사라져야 한다(showCategoryToggle=false)',
      );

      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      // 닫기로 정상 종료 → 드롭다운이 다시 나타남 → 코디로 이동.
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      await goToCategory(tester, '코디');

      // 코디 화면은 완전히 새 상태여야 한다 — 옷장에서 선택했던 "2개"가 전혀 남아있지 않다.
      expect(find.text('2개 선택'), findsNothing);
      expect(find.text('선택'), findsOneWidget, reason: '코디 메인은 다중선택모드가 아닌 초기 상태여야 한다');

      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget, reason: '코디 화면의 다중선택은 옷장과 독립적으로 0부터 시작해야 한다');

      // 코디에서도 닫기 없이 드롭다운으로 옷장으로 돌아가려 시도(드롭다운이 없으니 불가능함을
      // 재확인) — 닫기로 먼저 나가야만 드롭다운이 복귀한다.
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);

      await goToCategory(tester, '옷장');
      // 옷장으로 돌아와도 예전 "2개 선택" 잔재가 없다(다중선택모드 자체가 아님).
      expect(find.text('2개 선택'), findsNothing);
      expect(find.text('선택'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
