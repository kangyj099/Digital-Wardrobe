// integration_test/interactive_artboard_test.dart
//
// Tester가 직접 설계한 런타임 검증 스위트. `InteractiveArtboard`는
// `Composition`/Riverpod에 의존하지 않는 완전 독립 위젯이므로(스펙 §1/§7,
// `docs/superpowers/specs/2026-07-19-composition-artboard-isolated-widget-design.md`),
// 여기서도 로컬 mock `ArtboardItem`만 사용하고 `lib/mock/mock_data.dart`는
// 참조하지 않는다.
//
// 선택 상태는 완전 controlled 계약(스펙 §5) — 위젯이 `selectedItemId`를 내부에
// 소유하지 않으므로, 실제 화면이 나중에 맡을 "부모" 역할을 이 파일의
// `_ArtboardTestHost`가 대신한다.
//
// 제스처 관련 참고(실측으로 확인한 Flutter 프레임워크 동작): `GestureDetector`의
// Pan 인식기는 이동 임계값(터치 슬롭)을 넘는 순간 드래그로 확정되는데, 그 임계값을
// 넘긴 바로 그 첫 이동 이벤트 자체는 `onPanUpdate`로 전혀 보고되지 않는다(부분
// 반영이 아니라 통째로 소비됨). 그래서 몸체/핸들 드래그 테스트마다 먼저 임계값을
// 넘기기 위한 "아밍(arming)" 이동을 한 번 하고(결과 계산에서 제외), 그 다음 이동만
// 실제 검증에 사용한다. 크기조절/회전 핸들은 델타 누적이 아니라 매 이벤트의 절대
// 포인터 좌표(`details.globalPosition`)를 직접 쓰므로, 아밍 이동분을 빼고 계산한
// 나머지 이동으로 최종 절대 좌표를 목표 지점에 정확히 맞춘다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_item.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_overlap_popup.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/interactive_artboard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const canvasSize = Size(400, 400);
  const baseItemSizeFraction = 0.28; // 위젯 기본값과 동일 — 명시 고정으로 테스트 결정론 확보.

  // Pan 인식기의 이동 임계값을 안전하게 넘기기 위한 "아밍" 이동량(위 파일 상단 설명 참고).
  // 축 하나로도 임계값을 넉넉히 넘도록 두 축 모두에 적용.
  const armOffset = Offset(50, 50);

  ArtboardItem makeItem(
    String id, {
    double x = 0.5,
    double y = 0.5,
    double scale = 1.0,
    double rotation = 0.0,
    int zIndex = 0,
  }) {
    return ArtboardItem(
      id: id,
      imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
      x: x,
      y: y,
      scale: scale,
      rotation: rotation,
      zIndex: zIndex,
    );
  }

  Finder visualOf(String id) => find.byKey(ValueKey('$id:visual'));

  Finder handleByLabel(String label) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == label,
      );

  Finder moveHandleFinder() => handleByLabel('이동 핸들');
  Finder resizeHandleFinder() => handleByLabel('크기조절 핸들');
  Finder rotateHandleFinder() => handleByLabel('회전 핸들');

  void assertSelectionBoxVisible() {
    expect(moveHandleFinder(), findsOneWidget);
    expect(resizeHandleFinder(), findsOneWidget);
    expect(rotateHandleFinder(), findsOneWidget);
  }

  void assertNoSelectionBox() {
    expect(moveHandleFinder(), findsNothing);
    expect(resizeHandleFinder(), findsNothing);
    expect(rotateHandleFinder(), findsNothing);
  }

  Future<GlobalKey<_ArtboardTestHostState>> pumpArtboard(
    WidgetTester tester, {
    required List<ArtboardItem> items,
    String? initialSelectedId,
    bool mirrorSelectionChanges = true,
    List<List<ArtboardItem>>? commitLog,
    List<String>? deletionLog,
    List<String?>? selectionRequestLog,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hostKey = GlobalKey<_ArtboardTestHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: _ArtboardTestHost(
                key: hostKey,
                initialItems: items,
                initialSelectedId: initialSelectedId,
                mirrorSelectionChanges: mirrorSelectionChanges,
                baseItemSizeFraction: baseItemSizeFraction,
                onCommit: commitLog == null ? null : commitLog.add,
                onDelete: deletionLog == null ? null : deletionLog.add,
                onSelectionRequest:
                    selectionRequestLog == null ? null : selectionRequestLog.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return hostKey;
  }

  ArtboardItem itemById(GlobalKey<_ArtboardTestHostState> key, String id) =>
      key.currentState!.currentItems.firstWhere((it) => it.id == id);

  // ── 1. 정적 배치 + 선택/해제 ───────────────────────────────────────────────
  testWidgets('배치된 아이템은 기본적으로 Selection Box 없이 렌더되고, 탭으로 선택/빈 영역 탭으로 해제된다',
      (tester) async {
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('shirt', x: 0.25, y: 0.3),
        makeItem('pants', x: 0.75, y: 0.3),
      ],
    );

    expect(visualOf('shirt'), findsOneWidget);
    expect(visualOf('pants'), findsOneWidget);
    assertNoSelectionBox();

    await tester.tapAt(tester.getCenter(visualOf('shirt')));
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'shirt');
    assertSelectionBoxVisible();

    // 두 아이템 중 어디와도 겹치지 않는 빈 좌표.
    await tester.tapAt(const Offset(200, 380));
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, isNull);
    assertNoSelectionBox();
  });

  // ── 2. 몸체 드래그: 커밋은 제스처 종료 시점 1회뿐 ─────────────────────────────
  testWidgets('몸체 드래그는 진행 중엔 onItemsChanged를 호출하지 않고, 종료 시 1회만 정규화 좌표로 커밋한다',
      (tester) async {
    final commitLog = <List<ArtboardItem>>[];
    await pumpArtboard(
      tester,
      items: [makeItem('shirt', x: 0.5, y: 0.5)],
      commitLog: commitLog,
    );

    final gesture = await tester.startGesture(tester.getCenter(visualOf('shirt')));
    await gesture.moveBy(armOffset); // 아밍 — 결과 계산에서 제외
    await tester.pump();
    expect(commitLog, isEmpty, reason: '아밍 이동만으로 커밋되면 안 됨');

    await gesture.moveBy(const Offset(25, 15));
    await tester.pump();
    expect(commitLog, isEmpty, reason: '드래그 중엔 아직 커밋되면 안 됨');

    await gesture.moveBy(const Offset(-10, 5));
    await tester.pump();
    expect(commitLog, isEmpty, reason: '드래그 중 추가 이동에도 여전히 커밋 안 됨');

    await gesture.up();
    await tester.pumpAndSettle();

    expect(commitLog.length, 1, reason: '드래그 종료 시 정확히 1회만 커밋');
    final updated = commitLog.single.firstWhere((it) => it.id == 'shirt');
    expect(updated.x, closeTo(0.5 + 15 / canvasSize.width, 1e-6));
    expect(updated.y, closeTo(0.5 + 20 / canvasSize.height, 1e-6));
  });

  // ── 3. 이동 핸들도 몸체 드래그와 동일하게 위치를 갱신한다 ──────────────────────
  testWidgets('선택 후 좌하단 이동 핸들을 드래그하면 몸체 드래그와 동일하게 위치가 커밋된다', (tester) async {
    final commitLog = <List<ArtboardItem>>[];
    final key = await pumpArtboard(
      tester,
      items: [makeItem('shirt', x: 0.5, y: 0.5)],
      commitLog: commitLog,
    );

    await tester.tapAt(tester.getCenter(visualOf('shirt')));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(moveHandleFinder()));
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    expect(commitLog, isEmpty);
    await gesture.moveBy(const Offset(18, -12));
    await tester.pump();
    expect(commitLog, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();

    final updated = itemById(key, 'shirt');
    expect(updated.x, closeTo(0.5 + 18 / canvasSize.width, 1e-6));
    expect(updated.y, closeTo(0.5 - 12 / canvasSize.height, 1e-6));
  });

  // ── 4. 크기조절/회전 핸들의 상호 독립성 ────────────────────────────────────
  testWidgets('크기조절 핸들 드래그는 scale만 바꾸고, 회전 핸들 드래그는 rotation만 바꾼다', (tester) async {
    final key = await pumpArtboard(tester, items: [makeItem('shirt', x: 0.5, y: 0.5)]);

    await tester.tapAt(tester.getCenter(visualOf('shirt')));
    await tester.pumpAndSettle();

    final center = tester.getCenter(visualOf('shirt'));
    final resizeHandleDown = tester.getCenter(resizeHandleFinder());
    final resizeArmedStart = resizeHandleDown + armOffset;
    final startDist = (resizeArmedStart - center).distance;
    const resizeDelta = Offset(-20, 20); // 중심에 가까워지는 방향 = 축소 검증까지 겸함
    final resizeTarget = resizeHandleDown + resizeDelta;
    final endDist = (resizeTarget - center).distance;
    final expectedScale = 1.0 * (endDist / startDist);

    // Empirically confirmed Flutter framework behavior: the Pan recognizer's onPanStart
    // reports the pointer position at the moment the touch-slop threshold is crossed, not
    // the original pointer-down position. Resize/rotate math uses the absolute pointer
    // position (not accumulated delta), so the expected-value baseline must be the
    // post-arming position, and the follow-up move targets the absolute end position.
    var gesture = await tester.startGesture(resizeHandleDown);
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(resizeTarget - resizeArmedStart);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    var updated = itemById(key, 'shirt');
    expect(updated.scale, closeTo(expectedScale, 0.01));
    expect(updated.rotation, 0.0, reason: '크기조절 후 rotation은 그대로여야 함');

    final scaleAfterResize = updated.scale;
    final center2 = tester.getCenter(visualOf('shirt'));
    final rotateHandleDown = tester.getCenter(rotateHandleFinder());
    final rotateArmedStart = rotateHandleDown + armOffset;
    final startAngle =
        math.atan2(rotateArmedStart.dy - center2.dy, rotateArmedStart.dx - center2.dx);
    const rotateDelta = Offset(0, 40);
    final rotateTarget = rotateHandleDown + rotateDelta;
    final endAngle = math.atan2(rotateTarget.dy - center2.dy, rotateTarget.dx - center2.dx);
    final expectedRotation = endAngle - startAngle;

    gesture = await tester.startGesture(rotateHandleDown);
    await gesture.moveBy(armOffset);
    await tester.pump();
    await gesture.moveBy(rotateTarget - rotateArmedStart);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    updated = itemById(key, 'shirt');
    expect(updated.rotation, closeTo(expectedRotation, 0.01));
    expect(updated.scale, closeTo(scaleAfterResize, 0.01),
        reason: '회전 후 scale은 직전 크기조절 값 그대로 유지돼야 함');
  });

  // ── 5. Hit Area 데드존: 렌더 박스 안 ≠ 터치 판정 안 ──────────────────────────
  testWidgets('렌더 박스 가장자리(축소된 Hit Area 밖)를 탭하면 선택되지 않고, Hit Area 안쪽은 선택된다',
      (tester) async {
    final key = await pumpArtboard(tester, items: [makeItem('shirt', x: 0.5, y: 0.5)]);
    final center = tester.getCenter(visualOf('shirt'));

    // baseItemSize=112 → renderHalf=56, hitHalf=112*0.85/2=47.6. 51은 그 사이 지점.
    await tester.tapAt(center + const Offset(51, 0));
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, isNull, reason: '렌더 박스 안이지만 Hit Area 밖이라 선택되면 안 됨');
    assertNoSelectionBox();

    await tester.tapAt(center + const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'shirt');
    assertSelectionBoxVisible();
  });

  // ── 6. 비정형 흐름: 이미 선택된 아이템을 다시 탭해도 토글 해제되지 않는다 ──────
  testWidgets('선택된 아이템을 연속으로 다시 탭해도 선택이 유지된다(토글 아님)', (tester) async {
    final key = await pumpArtboard(tester, items: [makeItem('shirt', x: 0.5, y: 0.5)]);
    final point = tester.getCenter(visualOf('shirt'));

    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'shirt');

    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'shirt', reason: '같은 아이템 재탭은 토글 해제가 아니어야 함');
    assertSelectionBoxVisible();
  });

  // ── 7. 겹침 팝업: z-순서 나열 + 원래 zIndex 값 재사용(압축 안 함) ─────────────
  testWidgets('겹친 영역 탭 시 팝업이 z-순서로 뜨고, 드래그핸들 재배열은 원래 zIndex 값 집합을 재사용하며 팝업은 열린 채 유지된다',
      (tester) async {
    final commitLog = <List<ArtboardItem>>[];
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('blazer', x: 0.5, y: 0.5, zIndex: 5),
        makeItem('trousers', x: 0.5, y: 0.5, zIndex: 2),
        makeItem('boots', x: 0.15, y: 0.85, zIndex: 3), // 겹침 무관 아이템(비교용)
      ],
      commitLog: commitLog,
    );

    await tester.tapAt(tester.getCenter(visualOf('blazer')));
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);
    final rows = find.byType(ListTile);
    expect(rows, findsNWidgets(2));
    final topRow = tester.widget<ListTile>(rows.first);
    expect((topRow.title as Text).data, 'blazer', reason: 'zIndex가 큰 쪽이 먼저 나열돼야 함');

    final dragHandles = find.byIcon(Icons.drag_handle);
    expect(dragHandles, findsNWidgets(2));
    // trousers(현재 index 1)의 드래그핸들을 blazer 행 위치까지 끌어올려 순서를 바꾼다.
    // `ReorderableDragStartListener`는 (핸들 전용이라) 별도 임계값 없이 포인터 다운 즉시
    // 드래그를 시작하므로, Pan 인식기의 "첫 이동 미보고" 현상과 무관하다 — 목표 지점으로
    // 곧장 이동시키면 된다.
    final blazerRowCenter = tester.getCenter(find.text('blazer'));
    final gesture = await tester.startGesture(tester.getCenter(dragHandles.at(1)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(blazerRowCenter);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '재배열만으론 팝업이 닫히면 안 됨');
    expect(commitLog, isNotEmpty);
    // 원래 {5,2} 값 집합만 재사용, 새 범위(0/1)로 압축 안 됨. boots(3)는 영향 없음.
    expect(itemById(key, 'trousers').zIndex, 5);
    expect(itemById(key, 'blazer').zIndex, 2);
    expect(itemById(key, 'boots').zIndex, 3, reason: '겹침에 관여 안 한 아이템은 그대로여야 함');

    // 썸네일/라벨 탭 → 선택 + 팝업 닫힘.
    await tester.tap(find.text('trousers'));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsNothing);
    expect(key.currentState!.selected, 'trousers');
    assertSelectionBoxVisible();
  });

  // ── 8. 팝업을 거치지 않고 곧바로 드래그 → 최상단(zIndex 최댓값) 아이템 이동 ────
  testWidgets('겹친 영역을 곧바로 드래그하면 팝업 없이 zIndex가 가장 큰 아이템이 움직인다', (tester) async {
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('coat', x: 0.5, y: 0.5, zIndex: 4),
        makeItem('sweater', x: 0.5, y: 0.5, zIndex: 1),
      ],
    );

    final sharedPoint = tester.getCenter(visualOf('coat'));
    final gesture = await tester.startGesture(sharedPoint);
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsNothing, reason: '드래그는 팝업을 열지 않아야 함');
    expect(itemById(key, 'coat').x, isNot(0.5), reason: '최상단 아이템이 움직여야 함');
    expect(itemById(key, 'sweater').x, 0.5, reason: '가려진 아래쪽 아이템은 그대로여야 함');
  });

  // ── 9. 팝업으로 선택한 하위 아이템은 가려진 채로도 드래그 가능 (회귀 확인) ─────
  testWidgets('팝업에서 하위(비-최상단) 아이템을 선택하면, 위쪽 아이템에 가려진 채로도 몸체 드래그가 그 아이템에 적용된다',
      (tester) async {
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('scarf', x: 0.6, y: 0.4, zIndex: 3),
        makeItem('hat', x: 0.6, y: 0.4, zIndex: 1),
      ],
    );

    final sharedPoint = tester.getCenter(visualOf('scarf'));
    await tester.tapAt(sharedPoint);
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

    await tester.tap(find.text('hat'));
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'hat');

    // hat은 여전히 scarf(zIndex 높음) 아래에 시각적으로 깔려 있지만, 선택된 아이템의
    // 상호작용 레이어는 항상 최상단이므로 같은 좌표를 드래그하면 hat이 움직여야 한다.
    final gesture = await tester.startGesture(sharedPoint);
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 10));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(itemById(key, 'hat').x, isNot(0.6), reason: '선택된 하위 아이템이 이동해야 함');
    expect(itemById(key, 'scarf').x, 0.6, reason: '가리고 있던 최상단 아이템은 그대로여야 함');
  });

  // ── 10. 비정형 흐름: 팝업을 배리어 탭으로 닫아도 선택 요청이 발생하지 않고, ────
  //        같은 지점을 다시 탭하면 팝업이 재오픈된다 ────────────────────────────
  testWidgets('팝업을 항목 탭이 아니라 배리어 탭으로 닫으면 onSelectionChanged가 호출되지 않고, 재탭하면 다시 열린다',
      (tester) async {
    final selectionRequestLog = <String?>[];
    await pumpArtboard(
      tester,
      items: [
        makeItem('vest', x: 0.5, y: 0.5, zIndex: 2),
        makeItem('blouse', x: 0.5, y: 0.5, zIndex: 1),
      ],
      selectionRequestLog: selectionRequestLog,
    );

    final sharedPoint = tester.getCenter(visualOf('vest'));
    await tester.tapAt(sharedPoint);
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

    // 화면 상단(바텀시트 콘텐츠 영역 밖) = 모달 배리어.
    await tester.tapAt(const Offset(600, 100));
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsNothing);
    expect(selectionRequestLog, isEmpty, reason: '배리어로 닫힌 경우 onSelectionChanged가 호출되면 안 됨');

    await tester.tapAt(sharedPoint);
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '같은 지점 재탭이면 팝업이 다시 열려야 함');
  });

  // ── 11. 드래그아웃 삭제: 경계 넘김 + 드롭 → 삭제 ─────────────────────────────
  testWidgets('아이템 중심이 캔버스 경계를 넘어간 채로 드롭하면 딤드/휴지통이 뜨고, onItemDeleted가 호출되며 아이템이 사라진다',
      (tester) async {
    final deletionLog = <String>[];
    final key = await pumpArtboard(
      tester,
      items: [makeItem('beanie', x: 0.5, y: 0.5)],
      deletionLog: deletionLog,
    );

    final gesture = await tester.startGesture(tester.getCenter(visualOf('beanie')));
    await gesture.moveBy(armOffset); // 아밍(경계 안쪽 이동이라 안전)
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsNothing, reason: '아밍 이동은 보고되지 않아 아직 경계 밖 판정이 없어야 함');

    await gesture.moveBy(const Offset(210, 0)); // 200+210=410 > 400 → 경계 밖
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(deletionLog, ['beanie']);
    expect(key.currentState!.currentItems.any((it) => it.id == 'beanie'), isFalse);
    expect(find.byIcon(Icons.delete), findsNothing, reason: '드롭 후 오버레이는 사라져야 함');
  });

  // ── 12. 경계 안쪽 드롭은 삭제 안 됨(범위 유지) + 나갔다 되돌아오면 삭제 취소 ────
  testWidgets('경계를 넘지 않은 드롭은 정상 이동으로 커밋되고(x/y는 [0,1] 유지), 경계 밖에 나갔다 되돌아와 드롭해도 삭제되지 않는다',
      (tester) async {
    final deletionLog = <String>[];
    final commitLog = <List<ArtboardItem>>[];
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('glove', x: 0.5, y: 0.5),
        makeItem('sock', x: 0.5, y: 0.15), // does not overlap glove, so each gesture hits its own item
      ],
      deletionLog: deletionLog,
      commitLog: commitLog,
    );

    // 경계 근접이지만 넘지 않음.
    var gesture = await tester.startGesture(tester.getCenter(visualOf('glove')));
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    await gesture.moveBy(const Offset(195, 0)); // 200+195=395 < 400
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deletionLog, isEmpty);
    final glove = itemById(key, 'glove');
    expect(glove.x, closeTo(0.5 + 195 / canvasSize.width, 1e-6));
    expect(glove.x, inInclusiveRange(0.0, 1.0));
    expect(glove.y, inInclusiveRange(0.0, 1.0));

    // 경계 밖으로 나갔다가 순 이동량 0으로 되돌아옴.
    gesture = await tester.startGesture(tester.getCenter(visualOf('sock')));
    await gesture.moveBy(armOffset); // 아밍
    await tester.pump();
    await gesture.moveBy(const Offset(300, 0)); // 경계 밖
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await gesture.moveBy(const Offset(-300, 0)); // 다시 안쪽(순 이동량 0)
    await tester.pump();
    expect(find.byIcon(Icons.delete), findsNothing, reason: '다시 경계 안으로 들어오면 오버레이가 사라져야 함');
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deletionLog, isEmpty, reason: '되돌아온 뒤 드롭했으니 삭제되면 안 됨');
    final sock = itemById(key, 'sock');
    expect(sock.x, closeTo(0.5, 1e-6));
    expect(sock.y, closeTo(0.15, 1e-6));
  });

  // ── 13. 외부에서 selectedItemId 변경(미래의 Thumbnail 탭 시뮬레이션) ──────────
  testWidgets('캔버스 탭 없이 외부에서 selectedItemId를 바꾸면 해당 아이템의 Selection Box가 표시된다', (tester) async {
    final key = await pumpArtboard(tester, items: [makeItem('cap', x: 0.5, y: 0.5)]);
    assertNoSelectionBox();

    key.currentState!.requestExternalSelection('cap');
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, 'cap');
    assertSelectionBoxVisible();

    key.currentState!.requestExternalSelection(null);
    await tester.pumpAndSettle();
    assertNoSelectionBox();
  });

  // ── 14. 캔버스 탭은 onSelectionChanged만 호출 — 위젯 스스로 반영하지 않음 ──────
  testWidgets('부모가 onSelectionChanged를 무시하면, 캔버스를 탭해도 Selection Box는 바뀌지 않는다(완전 controlled 계약)',
      (tester) async {
    final selectionRequestLog = <String?>[];
    final key = await pumpArtboard(
      tester,
      items: [makeItem('cap', x: 0.5, y: 0.5)],
      mirrorSelectionChanges: false,
      selectionRequestLog: selectionRequestLog,
    );

    await tester.tapAt(tester.getCenter(visualOf('cap')));
    await tester.pumpAndSettle();

    expect(selectionRequestLog, ['cap'], reason: '콜백 자체는 여전히 호출돼야 함');
    expect(key.currentState!.selected, isNull, reason: '부모가 반영하지 않았으니 selectedId는 그대로여야 함');
    assertNoSelectionBox();
  });
}

