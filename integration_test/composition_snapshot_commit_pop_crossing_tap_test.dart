// integration_test/composition_snapshot_commit_pop_crossing_tap_test.dart
//
// [3차 Tester 작성] F6 수정(`db56ecf` — `_handleCommit`의 `_isCommitting` 재진입 가드)이
// 막으려는 **pop을 가로지르는 탭**을 런타임으로 재현한다.
//
// 왜 별도 시나리오인가: F6 원본 재현(`composition_snapshot_followup_b_test.dart`)은
// `tester.tap()`으로 두 번 누른다. `tester.tap()`은 down과 up을 같은 동기 호출에서 처리하므로
// "pointer-down이 pop 직전, pointer-up이 pop 직후"인 창은 만들 수 없다. 그 창이 수정 1차
// 시도(`finally` 해제)가 반려된 근거이므로 `tester.startGesture()`로 직접 만든다.
//
// **관측 결과(Flutter 3.44.4 / Windows): 그 창으로는 두 번째 `onTap`이 발화하지 않는다.**
// 아래 하네스 자기검증 테스트가 원인을 분리했다 — `NavigatorState._flushHistoryUpdates()`가
// 끝에서 `_cancelActivePointers()`를 부르고, 이게 그 Navigator 안에서 눌려 있는 모든 포인터에
// `PointerCancelEvent`를 보낸다(`navigator.dart` L5128/L5868, `Listener`+`AbsorbPointer` 구조).
// 취소된 포인터의 tap recognizer는 arena에서 빠지므로, 뒤이은 pointer-up은 `onTap`을 다시
// 발화시키지 못한다. 즉 이 경로의 재진입은 프레임워크가 한 겹 더 막아준다 — 가드의 "pop 이후
// 해제하지 않는다" 규칙은 그 위에 얹힌 방어이며, 이 버전에서는 런타임으로 구분 관측되지 않는다.
//
// 그래도 이 파일을 회귀 스위트로 남기는 이유:
//  1. 앱 불변식(고아 스냅샷 0개 / `coverImagePath`가 실존 파일 / 스택이 코디 상세에 남음)은
//     이 제스처에서도 실제로 지켜지는지 매번 확인된다.
//  2. 자기검증 테스트가 프레임워크 전제를 고정한다 — Flutter 업그레이드로 포인터 취소가
//     사라지면 그 테스트가 먼저 깨져서, `_handleCommit`의 해제 규칙을 다시 따져야 한다는 걸
//     알려준다.
//
// 실행: `flutter test integration_test/composition_snapshot_commit_pop_crossing_tap_test.dart
// -d windows`
//
// [실행 결과 2026-08-17 / db56ecf] 4/4 통과. 앱 시나리오는 3회차에서 창 성립(down t=64ms,
// pop t=375ms, 홀드 311ms, up 시점 편집기 생존=true) 후 불변식 전부 충족.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const screenSize = Size(390, 844);
  const armOffset = Offset(50, 50);

  late Directory snapshotDir;
  late Set<String> preExistingSnapshots;

  setUpAll(() async {
    final support = await getApplicationSupportDirectory();
    snapshotDir = Directory('${support.path}/composition_snapshots');
    if (!snapshotDir.existsSync()) snapshotDir.createSync(recursive: true);
    preExistingSnapshots = snapshotDir.listSync().map((e) => e.path).toSet();
  });

  tearDownAll(() {
    if (!snapshotDir.existsSync()) return;
    for (final entity in snapshotDir.listSync()) {
      if (preExistingSnapshots.contains(entity.path)) continue;
      try {
        entity.deleteSync();
      } on FileSystemException {
        // 정리 실패는 무시.
      }
    }
  });

  List<String> snapshotFiles() => snapshotDir.listSync().map((e) => e.path).toList();

  /// Windows에서 Record가 들고 있는 경로(`getApplicationSupportDirectory()` + '/'로 조립)와
  /// `Directory.listSync()`가 돌려주는 경로는 구분자가 섞여 있어 비교 전에 정규화해야 한다.
  String norm(String path) => path.replaceAll(Platform.pathSeparator, '/');

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = screenSize;
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

  /// 실시간(real clock) 조건 대기 — 캡처/파일 I/O가 진짜 비동기라 `pumpAndSettle`로는
  /// 기다려지지 않는다.
  Future<bool> waitUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(milliseconds: 4),
  }) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < timeout) {
      if (condition()) return true;
      await Future<void>.delayed(interval);
      await tester.pump();
    }
    return condition();
  }

  Future<void> drain(WidgetTester tester, {int frames = 20}) async {
    for (var i = 0; i < frames; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Composition record(ProviderContainer container, String id) =>
      container.read(compositionsProvider).firstWhere((c) => c.id == id);

  Finder tileFinder(String compositionId) => find.byWidgetPredicate(
        (w) => w is CompositionGalleryTile && w.composition.id == compositionId,
      );

  Future<void> goToCompositionDetail(WidgetTester tester) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디').last);
    await tester.pumpAndSettle();
    await tester.tap(tileFinder('comp03'));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);
  }

  /// 코디 상세에서 아이템을 길게 눌러 편집기로 들어가고, 아이템 하나를 옮겨 Draft를 더럽힌다.
  Future<void> enterEditorAndDirtyDraft(WidgetTester tester, {required int round}) async {
    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('static-artboard-item-c04'))),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await press.up();
    await tester.pumpAndSettle();
    expect(find.byType(CompositionEditorScreen), findsOneWidget, reason: '$round회차 편집기 진입');

    final drag =
        await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('c04:visual'))));
    await drag.moveBy(armOffset);
    await tester.pump();
    await drag.moveBy(Offset(round.isEven ? 14 : -14, round.isEven ? -10 : 10));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
  }

  testWidgets(
      '완료(✔) 커밋 중에 누른 두 번째 탭의 손가락을 pop 이후에 떼도(down=pop 직전, up=pop 직후) '
      '커버 파일이 지워지지 않고 고아 스냅샷도 남지 않는다', (tester) async {
    final container = await pumpApp(tester);
    await goToCompositionDetail(tester);

    final before = snapshotFiles().toSet();

    // ① 1회차: 커밋 소요시간 계측만 한다. 캡처+저장 시간은 이미지 캐시 상태에 따라 크게
    //    달라서(콜드 420ms → 웜 140ms 관측), "pop 직전"에 pointer-down을 놓으려면 실측값이
    //    필요하다.
    await enterEditorAndDirtyDraft(tester, round: 1);
    var coverBefore = record(container, 'comp03').coverImagePath;
    final calibrationWatch = Stopwatch()..start();
    await tester.tap(find.byTooltip('완료'));
    await waitUntil(tester, () => record(container, 'comp03').coverImagePath != coverBefore);
    final commitMillis = calibrationWatch.elapsedMilliseconds;
    await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
    await drain(tester, frames: 30);
    debugPrint('[Tester] 계측 — 완료 탭부터 Record 갱신(=pop)까지 ${commitMillis}ms');
    expect(find.byType(CompositionDetailScreen), findsOneWidget);

    // ② 2회차부터 "pop 직전 down / pop 직후 up"을 실제로 만든다. 홀드는 500ms
    //    (kLongPressTimeout) 미만이어야 한다 — 넘기면 완료 버튼 툴팁의 롱프레스 recognizer가
    //    arena를 가져가 탭 자체가 성립하지 않는다(아래 자기검증 테스트에서 분리 확인).
    //    커밋 시간이 회차마다 흔들리므로 직전 회차 실측값의 비율로 down 시점을 잡고, 빗나가면
    //    비율을 바꿔 다시 시도한다.
    var achieved = false;
    var achievedHold = -1;
    var achievedEditorAliveAtUp = false;
    var lastCommitMillis = commitMillis;
    const offsetFactors = <double>[0.6, 0.45, 0.75, 0.3, 0.85, 0.15];
    for (var i = 0; i < offsetFactors.length && !achieved; i++) {
      final round = i + 2;
      final offset = Duration(milliseconds: (lastCommitMillis * offsetFactors[i]).round());
      await enterEditorAndDirtyDraft(tester, round: round);
      coverBefore = record(container, 'comp03').coverImagePath;
      final watch = Stopwatch()..start();
      await tester.tap(find.byTooltip('완료'));

      // pop 직전까지 기다린다(단, pop이 먼저 오면 즉시 중단).
      while (watch.elapsed < offset &&
          record(container, 'comp03').coverImagePath == coverBefore) {
        await Future<void>.delayed(const Duration(milliseconds: 4));
        await tester.pump();
      }
      final tDown = watch.elapsedMilliseconds;
      final missed = record(container, 'comp03').coverImagePath != coverBefore ||
          find.byType(CompositionEditorScreen).evaluate().isEmpty;

      // pop 이전 pointer-down. 빗나간 회차(이미 pop됨)는 down을 넣지 않는다 — 편집기가 없어
      // 엉뚱한 화면을 누르게 된다.
      final secondTap =
          missed ? null : await tester.startGesture(tester.getCenter(find.byTooltip('완료')));

      // pop까지 누른 채 대기 — `_handleCommit`은 `updateItems`(coverImagePath 갱신) 바로
      // 다음 줄에서 `context.pop()`을 부르므로, Record 변화 관측 = pop 직후다.
      final committed = await waitUntil(
        tester,
        () => record(container, 'comp03').coverImagePath != coverBefore,
      );
      final tPop = watch.elapsedMilliseconds;
      // 종료 트랜지션(약 300ms) 동안 편집기 State는 아직 살아 있다 = up이 향하는 recognizer도
      // dispose되지 않은 상태다.
      final editorAliveAtUp = find.byType(CompositionEditorScreen).evaluate().isNotEmpty;
      // pop 직후 pointer-up.
      if (secondTap != null) {
        await secondTap.up();
        await tester.pump();
      }
      final hold = tPop - tDown;
      debugPrint('[Tester] $round회차 — offset=${offset.inMilliseconds}ms, down t=${tDown}ms, '
          'pop t=${tPop}ms, 홀드=${hold}ms, down이 pop보다 늦음=$missed, '
          'up 시점 편집기 생존=$editorAliveAtUp, 커밋=$committed');

      await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
      await drain(tester, frames: 60);
      lastCommitMillis = tPop;
      if (!missed && committed && hold < 500) {
        achieved = true;
        achievedHold = hold;
        achievedEditorAliveAtUp = editorAliveAtUp;
      }
    }

    expect(achieved, isTrue,
        reason: 'pop 직전 down / pop 직후 up(사람 탭 길이 <500ms) 조합을 한 번은 만들어야 이 '
            '시나리오가 성립한다');
    debugPrint('[Tester] pop을 가로지른 탭 성립 — 홀드 ${achievedHold}ms, '
        'up 시점 편집기 생존=$achievedEditorAliveAtUp');

    // ③ 가드가 없었다면 두 번째 커밋이 캡처+저장(수백 ms) 뒤 Record가 가리키는 파일을 지운다.
    //    그 시간을 충분히 넘겨(약 3초) 관측한다.
    await drain(tester, frames: 150);

    final created = snapshotFiles().where((p) => !before.contains(p)).toList();
    final committedPath = record(container, 'comp03').coverImagePath;
    final orphans = created.where((p) => norm(p) != norm(committedPath ?? '')).toList();
    debugPrint('[Tester] 남아 있는 새 스냅샷 ${created.length}개 / Record가 가리키는 것: $committedPath');
    debugPrint('[Tester] 고아 파일 ${orphans.length}개: $orphans');
    debugPrint('[Tester] 현재 화면: 코디상세=${find.byType(CompositionDetailScreen).evaluate().length}, '
        '코디메인=${find.byType(CompositionMainScreen).evaluate().length}');

    expect(tester.takeException(), isNull, reason: 'pop을 가로지르는 탭 자체로 예외가 나면 안 된다');
    expect(committedPath, isNotNull, reason: '커밋된 커버 경로가 있어야 한다');
    expect(File(committedPath!).existsSync(), isTrue,
        reason: 'Record가 가리키는 커버 파일이 실제로 존재해야 한다 — 재진입한 두 번째 커밋은 Record가 '
            '가리키는 파일을 지운 뒤 !mounted로 Record를 갱신하지 못해, 존재하지 않는 경로만 남긴다');
    expect(created.length, 1,
        reason: '코디 1개의 커버는 항상 1개다 — `saveCompositionSnapshot`이 이전 커버를 지우므로 '
            '재커밋을 반복해도 파일은 1개만 남아야 한다');
    expect(orphans, isEmpty, reason: '아무도 참조하지 않는 스냅샷 파일이 남으면 안 된다');
    expect(find.byType(CompositionDetailScreen), findsOneWidget,
        reason: '커밋 후에는 코디 상세로만 돌아와야 한다 — 코디 메인까지 튕기면 안 된다');
    expect(find.byType(CompositionMainScreen), findsNothing);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 하네스 자기검증 — 앱 위젯이 아니라 같은 모양(비동기 onPressed → await → pop)의 최소
  // 화면으로 프레임워크 동작만 분리한다. 위 앱 시나리오의 Pass가 "가드가 막아서"인지 "애초에
  // 두 번째 탭이 안 들어와서"인지 구분하기 위한 것이다.
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> setUpProbe(WidgetTester tester, {required bool withTooltip}) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _ProbeState.reset();
    await tester.pumpWidget(_ProbeApp(withTooltip: withTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
  }

  Future<void> holdFor(WidgetTester tester, Duration duration) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < duration) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await tester.pump();
    }
  }

  testWidgets('[자기검증 1] pop이 없으면 눌렀다 떼는 탭(100ms 홀드)은 정상적으로 onTap을 발화시킨다',
      (tester) async {
    // 이게 통과해야 아래 두 테스트의 "발화하지 않았다"가 하네스 결함이 아니라고 말할 수 있다.
    await setUpProbe(tester, withTooltip: true);
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.check)));
    await holdFor(tester, const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    await holdFor(tester, const Duration(milliseconds: 200));
    debugPrint('[Tester] 자기검증1 — pop 없음/짧은 홀드 → onPressed ${_ProbeState.taps}회');
    expect(_ProbeState.taps, 1, reason: 'startGesture+up 조합 자체는 정상적으로 탭이 된다');
  });

  testWidgets('[자기검증 2] 툴팁이 달린 버튼을 500ms 이상 누르고 있으면 롱프레스가 arena를 가져가 '
      'onTap이 발화하지 않는다', (tester) async {
    // 위 앱 시나리오가 홀드를 500ms 미만으로 제한하는 근거. 완료(✔)에도 `tooltip: '완료'`가
    // 달려 있어 같은 제약을 받는다.
    await setUpProbe(tester, withTooltip: true);
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.check)));
    await holdFor(tester, const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump();
    await holdFor(tester, const Duration(milliseconds: 200));
    debugPrint('[Tester] 자기검증2 — 툴팁+긴 홀드 → onPressed ${_ProbeState.taps}회');
    expect(_ProbeState.taps, 0,
        reason: '툴팁 롱프레스가 tap recognizer를 arena에서 밀어낸다 — 사람 탭 길이(<500ms)를 '
            '넘기면 이 버튼은 애초에 눌리지 않는다');
  });

  testWidgets('[자기검증 3] pop을 가로지른 pointer-up은 onTap을 다시 발화시키지 않는다 '
      '(Navigator가 활성 포인터를 취소한다)', (tester) async {
    await setUpProbe(tester, withTooltip: true);
    final button = find.byIcon(Icons.check);

    // ① 1차 탭 — 게이트가 열릴 때까지 대기하는 비동기 커밋 시작.
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 32));
    expect(_ProbeState.taps, 1);

    // ② pop 이전 pointer-down.
    final gesture = await tester.startGesture(tester.getCenter(button));
    await holdFor(tester, const Duration(milliseconds: 100));

    // ③ 게이트를 열어 pop을 일으킨다(시점을 테스트가 완전히 통제).
    _ProbeState.gate.complete();
    final watch = Stopwatch()..start();
    while (!_ProbeState.popCalled && watch.elapsedMilliseconds < 3000) {
      await Future<void>.delayed(const Duration(milliseconds: 4));
      await tester.pump();
    }
    final screenAliveAtUp = find.byType(_ProbeCommitScreen).evaluate().isNotEmpty;

    // ④ pop 직후 pointer-up.
    await gesture.up();
    await tester.pump();
    await holdFor(tester, const Duration(milliseconds: 400));

    debugPrint('[Tester] 자기검증3 — pop 가로지르기(홀드 100ms, up 시점 화면 생존=$screenAliveAtUp) '
        '→ onPressed ${_ProbeState.taps}회');
    expect(screenAliveAtUp, isTrue,
        reason: '종료 트랜지션 중이라 화면(=recognizer)은 아직 살아 있다 — 그런데도 아래처럼 '
            '탭이 발화하지 않는다면 원인은 위젯 dispose가 아니다');
    expect(_ProbeState.taps, 1,
        reason: 'Flutter 3.44.4에서는 `NavigatorState._flushHistoryUpdates()`가 '
            '`_cancelActivePointers()`로 눌려 있는 포인터를 취소하므로 pop 이후의 up은 onTap을 '
            '다시 발화시키지 못한다. 이 기대가 깨졌다면(=2회) 프레임워크가 더 이상 포인터를 '
            '취소하지 않는 것이고, `CompositionEditorScreen._handleCommit`의 가드 해제 규칙이 '
            '실제로 필요한 방어가 된 것이므로 앱 시나리오를 다시 설계해야 한다');
  });
}

