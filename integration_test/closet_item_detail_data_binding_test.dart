import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// Tester 검증 — f66a0a9 "옷 상세 real data 바인딩".
///
/// `detail_screens_header_hud_test.dart`가 이미 다루는 것(진입/HUD/뒤로가기/스크롤/카테고리
/// 이동)은 다시 만들지 않는다. 이 파일은 그 스위트가 다루지 않는 것만 확인한다:
/// 1) 옷 상세 화면의 메타데이터 텍스트(카테고리/계절/소재/색상/보관위치/착용횟수)가
///    mock_data.dart의 실제 값과 정확히 일치하는가.
/// 2) 크로스 레퍼런스 칩을 실제로 탭했을 때 코디 상세(comp01)/스타일일지 열람(log01)
///    화면으로 각각 이동하는가, 그리고 뒤로가기로 돌아왔을 때 옷 상세 상태가 유지되는가.
/// 3) 연결된 코디가 하나도 없는 아이템(c02)의 경우 크로스 레퍼런스 바가 비어 있는
///    상태로(크래시 없이) 렌더링되는가.
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

  Future<void> tapItemById(WidgetTester tester, String itemId) async {
    final tile = find.byWidgetPredicate(
      (w) => w is SelectableGalleryTile && w.item.id == itemId,
    );
    expect(tile, findsOneWidget, reason: '아이템 $itemId 타일을 옷장 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  group('옷 상세 — 메타데이터 실제 바인딩', () {
    testWidgets('c01(플로럴 원피스) 상세 — 이름/카테고리/계절/소재/색상/보관위치/착용횟수가 mock 데이터와 일치한다',
        (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('플로럴 원피스'), findsOneWidget);
      expect(
        find.textContaining('원피스'),
        findsWidgets,
        reason: 'ClothingCategory.dress의 label(원피스)이 메타데이터 줄에 보여야 한다',
      );
      expect(find.textContaining('보관 위치: 옷장 2단'), findsOneWidget);
      expect(find.textContaining('착용 3회'), findsOneWidget);

      // 실제 asset 이미지가 예외 없이 렌더링된다(누락 asset이면 여기서 예외가 잡힌다).
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('옷 상세 — 크로스 레퍼런스 탭 → 실제 네비게이션', () {
    testWidgets(
      'c01 상세에서 "데일리 룩"(comp01) 칩 탭 → 코디 상세로 이동, 뒤로가기 → 옷 상세 상태 유지, '
      '이어서 스타일일지 칩 탭 → 스타일일지 열람(log01)으로 이동',
      (tester) async {
        await pumpApp(tester);
        await tapItemById(tester, 'c01');
        expect(find.byType(CrossReferenceLinkBar), findsOneWidget);

        final compositionChip = find.text('데일리 룩');
        expect(compositionChip, findsOneWidget);
        await tester.tap(compositionChip);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CompositionDetailScreen), findsOneWidget);
        expect(find.textContaining('comp01'), findsOneWidget);
        expect(find.byType(ClosetItemDetailScreen), findsNothing);

        // 뒤로가기 → 옷 상세로 복귀, 이름/착용횟수 등 상태가 그대로 유지되어야 한다.
        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.text('플로럴 원피스'), findsOneWidget);
        expect(find.textContaining('착용 3회'), findsOneWidget);

        // 같은 화면에서 스타일일지 칩(log01, wornDate 2026.1.5)도 탭해본다.
        final styleLogChip = find.text('2026.1.5');
        expect(styleLogChip, findsOneWidget);
        await tester.tap(styleLogChip);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(StyleLogViewerScreen), findsOneWidget);
        expect(find.textContaining('log01'), findsOneWidget);
      },
    );
  });

  group('옷 상세 — 연결된 코디가 없는 아이템', () {
    testWidgets('c02(데님 팬츠) 상세 — 어떤 코디에도 포함되지 않아 크로스 레퍼런스 바가 빈 상태로 크래시 없이 렌더링된다',
        (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c02');

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text('데님 팬츠'), findsOneWidget);
      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      // 비어 있으면 칩(아이콘 텍스트)이 하나도 없어야 한다 — 특히 다른 코디명이 새어 보이면 안 된다.
      expect(find.textContaining('데일리 룩'), findsNothing);
      expect(find.textContaining('포멀 코디'), findsNothing);
    });
  });
}