// ── 테스트 전용 "부모" 호스트 ─────────────────────────────────────────────────
//
// `InteractiveArtboard`는 완전 controlled 위젯(스펙 §5)이라 items/선택 상태를
// 스스로 소유하지 않는다. 이 호스트가 실제 화면이 나중에 맡을 역할(진실 소스
// 보관 + 콜백 반영)을 대신 수행해, 위젯이 controlled 계약을 실제로 지키는지
// 확인할 수 있게 한다.
class _ArtboardTestHost extends StatefulWidget {
  const _ArtboardTestHost({
    super.key,
    required this.initialItems,
    this.initialSelectedId,
    this.mirrorSelectionChanges = true,
    this.baseItemSizeFraction = 0.28,
    this.onCommit,
    this.onDelete,
    this.onSelectionRequest,
  });

  final List<ArtboardItem> initialItems;
  final String? initialSelectedId;
  final bool mirrorSelectionChanges;
  final double baseItemSizeFraction;
  final void Function(List<ArtboardItem>)? onCommit;
  final void Function(String)? onDelete;
  final void Function(String?)? onSelectionRequest;

  @override
  State<_ArtboardTestHost> createState() => _ArtboardTestHostState();
}

class _ArtboardTestHostState extends State<_ArtboardTestHost> {
  late List<ArtboardItem> currentItems = widget.initialItems;
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelectedId;
  }

  /// 캔버스 탭을 거치지 않은 외부발 선택 변경 — 나중에 실제 Thumbnail 탭이 호출할
  /// 경로를 시뮬레이션한다(스펙 §5/§9).
  void requestExternalSelection(String? id) {
    setState(() => selected = id);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveArtboard(
      items: currentItems,
      selectedItemId: selected,
      baseItemSizeFraction: widget.baseItemSizeFraction,
      onItemsChanged: (updated) {
        widget.onCommit?.call(updated);
        setState(() => currentItems = updated);
      },
      onItemDeleted: (id) {
        widget.onDelete?.call(id);
        setState(() => currentItems = currentItems.where((it) => it.id != id).toList());
      },
      onSelectionChanged: (id) {
        widget.onSelectionRequest?.call(id);
        if (widget.mirrorSelectionChanges) {
          setState(() => selected = id);
        }
      },
    );
  }
}
