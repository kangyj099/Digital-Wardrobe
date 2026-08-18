// integration_test/composition_snapshot_followup_test.dart
//
// 2차 Tester 검증 — 1차 FAIL(F1~F5) 수정분(`f84ce62`, `80f7e1a`) 재확인 중, 1차 스위트
// (`composition_snapshot_runtime_test.dart`)가 닿지 않은 구멍만 다룬다. 겹치는 축은 반복하지
// 않는다:
//  - 1차가 이미 커버: 커밋 → PNG 실제 저장/픽셀 내용, 정리(§13.2b) 3분기, Stale-Draft,
//    "연결끊김" 배지(purge된 옷 포함), 커밋 경로의 콜드 캐시(그룹 6), 커밋 후 코디 메인
//    복귀 회귀(그룹 7).
//  - 이 파일이 메우는 구멍:
//    A) 저장된 스냅샷이 **실사용 동선만으로** 여러 화면에 일관되게 나타나는지 — 1차 그룹 5는
//       `updateItems`로 경로를 주입해 각 화면을 따로 확인했다(주입 없이, 실제 편집 커밋 →
//       화면 이동으로 같은 파일이 계속 쓰이는지는 확인된 적 없음).
//    B) 완료(✔) **빠른 연속 탭** — 커밋이 이 Task에서 async가 되면서(캡처/파일 I/O가 여러
//       await를 건넌다) 생긴 창. **현재 실패 중**이라 별도 파일로 분리했다
//       (`composition_snapshot_followup_b_test.dart`) — 실패한 테스트 뒤 테스트들이 바인딩
//       오염으로 연쇄 실패하는 것을 피하려는 1차 스위트의 관례와 같은 이유.
//    C) F5(purge 시 스냅샷 파일 삭제)의 **실제 파일 결과** — 1차 스위트엔 purge 경로 자체가
//       없다. 반대편(복원)에서 파일이 살아남는지도 함께 본다.
//    D) F3(콜드 디코드) — 1차 그룹 6은 **에디터 커밋** 경로만 캐시를 비웠다. 캡처 호출부는
//       2곳이므로(§13.2a/b) 정리 write-back 경로도 같은 조건에서 확인한다.
//
// C/A의 "삭제 → 휴지통 → 복원/영구삭제 후 코디 메인 복귀"는 F1이 깨뜨렸던 지점(코디 메인이
// 스택에 남은 채 Record가 바뀐 뒤 복귀)을 1차 그룹 7과 다른 경로로 한 번 더 밟는다.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/classification_group_card.dart';
import 'package:digittal_wardrobe/widgets/composition_cover_image.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_preview_card.dart';