/// 자기검증용 최소 앱 — 실제 앱 코드가 아니라 프레임워크 동작 확인용이다.
class _ProbeApp extends StatelessWidget {
  const _ProbeApp({required this.withTooltip});

  final bool withTooltip;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ProbeCommitScreen(withTooltip: withTooltip),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _ProbeState {
  static int taps = 0;
  static bool popCalled = false;
  static Completer<void> gate = Completer<void>();

  static void reset() {
    taps = 0;
    popCalled = false;
    gate = Completer<void>();
  }
}

class _ProbeCommitScreen extends StatefulWidget {
  const _ProbeCommitScreen({required this.withTooltip});

  final bool withTooltip;

  @override
  State<_ProbeCommitScreen> createState() => _ProbeCommitScreenState();
}

class _ProbeCommitScreenState extends State<_ProbeCommitScreen> {
  /// `_handleCommit`과 같은 모양: 비동기로 기다렸다가 `mounted` 가드를 지나 pop한다.
  /// 재진입 가드는 **일부러 넣지 않는다** — 넣으면 프레임워크 동작을 관측할 수 없다.
  Future<void> _handleProbeCommit() async {
    _ProbeState.taps += 1;
    await _ProbeState.gate.future;
    if (!mounted) return;
    _ProbeState.popCalled = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IconButton(
          icon: const Icon(Icons.check),
          tooltip: widget.withTooltip ? '완료' : null,
          onPressed: _handleProbeCommit,
        ),
      ),
    );
  }
}
