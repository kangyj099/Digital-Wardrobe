// integration_test/composition_snapshot_runtime_test.dart
//
// Tester가 직접 설계한 런타임 검증 — 코디 스냅샷 캡처/로컬 저장 구현
// (`docs/reference/data/00_DataSchema.md` §13, `docs/history/Decision.md` "코디 스냅샷
// 캡처/로컬 저장 아키텍처 확정").
//
// 이 스위트는 위젯 테스트로는 확인할 수 없는 것만 다룬다:
//  - `getApplicationSupportDirectory()` 아래에 **실제 PNG 파일**이 생기는지(경로/크기/픽셀
//    내용까지 직접 디코드해 확인), 그 파일이 갤러리 타일에서 `Image.file`로 실제로 쓰이는지
//  - 캡처가 여러 `await`(오프스크린 Overlay 마운트 → `endOfFrame` ×2 → `toImage` → 파일
//    쓰기)를 건너는 동안의 실제 타이밍
//  - 삭제된 옷 정리(§13.2b) 진행/취소/no-op 3분기의 실제 파일·Record 결과
//  - 방치된 Draft가 남아있는 상태에서의 Stale-Draft carve-out
//  - 영구삭제(purge)된 옷을 참조하는 코디의 "연결끊김" 배지
//
// `composition_editor_draft_commit_cancel_test.dart`(Draft↔Record 분리)와
// `composition_detail_static_artboard_test.dart`(정적 아트보드 상호작용)가 이미 다루는
// 축은 반복하지 않는다.
//
// 작성 관례 2가지:
//  1. 커밋/정리 경로는 프레임을 스케줄하지 않는 비동기 구간(`toImage`, 파일 I/O)을
//     포함하므로 `pumpAndSettle()`만으로 완료를 보장할 수 없다 — 실제 시간을 흘려보내며
//     조건 성립을 기다리는 [waitUntil]을 쓴다.
//  2. **그룹 7이 회귀로 고정한 문제**(코디 Record/옷 목록이 바뀐 뒤 이미 스택에 있던 코디
//     메인으로 되돌아가면 빌드 중 setState 예외) 때문에, 그룹 1~4는 그 복귀 경로를 검증
//     동선에 넣지 않는다 — 각 그룹이 보려는 축을 그 회귀와 분리하기 위함이다.
//
// 그룹 순서: 현재 통과하는 1~4를 앞에, **현재 실패하는 5~7**을
// 뒤에 둔다 — 실기기(`-d windows`) 실행에서 테스트 하나가 예외로 실패하면 그 뒤 테스트들이
// 바인딩 오염(`!inTest`)으로 연쇄 실패하기 때문. 5/6이 고쳐지면 순서 제약도 사라진다.
// 개별 실행: `flutter test integration_test/composition_snapshot_runtime_test.dart -d windows
// --plain-name "<테스트 이름 일부>"`.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_editor_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/services/composition_snapshot_service.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_cover_image.dart';
import 'package:digittal_wardrobe/widgets/classification_group_card.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';

/// 그룹 1-A가 실제 편집 커밋으로 만들어낸 스냅샷 파일 경로 — 그룹 1-B가 "그 파일이 타일에서
/// 실제로 렌더되는가"를 확인할 때 재사용한다(파일은 테스트 간에도 디스크에 남는다).
String? committedSnapshotPath;

