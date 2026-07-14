import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/screens/closet_add_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_add_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/widgets/editor_header.dart';
import 'package:digittal_wardrobe/widgets/glass_circle_button.dart';
import 'package:digittal_wardrobe/widgets/glass_pill.dart';

/// Step⑤(Editor/Add·Create 3화면 적용) Tester 검증.
///
/// 이 태스크로 새로 생긴 위험만 다룬다: skeleton 시절엔 없던 실제 네비게이션
/// (`EditorHeader`의 "취소" 버튼 → `context.pop()`)이 3개 화면 전부에서 실제로
/// 동작하는지, "?" 도움말 버튼이 Step⑦ stub 상태에서 크래시 없이 무동작인지,
/// `EditorHeader`가 TechDebt 해소 기록대로 Glass primitive가 아닌 원시
/// TextButton/IconButton으로 렌더링되는지.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 800);

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

  Finder categoryDropdownFinder() =>
      find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>);

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  // 옷장 메인/스타일일지 메인의 FAB는 펼침 메뉴(1건/여러건 옵션)를 거쳐야 Add 화면으로
  // 진입한다 — 두 옵션 모두 같은 라우트를 호출하므로, 펼침 후 첫 번째 옵션의 라벨
  // 텍스트를 직접 탭한다(내부 InkWell을 타입으로 찾으면 화면의 다른 InkWell과 섞여
  // 잘못된 위젯을 탭할 위험이 있다).
  Future<void> openViaExpandingFab(WidgetTester tester, String firstOptionLabel) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstOptionLabel));
    await tester.pumpAndSettle();
  }

  const closetFabOptionLabel = '한 장 추가하기';
  const styleLogFabOptionLabel = '1카드 추가';

  // ── 1) 화면 진입 + EditorHeader 렌더링 ───────────────────────────────────

  group('EditorHeader 렌더링 — 3개 Add/Create 화면', () {
    testWidgets('옷 추가하기 화면 진입 시 EditorHeader가 "취소" 텍스트버튼 + "?" 아이콘버튼을 렌더링한다',
        (tester) async {
      await pumpApp(tester);
      await openViaExpandingFab(tester, closetFabOptionLabel);

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetAddScreen), findsOneWidget);
      expect(find.byType(EditorHeader), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.byTooltip('도움말'), findsOneWidget);
    });

    testWidgets('코디 만들기 화면 진입 시 EditorHeader가 "취소" 텍스트버튼 + "?" 아이콘버튼을 렌더링한다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      expect(find.byType(EditorHeader), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.byTooltip('도움말'), findsOneWidget);
    });

    testWidgets('스타일일지 추가 화면 진입 시 EditorHeader가 "취소" 텍스트버튼 + "?" 아이콘버튼을 렌더링한다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await openViaExpandingFab(tester, styleLogFabOptionLabel);

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogAddScreen), findsOneWidget);
      expect(find.byType(EditorHeader), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.byTooltip('도움말'), findsOneWidget);
    });
  });

  // ── 2) "취소" 버튼 → 실제 pop 네비게이션 ─────────────────────────────────

  group('"취소" 버튼 — 실제 pop 네비게이션', () {
    testWidgets('옷 추가하기 화면에서 취소 탭 → 옷장 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await openViaExpandingFab(tester, closetFabOptionLabel);
      expect(find.byType(ClosetAddScreen), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(ClosetAddScreen), findsNothing);
    });

    testWidgets('코디 만들기 화면에서 취소 탭 → 코디 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionEditorScreen), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(CompositionEditorScreen), findsNothing);
    });

    testWidgets('스타일일지 추가 화면에서 취소 탭 → 스타일일지 메인으로 pop된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await openViaExpandingFab(tester, styleLogFabOptionLabel);
      expect(find.byType(StyleLogAddScreen), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.byType(StyleLogAddScreen), findsNothing);
    });

    testWidgets('[비정형 흐름] 코디 만들기 화면에서 취소를 pumpAndSettle 없이 연속으로 두 번 빠르게 탭해도 크래시 없이 코디 메인으로 돌아간다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionEditorScreen), findsOneWidget);

      final cancelButton = find.text('취소');
      await tester.tap(cancelButton);
      await tester.pump(const Duration(milliseconds: 16));
      // 이 시점에 이미 pop 애니메이션이 진행 중이라 같은 화면의 "취소"가 더 이상 없을 수
      // 있다 — 남아있다면 한 번 더 탭해 중복 pop 시도 시 크래시가 없는지 확인한다.
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(CompositionEditorScreen), findsNothing);
    });
  });

  // ── 3) "?" 도움말 버튼 — Step⑦ 이전 stub, 크래시 없이 무동작 ────────────

  group('"?" 도움말 버튼 — stub 상태, 크래시 없이 무동작', () {
    testWidgets('옷 추가하기 화면에서 도움말 탭 → 크래시 없고 화면 전환도 없다', (tester) async {
      await pumpApp(tester);
      await openViaExpandingFab(tester, closetFabOptionLabel);

      await tester.tap(find.byTooltip('도움말'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetAddScreen), findsOneWidget);
    });

    testWidgets('코디 만들기 화면에서 도움말 탭 → 크래시 없고 화면 전환도 없다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('도움말'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
    });

    testWidgets('스타일일지 추가 화면에서 도움말 탭 → 크래시 없고 화면 전환도 없다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await openViaExpandingFab(tester, styleLogFabOptionLabel);

      await tester.tap(find.byTooltip('도움말'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogAddScreen), findsOneWidget);
    });
  });

  // ── 4) Glass primitive 미사용 확인 (TechDebt 해소 기록 — 의도된 예외) ────

  group('EditorHeader — Glass primitive 미사용 확인', () {
    testWidgets('EditorHeader 하위에 GlassPill/GlassCircleButton이 없고, 원시 TextButton/IconButton으로 렌더링된다',
        (tester) async {
      await pumpApp(tester);
      await openViaExpandingFab(tester, closetFabOptionLabel);
      expect(find.byType(EditorHeader), findsOneWidget);

      expect(
        find.descendant(of: find.byType(EditorHeader), matching: find.byType(GlassPill)),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(EditorHeader), matching: find.byType(GlassCircleButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(EditorHeader), matching: find.byType(TextButton)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(EditorHeader), matching: find.byType(IconButton)),
        findsOneWidget,
      );
    });
  });
}
