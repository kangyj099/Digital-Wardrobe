// integration_test/composition_snapshot_repeated_commit_cold_asset_test.dart
//
// 한 세션 안에서 코디 편집 완료(✔)를 8번 반복한 뒤, **그 세션에서 아직 한 번도 화면에 안 떴던
// 옷 이미지**(mock c08 = `assets/images/mock/IMG_4276.PNG`, 휴지통에만 보인다)를 처음 그리는
// 화면으로 이동한다. 사용자 동선으로 옮기면 "코디를 여러 번 저장한 뒤 휴지통을 열면 아직 안
// 봤던 옷 썸네일이 깨진다"에 해당한다.
//
// 커밋마다 `captureCompositionSnapshot`이 아이템 이미지를 `precacheImage`로 강제 디코드하고
// 1024×1024 `ui.Image`를 만들었다 버린다 — 반복 커밋이 이미지 캐시/에셋 로딩에 남기는 영향이
// 이후 콜드 디코드를 깨뜨리지 않는지 확인하는 것이 이 파일의 역할이다.
//
// 이력(중요): 이 파일은 2차 Tester가 "`composition_snapshot_runtime_test.dart`를 파일 전체로
// 실행하면 그룹 4/5가 `Unable to load asset ... Asset not found`로 실패하는데 `--plain-name`
// 단독 실행은 통과한다"는 관찰에서 출발해 작성했다. **그 전제는 현재 성립하지 않는다** —
// F1~F5 수정 이후 `composition_snapshot_runtime_test.dart`는 파일 전체 실행에서 14/14 통과한다
// (3차 Tester 재확인). 그래서 이 파일은 원래 쫓던 버그의 재현 스크립트가 아니라, 위에 적은
// "반복 커밋 후 콜드 에셋 디코드" 회귀 가드로만 남긴다.
//
// 실행: `flutter test integration_test/composition_snapshot_repeated_commit_cold_asset_test.dart
// -d windows`
//
// [실행 결과 2026-08-17 / db56ecf] 1/1 통과 — 커밋 8회 모두 새 coverImagePath로 반영, 이후
// 휴지통의 c08 썸네일도 예외 없이 로드.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const screenSize = Size(390, 844);
  const armOffset = Offset(50, 50);

  /// mock c08(슬립 드레스, 소프트 삭제 상태)의 이미지 — 옷장 메인엔 안 뜨고 휴지통에서만
  /// 처음 그려지므로, "그 세션에서 처음 디코드되는 에셋"의 대표로 쓴다.
  const coldAsset = 'assets/images/mock/IMG_4276.PNG';

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

  testWidgets('코디 편집 완료(✔)를 8번 반복한 뒤 휴지통을 열어도 아직 안 봤던 옷 썸네일이 정상 로드된다',
      (tester) async {
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

    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디').last);
    await tester.pumpAndSettle();

    await tester.tap(tileFinder('comp03'));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);

    for (var round = 1; round <= 8; round++) {
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('static-artboard-item-c04'))),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      await press.up();
      await tester.pumpAndSettle();
      expect(find.byType(CompositionEditorScreen), findsOneWidget,
          reason: '$round번째 편집 진입');

      final drag = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('c04:visual'))));
      await drag.moveBy(armOffset);
      await tester.pump();
      await drag.moveBy(Offset(round.isEven ? 12 : -12, round.isEven ? -10 : 10));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      final before = record(container, 'comp03').coverImagePath;
      await tester.tap(find.byTooltip('완료'));
      await tester.pumpAndSettle();
      final committed =
          await waitUntil(tester, () => record(container, 'comp03').coverImagePath != before);
      expect(committed, isTrue, reason: '$round번째 커밋이 반영돼야 함');
      await waitUntil(tester, () => find.byType(CompositionEditorScreen).evaluate().isEmpty);
      await drain(tester);
      debugPrint('[Tester] 커밋 $round회 완료 — coverImagePath='
          '${record(container, 'comp03').coverImagePath}');
    }

    // 여기까지 예외가 없어야 커밋 자체는 정상이라는 뜻.
    expect(tester.takeException(), isNull, reason: '반복 커밋 자체로 예외가 나면 안 됨');

    // 이 세션에서 처음으로 c08($coldAsset)을 그리는 화면 = 휴지통.
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();
    await drain(tester, frames: 40);
    expect(find.byType(TrashMainScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('c08')), findsOneWidget,
        reason: 'mock c08은 휴지통에 있어야 함');

    expect(tester.takeException(), isNull,
        reason: '반복 커밋 뒤에 처음 디코드되는 에셋($coldAsset)도 정상 로드돼야 함');
  });
}
