import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/providers/theme_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/classification_drilldown_capsule.dart';

/// Tester 검증 — Audit P1(다크모드 `primaryLight`가 `colorScheme.primary`와 동일값이라
/// `GlassToast`/휴지통 필터칩 텍스트가 배경에 묻히던 버그, `lib/theme/app_colors.dart`
/// `AppSemanticColors.dark.primaryLight` 0xFF93B5CC → 0xFF263F50) 수정.
///
/// `test/widgets/glass_toast_test.dart`/`integration_test/trash_scenarios_test.dart`에
/// Worker가 이미 추가한 다크모드 케이스(둘 다 위젯 속성 값 비교로 "primaryLight != 기본
/// 전경색" 확인)와 중복되지 않게, 이 파일은 값 계산만으로는 확인 못 하는 두 축만 다룬다:
/// 1) `CategoryToggleDropdown`/`ClassificationDrilldownCapsule` — 이 둘은 `TextButton`이
///    아니라 `Container.color`로 선택 항목을 하이라이트하므로 원래 버그(텍스트-배경 동일색)
///    자체는 없었지만, `primaryLight` 값이 바뀌며(밝은 파랑 → 어두운 남색) 팝업 메뉴 자체
///    배경(`colorScheme.surface` 0.96 alpha)과 더 가까워졌다 — 실제 라이브 위젯 트리에서
///    여전히 서로 다른 색으로 렌더링되고, 실제 탭으로 열기/선택/닫기가 정상 동작하는지.
/// 2) 실제 앱 흐름(다중선택 삭제)으로 다크모드에서 GlassToast를 띄워 "실행취소" 텍스트가
///    실제로 화면에 렌더링되고 탭하면 정상 복원되는지(단위 테스트가 아닌 통합 시나리오).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).set(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    '다크모드 — 카테고리 드롭다운을 실제로 열면 현재 선택된 항목("옷장")에 primaryLight '
    '배경이 실제로 적용되고, 그 색은 메뉴 자체 배경/colorScheme.primary와 다르며(둘 다와 '
    '뭉개지지 않음), 다른 카테고리를 실제 탭하면 정상 이동한다',
    (tester) async {
      await pumpApp(tester);
      expect(Theme.of(tester.element(find.byType(CategoryToggleDropdown))).brightness, Brightness.dark);

      // `CategoryToggleDropdown` 내부 `PopupMenuButton<T>`의 T(`_CategoryMenuEntry`)는
      // 이 위젯 파일에 private이라 외부에서 직접 제네릭으로 지정할 수 없다 — `is`/캐스트를
      // 제네릭 없이(`PopupMenuButton`, Dart 런타임 공변 규칙상 `PopupMenuButton<dynamic>`과
      // 동일하게 취급) 쓰면 T와 무관하게 안전하게 찾고 `color` 필드(제네릭과 무관)에
      // 접근할 수 있다.
      final popupFinder = find.descendant(
        of: find.byType(CategoryToggleDropdown),
        matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
      );
      final menuColor = tester.widget<PopupMenuButton>(popupFinder).color;

      await tester.tap(find.byType(CategoryToggleDropdown));
      await tester.pumpAndSettle();

      // "옷장"이 현재 카테고리이므로 그 행에만 primaryLight 배경이 실제로 그려진다.
      final highlighted = find.byWidgetPredicate(
        (w) => w is Container && w.color == AppSemanticColors.dark.primaryLight,
      );
      expect(highlighted, findsOneWidget, reason: '선택된 항목 1개에만 primaryLight 배경이 실제로 적용되어야 한다');

      final highlightColor = tester.widget<Container>(highlighted).color!;
      expect(highlightColor, isNot(menuColor), reason: '하이라이트 배경이 메뉴 자체 배경과 같은 값으로 뭉개지면 안 된다');
      expect(
        highlightColor,
        isNot(AppColors.dark.primary),
        reason: '이번 Audit이 고친 바로 그 회귀(highlight==colorScheme.primary) 재발 방지',
      );

      // 실제 탭으로 다른 카테고리("코디") 선택 → 정상 이동까지 확인(색상 변경이 인터랙션을
      // 깨지 않았는지).
      await tester.tap(find.text('코디').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('코디').first, findsOneWidget);
    },
  );

  testWidgets(
    '다크모드 — 분류 드릴다운 캡슐의 소분류를 실제 탭(계절→여름)으로 드릴인한 뒤 캡슐을 다시 '
    '열면 "여름" 항목에 primaryLight 하이라이트가 실제로 적용되고, 메뉴 자체 배경/'
    'colorScheme.primary와 다르다',
    (tester) async {
      await pumpApp(tester);

      final criterionDropdown = find.byType(PopupMenuButton<int>);
      await tester.tap(criterionDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('계절').last);
      await tester.pumpAndSettle();

      final subDropdown = find.byType(PopupMenuButton<int?>);
      expect(subDropdown, findsOneWidget, reason: '"계절"은 소분류를 가지므로 캡슐 2번째 세그먼트가 나타나야 한다');
      final subMenuColor = tester.widget<PopupMenuButton<int?>>(subDropdown).color;

      await tester.tap(subDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('여름').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 다시 열어 "여름" 항목의 실제 하이라이트를 확인한다.
      await tester.tap(find.byType(PopupMenuButton<int?>));
      await tester.pumpAndSettle();

      final highlighted = find.byWidgetPredicate(
        (w) => w is Container && w.color == AppSemanticColors.dark.primaryLight,
      );
      expect(highlighted, findsOneWidget, reason: '드릴인된 "여름" 항목 1개에만 primaryLight 배경이 실제로 적용되어야 한다');

      final highlightColor = tester.widget<Container>(highlighted).color!;
      expect(highlightColor, isNot(subMenuColor), reason: '하이라이트 배경이 메뉴 자체 배경과 같은 값으로 뭉개지면 안 된다');
      expect(highlightColor, isNot(AppColors.dark.primary));
      expect(find.byType(ClassificationDrilldownCapsule), findsOneWidget);
    },
  );

  testWidgets(
    '다크모드 — 실제 다중선택 삭제 흐름으로 뜬 GlassToast의 "실행취소" 텍스트가 실제로 '
    '보이고, 탭하면 실제로 복원된다(단위 테스트가 아닌 통합 시나리오)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(Theme.of(tester.element(find.byType(StyleLogMainScreen))).brightness, Brightness.dark);

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('실행취소'), findsOneWidget, reason: '다크모드에서도 실행취소 텍스트가 실제로 렌더링되어야 한다');

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('실행취소'), findsNothing);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isFalse);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02').isDeleted, isFalse);
    },
  );
}
