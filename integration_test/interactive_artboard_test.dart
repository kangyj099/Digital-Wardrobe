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
// `_ArtboardTestHost`가 대신한다. 배경색(`backgroundColor`/§11)도 동일한 controlled
// 패턴이라 호스트가 함께 진실 소스를 대신 보관한다.
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

import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_background_color.dart';
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

  // 배경색 버튼/스와치의 화면 좌표(캔버스 400x400, 캔버스가 화면 좌상단에 정렬된
  // 기본 배치 기준) — `interactive_artboard.dart`의 실제 상수
  // (`_backgroundColorButtonMargin=16`, `_backgroundColorButtonDiameter=44`,
  // `_backgroundSwatchSpacing=8`)로부터 역산한 값. 위젯이 렌더하는 정확한 위치라
  // 임의값이 아니다 — 라이브러리 코드 값이 바뀌면 이 상수도 함께 갱신해야 한다.
  const backgroundButtonCenter = Offset(362, 362); // 400-16-22
  const backgroundSwatchWhiteCenter = Offset(362, 154);
  const backgroundSwatchLightGrayCenter = Offset(362, 206);
  const backgroundSwatchDarkGrayCenter = Offset(362, 258);
  const backgroundSwatchBlackCenter = Offset(362, 310);

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

  // 팝업 행(`ArtboardOverlapPopup._row`)의 `ListTile.title`은 Row(썸네일+라벨)라 곧바로
  // Text로 캐스트할 수 없다(스펙 §4.5 3-히트영역 리디자인으로 leading이 선택 아이콘이
  // 되면서 썸네일이 title 쪽으로 옮겨졌다) — 라벨 Text만 뽑아내는 헬퍼.
  String rowLabel(ListTile tile) =>
      (((tile.title! as Row).children.last as Flexible).child as Text).data!;

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
    ArtboardBackgroundColor initialBackgroundColor = ArtboardBackgroundColor.white,
    bool mirrorBackgroundColorChanges = true,
    Alignment canvasAlignment = Alignment.topLeft,
    Size? canvasSizeOverride,
    List<List<ArtboardItem>>? commitLog,
    List<String>? deletionLog,
    List<String?>? selectionRequestLog,
    List<ArtboardBackgroundColor>? backgroundColorRequestLog,
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
            alignment: canvasAlignment,
            child: SizedBox(
              width: (canvasSizeOverride ?? canvasSize).width,
              height: (canvasSizeOverride ?? canvasSize).height,
              child: _ArtboardTestHost(
                key: hostKey,
                initialItems: items,
                initialSelectedId: initialSelectedId,
                mirrorSelectionChanges: mirrorSelectionChanges,
                initialBackgroundColor: initialBackgroundColor,
                mirrorBackgroundColorChanges: mirrorBackgroundColorChanges,
                baseItemSizeFraction: baseItemSizeFraction,
                onCommit: commitLog == null ? null : commitLog.add,
                onDelete: deletionLog == null ? null : deletionLog.add,
                onSelectionRequest:
                    selectionRequestLog == null ? null : selectionRequestLog.add,
                onBackgroundColorRequest: backgroundColorRequestLog == null
                    ? null
                    : backgroundColorRequestLog.add,
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
    expect(rowLabel(topRow), 'blazer', reason: 'zIndex가 큰 쪽이 먼저 나열돼야 함');

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

  // ═══════════════════════════════════════════════════════════════════════
  // Round 2: 팝업 리디자인(Overlay 카드) + 배경색 스와치(§4.5/§11, 2026-07-19)
  // ═══════════════════════════════════════════════════════════════════════

  // ── 15. 재배열 버그 회귀: 같은 팝업 세션에서 연속 재배열이 매번 반영된다 ────────
  //        (§4.5.1 — showModalBottomSheet의 드래그-닫기 제스처와 재배열 드래그의
  //        경합이 간헐적 실패의 원인으로 추정됐고, Overlay 전환으로 해소됐다는
  //        진단을 검증한다. 여러 차례 연속 실행해 매번 정상 반영되는지 확인.)
  testWidgets('겹침 팝업에서 재배열을 4회 연속 실행해도 매번 정상 반영된다(재배열 간헐적 실패 회귀 검증)',
      (tester) async {
    final commitLog = <List<ArtboardItem>>[];
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('a', x: 0.5, y: 0.5, zIndex: 5),
        makeItem('b', x: 0.5, y: 0.5, zIndex: 3),
        makeItem('c', x: 0.5, y: 0.5, zIndex: 1),
      ],
      commitLog: commitLog,
    );

    await tester.tapAt(tester.getCenter(visualOf('a')));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

    List<String> currentRowOrder() =>
        tester.widgetList<ListTile>(find.byType(ListTile)).map(rowLabel).toList();

    Future<void> reorderDragHandleTo(int fromIndex, String targetLabel) async {
      final dragHandles = find.byIcon(Icons.drag_handle);
      final targetCenter = tester.getCenter(find.text(targetLabel));
      final gesture = await tester.startGesture(tester.getCenter(dragHandles.at(fromIndex)));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(targetCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    expect(currentRowOrder(), ['a', 'b', 'c']);

    // 1회차: c(index2)를 a 위치로 끌어올림 → [c, a, b]
    await reorderDragHandleTo(2, 'a');
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '1회차 재배열 후에도 팝업 유지');
    expect(currentRowOrder(), ['c', 'a', 'b'], reason: '1회차 재배열 반영 실패');
    expect(commitLog.length, 1);

    // 2회차: b(index2)를 c 위치로 끌어올림 → [b, c, a]
    await reorderDragHandleTo(2, 'c');
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '2회차 재배열 후에도 팝업 유지');
    expect(currentRowOrder(), ['b', 'c', 'a'], reason: '2회차 재배열 반영 실패');
    expect(commitLog.length, 2);

    // 3회차: a(index2)를 c 위치(index1)로 끌어당김 → [b, a, c]
    await reorderDragHandleTo(2, 'c');
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '3회차 재배열 후에도 팝업 유지');
    expect(currentRowOrder(), ['b', 'a', 'c'], reason: '3회차 재배열 반영 실패');
    expect(commitLog.length, 3);

    // 4회차: c(index2)를 b 위치(index0)로 끌어올림 → [c, b, a]
    await reorderDragHandleTo(2, 'b');
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget, reason: '4회차 재배열 후에도 팝업 유지');
    expect(currentRowOrder(), ['c', 'b', 'a'], reason: '4회차 재배열 반영 실패');
    expect(commitLog.length, 4);

    // 원래 zIndex 값 집합 {5,3,1}이 최종 순서([c,b,a])에 내림차순으로 재배정됐는지 확인.
    expect(itemById(key, 'c').zIndex, 5);
    expect(itemById(key, 'b').zIndex, 3);
    expect(itemById(key, 'a').zIndex, 1);
  });

  // ── 16. 팝업이 탭 좌표 근처에 앵커되고, 화면 전체폭 바텀시트가 아니다 ──────────
  testWidgets('겹침 팝업은 탭 좌표 근처에 고정폭 카드로 뜬다(화면 전체폭 바텀시트가 아님)',
      (tester) async {
    await pumpArtboard(
      tester,
      items: [
        makeItem('coat', x: 0.5, y: 0.3, zIndex: 2),
        makeItem('jacket', x: 0.5, y: 0.3, zIndex: 1),
      ],
    );

    final tapPoint = tester.getCenter(visualOf('coat')); // 화면 중앙 근처, 어느 경계에도 안 가까움
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    final popupFinder = find.byType(ArtboardOverlapPopup);
    expect(popupFinder, findsOneWidget);

    final popupSize = tester.getSize(popupFinder);
    expect(popupSize.width, lessThan(400), reason: '고정폭 카드여야 함(화면 전체폭 1200이 아님)');

    final popupTopLeft = tester.getTopLeft(popupFinder);
    // 클램핑이 필요 없는 위치이므로 카드 좌상단이 탭 좌표와 거의 일치해야 한다.
    expect(popupTopLeft.dx, closeTo(tapPoint.dx, 1.0));
    expect(popupTopLeft.dy, closeTo(tapPoint.dy, 1.0));
  });

  // ── 17. 화면 우측 가장자리 근처에서 열어도 카드가 오른쪽 경계 밖으로 나가지 않는다 ──
  //        (수평 클램프는 카드 폭(240)을 명시적으로 빼고 계산한다 — 실제로 clamp가
  //        걸리는 조건에서 카드가 화면 안에 머무는지 확인한다.)
  testWidgets('화면 우측 가장자리 근처에서 겹침 팝업을 열면 카드가 오른쪽 경계 밖으로 나가지 않는다',
      (tester) async {
    const bigCanvas = Size(1100, 1500); // 화면(1200x1600) 대부분을 채워, 캔버스 내부
    // 좌표만으로도 실제 화면 가장자리에 가까운 탭을 만들 수 있게 한다.
    // 배경색 버튼은 캔버스 우하단 모서리(마진 16, 지름 44 → 캔버스 로컬
    // x:[1040,1084] y:[1440,1484])에 항상 떠 있으므로, 그 자리와 안 겹치는
    // 우측-가운데 지점을 택해 버튼이 탭을 가로채지 않게 한다.
    await pumpArtboard(
      tester,
      items: [
        makeItem('belt', x: 0.98, y: 0.5, zIndex: 2),
        makeItem('bag', x: 0.98, y: 0.5, zIndex: 1),
      ],
      canvasSizeOverride: bigCanvas,
    );

    final tapPoint = tester.getCenter(visualOf('belt'));
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    final popupFinder = find.byType(ArtboardOverlapPopup);
    expect(popupFinder, findsOneWidget);

    const screenSize = Size(1200, 1600);
    final topLeft = tester.getTopLeft(popupFinder);
    final bottomRight = tester.getBottomRight(popupFinder);

    expect(topLeft.dx, greaterThanOrEqualTo(0), reason: '카드 좌측이 화면 밖(음수)으로 나가면 안 됨');
    expect(bottomRight.dx, lessThanOrEqualTo(screenSize.width),
        reason: '카드 우측이 화면 오른쪽 경계를 넘어가면 안 됨(수평 클램프가 카드 폭을 빼고 계산)');
    // 탭 좌표(화면 우측 근접) 그대로였다면 카드가 훨씬 오른쪽에 있었을 것 — 실제로
    // 클램프가 작동해 카드 좌표가 탭 좌표보다 왼쪽으로 당겨졌는지도 확인한다.
    expect(topLeft.dx, lessThan(tapPoint.dx), reason: '클램프가 실제로 걸려 카드가 왼쪽으로 당겨져야 함');
  });

  // ── 18. 화면 하단 가장자리 근처에서 열면 카드가 아래쪽 경계 밖으로 나가지 않는다 ──
  //        (소스코드상 수직 클램프(`top`)는 화면 여백(margin)만 빼고 계산하며,
  //        수평 클램프처럼 카드 자신의 세로 길이를 빼지 않는다 — 화면 하단에 아주
  //        가까운 탭이면 카드가 화면 아래로 넘칠 수 있는지 실측으로 확인한다.)
  testWidgets('화면 하단 가장자리 근처에서 겹침 팝업을 열면 카드가 아래쪽 경계 밖으로 나가지 않는다',
      (tester) async {
    const bigCanvas = Size(1100, 1500);
    await pumpArtboard(
      tester,
      items: [
        makeItem('cap', x: 0.1, y: 0.997, zIndex: 2), // 배경색 버튼(우하단)과 안 겹치는 좌측 하단
        makeItem('scarf', x: 0.1, y: 0.997, zIndex: 1),
      ],
      canvasSizeOverride: bigCanvas,
    );

    final tapPoint = tester.getCenter(visualOf('cap'));
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    final popupFinder = find.byType(ArtboardOverlapPopup);
    expect(popupFinder, findsOneWidget);

    const screenSize = Size(1200, 1600);
    final topLeft = tester.getTopLeft(popupFinder);
    final bottomRight = tester.getBottomRight(popupFinder);
    final cardHeight = bottomRight.dy - topLeft.dy;

    expect(topLeft.dy, greaterThanOrEqualTo(0), reason: '카드 상단이 화면 밖(음수)으로 나가면 안 됨');
    expect(
      bottomRight.dy,
      lessThanOrEqualTo(screenSize.height),
      reason: '카드 하단이 화면 아래쪽 경계를 넘어가면 안 됨 — 탭 좌표=${tapPoint.dy}, 카드 top=${topLeft.dy}, '
          '카드 높이=$cardHeight, 카드 bottom=${bottomRight.dy} (화면 높이 ${screenSize.height})',
    );
  });

  // ── 19. 팝업 행의 선택 아이콘 탭 → 선택 + 팝업 닫힘(썸네일/라벨 탭과 동일 결과) ──
  testWidgets('팝업 행의 선택 아이콘을 탭하면 그 아이템이 선택되고 팝업이 닫힌다', (tester) async {
    final key = await pumpArtboard(
      tester,
      items: [
        makeItem('scarf', x: 0.5, y: 0.5, zIndex: 2),
        makeItem('gloves', x: 0.5, y: 0.5, zIndex: 1),
      ],
    );

    await tester.tapAt(tester.getCenter(visualOf('scarf')));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

    // gloves(두 번째 행, index 1)의 선택 아이콘(미선택 상태라 outline)을 탭한다.
    final selectionIcons = find.byIcon(Icons.check_circle_outline);
    expect(selectionIcons, findsNWidgets(2));
    await tester.tap(selectionIcons.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(ArtboardOverlapPopup), findsNothing, reason: '선택 아이콘 탭도 팝업을 닫아야 함');
    expect(key.currentState!.selected, 'gloves');
    assertSelectionBoxVisible();
  });

  // ── 20. 선택된 아이템의 행만 배경 강조 + 채워진 체크 아이콘으로 표시된다 ────────
  testWidgets('팝업에서 현재 selectedItemId와 일치하는 행만 배경이 강조되고 채워진 체크 아이콘을 보인다',
      (tester) async {
    await pumpArtboard(
      tester,
      items: [
        makeItem('scarf', x: 0.5, y: 0.5, zIndex: 2),
        makeItem('gloves', x: 0.5, y: 0.5, zIndex: 1),
      ],
      initialSelectedId: 'gloves',
    );

    await tester.tapAt(tester.getCenter(visualOf('scarf')));
    await tester.pumpAndSettle();
    expect(find.byType(ArtboardOverlapPopup), findsOneWidget);

    final colorScheme = Theme.of(tester.element(find.byType(ArtboardOverlapPopup))).colorScheme;

    final scarfRow = tester.widget<ListTile>(find.byKey(const ValueKey('scarf')));
    final glovesRow = tester.widget<ListTile>(find.byKey(const ValueKey('gloves')));
    expect(scarfRow.tileColor, isNull, reason: '선택 안 된 행은 강조 배경이 없어야 함');
    expect(glovesRow.tileColor, colorScheme.primaryContainer, reason: '선택된 행은 강조 배경이어야 함');

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scarf')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
      reason: '선택 안 된 행은 outline 아이콘',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gloves')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
      reason: '선택된 행은 채워진 체크 아이콘',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gloves')),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsNothing,
      reason: '선택된 행에 outline 아이콘이 남아있으면 안 됨',
    );
  });

  // ── 21. 배경색 버튼 탭 → 스와치 4개를 각각 탭 → 매번 반영 + 닫힘 ─────────────
  testWidgets(
      '배경색 버튼을 탭해 스와치를 펼치고, 스와치 4개를 각각 탭하면 매번 onBackgroundColorChanged가 호출되며 캔버스 배경이 즉시 반영되고 스와치가 닫힌다',
      (tester) async {
    final backgroundColorRequestLog = <ArtboardBackgroundColor>[];
    final selectionRequestLog = <String?>[];
    await pumpArtboard(
      tester,
      items: [makeItem('shirt', x: 0.5, y: 0.5)],
      backgroundColorRequestLog: backgroundColorRequestLog,
      selectionRequestLog: selectionRequestLog,
    );

    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.white.value,
      reason: '초기 배경색은 기본값(white)이어야 함',
    );

    Future<void> pickSwatch(Offset swatchCenter, ArtboardBackgroundColor expected) async {
      await tester.tapAt(backgroundButtonCenter); // 스와치 펼침
      await tester.pumpAndSettle();
      await tester.tapAt(swatchCenter);
      await tester.pumpAndSettle();
      expect(backgroundColorRequestLog.last, expected, reason: '$expected 스와치 탭이 반영되지 않음');
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
        expected.value,
        reason: '스와치 선택 즉시 캔버스 배경이 반영돼야 함($expected)',
      );
    }

    await pickSwatch(backgroundSwatchLightGrayCenter, ArtboardBackgroundColor.lightGray);
    await pickSwatch(backgroundSwatchDarkGrayCenter, ArtboardBackgroundColor.darkGray);
    await pickSwatch(backgroundSwatchBlackCenter, ArtboardBackgroundColor.black);
    await pickSwatch(backgroundSwatchWhiteCenter, ArtboardBackgroundColor.white);

    expect(backgroundColorRequestLog, [
      ArtboardBackgroundColor.lightGray,
      ArtboardBackgroundColor.darkGray,
      ArtboardBackgroundColor.black,
      ArtboardBackgroundColor.white,
    ]);

    // 스와치가 매번 선택 직후 닫혔는지 확인: 마지막 선택 뒤 버튼을 다시 열지 않고
    // 같은 좌표를 탭하면 일반 캔버스 탭으로 처리돼 선택 해제 요청만 와야 한다.
    await tester.tapAt(backgroundSwatchWhiteCenter);
    await tester.pumpAndSettle();
    expect(backgroundColorRequestLog.length, 4,
        reason: '스와치가 닫혔으니 같은 좌표 재탭은 배경색 변경을 다시 일으키면 안 됨');
    expect(selectionRequestLog, [null], reason: '스와치 닫힌 뒤엔 일반 캔버스 탭(선택 해제)으로 처리돼야 함');
  });

  // ── 22. 스와치가 펼쳐진 상태에서 바깥(캔버스) 탭 → 스와치만 닫히고 아무것도 안 바뀜 ──
  testWidgets('스와치가 펼쳐진 상태에서 스와치 바깥 캔버스를 탭하면 스와치만 닫히고 배경색/선택 둘 다 바뀌지 않는다',
      (tester) async {
    final backgroundColorRequestLog = <ArtboardBackgroundColor>[];
    final selectionRequestLog = <String?>[];
    final key = await pumpArtboard(
      tester,
      items: [makeItem('shirt', x: 0.2, y: 0.2)], // 스와치/버튼 영역과 겹치지 않는 위치
      initialSelectedId: 'shirt',
      backgroundColorRequestLog: backgroundColorRequestLog,
      selectionRequestLog: selectionRequestLog,
    );
    assertSelectionBoxVisible();

    await tester.tapAt(backgroundButtonCenter);
    await tester.pumpAndSettle();

    // 스와치/버튼과 무관한 빈 캔버스 영역(shirt와도 겹치지 않는 좌표).
    const outsideTapPoint = Offset(100, 350);
    await tester.tapAt(outsideTapPoint);
    await tester.pumpAndSettle();

    expect(backgroundColorRequestLog, isEmpty, reason: '바깥 탭으로 배경색이 바뀌면 안 됨');
    expect(selectionRequestLog, isEmpty,
        reason: '스와치를 닫는 첫 바깥 탭은 onSelectionChanged조차 호출하지 않아야 함(스펙상 즉시 반환)');
    expect(key.currentState!.selected, 'shirt', reason: '선택 상태가 유지돼야 함');
    assertSelectionBoxVisible();
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox)).color,
      ArtboardBackgroundColor.white.value,
      reason: '배경색은 그대로 white여야 함',
    );

    // 스와치가 실제로 닫혔는지 재확인: 같은 좌표를 다시 탭하면 이번엔 일반 캔버스 탭으로
    // 처리돼 onSelectionChanged(null)이 호출돼야 한다.
    await tester.tapAt(outsideTapPoint);
    await tester.pumpAndSettle();
    expect(selectionRequestLog, [null], reason: '스와치가 닫혔으니 두 번째 탭은 일반 캔버스 탭으로 처리돼야 함');
  });

  // ── 23. 회귀: 배경색 버튼을 탭해도 기존 아이템 선택 상태에 영향이 없다 ─────────
  testWidgets('아이템이 선택된 상태에서 배경색 버튼을 탭해도 선택이 해제되지 않는다(레이어 우선순위 회귀 확인)',
      (tester) async {
    final selectionRequestLog = <String?>[];
    final key = await pumpArtboard(
      tester,
      items: [makeItem('shirt', x: 0.2, y: 0.2)],
      initialSelectedId: 'shirt',
      selectionRequestLog: selectionRequestLog,
    );
    assertSelectionBoxVisible();

    await tester.tapAt(backgroundButtonCenter);
    await tester.pumpAndSettle();

    expect(key.currentState!.selected, 'shirt', reason: '배경색 버튼 탭이 선택 해제를 유발하면 안 됨');
    assertSelectionBoxVisible();
    expect(selectionRequestLog, isEmpty, reason: '배경색 버튼 탭은 onSelectionChanged를 호출하면 안 됨');
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Audit 제기 이론(P2, 미확인) 확인: 작은 캔버스에서 배경색 스와치 목록이
  // 캔버스 상단 경계 밖으로 넘칠 때, 넘친 부분이 실제로 탭 가능한지 실측한다.
  // ═══════════════════════════════════════════════════════════════════════

  // ── 24. 캔버스 높이가 스와치 리스트 필요 높이보다 작으면, 캔버스 밖으로 넘친
  //        최상단 스와치는 그려지긴 해도(Clip.none) 탭이 반영되지 않는다 ────────
  //
  //        임계값 계산(코드 상수 기준):
  //        - 스와치 리스트의 bottom 오프셋 = `_backgroundColorButtonMargin`(16)
  //          + `_backgroundColorButtonDiameter`(44) + `_backgroundSwatchSpacing`(8)
  //          = 68.
  //        - 스와치 리스트 자체 높이 = `ArtboardBackgroundColor.values.length`(4)
  //          * `_backgroundSwatchDiameter`(44) + 3칸 * `_backgroundSwatchSpacing`(8)
  //          = 176 + 24 = 200.
  //        - 리스트가 캔버스 안에 완전히 들어가려면 캔버스 높이 >= 68 + 200 = 268
  //          이 필요하다. 기존 1~23번 시나리오는 전부 400x400/1100x1500이라 이
  //          임계값(268)을 한 번도 건드리지 않았다.
  //        - 여기서는 의도적으로 200x200(<268)을 사용한다: 스와치 리스트 top이
  //          캔버스 로컬 y = 200 - 268 = -68이 되어, 최상단(흰색) 스와치(리스트
  //          첫 항목, 높이 44)가 로컬 y [-68, -24] 구간, 즉 캔버스 자신의 경계
  //          [0, 200] 완전히 밖에 위치하게 된다.
  //
  //        `Stack`(캔버스) 자신의 `RenderBox.hitTest`는 자식을 살펴보기 전에
  //        자기 `size.contains(position)`부터 확인한다(Clip.none은 페인트에만
  //        영향, 히트테스트엔 영향 없음 — Round 1에서 핸들에 대해 이미 확인한
  //        것과 동일한 메커니즘, `_handleLayerMargin` 주석 참고). 캔버스를
  //        화면 중앙(Alignment.center)에 배치해, 넘친 스와치가 "화면 자체의
  //        경계" 밖이 아니라 "화면 안 · 캔버스 자신의 경계 밖"이라는 정확한
  //        지점에 위치하도록 구분한다.
  testWidgets(
      '캔버스 높이(200)가 스와치 리스트 필요 높이(268) 미만이면, 캔버스 경계 밖으로 넘친 최상단 스와치는 시각적으로는 보이지만 탭해도 반영되지 않는다',
      (tester) async {
    final backgroundColorRequestLog = <ArtboardBackgroundColor>[];
    const smallCanvas = Size(200, 200);
    await pumpArtboard(
      tester,
      items: const [],
      canvasSizeOverride: smallCanvas,
      canvasAlignment: Alignment.center,
      backgroundColorRequestLog: backgroundColorRequestLog,
    );

    final canvasTopLeft = tester.getTopLeft(find.byType(ColoredBox));
    expect(
      tester.getSize(find.byType(ColoredBox)),
      smallCanvas,
      reason: '캔버스 크기가 override대로 실제 반영됐는지 확인(계산 전제 검증)',
    );

    await tester.tap(handleByLabel('배경색 버튼'));
    await tester.pumpAndSettle();

    final whiteSwatchFinder = handleByLabel('배경색: 흰색');
    expect(whiteSwatchFinder, findsOneWidget,
        reason: '캔버스 밖으로 넘쳤어도 위젯 자체는 트리에 존재하고 그려져야 함(Clip.none)');

    final whiteSwatchCenter = tester.getCenter(whiteSwatchFinder);
    expect(
      whiteSwatchCenter.dy,
      lessThan(canvasTopLeft.dy),
      reason: '최상단(흰색) 스와치가 실제로 캔버스 자신의 위쪽 경계 밖에 그려지는지 확인 — '
          '스와치 중심 y=${whiteSwatchCenter.dy}, 캔버스 top y=${canvasTopLeft.dy}',
    );

    await tester.tapAt(whiteSwatchCenter);
    await tester.pumpAndSettle();

    expect(
      backgroundColorRequestLog,
      isEmpty,
      reason:
          '캔버스 Stack 자신의 히트테스트 경계 밖이라 탭이 onBackgroundColorChanged까지 전달되면 안 됨(버그 확인 시나리오)',
    );
    expect(
      handleByLabel('배경색: 흰색'),
      findsOneWidget,
      reason: '탭이 캔버스 자신에게도 전달되지 않았다면 스와치 목록이 닫히지 않은 채(펼쳐진 채로) 남아있어야 함',
    );
  });
}

// ── 테스트 전용 "부모" 호스트 ─────────────────────────────────────────────────
//
// `InteractiveArtboard`는 완전 controlled 위젯(스펙 §5)이라 items/선택 상태/배경색을
// 스스로 소유하지 않는다. 이 호스트가 실제 화면이 나중에 맡을 역할(진실 소스
// 보관 + 콜백 반영)을 대신 수행해, 위젯이 controlled 계약을 실제로 지키는지
// 확인할 수 있게 한다.
class _ArtboardTestHost extends StatefulWidget {
  const _ArtboardTestHost({
    super.key,
    required this.initialItems,
    this.initialSelectedId,
    this.mirrorSelectionChanges = true,
    this.initialBackgroundColor = ArtboardBackgroundColor.white,
    this.mirrorBackgroundColorChanges = true,
    this.baseItemSizeFraction = 0.28,
    this.onCommit,
    this.onDelete,
    this.onSelectionRequest,
    this.onBackgroundColorRequest,
  });

  final List<ArtboardItem> initialItems;
  final String? initialSelectedId;
  final bool mirrorSelectionChanges;
  final ArtboardBackgroundColor initialBackgroundColor;
  final bool mirrorBackgroundColorChanges;
  final double baseItemSizeFraction;
  final void Function(List<ArtboardItem>)? onCommit;
  final void Function(String)? onDelete;
  final void Function(String?)? onSelectionRequest;
  final void Function(ArtboardBackgroundColor)? onBackgroundColorRequest;

  @override
  State<_ArtboardTestHost> createState() => _ArtboardTestHostState();
}

class _ArtboardTestHostState extends State<_ArtboardTestHost> {
  late List<ArtboardItem> currentItems = widget.initialItems;
  String? selected;
  late ArtboardBackgroundColor backgroundColor = widget.initialBackgroundColor;

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
      backgroundColor: backgroundColor,
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
      onBackgroundColorChanged: (color) {
        widget.onBackgroundColorRequest?.call(color);
        if (widget.mirrorBackgroundColorChanges) {
          setState(() => backgroundColor = color);
        }
      },
    );
  }
}
