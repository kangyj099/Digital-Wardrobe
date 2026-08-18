// integration_test/composition_snapshot_followup_b_test.dart
//
// F6 회귀 스위트 — 완료(✔)를 사람이 실제로 하는 간격(약 150ms)으로 두 번 눌러도 커밋이 한 번만
// 실행되는지 확인한다.
//
// 배경: 2차 Tester가 이 파일로 F6을 재현했고(작성 당시엔 의도적 실패 상태), `db56ecf`의
// `_handleCommit` 재진입 가드(`_isCommitting`)로 닫혔다. 가드가 없으면 캡처+저장이 걸리는 수백
// ms 동안 완료 버튼이 그대로 살아 있어 `_handleCommit`이 두 번 실행되고:
//  1. 스냅샷 PNG가 2개 저장되는데 Record는 하나만 가리키므로 나머지는 아무도 참조하지 않는
//     고아 파일로 디스크에 영원히 남는다(`saveCompositionSnapshot`의 이전 파일 정리는
//     `previousCoverImagePath` 기준이라, 같은 "이전 경로"를 들고 시작한 두 호출은 서로가 만든
//     파일을 지우지 못한다).
//  2. `context.pop()`이 두 번 실행돼 편집기뿐 아니라 **코디 상세까지** 닫히고 코디 메인으로
//     튕긴다.
//
// down과 up이 pop을 가로지르는 변형(가드 1차 시도인 `finally` 해제가 반려된 근거)은
// `composition_snapshot_commit_pop_crossing_tap_test.dart`가 맡는다 — `tester.tap()`은 down과
// up을 같은 동기 호출에서 처리하므로 여기서는 그 창을 만들 수 없다.
//
// [실행 결과 2026-08-17 / db56ecf] 1/1 통과 — 새 스냅샷 1개, 고아 0개, 화면은 코디 상세 유지.
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

  Future<bool> waitUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final watch = Stopwatch()..start();
    while (watch.elapsed < timeout) {
      if (condition()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
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

  testWidgets(
      '완료(✔)를 사람이 실제로 하는 간격(150ms)으로 두 번 눌러도 스냅샷 파일은 1개만 남고 '
      '화면은 코디 상세에 그대로 있는다', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디').last);
    await tester.pumpAndSettle();

    await tester.tap(tileFinder('comp03'));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);

    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('static-artboard-item-c04'))),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await press.up();
    await tester.pumpAndSettle();
    expect(find.byType(CompositionEditorScreen), findsOneWidget);

    final drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('c04:visual'))));
    await drag.moveBy(armOffset);
    await tester.pump();
    await drag.moveBy(const Offset(20, -14));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    final before = snapshotFiles().toSet();

    // 캡처(프리캐시 → 오버레이 → endOfFrame ×2 → toImage → 파일 쓰기)는 실측 수백 ms 걸린다.
    // 그 사이 두 번째 탭은 사람의 평범한 연타 간격 안에 충분히 들어간다.
    await tester.tap(find.byTooltip('완료'));
    await tester.pump(const Duration(milliseconds: 150));
    // 시나리오 전제 확인 — 커밋 중에도 버튼은 그대로 눌리는 상태다(가드는 시각적 비활성화가
    // 아니라 `_handleCommit` 내부의 동작 가드이므로, 두 번째 탭 자체는 여전히 발생한다).
    final stillThere = find.byTooltip('완료').evaluate().isNotEmpty;
    debugPrint('[Tester] 1차 탭 150ms 후에도 완료 버튼이 그대로 눌리는 상태: $stillThere');
    expect(stillThere, isTrue, reason: '커밋이 진행 중인 동안 버튼이 그대로 살아 있다(두 번째 탭이 가능하다)');
    await tester.tap(find.byTooltip('완료'));
    await tester.pump(const Duration(milliseconds: 16));

    await waitUntil(tester, () => record(container, 'comp03').coverImagePath != null);
    await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
    await drain(tester, frames: 60);

    final created = snapshotFiles().where((p) => !before.contains(p)).toList();
    final committedPath = record(container, 'comp03').coverImagePath;
    // Windows에서 Record가 들고 있는 경로(`getApplicationSupportDirectory()` + '/'로 조립)와
    // `Directory.listSync()`가 돌려주는 경로는 구분자가 섞여 있어(슬래시 vs OS 구분자) 문자열
    // 전에 정규화해야 한다 — 정규화 없이 비교하면 고아 파일 개수가 과다 집계된다.
    String norm(String path) => path.replaceAll(Platform.pathSeparator, '/');
    final orphans =
        created.where((p) => norm(p) != norm(committedPath ?? '')).toList();
    debugPrint('[Tester] 새로 생긴 스냅샷 파일 ${created.length}개 / Record가 가리키는 것: $committedPath');
    debugPrint('[Tester] 아무도 참조하지 않는 고아 파일 ${orphans.length}개: $orphans');
    debugPrint('[Tester] 현재 화면: 코디상세=${find.byType(CompositionDetailScreen).evaluate().length}, '
        '코디메인=${find.byType(CompositionMainScreen).evaluate().length}');

    expect(tester.takeException(), isNull, reason: '연속 탭 자체로 예외가 나지는 않는다');
    expect(committedPath, isNotNull);
    expect(File(committedPath!).existsSync(), isTrue);

    expect(orphans, isEmpty,
        reason: '완료를 두 번 눌러도 아무도 참조하지 않는 스냅샷 파일이 남으면 안 됨');
    expect(find.byType(CompositionDetailScreen), findsOneWidget,
        reason: '커밋 후에는 코디 상세로만 돌아와야 한다 — 두 번 눌렀다고 코디 상세까지 pop되면 안 됨');
  });
}
