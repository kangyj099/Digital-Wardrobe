// integration_test/composition_editor_screen_test.dart
//
// Tester가 직접 설계한 런타임 검증 스위트(Task A, InteractiveArtboard 연결) — Worker가
// Editor Draft/Commit/Cancel 리워크(`docs/history/Decision.md` "Editor 저장 모델 전환")에
// 맞춰 기존 시나리오를 갱신했다. `interactive_artboard_test.dart`는 `InteractiveArtboard`
// 자체를 독립 위젯으로만 검증하므로(전용 테스트 호스트), 여기서는 그 위젯이 실제
// `CompositionEditorScreen` + Draft(`compositionDraftProvider`)/Record(`compositionsProvider`,
// Riverpod)와 올바르게 배선됐는지만 다룬다: 기존 코디 로드, 제스처 커밋의 Draft 즉시 반영
// (Record는 완료 전까지 불변), 완료(✔) 시점의 Record Commit, 취소(✕) 시점의 Draft 폐기
// (Rollback), 겹침 팝업, 배경색 스와치(Draft 로컬), 신규 생성 진입+커밋, 드래그아웃 삭제의
// Draft/Commit 반영.
//
// `compositionEditorWithId`(기존 코디 편집) 라우트는 이번 스코프에 진입 UI가 없어
// (다른 화면에서 아직 링크되지 않음) `appRouterProvider`를 통해 직접 push한다 —
// `trash_scenarios_test.dart` 등 기존 스위트가 쓰는 것과 동일한 패턴.
//
// 참고: 과거 이 화면을 벗어날 때(취소/뒤로가기 등)마다 `dispose()`의 `ref` 오용으로
// 매번 처리되지 않은 StateError가 발생하던 버그가 있었다 — Worker가 수정했고, 그
// 재발 방지 검증은 `composition_editor_dispose_crash_regression_test.dart`가 전담한다.
// 여기 각 시나리오는 화면 이탈 지점에서 `exitEditor()`/`commitEditor()`로 여분의 프레임을
// 흘려보낸 뒤 예외가 없는지도 함께 확인한다(`IntegrationTestWidgetsFlutterBinding`의 "live"
// 프레임 스케줄링 특성상 unmount 마무리가 다음 실제 프레임으로 미뤄질 수 있어, 이
// 드레인 없이는 예외가 이 테스트가 아니라 엉뚱하게 다음 테스트로 새어나가 오귀속될
// 수 있다).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_editor_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_background_color.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_overlap_popup.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/interactive_artboard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `editor_header_navigation_test.dart`와 동일한 화면 크기 — 이미 이 크기에서
  // EditorHeader + AspectRatio 캔버스가 정상 레이아웃됨이 검증돼 있다.
  const defaultSize = Size(390, 800);

  // Pan 인식기의 이동 임계값(터치 슬롭)을 넘기기 위한 "아밍" 이동량
  // (`interactive_artboard_test.dart`와 동일 근거 — 임계값을 넘긴 첫 이동은
  // onPanUpdate로 보고되지 않는다).
  const armOffset = Offset(50, 50);

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

  Finder visualOf(String clothingItemId) => find.byKey(ValueKey('$clothingItemId:visual'));

  Finder labelFinder(String label) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      );

  Future<void> openExisting(WidgetTester tester, ProviderContainer container, String id) async {
    container.read(appRouterProvider).push('/composition/editor/$id');
    await tester.pumpAndSettle();
  }

  // `IntegrationTestWidgetsFlutterBinding`(Windows 데스크톱 "live" 바인딩)은 element
  // unmount 마무리를 실제 vsync 콜백에 맡길 수 있어, 가상 시계만 진행시키는 pump()
  // 호출만으론 충분하지 않을 때가 있었다(관찰됨) — 실제 벽시계 지연을 섞어 엔진이
  // 실제로 다음 프레임을 그릴 시간을 준다. 이렇게 이 테스트 안에서 미리 흘려보내지
  // 않으면, 그 예외가 이 테스트가 아니라 다음 테스트로 새어나가 오귀속될 수 있다.
  Future<void> drainDeferredFrames(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
  }

  // 화면을 벗어난 뒤(취소 탭 — Draft 폐기/Rollback) 예외 없이 정상 종료되는지까지
  // 확인하고 정리한다.
  Future<void> exitEditor(WidgetTester tester) async {
    final cancelButton = find.text('취소');
    if (cancelButton.evaluate().isNotEmpty) {
      await tester.tap(cancelButton, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await drainDeferredFrames(tester);
    expect(tester.takeException(), isNull, reason: '화면 이탈(취소) 후 예외 없이 종료돼야 함');
  }

  // 화면을 벗어난 뒤(완료 탭 — Draft → Record Commit) 예외 없이 정상 종료되는지까지
  // 확인하고 정리한다.
  Future<void> commitEditor(WidgetTester tester) async {
    final commitButton = find.byTooltip('완료');
    await tester.tap(commitButton);
    await tester.pumpAndSettle();
    await drainDeferredFrames(tester);
    expect(tester.takeException(), isNull, reason: '화면 이탈(완료) 후 예외 없이 종료돼야 함');
  }

  // ── 1. 기존 코디 로드 ──────────────────────────────────────────────────────
  testWidgets('comp01 id로 편집기 진입 시 실제 4개 아이템이 아트보드에 렌더된다', (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionEditorScreen), findsOneWidget);
    expect(find.byType(InteractiveArtboard), findsOneWidget);
    for (final id in ['c01', 'c11', 'c07', 'c03']) {
      expect(visualOf(id), findsOneWidget, reason: 'comp01의 $id가 렌더되지 않음');
    }

    await exitEditor(tester);
  });

  // ── 2. 드래그(이동) → Draft에만 즉시 반영, Record는 완료 전까지 불변 ─────────
  testWidgets(
      '아이템 드래그는 Draft에 즉시 반영되지만 완료(✔) 전까지 compositionsProvider(Record)는 그대로다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    CompositionItemPlacement recordPlacementC01() => container
        .read(compositionsProvider)
        .firstWhere((c) => c.id == 'comp01')
        .items
        .firstWhere((p) => p.clothingItemId == 'c01');
    CompositionItemPlacement draftPlacementC01() => container
        .read(compositionDraftProvider('comp01'))
        .items
        .firstWhere((p) => p.clothingItemId == 'c01');

    final recordBefore = recordPlacementC01();
    final draftBefore = draftPlacementC01();

    final gesture = await tester.startGesture(tester.getCenter(visualOf('c01')));
    await gesture.moveBy(armOffset); // 아밍 — 결과 계산에서 제외
    await tester.pump();
    expect(draftPlacementC01().x, draftBefore.x, reason: '아밍 이동만으로 커밋되면 안 됨');
    await gesture.moveBy(const Offset(20, 12));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final draftAfterDrag = draftPlacementC01();
    expect(draftAfterDrag.x, isNot(draftBefore.x), reason: '드래그 종료 후 x가 Draft에 즉시 반영돼야 함');
    expect(draftAfterDrag.y, isNot(draftBefore.y), reason: '드래그 종료 후 y가 Draft에 즉시 반영돼야 함');
    expect(recordPlacementC01().x, recordBefore.x, reason: '완료(commit) 전까지 Record x는 바뀌면 안 됨');
    expect(recordPlacementC01().y, recordBefore.y, reason: '완료(commit) 전까지 Record y는 바뀌면 안 됨');
    expect(tester.takeException(), isNull, reason: '드래그 커밋 자체는 예외 없이 끝나야 함');

    // 취소 — Draft 폐기, Record는 진입 이전 상태 그대로(Rollback) 유지돼야 한다.
    await exitEditor(tester);
    expect(recordPlacementC01().x, recordBefore.x, reason: '취소 후에도 Record x는 원래대로여야 함(Rollback)');
    expect(recordPlacementC01().y, recordBefore.y, reason: '취소 후에도 Record y는 원래대로여야 함(Rollback)');
  });

  // ── 3. 드래그(이동) → 완료(✔) → Record Commit, 재진입 시 Draft가 그 값으로 초기화 ──
  testWidgets('아이템 드래그 후 완료(✔)하면 Record에 반영되고, 다시 열면 그 값으로 Draft가 시작한다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    CompositionItemPlacement recordPlacementC01() => container
        .read(compositionsProvider)
        .firstWhere((c) => c.id == 'comp01')
        .items
        .firstWhere((p) => p.clothingItemId == 'c01');

    final before = recordPlacementC01();

    final gesture = await tester.startGesture(tester.getCenter(visualOf('c01')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(20, 12));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    await commitEditor(tester);

    final afterCommit = recordPlacementC01();
    expect(afterCommit.x, isNot(before.x), reason: '완료 후 x가 Record에 반영돼야 함');
    expect(afterCommit.y, isNot(before.y), reason: '완료 후 y가 Record에 반영돼야 함');
    expect(find.byType(CompositionEditorScreen), findsNothing);

    await openExisting(tester, container, 'comp01');
    final reentered = container
        .read(compositionDraftProvider('comp01'))
        .items
        .firstWhere((p) => p.clothingItemId == 'c01');
    expect(reentered.x, afterCommit.x, reason: '재진입 시 Draft가 Commit된 Record 값으로 초기화돼야 함');
    expect(reentered.y, afterCommit.y);
    expect(visualOf('c01'), findsOneWidget, reason: '재진입 시 커밋된 위치로 다시 렌더돼야 함');

    await exitEditor(tester);
  });

  // ── 4. 크기조절/회전 핸들 → Draft 즉시 반영, 완료 시 Record 반영 ─────────────
  testWidgets('크기조절/회전 핸들 조작이 Draft에 반영되고, 완료(✔) 시 Record의 scale/rotation에 반영된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    CompositionItemPlacement draftC11() => container
        .read(compositionDraftProvider('comp01'))
        .items
        .firstWhere((p) => p.clothingItemId == 'c11');
    CompositionItemPlacement recordC11() => container
        .read(compositionsProvider)
        .firstWhere((c) => c.id == 'comp01')
        .items
        .firstWhere((p) => p.clothingItemId == 'c11');

    expect(draftC11().scale, 1.0);
    expect(draftC11().rotation, 0.0);

    await tester.tapAt(tester.getCenter(visualOf('c11')));
    await tester.pumpAndSettle();
    expect(labelFinder('크기조절 핸들'), findsOneWidget);
    expect(labelFinder('회전 핸들'), findsOneWidget);

    var gesture = await tester.startGesture(tester.getCenter(labelFinder('크기조절 핸들')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 30)); // 중심에서 멀어지는 방향 = 확대
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final scaleAfterResize = draftC11().scale;
    expect(scaleAfterResize, isNot(1.0), reason: '크기조절 핸들 조작이 Draft에 즉시 반영돼야 함');
    expect(draftC11().rotation, 0.0, reason: '크기조절만으론 rotation이 바뀌면 안 됨');
    expect(recordC11().scale, 1.0, reason: '완료(commit) 전까지 Record scale은 그대로여야 함');

    gesture = await tester.startGesture(tester.getCenter(labelFinder('회전 핸들')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(draftC11().rotation, isNot(0.0), reason: '회전 핸들 조작이 Draft에 즉시 반영돼야 함');
    expect(draftC11().scale, closeTo(scaleAfterResize, 0.01),
        reason: '회전 후 scale은 직전 크기조절 값 그대로 유지돼야 함');
    expect(tester.takeException(), isNull, reason: '크기조절/회전 커밋 자체는 예외 없이 끝나야 함');

    await commitEditor(tester);
    expect(recordC11().scale, closeTo(scaleAfterResize, 0.01), reason: '완료 후 Record에 scale이 반영돼야 함');
    expect(recordC11().rotation, isNot(0.0), reason: '완료 후 Record에 rotation이 반영돼야 함');
  });

  // ── 5. 겹침 처리 ──────────────────────────────────────────────────────────
  testWidgets('겹치게 배치된 아이템 2개의 공유 영역을 탭하면 겹침 팝업이 뜬다', (tester) async {
    final container = await pumpApp(tester);
    container.read(compositionsProvider.notifier).add(
          Composition(
            id: 'test_overlap',
            name: '겹침 테스트',
            createdAt: DateTime(2026, 1, 1),
            items: const [
              CompositionItemPlacement(clothingItemId: 'c01', x: 0.5, y: 0.5, zIndex: 0),
              CompositionItemPlacement(clothingItemId: 'c02', x: 0.5, y: 0.5, zIndex: 1),
            ],
          ),
        );

    await openExisting(tester, container, 'test_overlap');
    expect(tester.takeException(), isNull);
    expect(visualOf('c01'), findsOneWidget);
    expect(visualOf('c02'), findsOneWidget);
    expect(find.byType(ArtboardOverlapPopup), findsNothing);

    await tester.tapAt(tester.getCenter(visualOf('c02'))); // zIndex 최댓값 = 최상단
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // 팝업의 전체화면 배리어(Overlay, 앱 위젯 트리 최상단)가 열려있는 채로 "취소"를
    // 탭하면 그 탭이 배리어에 먼저 가로채여 팝업만 닫힐 뿐 실제로 화면을 벗어나지
    // 않는다 — 먼저 팝업을 닫아야 exitEditor()의 "취소" 탭이
    // 실제 EditorHeader 버튼에 도달한다.
    await tester.tapAt(const Offset(20, 20)); // 팝업 카드 밖 배리어 탭 → 팝업만 닫힘
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsNothing);

    await exitEditor(tester);
  });

  // ── 6. 배경색 스와치: 버튼→4개 노출→선택→캔버스 반영(Draft 로컬) ─────────────
  testWidgets('배경색 버튼을 탭해 스와치 4개를 펼치고, 하나를 선택하면 캔버스 배경에 즉시 반영된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.white.value,
      reason: '초기 배경은 흰색이어야 함',
    );

    await tester.tap(labelFinder('배경색 버튼'));
    await tester.pumpAndSettle();

    for (final color in ArtboardBackgroundColor.values) {
      expect(labelFinder('배경색: ${color.label}'), findsOneWidget, reason: '${color.label} 스와치 없음');
    }

    await tester.tap(labelFinder('배경색: ${ArtboardBackgroundColor.darkGray.label}'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.darkGray.value,
      reason: '스와치 선택이 캔버스 배경에 즉시 반영돼야 함',
    );
    expect(labelFinder('배경색: ${ArtboardBackgroundColor.white.label}'), findsNothing,
        reason: '선택 직후 스와치 목록은 닫혀야 함');
    expect(
      container.read(compositionDraftProvider('comp01')).backgroundColor,
      ArtboardBackgroundColor.darkGray,
      reason: '배경색 변경도 Draft에 반영돼야 함',
    );
    expect(tester.takeException(), isNull);

    await exitEditor(tester);
  });

  // ── 7. 신규 생성 플로우: id 없는 라우트, 빈 아트보드, 크래시 없음 ────────────
  testWidgets('id 없는 편집기 라우트로 진입하면 빈 아트보드로 시작하고 크래시 없다', (tester) async {
    final container = await pumpApp(tester);
    final beforeCount = container.read(compositionsProvider).length;

    container.read(appRouterProvider).push(AppRoute.compositionEditor);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionEditorScreen), findsOneWidget);
    expect(find.byType(InteractiveArtboard), findsOneWidget);
    expect(
      container.read(compositionsProvider).length,
      beforeCount,
      reason: '아이템을 하나도 배치/완료하지 않았으면 새 Composition 레코드가 생기면 안 됨',
    );

    // 빈 캔버스를 탭해도(선택 해제 경로) 크래시 없어야 한다 — 비정형 흐름.
    await tester.tapAt(tester.getCenter(find.byType(InteractiveArtboard)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await exitEditor(tester);
    expect(
      container.read(compositionsProvider).length,
      beforeCount,
      reason: '취소했으므로 여전히 새 레코드가 생기면 안 됨',
    );
  });

  // ── 8. 신규 생성 → 완료(✔) → 새 Composition 레코드 생성 ─────────────────────
  //        이 스코프엔 옷 추가 바텀시트(캔버스에 새 아이템을 올리는 UI)가 아직 없어
  //        (Task A/이번 리워크 스코프 밖) Draft notifier에 직접 items를 주입해
  //        "완료 시 신규 Record 생성" 커밋 경로만 검증한다.
  testWidgets('신규 생성 진입 후 완료(✔)하면 Draft의 items로 새 Composition 레코드가 생성된다',
      (tester) async {
    final container = await pumpApp(tester);
    final beforeCount = container.read(compositionsProvider).length;

    container.read(appRouterProvider).push(AppRoute.compositionEditor);
    await tester.pumpAndSettle();
    expect(find.byType(CompositionEditorScreen), findsOneWidget);

    container.read(compositionDraftProvider(null).notifier).updateItems(
      const [CompositionItemPlacement(clothingItemId: 'c01', x: 0.4, y: 0.4)],
    );
    await tester.pump();

    await commitEditor(tester);

    final compositions = container.read(compositionsProvider);
    expect(compositions.length, beforeCount + 1, reason: '완료 시 새 Composition 레코드가 생성돼야 함');
    expect(compositions.last.items.single.clothingItemId, 'c01');
    expect(find.byType(CompositionEditorScreen), findsNothing);
  });

  // ── 9. 취소(EditorHeader.onCancel) → 실제 pop 네비게이션 ────────────────────
  testWidgets('기존 코디 편집기에서 취소를 탭하면 이전 화면으로 예외 없이 정상 pop된다', (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');
    expect(find.byType(CompositionEditorScreen), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await drainDeferredFrames(tester);

    expect(find.byType(CompositionEditorScreen), findsNothing);
    expect(find.byType(ClosetMainScreen), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: '과거 dispose() ref 크래시 회귀 여부 — 이 assert가 실패하면 재발한 것');
  });

  // ── 10. 비정형 흐름: 취소를 pumpAndSettle 없이 빠르게 연속 탭해도 크래시 없음 ────
  testWidgets('[비정형 흐름] 기존 코디 편집기에서 취소를 연속으로 빠르게 두 번 탭해도 크래시 없이 정상 pop된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    final cancelButton = find.text('취소');
    await tester.tap(cancelButton);
    await tester.pump(const Duration(milliseconds: 16));
    // 이 시점에 이미 pop 애니메이션이 진행 중이라 같은 화면의 "취소"가 더 이상 없을 수
    // 있다 — 남아있다면 한 번 더 탭해 중복 pop 시도 시 크래시가 없는지 확인한다.
    if (cancelButton.evaluate().isNotEmpty) {
      await tester.tap(cancelButton, warnIfMissed: false);
    }
    await tester.pumpAndSettle();
    await drainDeferredFrames(tester);

    expect(find.byType(CompositionEditorScreen), findsNothing);
    expect(find.byType(ClosetMainScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '연타로 인한 크래시(중복 pop 등)가 없어야 함');
  });

  // ── 11. 드래그아웃 삭제: Draft 즉시 반영 + 완료 시 Record 반영 ────────────────
  testWidgets(
      '아이템을 캔버스 밖으로 드래그아웃하면 Draft에서 즉시 삭제되고 선택도 해제되며, 완료(✔) 시 Record에도 반영된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    await tester.tapAt(tester.getCenter(visualOf('c03')));
    await tester.pumpAndSettle();
    expect(labelFinder('이동 핸들'), findsOneWidget, reason: 'c03이 선택돼 핸들이 보여야 함');

    final canvasSize = tester.getSize(find.byType(InteractiveArtboard));
    final gesture = await tester.startGesture(tester.getCenter(visualOf('c03')));
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    await gesture.moveBy(Offset(0, canvasSize.height)); // 캔버스 세로 전체보다 크게 이동 → 경계 밖
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsOneWidget, reason: '경계 밖 드래그 중 삭제 존 오버레이가 떠야 함');
    await gesture.up();
    await tester.pumpAndSettle();

    expect(visualOf('c03'), findsNothing, reason: '드롭 후 아이템이 화면에서 사라져야 함');
    final draft = container.read(compositionDraftProvider('comp01'));
    expect(draft.items.any((p) => p.clothingItemId == 'c03'), isFalse, reason: 'Draft에서 즉시 삭제돼야 함');
    final recordBeforeCommit =
        container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
    expect(recordBeforeCommit.items.any((p) => p.clothingItemId == 'c03'), isTrue,
        reason: '완료(commit) 전까지 Record는 그대로여야 함');
    expect(labelFinder('이동 핸들'), findsNothing, reason: '삭제된 아이템의 선택/핸들도 함께 사라져야 함');
    expect(tester.takeException(), isNull, reason: '드래그아웃 삭제 커밋 자체는 예외 없이 끝나야 함');

    await commitEditor(tester);
    final recordAfterCommit =
        container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
    expect(recordAfterCommit.items.any((p) => p.clothingItemId == 'c03'), isFalse,
        reason: '완료 후 Record에서도 삭제가 반영돼야 함');
  });
}
