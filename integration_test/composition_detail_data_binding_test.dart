import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — e015319 "코디 상세 real data 바인딩(사용된 옷 목록 + 스타일일지 크로스
/// 레퍼런스)".
///
/// `detail_screens_header_hud_test.dart`가 이미 다루는 것(진입/HUD/뒤로가기/스크롤/카테고리
/// 이동, comp01의 크로스 레퍼런스 chip 존재 자체)은 다시 만들지 않는다. 이 파일은 그
/// 스위트가 다루지 않는 것만 확인한다:
/// 1) comp01(데일리 룩)의 "사용된 옷" 가로 목록에 실제 4개 아이템(c01/c11/c07/c03) 이름이
///    전부 보이고, 이미지 렌더링이 예외 없이 되며, 항목 탭 시 실제 옷 상세로 이동하는가.
/// 2) comp03(레인 코디, c04/c05 재사용 — comp02와 동일 아이템 구성)에 스타일일지를 런타임
///    주입해 "이미 연결됨" 상태를 재현했을 때도 사용된 옷 2개(c04/c05)가 보이고, 크로스
///    레퍼런스에는 그 연결된 로그 타일만 보이며 "+ 스타일일지 연결하기" 바인딩 타일은
///    나타나지 않는가(연결된 로그가 있으면 바인딩 UI 대신 로그 타일 목록을 보여준다는 분기
///    검증). [갱신, Task 7 이후 comp02 소프트삭제] 원래 이 시나리오는 comp02(log02 직접
///    연결)로 검증했으나 comp02가 코디 메인에서 더 이상 보이지 않아, comp03 + 런타임 주입
///    스타일일지 조합으로 대체(`style_log_gallery_column_count_test.dart`가 이미 쓴 기법).
/// 3) 스타일일지가 전혀 연결되지 않은 코디는 "+" 바인딩 타일이 렌더링되는가(Task 6,
///    `StyleLogCrossReferenceGallery`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapCompositionById(WidgetTester tester, String compositionId) async {
    final tile = find.byWidgetPredicate(
      (w) => w is CompositionGalleryTile && w.composition.id == compositionId,
    );
    expect(tile, findsOneWidget, reason: '코디 $compositionId 타일을 코디 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  group('코디 상세 — 사용된 옷 목록 실제 바인딩(comp01)', () {
    testWidgets(
      'comp01(데일리 룩) 상세 — 사용된 옷 4개(c01/c11/c07/c03) 이름이 모두 보이고 이미지가 '
      '예외 없이 렌더링되며, 항목 탭 시 실제 옷 상세(c11)로 이동한다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp01');

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('데일리 룩'), findsOneWidget);

        // c01은 이름이 크로스 레퍼런스 화면과 겹치지 않으니, "사용된 옷" 목록에서
        // 4개 이름 텍스트가 전부 실제로 보이는지 확인한다.
        expect(find.text('플로럴 원피스'), findsOneWidget); // c01
        expect(find.text('그래픽 맨투맨'), findsOneWidget); // c11
        expect(find.text('리넨 반바지'), findsOneWidget); // c07
        expect(find.text('그래픽 와이드팬츠'), findsOneWidget); // c03

        // 실제 asset 이미지가 예외 없이 렌더링된다(누락 asset이면 여기서 예외가 잡힌다).
        expect(find.byType(Image), findsWidgets);
        expect(tester.takeException(), isNull);

        // c11("그래픽 맨투맨") 항목을 탭하면 실제 옷 상세로 이동해야 한다.
        await tester.tap(find.byKey(const ValueKey('c11')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('그래픽 맨투맨'), findsOneWidget);
        expect(find.byType(CompositionDetailScreen), findsNothing);

        // 뒤로가기 → 코디 상세 상태(이름/사용된 옷 목록)가 그대로 유지되어야 한다.
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('데일리 룩'), findsOneWidget);
        expect(find.text('플로럴 원피스'), findsOneWidget);
      },
    );

    testWidgets('comp01 상세에서 연결된 스타일일지 타일(log01, 2026-01-05)을 탭하면 스타일일지 열람으로 이동한다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);
      final logTile = find.byType(StyleLogGalleryTile);
      expect(logTile, findsOneWidget);
      expect(find.textContaining('2026-01-05'), findsOneWidget);
      // 연결된 로그가 있으니 "+" 바인딩 타일은 보이지 않아야 한다.
      expect(find.text('스타일일지 연결하기'), findsNothing);

      await tester.tap(logTile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      // Task 7(스타일일지 열람 실데이터 바인딩) 완료 — 실제 착용일자 라벨로 검증한다.
      expect(find.textContaining('2026.1.5'), findsOneWidget);
    });
  });

  group('코디 상세 — 사용된 옷 목록 + 크로스 레퍼런스(comp03, 런타임 주입 스타일일지로 "이미 연결됨" 재현)', () {
    testWidgets(
      'comp03(레인 코디, c04/c05 재사용) 상세 — 런타임 주입 스타일일지 1장으로 사용된 옷 2개'
      '(c04/c05)가 보이고, 크로스 레퍼런스에는 그 연결된 로그 타일만 보이며 "+" 바인딩 타일은 '
      '나타나지 않는다',
      (tester) async {
        final container = await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp03');

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('레인 코디'), findsOneWidget);

        expect(find.text('트렌치코트'), findsOneWidget); // c04
        expect(find.text('스트라이프 블라우스'), findsOneWidget); // c05
        expect(find.byType(Image), findsWidgets);
        expect(tester.takeException(), isNull);

        // 원래 log02가 comp02에 직접 연결돼 있었으니, 그 "이미 연결됨" 상태를 comp03에
        // 런타임 주입으로 재현한다(`style_log_gallery_column_count_test.dart` 기법 재사용).
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          StyleLog(
            id: 'test-comp03-log-binding',
            coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
            createdAt: DateTime(2026, 1, 10), wornDate: DateTime(2026, 1, 10),
            linkedCompositionId: 'comp03',
          ),
        ];
        await tester.pumpAndSettle();

        expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);
        final logTile = find.byType(StyleLogGalleryTile);
        expect(logTile, findsOneWidget);
        expect(find.textContaining('2026-01-10'), findsOneWidget);
        expect(find.text('스타일일지 연결하기'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);

        await tester.tap(logTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        // Task 7(스타일일지 열람 실데이터 바인딩) 완료 — 실제 착용일자 라벨로 검증한다.
        expect(find.textContaining('2026.1.10'), findsOneWidget);
      },
    );
  });

  group('코디 상세 — 스타일일지가 전혀 연결되지 않은 코디("+" 바인딩 타일)', () {
    testWidgets(
      'mock 코디는 전부 이미 연결돼 있어(comp01/comp02), 미연결 상태를 검증하려면 코디 목록에 '
      '임시 코디를 하나 추가해 격리한다 — "+" 바인딩 타일 렌더링만 확인(탭 시 실제 이동 여부는 '
      'Task 7의 composition_detail_screen_test.dart 위젯 테스트가 이미 커버 — 중복 검증 지양)',
      (tester) async {
        final container = await pumpApp(tester);
        final unlinkedComposition =
            Composition(id: 'test-unlinked', name: '미연결 코디', items: const [], createdAt: DateTime(2025, 1, 1));
        container.read(compositionsProvider.notifier).state = [
          ...container.read(compositionsProvider),
          unlinkedComposition,
        ];

        final context = tester.element(find.byType(ClosetMainScreen));
        GoRouter.of(context)
            .push(AppRoute.compositionDetail.replaceFirst(':id', 'test-unlinked'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('미연결 코디'), findsOneWidget);
        expect(find.byType(StyleLogCrossReferenceGallery), findsOneWidget);
        expect(find.text('스타일일지 연결하기'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      },
    );
  });
}