/// 디코드한 스냅샷 PNG의 픽셀 통계.
class _PngStats {
  _PngStats(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;

  /// 배경(흰색)과 다른 픽셀의 비율 — 0에 가까우면 "빈 이미지"(§13.1이 경고한 콜드 디코드
  /// 실패 증상)라는 뜻이다.
  double get nonBackgroundRatio => _ratioIn(0, 0, width, height);

  /// 정규화 좌표 [cx],[cy] 중심의 한 변 [size]px 정사각 영역에서 배경이 아닌 픽셀 비율.
  double ratioAround(double cx, double cy, int size) {
    final left = (width * cx - size / 2).round().clamp(0, width - 1);
    final top = (height * cy - size / 2).round().clamp(0, height - 1);
    final right = (left + size).clamp(0, width);
    final bottom = (top + size).clamp(0, height);
    return _ratioIn(left, top, right, bottom);
  }

  double _ratioIn(int left, int top, int right, int bottom) {
    var counted = 0;
    var nonBackground = 0;
    // 4픽셀 간격 샘플링 — 디버그 빌드의 Dart 루프가 느려 100만 픽셀 전수 검사가 UI 스레드를
    // 수백 ms 붙잡는다(검사 자체가 앱 동작을 교란하면 안 됨). 비율 판정엔 충분한 해상도다.
    const step = 4;
    for (var y = top; y < bottom; y += step) {
      for (var x = left; x < right; x += step) {
        final i = (y * width + x) * 4;
        final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
        counted++;
        if ((255 - r).abs() > 12 || (255 - g).abs() > 12 || (255 - b).abs() > 12) {
          nonBackground++;
        }
      }
    }
    return counted == 0 ? 0 : nonBackground / counted;
  }
}

Future<_PngStats> _analyzePng(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return _PngStats(image.width, image.height, data!.buffer.asUint8List());
}

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
    debugPrint('[Tester] 스냅샷 디렉토리: ${snapshotDir.path}');
  });

  // 이 스위트가 실제로 만든 파일만 정리한다(실행 전부터 있던 파일은 건드리지 않음).
  tearDownAll(() {
    if (!snapshotDir.existsSync()) return;
    for (final entity in snapshotDir.listSync()) {
      if (preExistingSnapshots.contains(entity.path)) continue;
      try {
        entity.deleteSync();
      } on FileSystemException {
        // 정리 실패는 무시 — 검증 결과와 무관.
      }
    }
  });

  List<String> newSnapshotFiles() => snapshotDir
      .listSync()
      .map((e) => e.path)
      .where((p) => !preExistingSnapshots.contains(p))
      .toList();

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

  /// 프레임을 스케줄하지 않는 비동기 구간(파일 I/O, `toImage`)이 끝날 때까지 실제 시간을
  /// 흘려보내며 [condition] 성립을 기다린다. 성립하면 true.
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

  Finder artboardKey(String clothingItemId) =>
      find.byKey(ValueKey('static-artboard-item-$clothingItemId'));

  Finder editorVisual(String clothingItemId) => find.byKey(ValueKey('$clothingItemId:visual'));

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> openCompositionDetail(WidgetTester tester, String compositionId) async {
    await tester.tap(tileFinder(compositionId));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);
  }

  /// 코디 상세의 아트보드 아이템을 1.5초 이상 눌렀다 떼는 실제 사용자 제스처(편집 진입).
  Future<void> longPressArtboardItem(WidgetTester tester, String clothingItemId) async {
    final gesture = await tester.startGesture(tester.getCenter(artboardKey(clothingItemId)));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// 편집기 아트보드에서 아이템을 실제로 드래그해 Draft를 더럽힌다.
  Future<void> dragEditorItem(WidgetTester tester, String clothingItemId, Offset delta) async {
    final gesture = await tester.startGesture(tester.getCenter(editorVisual(clothingItemId)));
    await gesture.moveBy(armOffset); // 아밍 구간(결과 계산에서 제외됨)
    await tester.pump();
    await gesture.moveBy(delta);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// 완료(✔) 탭 → 캡처/저장/커밋이 실제로 끝날 때까지 대기. 소요 시간과
  /// "`pumpAndSettle()`만으로 충분했는지"를 함께 관찰해 로그로 남긴다.
  Future<Duration> commitAndWait(
    WidgetTester tester,
    bool Function() committed, {
    String label = '',
  }) async {
    final watch = Stopwatch()..start();
    await tester.tap(find.byTooltip('완료'));
    await tester.pumpAndSettle();
    final settledEnough = committed();
    final ok = await waitUntil(tester, committed);
    watch.stop();
    debugPrint('[Tester] $label 완료(✔) → 커밋 반영까지 ${watch.elapsedMilliseconds}ms '
        '/ pumpAndSettle()만으로 충분: $settledEnough');
    expect(ok, isTrue, reason: '$label 완료(✔) 후 커밋이 실제로 반영돼야 함');
    return watch.elapsed;
  }

  /// 그룹 1-A가 만든 실제 캡처 파일을 쓴다. 이 파일 하나만 단독 실행(`--plain-name`)할
  /// 때는 1-A가 돌지 않으므로, 같은 서비스(`saveCompositionSnapshot`)로 동일한 형태의
  /// 로컬 파일(에셋이 아닌 절대경로 PNG)을 만들어 대체한다 — 이 그룹들이 보는 건 "그 경로를
  /// 화면들이 제대로 읽는가"이지 캡처 자체가 아니다.
  Future<String> ensureSnapshotFile() async {
    final existing = committedSnapshotPath;
    if (existing != null && File(existing).existsSync()) return existing;
    final data = await rootBundle.load('assets/images/mock/IMG_4273.PNG');
    final path = await saveCompositionSnapshot(
      compositionId: 'comp03',
      pngBytes: data.buffer.asUint8List(),
    );
    committedSnapshotPath = path;
    return path;
  }

  // ────────────────────────────────────────────────────────────────────────────
  group('1) 에디터 완료(✔) → 실제 PNG 저장 / 저장된 파일의 타일 렌더링', () {
    testWidgets(
        '1-A) 코디 메인 → 상세 → 롱프레스 편집 → 드래그 → 완료: applicationSupportDirectory 아래에 '
        '내용이 있는 PNG가 실제로 저장되고, 재커밋하면 새 파일로 교체된다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');

      // 커밋 전: coverImagePath 없음 → 텍스트 전용 폴백이 보여야 한다(§13.6).
      expect(record(container, 'comp03').coverImagePath, isNull);
      expect(find.descendant(of: tileFinder('comp03'), matching: find.text('레인 코디')), findsOneWidget);
      expect(find.descendant(of: tileFinder('comp03'), matching: find.byType(CompositionCoverImage)),
          findsNothing);

      await openCompositionDetail(tester, 'comp03');
      await longPressArtboardItem(tester, 'c04');
      expect(find.text('삭제된 옷이 포함돼 있어요'), findsNothing,
          reason: 'comp03은 정리 대상이 없어 다이얼로그가 뜨면 안 됨');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);

      await dragEditorItem(tester, 'c04', const Offset(18, -22));

      await commitAndWait(
        tester,
        () => record(container, 'comp03').coverImagePath != null,
        label: 'comp03 최초 커밋',
      );

      final firstPath = record(container, 'comp03').coverImagePath!;
      expect(firstPath.startsWith(snapshotDir.path), isTrue,
          reason: '스냅샷은 <applicationSupportDirectory>/composition_snapshots/ 아래여야 함: $firstPath');
      expect(firstPath.endsWith('.png'), isTrue);
      expect(firstPath.contains('comp03_'), isTrue, reason: '파일명은 {compositionId}_{timestamp}.png');

      final file = File(firstPath);
      expect(file.existsSync(), isTrue, reason: '실제 파일이 디스크에 존재해야 함');
      expect(file.lengthSync(), greaterThan(1000), reason: '빈 파일이면 안 됨');

      // 편집기가 닫히고 코디 상세로 복귀했는지 확인한 뒤에 픽셀을 검사한다(전환 도중
      // UI 스레드를 붙잡으면 검사가 앱 동작을 교란한다).
      await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      await drain(tester);

      final stats = await _analyzePng(file);
      debugPrint('[Tester] comp03 스냅샷 ${stats.width}x${stats.height}, '
          '비배경 픽셀 ${(stats.nonBackgroundRatio * 100).toStringAsFixed(2)}%, '
          '${file.lengthSync()} bytes');
      expect(stats.width, 1024, reason: '§13.1 고정 캡처 크기(1024, pixelRatio 1.0)');
      expect(stats.height, 1024);
      expect(stats.nonBackgroundRatio, greaterThan(0.01),
          reason: '옷 이미지가 실제로 그려진 스냅샷이어야 함(빈/투명 캡처면 0에 가깝다)');

      // 아이템이 "배치된 좌표에" 실제로 그려졌는지 — Record의 최종 좌표 기준으로 확인.
      for (final placement in record(container, 'comp03').items) {
        final ratio = stats.ratioAround(placement.x, placement.y, 120);
        debugPrint('[Tester]   ${placement.clothingItemId} @(${placement.x.toStringAsFixed(2)},'
            '${placement.y.toStringAsFixed(2)}) 영역 비배경 ${(ratio * 100).toStringAsFixed(1)}%');
        expect(ratio, greaterThan(0.05),
            reason: '${placement.clothingItemId}가 배치 좌표에 실제로 렌더돼야 함');
      }

      // 재커밋: 새 파일명 발급 + 이전 파일 best-effort 삭제(§13.3).
      await longPressArtboardItem(tester, 'c05');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      await dragEditorItem(tester, 'c05', const Offset(-16, 20));
      await commitAndWait(
        tester,
        () => record(container, 'comp03').coverImagePath != firstPath,
        label: 'comp03 재커밋',
      );

      final secondPath = record(container, 'comp03').coverImagePath!;
      expect(secondPath, isNot(firstPath), reason: '재생성마다 새 파일명을 발급해야 함(§13.3)');
      expect(File(secondPath).existsSync(), isTrue);
      expect(File(firstPath).existsSync(), isFalse, reason: '이전 스냅샷 파일은 삭제돼야 함(§13.3)');
      committedSnapshotPath = secondPath;
      await drain(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1-B) 저장된 스냅샷을 가진 코디의 갤러리 타일은 그 파일을 Image.file로 그린다', (tester) async {
      await ensureSnapshotFile();
      expect(File(committedSnapshotPath!).existsSync(), isTrue);

      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      // 1-A가 편집기 커밋으로 실제 저장한 파일을 그대로 Record에 반영한다(코디 메인이
      // 보이는 상태에서 갱신 — 그룹 7의 회귀 경로와 겹치지 않게 하기 위함).
      final comp03 = record(container, 'comp03');
      container.read(compositionsProvider.notifier).updateItems(
            'comp03',
            comp03.items,
            coverImagePath: committedSnapshotPath,
          );
      await tester.pumpAndSettle();
      await drain(tester);

      final coverFinder = find.descendant(
        of: tileFinder('comp03'),
        matching: find.byType(CompositionCoverImage),
      );
      expect(coverFinder, findsOneWidget, reason: '스냅샷이 있으면 타일은 그 이미지를 표시해야 함');
      final image = tester.widget<Image>(find.descendant(of: coverFinder, matching: find.byType(Image)));
      expect(image.image, isA<FileImage>(),
          reason: 'assets/... 폴백이 아니라 런타임 저장 파일을 Image.file로 그려야 함');
      expect((image.image as FileImage).file.path, committedSnapshotPath);
      expect(find.descendant(of: tileFinder('comp03'), matching: find.text('레인 코디')), findsNothing,
          reason: '스냅샷이 생겼으면 텍스트 전용 폴백은 더 이상 쓰이지 않아야 함');
      expect(tester.takeException(), isNull, reason: 'Image.file 디코드/렌더에서 예외가 없어야 함');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('2) 편집 진입 전 "삭제된 옷 자동 정리"(§13.2b) 3분기', () {
    testWidgets('진행: 다이얼로그 → 정리 → 새 스냅샷 재생성 → 정리된 상태로 편집기 진입', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');

      // comp01은 c07(휴지통 상태)을 포함 → 타일에 "연결끊김" 배지가 보인다.
      expect(find.descendant(of: tileFinder('comp01'), matching: find.byIcon(Icons.link_off)),
          findsOneWidget);
      expect(record(container, 'comp01').items.length, 4);
      expect(record(container, 'comp01').coverImagePath, isNull);

      await openCompositionDetail(tester, 'comp01');
      await longPressArtboardItem(tester, 'c01');

      expect(find.text('삭제된 옷이 포함돼 있어요'), findsOneWidget);
      expect(find.text('삭제된 옷 1개 포함, 편집 시작 시 자동 제거돼요.'), findsOneWidget);
      expect(find.byType(CompositionEditorScreen), findsNothing,
          reason: '확인 전엔 편집 화면으로 넘어가면 안 됨');

      await tester.tap(find.text('진행'));
      await tester.pumpAndSettle();
      final entered = await waitUntil(
        tester,
        () => find.byType(CompositionEditorScreen).evaluate().isNotEmpty,
      );
      expect(entered, isTrue, reason: '진행 선택 후 편집 화면으로 이어져야 함');
      await drain(tester);

      // Record: c07이 실제로 빠지고 새 스냅샷이 생겼다.
      final cleaned = record(container, 'comp01');
      expect(cleaned.items.length, 3);
      expect(cleaned.items.any((p) => p.clothingItemId == 'c07'), isFalse);
      expect(cleaned.isIncomplete, isFalse, reason: '3개 남았으니 미완성이 아니어야 함(§13.5)');
      expect(cleaned.coverImagePath, isNotNull, reason: '정리 write-back도 스냅샷을 재생성해야 함');
      final file = File(cleaned.coverImagePath!);
      expect(file.existsSync(), isTrue);

      final stats = await _analyzePng(file);
      debugPrint('[Tester] 정리 후 comp01 스냅샷 비배경 '
          '${(stats.nonBackgroundRatio * 100).toStringAsFixed(2)}%');
      expect(stats.nonBackgroundRatio, greaterThan(0.01));
      // c07이 있던 자리(0.3, 0.65)는 비어야 하고, 남은 3개 자리는 그려져 있어야 한다.
      expect(stats.ratioAround(0.3, 0.65, 120), lessThan(0.01),
          reason: '정리된 c07 자리는 스냅샷에서도 비어 있어야 함');
      for (final placement in cleaned.items) {
        expect(stats.ratioAround(placement.x, placement.y, 120), greaterThan(0.05),
            reason: '${placement.clothingItemId}는 정리 후 스냅샷에 남아야 함');
      }

      // 편집기/Draft도 정리된 상태로 열렸다.
      expect(editorVisual('c07'), findsNothing, reason: '편집기에 삭제된 옷이 남아 있으면 안 됨');
      expect(editorVisual('c01'), findsOneWidget);
      expect(container.read(compositionDraftProvider('comp01')).items.length, 3);

      // 정리됐으므로 타일 배지의 근거(§13.4 판정)도 함께 꺼져야 한다(화면 간 일관성).
      // 배지 위젯 자체 확인은 코디 메인 복귀가 필요한데 그 경로는 그룹 7의 회귀와 겹치므로,
      // 여기서는 타일이 바인딩하는 provider 값으로 확인한다.
      expect(container.read(compositionHasDeletedItemsProvider('comp01')), isFalse);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('취소: Record/파일 어느 것도 바뀌지 않고 편집 화면으로 넘어가지 않는다', (tester) async {
      final container = await pumpApp(tester);
      final before = newSnapshotFiles().length;
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp01');
      await longPressArtboardItem(tester, 'c01');
      expect(find.text('삭제된 옷이 포함돼 있어요'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      await drain(tester);

      expect(find.byType(CompositionEditorScreen), findsNothing, reason: '취소하면 편집 화면으로 가면 안 됨');
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      final unchanged = record(container, 'comp01');
      expect(unchanged.items.length, 4, reason: '취소했으므로 items가 그대로여야 함');
      expect(unchanged.items.any((p) => p.clothingItemId == 'c07'), isTrue);
      expect(unchanged.coverImagePath, isNull, reason: '취소 경로는 스냅샷을 만들지 않아야 함');
      expect(newSnapshotFiles().length, before, reason: '취소 경로는 파일을 쓰지 않아야 함');
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-op: 정리 대상이 없는 코디는 다이얼로그도 없고 write-back도 없다', (tester) async {
      final container = await pumpApp(tester);
      final before = newSnapshotFiles().length;
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp03');
      await longPressArtboardItem(tester, 'c04');
      await drain(tester);

      expect(find.text('삭제된 옷이 포함돼 있어요'), findsNothing);
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      expect(record(container, 'comp03').coverImagePath, isNull,
          reason: 'no-op 경로는 캡처/저장을 하지 않아야 함');
      expect(newSnapshotFiles().length, before);
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('3) Stale-Draft carve-out — 방치된 Draft가 있어도 정리 결과가 반영된다', () {
    testWidgets(
        '편집 중 뒤로가기로 방치(Draft 남음) → 그 코디의 옷을 옷장에서 삭제 → 다시 편집 진입: '
        '정리 다이얼로그가 뜨고 편집기가 정리된 상태로 열리며, 거기서 완료해도 삭제된 옷이 되살아나지 않는다',
        (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp03');
      await longPressArtboardItem(tester, 'c04');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);

      // Draft를 실제로 더럽힌 뒤, 취소(✕)/완료(✔)를 거치지 않고 뒤로가기로 이탈한다.
      await dragEditorItem(tester, 'c04', const Offset(24, 18));
      final dirtyDraft = container.read(compositionDraftProvider('comp03'));
      expect(dirtyDraft.items.length, 2);
      final movedC04 = dirtyDraft.items.firstWhere((p) => p.clothingItemId == 'c04');
      expect(movedC04.x, isNot(0.3), reason: '드래그가 Draft에 반영돼야 함(방치 Draft 조건 성립)');

      container.read(appRouterProvider).pop(); // 시스템 뒤로가기와 동등한 이탈 경로
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      // 방치 Draft가 실제로 살아 있는지 확인(이 검증의 전제).
      expect(
        container
            .read(compositionDraftProvider('comp03'))
            .items
            .firstWhere((p) => p.clothingItemId == 'c04')
            .x,
        movedC04.x,
      );

      // 다른 화면(옷 상세)에서 그 옷을 삭제한다 — 코디 상세의 "사용된 옷" 목록에서 바로
      // 진입하는 실제 경로를 쓴다(코디 메인 재진입은 그룹 7의 회귀와 겹치므로 피한다).
      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('사용 중인 코디가 있어요'), findsOneWidget,
          reason: 'c04는 comp03이 사용 중이라 확인 팝업이 떠야 함');
      await tester.tap(find.text('휴지통으로 이동'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c04').isDeleted, isTrue);
      expect(find.byType(CompositionDetailScreen), findsOneWidget,
          reason: '삭제 후 원래 있던 코디 상세로 돌아와야 함');

      await longPressArtboardItem(tester, 'c05');
      expect(find.text('삭제된 옷 1개 포함, 편집 시작 시 자동 제거돼요.'), findsOneWidget,
          reason: '방치 Draft가 있어도 정리 가드는 Record 기준으로 동작해야 함');
      await tester.tap(find.text('진행'));
      await tester.pumpAndSettle();
      final entered = await waitUntil(
        tester,
        () => find.byType(CompositionEditorScreen).evaluate().isNotEmpty,
      );
      expect(entered, isTrue);
      await drain(tester);

      // 핵심: 방치돼 있던(정리 이전) Draft가 아니라 정리된 Record로 다시 초기화돼야 한다.
      expect(container.read(compositionDraftProvider('comp03')).items.length, 1,
          reason: 'Stale Draft(2개)가 그대로 재사용되면 안 됨 — invalidate 후 정리된 Record로 재초기화');
      expect(container.read(compositionDraftProvider('comp03')).items.single.clothingItemId, 'c05');
      expect(editorVisual('c04'), findsNothing, reason: '편집기에 삭제된 c04가 보이면 안 됨');
      expect(editorVisual('c05'), findsOneWidget);

      // 여기서 완료해도 c04 참조가 되살아나면 안 된다.
      final pathAfterCleanup = record(container, 'comp03').coverImagePath;
      expect(pathAfterCleanup, isNotNull);
      await commitAndWait(
        tester,
        () => record(container, 'comp03').coverImagePath != pathAfterCleanup,
        label: '정리 후 편집기에서 커밋',
      );
      final committed = record(container, 'comp03');
      expect(committed.items.length, 1);
      expect(committed.items.any((p) => p.clothingItemId == 'c04'), isFalse,
          reason: '삭제된 옷 참조가 커밋으로 되살아나면 안 됨');
      expect(File(committed.coverImagePath!).existsSync(), isTrue);
      await drain(tester);
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('4) "연결끊김" 배지 — 영구삭제(purge)된 옷도 잡아낸다(§13.4)', () {
    testWidgets('휴지통에서 c07을 영구삭제해도 comp01 타일의 배지가 유지된다', (tester) async {
      final container = await pumpApp(tester);
      // 코디 메인을 먼저 방문하지 않고(그룹 7의 회귀 경로와 겹치지 않게) 옷장 → 휴지통으로
      // 바로 진입해 purge한 뒤, 그 다음에 코디 메인을 처음 열어 배지를 확인한다.
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c07').isDeleted, isTrue,
          reason: 'mock 기준 c07은 휴지통(소프트 삭제) 상태');
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      expect(find.byType(TrashMainScreen), findsOneWidget);

      final c07Tile = find.byKey(const ValueKey('c07'));
      expect(c07Tile, findsOneWidget);
      await tester.longPress(c07Tile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제').last); // 확인 모달
      await tester.pumpAndSettle();
      await drain(tester);

      expect(container.read(closetItemsProvider).any((i) => i.id == 'c07'), isFalse,
          reason: 'c07이 완전히 사라져야 함(purge)');

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      await goToCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.descendant(of: tileFinder('comp01'), matching: find.byIcon(Icons.link_off)),
          findsOneWidget, reason: 'purge 이후에도 배지가 유지돼야 함(Track A 구로직이 놓치던 케이스)');
      expect(tester.widget<CompositionGalleryTile>(tileFinder('comp01')).hasDeletedItem, isTrue);
      expect(find.descendant(of: tileFinder('comp03'), matching: find.byIcon(Icons.link_off)),
          findsNothing, reason: '정상 코디엔 배지가 없어야 함');
      expect(container.read(compositionHasDeletedItemsProvider('comp01')), isTrue,
          reason: 'purge된 옷을 참조하는 코디도 §13.4 판정에 걸려야 함');

      // purge된 옷도 편집 진입 시 정리 대상으로 잡혀야 한다.
      await openCompositionDetail(tester, 'comp01');
      await longPressArtboardItem(tester, 'c01');
      expect(find.text('삭제된 옷 1개 포함, 편집 시작 시 자동 제거돼요.'), findsOneWidget,
          reason: 'purge된 참조도 정리 다이얼로그의 N에 포함돼야 함');
      await tester.tap(find.text('진행'));
      await tester.pumpAndSettle();
      final entered = await waitUntil(
        tester,
        () => find.byType(CompositionEditorScreen).evaluate().isNotEmpty,
      );
      expect(entered, isTrue);
      await drain(tester);
      expect(record(container, 'comp01').items.length, 3);
      expect(record(container, 'comp01').items.any((p) => p.clothingItemId == 'c07'), isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('5) [실패 중] 저장된 스냅샷 경로를 소비하는 다른 화면들', () {
    // §13.3은 `coverImagePath`를 읽는 호출부가 `CompositionCoverImage`(에셋/파일 분기)를
    // 쓰도록 못박았다. 커밋 이후의 `coverImagePath`는 `assets/...`가 아니라 실제 로컬 파일
    // 절대경로이므로, 아직 `Image.asset`으로 읽는 화면이 남아 있으면 그 화면에서 이미지
    // 로드가 실패한다.
    Future<void> seedRealSnapshot(WidgetTester tester, ProviderContainer container) async {
      final comp03 = record(container, 'comp03');
      container.read(compositionsProvider.notifier).updateItems(
            'comp03',
            comp03.items,
            coverImagePath: committedSnapshotPath,
          );
      await tester.pumpAndSettle();
      await drain(tester);
    }

    testWidgets('코디 메인 "계절/날씨" 그룹 개요의 썸네일이 저장된 스냅샷 파일을 읽는다', (tester) async {
      await ensureSnapshotFile();
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await seedRealSnapshot(tester, container);

      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('날씨').last);
      await tester.pumpAndSettle();
      await drain(tester);

      expect(find.byType(ClassificationGroupCard), findsWidgets, reason: '그룹 개요 카드가 보여야 함');
      expect(tester.takeException(), isNull,
          reason: '그룹 카드 썸네일이 저장된 스냅샷(로컬 파일 경로)을 읽지 못하면 안 됨');
    });

    testWidgets('스냅샷이 있는 코디를 삭제하면 휴지통 타일이 그 스냅샷을 읽는다', (tester) async {
      await ensureSnapshotFile();
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await seedRealSnapshot(tester, container);

      container.read(compositionsProvider.notifier).softDeleteMany({'comp03'});
      await tester.pumpAndSettle();
      await drain(tester);

      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(TrashMainScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget, reason: '삭제한 코디가 휴지통에 보여야 함');
      expect(tester.takeException(), isNull,
          reason: '휴지통 타일이 저장된 스냅샷(로컬 파일 경로)을 읽지 못하면 안 됨');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('6) [실패 중] 캡처 타이밍 — 이미지 캐시가 비워진 직후 커밋해도 빈 스냅샷이 저장되지 않는다', () {
    testWidgets(
        '편집 중 이미지 캐시가 비워진(=OS 메모리 압박 시 Flutter가 실제로 하는 동작) 직후 완료해도 '
        '옷이 그려진 스냅샷이 저장된다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp03');
      await longPressArtboardItem(tester, 'c04');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);

      // §13.1이 "이 세션에 한 번도 렌더된 적 없는 이미지는 콜드 디코드가 캡처 대기시간 안에
      // 안 끝나 빈 타일로 잡힐 수 있다"고 경고한 리스크를, 재현 가능한 형태로 강제한다 —
      // 앱이 실제로 겪는 동등한 상황은 메모리 압박에 의한 이미지 캐시 비움이다.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await commitAndWait(
        tester,
        () => record(container, 'comp03').coverImagePath != null,
        label: '이미지 캐시 비운 직후 커밋',
      );

      final path = record(container, 'comp03').coverImagePath!;
      await drain(tester);
      final stats = await _analyzePng(File(path));
      debugPrint('[Tester] 캐시 비운 직후 스냅샷 비배경 픽셀 '
          '${(stats.nonBackgroundRatio * 100).toStringAsFixed(2)}% '
          '(정상 캡처 기준값 ≈5.9%)');
      expect(stats.nonBackgroundRatio, greaterThan(0.01),
          reason: '이미지 캐시가 비워진 직후 캡처해도 빈 이미지가 저장되면 안 됨(§13.1 known risk)');
      // 전체 비율만 보면 "일부 아이템만 빠진" 부분 캡처를 놓친다 — 아이템별 영역까지 본다.
      for (final placement in record(container, 'comp03').items) {
        final ratio = stats.ratioAround(placement.x, placement.y, 120);
        debugPrint('[Tester]   ${placement.clothingItemId} 영역 비배경 '
            '${(ratio * 100).toStringAsFixed(1)}%');
        expect(ratio, greaterThan(0.05),
            reason: '${placement.clothingItemId}가 캐시 비움 직후 캡처에서 누락되면 안 됨');
      }
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // [Tester 발견] 현재 브랜치에서 재현되는 회귀 — 코디 메인이 화면에서 가려진 사이 코디
  // Record가 바뀌고, 그 뒤 이미 스택에 있던 코디 메인으로 되돌아가면 빌드 중 setState 예외가
  // 난다. 같은 스크립트가 구현 직전 커밋(ad2b5a7)에서는 통과한다(A/B 확인). 예외가 나면
  // 뒤이은 테스트들도 바인딩이 오염돼 연쇄 실패하므로 이 그룹은 파일 맨 뒤에 둔다.
  group('7) [실패 중, 회귀] Record 변경 후 코디 메인 복귀 시 빌드 중 setState 예외', () {
    testWidgets('편집 완료(✔) 후 뒤로가기로 코디 메인에 복귀해도 예외가 없어야 한다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp03');
      await longPressArtboardItem(tester, 'c04');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      await dragEditorItem(tester, 'c04', const Offset(18, -22));
      await commitAndWait(
        tester,
        () => record(container, 'comp03').coverImagePath != null,
        label: '회귀 확인용 커밋',
      );
      await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
      await drain(tester);
      expect(tester.takeException(), isNull, reason: '편집기 → 상세 복귀까지는 예외가 없어야 함');

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '코디 메인 복귀에서 예외가 없어야 함');
    });

    testWidgets(
        '[최소 재현] 편집기/스냅샷 없이 코디 상세에서 Record만 바꾼 뒤 뒤로가기해도 예외가 없어야 한다',
        (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp03');

      final comp03 = record(container, 'comp03');
      container.read(compositionsProvider.notifier).updateItems('comp03', [comp03.items.first]);
      await tester.pumpAndSettle();
      await drain(tester);
      expect(tester.takeException(), isNull, reason: 'Record 변경 자체로는 예외가 없어야 함');

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '코디 메인 복귀에서 예외가 없어야 함');
    });
  });
}