/// 디코드한 스냅샷 PNG의 픽셀 통계(1차 스위트의 동일 헬퍼 — 테스트 파일끼리는 import로
/// 공유할 수 없어 필요한 부분만 옮겨 왔다).
class _PngStats {
  _PngStats(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;

  double get nonBackgroundRatio => _ratioIn(0, 0, width, height);

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
  // `image`/`codec`은 GC 대상이 아닌 네이티브 리소스라 반드시 직접 해제해야 한다. 1024x1024
  // RGBA 한 장이 4MB이고, 이걸 흘리면 **이 프로세스에서 그 뒤에 처음 디코드되는 에셋**이
  // `Unable to load asset ... Asset not found`로 실패한다(2차 Tester가 실기기에서 확인:
  // 그룹 1만 돌고 그룹 4로 넘어가도 휴지통의 c07/c08 썸네일이 그 오류로 깨졌고, 아래 dispose를
  // 넣자 그대로 통과했다 — 앱 코드가 아니라 이 헬퍼가 원인이었다).
  // `toByteData`가 준 버퍼는 `image`에 딸린 것이라, dispose 전에 복사해 둔다.
  final stats = _PngStats(
      image.width, image.height, Uint8List.fromList(data!.buffer.asUint8List()));
  image.dispose();
  codec.dispose();
  return stats;
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

  /// 프레임을 스케줄하지 않는 비동기 구간(파일 I/O, `toImage`, `unawaited` 파일 삭제)이 끝날
  /// 때까지 실제 시간을 흘려보내며 [condition] 성립을 기다린다.
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

  Future<void> longPressArtboardItem(WidgetTester tester, String clothingItemId) async {
    final gesture = await tester.startGesture(tester.getCenter(artboardKey(clothingItemId)));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> dragEditorItem(WidgetTester tester, String clothingItemId, Offset delta) async {
    final gesture = await tester.startGesture(tester.getCenter(editorVisual(clothingItemId)));
    await gesture.moveBy(armOffset); // 아밍 구간
    await tester.pump();
    await gesture.moveBy(delta);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// comp03을 실제 편집 커밋시켜 진짜 스냅샷 파일을 만든다(주입 없음). 반환값은 저장된 경로.
  Future<String> commitComp03(
    WidgetTester tester,
    ProviderContainer container, {
    Offset drag = const Offset(18, -22),
  }) async {
    await openCompositionDetail(tester, 'comp03');
    await longPressArtboardItem(tester, 'c04');
    expect(find.byType(CompositionEditorScreen), findsOneWidget);
    await dragEditorItem(tester, 'c04', drag);
    await tester.tap(find.byTooltip('완료'));
    await tester.pumpAndSettle();
    final ok = await waitUntil(tester, () => record(container, 'comp03').coverImagePath != null);
    expect(ok, isTrue, reason: '커밋이 실제로 반영돼야 함');
    await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
    await drain(tester);
    final path = record(container, 'comp03').coverImagePath!;
    expect(File(path).existsSync(), isTrue);
    return path;
  }

  /// [cardFinder] 하위의 `Image`가 [path] 파일을 그리고 있는지 — "예외가 없다"만으로는
  /// 부족하다(경로가 null이면 아예 안 그려도 예외는 안 난다).
  void expectRendersFile(WidgetTester tester, Finder cardFinder, String path) {
    final image = tester.widget<Image>(
      find.descendant(of: cardFinder, matching: find.byType(Image)).first,
    );
    expect(image.image, isA<FileImage>(),
        reason: 'assets/... 폴백이 아니라 런타임 저장 스냅샷을 Image.file로 그려야 함');
    expect((image.image as FileImage).file.path, path);
  }

  // ────────────────────────────────────────────────────────────────────────────
  group('A) 실제 편집 커밋으로 만든 스냅샷이 화면을 옮겨 다녀도 계속 같은 파일로 보인다', () {
    testWidgets(
        '커밋 → (코디 상세) 사용된 옷 탭 → 옷 상세 "연결된 코디" 카드 → 뒤로 → 코디 메인 타일 → '
        '"날씨" 그룹 개요 카드까지 전부 같은 스냅샷 파일을 그린다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      final path = await commitComp03(tester, container);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // (1) 옷 상세의 "연결된 코디" 캐러셀 — 코디 상세의 "사용된 옷" 타일에서 실제로 탭해 이동.
      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      final card = find.byType(CompositionPreviewCard);
      expect(card, findsOneWidget, reason: 'c04를 쓰는 코디(comp03) 카드가 캐러셀에 보여야 함');
      expectRendersFile(tester, card, path);
      expect(tester.takeException(), isNull);

      // (2) 뒤로 → 코디 상세 → 뒤로 → 코디 메인 타일(F1이 깨뜨렸던 복귀 경로).
      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '코디 메인 복귀에서 예외가 없어야 함');

      final tileCover = find.descendant(
        of: tileFinder('comp03'),
        matching: find.byType(CompositionCoverImage),
      );
      expect(tileCover, findsOneWidget);
      expectRendersFile(tester, tileCover, path);

      // (3) "날씨" 그룹 개요 카드 썸네일.
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('날씨').last);
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(ClassificationGroupCard), findsWidgets);
      final groupThumbs = find.descendant(
        of: find.byType(ClassificationGroupCard),
        matching: find.byType(Image),
      );
      final rendersSnapshot = groupThumbs.evaluate().any((e) {
        final image = e.widget as Image;
        return image.image is FileImage && (image.image as FileImage).file.path == path;
      });
      expect(rendersSnapshot, isTrue,
          reason: '그룹 개요 썸네일도 같은 스냅샷 파일(Image.file)을 그려야 함');
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('C) 휴지통 — 영구삭제는 스냅샷 파일까지 지우고, 복원은 그대로 살려둔다(F5)', () {
    Future<void> deleteFromDetail(WidgetTester tester) async {
      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await drain(tester);
    }

    Future<void> openTrash(WidgetTester tester, ProviderContainer container) async {
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(TrashMainScreen), findsOneWidget);
    }

    testWidgets('스냅샷이 있는 코디를 휴지통에서 영구삭제하면 그 PNG 파일이 디스크에서 사라진다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      final path = await commitComp03(tester, container);

      await deleteFromDetail(tester);
      expect(record(container, 'comp03').isDeleted, isTrue);
      expect(File(path).existsSync(), isTrue, reason: '휴지통으로 옮긴 것만으로는 파일이 지워지면 안 됨');

      await openTrash(tester, container);
      final trashTile = find.byKey(const ValueKey('comp03'));
      expect(trashTile, findsOneWidget);
      // 휴지통 타일이 그 스냅샷 파일을 그리는지도 이 김에 확인(§13.3 호출부).
      expectRendersFile(tester, trashTile, path);

      await tester.tap(trashTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제').last); // 정보 팝업의 [영구 삭제]
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제').last); // 확인 모달
      await tester.pumpAndSettle();
      await drain(tester);

      expect(container.read(compositionsProvider).any((c) => c.id == 'comp03'), isFalse,
          reason: 'purge됐으니 Record가 사라져야 함');
      // 파일 삭제는 `unawaited` best-effort라 상태 갱신과 동시에 끝나지 않는다.
      final gone = await waitUntil(tester, () => !File(path).existsSync());
      expect(gone, isTrue, reason: 'purge된 코디의 스냅샷 PNG는 디스크에서도 지워져야 함(F5)');

      // purge 직후 코디 메인으로 복귀해도 예외가 없어야 한다(F1이 깨뜨렸던 복귀 경로의 변형).
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(tileFinder('comp03'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('휴지통에서 복원하면 스냅샷 파일은 남아 있고, 코디 메인 타일이 다시 그 파일을 그린다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      final path = await commitComp03(tester, container);

      await deleteFromDetail(tester);
      await openTrash(tester, container);
      await tester.tap(find.byKey(const ValueKey('comp03')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      await drain(tester);

      expect(record(container, 'comp03').isDeleted, isFalse);
      expect(File(path).existsSync(), isTrue, reason: '복원 경로는 스냅샷 파일을 지우면 안 됨');
      expect(record(container, 'comp03').coverImagePath, path);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      final tileCover = find.descendant(
        of: tileFinder('comp03'),
        matching: find.byType(CompositionCoverImage),
      );
      expect(tileCover, findsOneWidget, reason: '복원된 코디가 스냅샷 커버로 다시 보여야 함');
      expectRendersFile(tester, tileCover, path);
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('D) 정리 write-back(§13.2b) 캡처도 이미지 캐시가 비워진 직후 빈 스냅샷을 만들지 않는다', () {
    testWidgets('이미지 캐시를 비운 직후 comp01 편집 진입 → 진행: 정리된 스냅샷에 남은 옷들이 실제로 그려진다',
        (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');
      await openCompositionDetail(tester, 'comp01');
      expect(record(container, 'comp01').coverImagePath, isNull);

      // 캡처 호출부는 2곳(§13.2a 커밋 / §13.2b 정리 write-back)인데 1차 스위트 그룹 6은
      // 커밋 쪽만 콜드 캐시로 확인했다 — 정리 쪽은 사용자가 다이얼로그를 읽는 동안에도
      // 메모리 압박이 올 수 있어 같은 리스크가 있다.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await longPressArtboardItem(tester, 'c01');
      expect(find.text('삭제된 옷 1개 포함, 편집 시작 시 자동 제거돼요.'), findsOneWidget);
      await tester.tap(find.text('진행'));
      await tester.pumpAndSettle();
      final entered = await waitUntil(
        tester,
        () => find.byType(CompositionEditorScreen).evaluate().isNotEmpty,
      );
      expect(entered, isTrue);
      await drain(tester);

      final cleaned = record(container, 'comp01');
      expect(cleaned.items.length, 3);
      expect(cleaned.coverImagePath, isNotNull, reason: '정리 write-back이 스냅샷을 만들어야 함');
      final stats = await _analyzePng(File(cleaned.coverImagePath!));
      debugPrint('[Tester] 캐시 비운 직후 정리 스냅샷 비배경 픽셀 '
          '${(stats.nonBackgroundRatio * 100).toStringAsFixed(2)}% (정상 기준값 ≈7.4%)');
      expect(stats.nonBackgroundRatio, greaterThan(0.01),
          reason: '콜드 캐시에서도 빈 스냅샷이 저장되면 안 됨(§13.1)');
      for (final placement in cleaned.items) {
        final ratio = stats.ratioAround(placement.x, placement.y, 120);
        debugPrint('[Tester]   ${placement.clothingItemId} 영역 비배경 '
            '${(ratio * 100).toStringAsFixed(1)}%');
        expect(ratio, greaterThan(0.05),
            reason: '${placement.clothingItemId}가 콜드 캐시 정리 캡처에서 누락되면 안 됨');
      }
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  group('E) 커밋 전에 이미 열어봤던 화면을 커밋 후 다시 열면 새 스냅샷으로 갱신돼 있다', () {
    testWidgets(
        '옷 상세("연결된 코디" 카드)를 먼저 본 뒤 그 코디를 편집 커밋하고, 같은 옷 상세를 다시 열면 '
        '카드가 새 스냅샷 파일로 갱신되고 예외도 없다', (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');

      // (1) 커밋 **전** 방문 — 이 시점에 `compositionCoverImageProvider('comp03')` 인스턴스가
      // 만들어진다. 이 provider는 `.autoDispose`가 아니라 화면을 떠나도 컨테이너에 남고,
      // 이후 `compositionsProvider`가 바뀌면 dirty 상태로 남아 있다가 재방문 시 재구독
      // 시점에 동기 flush된다 — `docs/history/TechnicalDebt.md` 최상단 항목이 실제 크래시로
      // 이어진 형태와 같은 구조라, 커밋으로 Record가 자주 바뀌게 된 이번 Task에서 실제
      // 재방문 동선으로 확인해둘 값어치가 있다.
      await openCompositionDetail(tester, 'comp03');
      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      final firstCard = find.byType(CompositionPreviewCard);
      expect(firstCard, findsOneWidget);
      final beforeImage = tester.widget<Image>(
        find.descendant(of: firstCard, matching: find.byType(Image)).first,
      );
      expect(beforeImage.image, isA<AssetImage>(),
          reason: '커밋 전에는 스냅샷이 없어 첫 옷 이미지(에셋) 폴백이어야 함');

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      // (2) 같은 코디를 편집 커밋 — Record의 coverImagePath가 바뀐다.
      await longPressArtboardItem(tester, 'c04');
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      await dragEditorItem(tester, 'c04', const Offset(-14, 16));
      await tester.tap(find.byTooltip('완료'));
      await tester.pumpAndSettle();
      await waitUntil(tester, () => record(container, 'comp03').coverImagePath != null);
      await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
      await drain(tester);
      final path = record(container, 'comp03').coverImagePath!;

      // (3) 커밋 **후** 같은 옷 상세 재방문.
      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      await drain(tester);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '재방문 시 빌드 중 setState 예외가 없어야 함');
      final card = find.byType(CompositionPreviewCard);
      expect(card, findsOneWidget);
      expectRendersFile(tester, card, path);
    });
  });
}
