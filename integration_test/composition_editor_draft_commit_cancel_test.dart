// integration_test/composition_editor_draft_commit_cancel_test.dart
//
// Tester가 직접 설계한 런타임 검증 스위트 — Task A 리워크(Editor Draft/Commit/Cancel
// 모델, `docs/history/Decision.md` "Editor 저장 모델 전환") 대상.
//
// 이전 라운드의 `composition_editor_screen_test.dart`는 "제스처 커밋마다 Record에
// 즉시 반영"이던 구모델을 검증했다 — 이제 그 가정 자체가 리워크로 무효화됐으므로
// (제스처는 `compositionDraftProvider`에만 반영되고, Record는 완료(✔) 시점에만
// 바뀐다), 이 파일은 신모델(Draft/Commit/Cancel)에 맞춰 새로 설계한 시나리오만
// 다룬다. 겹침 팝업/취소 네비게이션/드래그아웃 삭제 등 `InteractiveArtboard` 자체의
// 상호작용 로직은 `interactive_artboard_test.dart`가 이미 충분히 검증했고,
// `composition_editor_screen_test.dart`도 화면 배선 자체(선택 상태, 겹침, 배경색
// UI, dispose 크래시)는 이미 검증했으므로 여기서는 "Draft ↔ Record 분리"라는 이번
// 리워크의 핵심 계약만 집중 검증한다(중복 방지).
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

  const defaultSize = Size(390, 800);
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

  Future<void> openExisting(WidgetTester tester, ProviderContainer container, String? id) async {
    container.read(appRouterProvider).push(
          id == null ? AppRoute.compositionEditor : '/composition/editor/$id',
        );
    await tester.pumpAndSettle();
  }

  // 화면 이탈(취소/완료 버튼 탭) 이후 여분의 프레임을 흘려보내 dispose() 관련 지연
  // 콜백까지 이 테스트 안에서 확실히 드러나게 하고, 예외 없이 끝났는지 확인한다
  // (`composition_editor_dispose_crash_regression_test.dart`가 다루는 회귀의 재발
  // 여부를 이 리워크에서도 함께 감시).
  Future<void> drainAndAssertNoException(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '화면 이탈 후 예외 없이 종료돼야 함');
  }

  CompositionItemPlacement recordPlacement(
    ProviderContainer container,
    String compositionId,
    String clothingItemId,
  ) =>
      container
          .read(compositionsProvider)
          .firstWhere((c) => c.id == compositionId)
          .items
          .firstWhere((p) => p.clothingItemId == clothingItemId);

  CompositionItemPlacement draftPlacement(
    ProviderContainer container,
    String? compositionId,
    String clothingItemId,
  ) =>
      container
          .read(compositionDraftProvider(compositionId))
          .items
          .firstWhere((p) => p.clothingItemId == clothingItemId);

  // ── 1. 취소 → Record는 변경되지 않고, 다시 열면 원래 위치 그대로 ────────────
  testWidgets('기존 코디 열기 → 드래그 → 취소 → Record는 안 바뀌고, 다시 열면 원래 위치 그대로다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    final original = recordPlacement(container, 'comp01', 'c01');

    final gesture = await tester.startGesture(tester.getCenter(visualOf('c01')));
    await gesture.moveBy(armOffset); // 아밍 — 결과 계산에서 제외
    await tester.pump();
    await gesture.moveBy(const Offset(20, 12));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // 제스처 커밋 시점에도 Draft만 바뀌고 Record는 그대로여야 한다(신모델 핵심 계약).
    final draftAfterDrag = draftPlacement(container, 'comp01', 'c01');
    expect(draftAfterDrag.x, isNot(original.x), reason: 'Draft는 즉시 반영돼야 함');
    expect(recordPlacement(container, 'comp01', 'c01').x, original.x,
        reason: '제스처 커밋 시점에도 Record(compositionsProvider)는 그대로여야 함');
    expect(recordPlacement(container, 'comp01', 'c01').y, original.y);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);
    expect(find.byType(CompositionEditorScreen), findsNothing);

    // 취소 후에도 Record는 여전히 원래 값 그대로(진짜 Rollback).
    expect(recordPlacement(container, 'comp01', 'c01').x, original.x);
    expect(recordPlacement(container, 'comp01', 'c01').y, original.y);

    await openExisting(tester, container, 'comp01');
    final reentered = draftPlacement(container, 'comp01', 'c01');
    expect(reentered.x, original.x, reason: '취소로 폐기된 Draft는 재진입 시 Record 기준으로 새로 초기화돼야 함');
    expect(reentered.y, original.y);
    expect(visualOf('c01'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await drainAndAssertNoException(tester);
  });

  // ── 2. 완료(✔) → Record에 실제로 반영되고, 다시 열면 유지된다 ───────────────
  testWidgets('기존 코디 열기 → 드래그/회전/크기조절 → 완료 → Record에 실제로 반영되고 다시 열면 유지된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    final originalC11 = recordPlacement(container, 'comp01', 'c11');
    expect(originalC11.scale, 1.0);
    expect(originalC11.rotation, 0.0);

    await tester.tapAt(tester.getCenter(visualOf('c11')));
    await tester.pumpAndSettle();

    var gesture = await tester.startGesture(tester.getCenter(labelFinder('크기조절 핸들')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 30)); // 중심에서 멀어짐 = 확대
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    gesture = await tester.startGesture(tester.getCenter(labelFinder('회전 핸들')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final draftC11 = draftPlacement(container, 'comp01', 'c11');
    expect(draftC11.scale, isNot(1.0));
    expect(draftC11.rotation, isNot(0.0));
    expect(recordPlacement(container, 'comp01', 'c11').scale, 1.0,
        reason: '완료를 누르기 전엔 Record가 그대로여야 함');
    expect(recordPlacement(container, 'comp01', 'c11').rotation, 0.0);

    await tester.tap(find.byTooltip('완료'));
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);
    expect(find.byType(CompositionEditorScreen), findsNothing);

    final committed = recordPlacement(container, 'comp01', 'c11');
    expect(committed.scale, draftC11.scale, reason: '완료 시 Draft의 scale이 Record에 반영돼야 함');
    expect(committed.rotation, draftC11.rotation, reason: '완료 시 Draft의 rotation이 Record에 반영돼야 함');

    await openExisting(tester, container, 'comp01');
    final reentered = draftPlacement(container, 'comp01', 'c11');
    expect(reentered.scale, committed.scale, reason: '재진입해도 커밋된 값이 유지돼야 함');
    expect(reentered.rotation, committed.rotation);
    expect(visualOf('c11'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await drainAndAssertNoException(tester);
  });

  // ── 3. 신규 생성(빈 라우트) → Draft에 직접 주입 → 완료 → 새 Record 생성 ──────
  testWidgets('신규 생성 라우트 → Draft에 아이템 직접 주입 → 완료 → 새 Record가 실제로 생성된다',
      (tester) async {
    final container = await pumpApp(tester);
    final beforeIds = container.read(compositionsProvider).map((c) => c.id).toSet();

    await openExisting(tester, container, null);
    expect(find.byType(CompositionEditorScreen), findsOneWidget);
    expect(find.byType(InteractiveArtboard), findsOneWidget);

    // 이번 스코프엔 아이템 추가 UI가 없어 Draft에 직접 주입한다(요청 안내대로).
    container.read(compositionDraftProvider(null).notifier).updateItems(const [
      CompositionItemPlacement(clothingItemId: 'c02', x: 0.5, y: 0.5, zIndex: 0),
    ]);
    await tester.pumpAndSettle();
    expect(visualOf('c02'), findsOneWidget, reason: '주입한 아이템이 아트보드에 렌더돼야 함');
    expect(
      container.read(compositionsProvider).length,
      beforeIds.length,
      reason: '완료를 누르기 전엔 아직 새 Record가 생기면 안 됨',
    );

    await tester.tap(find.byTooltip('완료'));
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);
    expect(find.byType(CompositionEditorScreen), findsNothing);

    final afterIds = container.read(compositionsProvider).map((c) => c.id).toSet();
    final newIds = afterIds.difference(beforeIds);
    expect(newIds.length, 1, reason: '완료 시점에 새 Record가 정확히 1개 생겨야 함');
    final newComposition =
        container.read(compositionsProvider).firstWhere((c) => c.id == newIds.single);
    expect(newComposition.items.length, 1);
    expect(newComposition.items.single.clothingItemId, 'c02');
  });

  // ── 4. 배경색 스와치 + 완료/취소 ─────────────────────────────────────────────
  // 이전 라운드엔 `Composition`에 배경색 필드가 없어 완료해도 재진입 시 흰색으로
  // 리셋되는 버그가 있었다(당시 이 테스트는 하드 assert 없이 print로만 결과를
  // 기록했다) — `Composition.backgroundColor` 필드 추가 + Draft 초기화/Commit 배선
  // 수정으로 해소됐다. 이제 실제로 assert한다.
  testWidgets(
      '배경색 스와치는 편집 세션 중 즉시 반영되고, 완료(✔) 후 재진입해도 그 값이 유지된다',
      (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.white.value,
    );

    await tester.tap(labelFinder('배경색 버튼'));
    await tester.pumpAndSettle();
    await tester.tap(labelFinder('배경색: ${ArtboardBackgroundColor.darkGray.label}'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.darkGray.value,
      reason: '편집 세션 중엔 스와치 선택이 즉시 캔버스에 반영돼야 함',
    );
    await tester.tap(find.byTooltip('완료'));
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);

    await openExisting(tester, container, 'comp01');
    final afterCommitColor = tester.widget<ColoredBox>(find.byType(ColoredBox)).color;
    expect(afterCommitColor, ArtboardBackgroundColor.darkGray.value,
        reason: '완료 후 재진입 시 배경색이 유지돼야 함');

    await tester.tap(find.text('취소'));
    await drainAndAssertNoException(tester);
  });

  // ── 5. 회귀: 겹침 팝업 + dispose 크래시 재발 여부(리워크로 다시 깨지지 않았는지) ──
  testWidgets('[회귀] 겹치게 배치된 아이템 2개의 공유 영역을 탭하면 겹침 팝업이 뜨고, 화면 이탈도 예외 없이 끝난다',
      (tester) async {
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

    await tester.tapAt(tester.getCenter(visualOf('c02')));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    // 팝업의 전체화면 배리어가 열린 채로 "취소"를 탭하면 배리어가 탭을 가로채 팝업만
    // 닫힌다 — 먼저 팝업부터 닫는다(이전 라운드에서 확인된 테스트 스크립트 주의사항,
    // 앱 버그 아님).
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsNothing);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);
    expect(find.byType(CompositionEditorScreen), findsNothing);
  });

  // ── 6. Draft 재사용: 취소/완료 없이 다른 방식으로 벗어났다가 같은 id로 다시 ────
  //        들어가면 이전 미커밋 Draft가 남아있다(Decision.md "기존 미커밋 Draft가
  //        있으면 재사용"). 정상 취소/완료 버튼 경로 밖에서도 재사용되는지 확인하기
  //        위해 화면 자체의 버튼이 아니라 라우터를 직접 조작해 벗어난다.
  testWidgets('취소/완료 버튼을 거치지 않고(라우터 직접 조작) 벗어났다가 같은 id로 다시 들어가면 '
      '이전 미커밋 Draft가 그대로 남아있다', (tester) async {
    final container = await pumpApp(tester);
    await openExisting(tester, container, 'comp01');

    final original = recordPlacement(container, 'comp01', 'c07');

    final gesture = await tester.startGesture(tester.getCenter(visualOf('c07')));
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(const Offset(-15, 25));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final draftAfterDrag = draftPlacement(container, 'comp01', 'c07');
    expect(draftAfterDrag.x, isNot(original.x));

    // 취소/완료 버튼이 아니라 라우터를 직접 조작해 벗어난다(예: 시스템 뒤로가기와
    // 유사하게, 화면 자체의 명시적 폐기 로직을 거치지 않는 이탈 경로).
    container.read(appRouterProvider).go(AppRoute.closetMain);
    await tester.pumpAndSettle();
    await drainAndAssertNoException(tester);
    expect(find.byType(CompositionEditorScreen), findsNothing);
    expect(find.byType(ClosetMainScreen), findsOneWidget);

    // Record는 여전히 미변경(커밋된 적 없음).
    expect(recordPlacement(container, 'comp01', 'c07').x, original.x,
        reason: '커밋 없이 벗어났으니 Record는 그대로여야 함');

    await openExisting(tester, container, 'comp01');
    final reenteredDraft = draftPlacement(container, 'comp01', 'c07');
    expect(reenteredDraft.x, draftAfterDrag.x,
        reason: '취소/완료를 거치지 않았으니 이전 미커밋 Draft가 재사용돼야 함');
    expect(reenteredDraft.y, draftAfterDrag.y);
    expect(visualOf('c07'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await drainAndAssertNoException(tester);
  });
}
