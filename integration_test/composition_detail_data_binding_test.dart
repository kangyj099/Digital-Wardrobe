import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';

/// Tester 검증 — e015319 "코디 상세 real data 바인딩(사용된 옷 목록 + 스타일일지 크로스
/// 레퍼런스)".
///
/// `detail_screens_header_hud_test.dart`가 이미 다루는 것(진입/HUD/뒤로가기/스크롤/카테고리
/// 이동, comp01의 크로스 레퍼런스 chip 존재 자체)은 다시 만들지 않는다. 이 파일은 그
/// 스위트가 다루지 않는 것만 확인한다:
/// 1) comp01(데일리 룩)의 "사용된 옷" 가로 목록에 실제 4개 아이템(c01/c11/c07/c03) 이름이
///    전부 보이고, 이미지 렌더링이 예외 없이 되며, 항목 탭 시 실제 옷 상세로 이동하는가.
/// 2) comp02(포멀 코디, mock 기준 이미 log02에 연결됨)도 사용된 옷 2개(c04/c05)가 보이고,
///    크로스 레퍼런스에는 이미 연결된 log02(2026.1.10) chip만 보이며 "+ 스타일일지
///    연결하기" 바인딩 엔트리는 나타나지 않는가(연결된 로그가 있으면 바인딩 UI 대신
///    로그 chip 목록을 보여준다는 분기 검증).
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
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>));
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

    testWidgets('comp01 상세에서 연결된 스타일일지(log01, 2026.1.5) chip을 탭하면 스타일일지 열람으로 이동한다',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      final logChip = find.text('2026.1.5');
      expect(logChip, findsOneWidget);
      // 연결된 로그가 있으니 "+" 바인딩 엔트리는 보이지 않아야 한다.
      expect(find.text('스타일일지 연결하기'), findsNothing);

      await tester.tap(logChip);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.textContaining('log01'), findsOneWidget);
    });
  });

  group('코디 상세 — 사용된 옷 목록 + 크로스 레퍼런스(comp02, 이미 log02에 연결됨)', () {
    testWidgets(
      'comp02(포멀 코디) 상세 — 사용된 옷 2개(c04/c05)가 보이고, 크로스 레퍼런스에는 이미 '
      '연결된 log02(2026.1.10) chip만 보이며 "+" 바인딩 엔트리는 나타나지 않는다',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp02');

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.text('포멀 코디'), findsOneWidget);

        expect(find.text('트렌치코트'), findsOneWidget); // c04
        expect(find.text('스트라이프 블라우스'), findsOneWidget); // c05
        expect(find.byType(Image), findsWidgets);
        expect(tester.takeException(), isNull);

        expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
        expect(find.text('2026.1.10'), findsOneWidget); // log02.wornDate
        expect(find.text('스타일일지 연결하기'), findsNothing);
        expect(find.byIcon(Icons.add), findsNothing);

        await tester.tap(find.text('2026.1.10'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.textContaining('log02'), findsOneWidget);
      },
    );
  });
}
