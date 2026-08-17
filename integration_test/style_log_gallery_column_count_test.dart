import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_cross_reference_gallery.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 검증 — Task 13("연결된 스타일일지" 갤러리, 기본 2열·1장이면 1열, commit
/// `4a2dbdd`)의 런타임 동작.
///
/// `detail_cross_reference_visuals_test.dart`/`detail_thumbnail_square_unification_test.dart`
/// /`composition_detail_addtile_square_test.dart`가 이미 확인한 것(타일이 정사각(1:1)
/// 비율이라는 것, 2개 연결 시 2열이 된다는 것, "+" 타일이 정사각이라는 것, 빈 상태가
/// 실제 0 높이/섹션 숨김이라는 것)은 다시 만들지 않는다. 이 파일은 그 스위트들이 확인하지
/// 않은, Task 13이 실제로 바꾼 것만 확인한다:
/// 1) 연결된 스타일일지가 정확히 1장일 때, 타일이 (기존처럼 2열 그리드의 절반 폭이 아니라)
///    컨테이너 폭 전체를 차지하는 실제 1열로 렌더링되는가 — 코디 상세(comp01, comp03)와
///    옷 상세(c01) 양쪽에서 실측. [갱신, Task 7] comp02가 소프트삭제되어 comp03(런타임
///    주입 로그 1장)으로 교체됨 — 아래 두 번째 테스트 참고.
/// 2) 1열이어도 타일이 여전히 정사각(1:1)인가(가로로 늘어난 2:1 와이드가 아닌가).
/// 3) 2장 이상 연결되면 실제로 2열(같은 행에 나란히 배치)로 되돌아가는가 — 임시 데이터로
///    구성해, 두 타일의 y좌표가 같고 x좌표가 서로 다른 값(같은 행 다른 열)임을 실측.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 844);
  const contentWidth = 390.0 - 2 * 16.0; // AppSpacing.md 패딩 양쪽 제외

  Future<ProviderContainer> pumpApp(WidgetTester tester, {Size size = defaultSize}) async {
    tester.view.physicalSize = size;
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
    final tile = find.byWidgetPredicate((w) => w is SelectableGalleryTile && w.item.id == itemId);
    expect(tile, findsOneWidget, reason: '아이템 $itemId 타일을 옷장 메인에서 찾을 수 없다');
    await tester.tap(tile);
    await tester.pumpAndSettle();
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

  group('스타일일지 1장 연결 — 실제 1열(타일 폭이 컨테이너 전체)로 렌더링되는가', () {
    testWidgets('코디 상세(comp01, log01 1장)의 타일이 컨테이너 폭 전체를 차지한다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tapCompositionById(tester, 'comp01');

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);

      expect(
        size.width,
        closeTo(contentWidth, 1.0),
        reason: '1장이면 crossAxisCount:1이라 타일 폭이 2열의 절반이 아니라 컨테이너 폭 전체여야 한다',
      );
      expect(
        size.width / size.height,
        closeTo(1, 0.02),
        reason: '폭이 넓어졌어도 childAspectRatio:1이라 정사각이어야 한다(2:1 와이드가 아님)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '[갱신, Task 7 재검증] 코디 상세(comp03, 런타임 주입 스타일일지 1장)의 타일도 '
      '컨테이너 폭 전체를 차지한다 — 원래 이 시나리오는 comp02(log02 1장 직접 연결)로 '
      '검증했으나, comp02가 이후 소프트삭제(`mock_data.dart`)되어 코디 메인 정상 흐름으로는 '
      '더 이상 도달할 수 없다. `mock_data.dart` 주석은 comp03이 comp02의 "season 미지정 + '
      'weather:rain" 분류 데모 역할만 이어받는다고 명시할 뿐, comp03에 연결된 mock '
      '스타일일지는 실제로 없다(log01→comp01, log02→comp02뿐, `mockStyleLogs` 확인) — 그래서 '
      '단순 ID 치환이 아니라, 아래 2열 회귀 테스트(comp01에 임시 로그 주입)와 동일한 기법으로 '
      '이 테스트 안에서 comp03에 스타일일지 1장을 직접 주입해 "1장 연결" 전제를 만든다.',
      (tester) async {
        final container = await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp03');

        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          StyleLog(
            id: 'test-comp03-log',
            coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
            createdAt: DateTime(2026, 3, 5), wornDate: DateTime(2026, 3, 5),
            linkedCompositionId: 'comp03',
          ),
        ];
        await tester.pumpAndSettle();

        final tileFinder = find.byType(StyleLogGalleryTile);
        expect(tileFinder, findsOneWidget);
        final size = tester.getSize(tileFinder);

        expect(size.width, closeTo(contentWidth, 1.0));
        expect(size.width / size.height, closeTo(1, 0.02));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('옷 상세(c01, log01 1장 간접 연결)의 타일도 컨테이너 폭 전체를 차지한다', (tester) async {
      await pumpApp(tester);
      await tapItemById(tester, 'c01');
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      final tileFinder = find.byType(StyleLogGalleryTile);
      expect(tileFinder, findsOneWidget);
      final size = tester.getSize(tileFinder);

      expect(
        size.width,
        closeTo(contentWidth, 1.0),
        reason: '옷 상세도 같은 위젯(StyleLogCrossReferenceGallery)을 공유하므로 1장이면 동일하게 1열이어야 한다',
      );
      expect(size.width / size.height, closeTo(1, 0.02));
      expect(tester.takeException(), isNull);
    });
  });

  group('스타일일지 2장 이상 연결 — 여전히 2열(같은 행에 나란히)로 되돌아가는가', () {
    testWidgets(
      'mock엔 comp01에 log01 1장뿐이라, 임시 스타일일지를 하나 더 comp01에 연결해 2장으로 만들면 '
      '두 타일이 같은 행(y좌표 동일)에 서로 다른 x좌표로 나란히 배치된다(2열)',
      (tester) async {
        final container = await pumpApp(tester);
        await goToCategory(tester, '코디');
        await tapCompositionById(tester, 'comp01');
        expect(find.byType(CompositionDetailScreen), findsOneWidget);

        // 1장일 때는 1열 — 사전 확인.
        expect(find.byType(StyleLogGalleryTile), findsOneWidget);
        final singleSize = tester.getSize(find.byType(StyleLogGalleryTile));
        expect(singleSize.width, closeTo(contentWidth, 1.0));

        final extraLog = StyleLog(
          id: 'test-extra-log-t13',
          coverImagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png',
          createdAt: DateTime(2026, 3, 1), wornDate: DateTime(2026, 3, 1),
          linkedCompositionId: 'comp01',
        );
        container.read(styleLogsProvider.notifier).state = [
          ...container.read(styleLogsProvider),
          extraLog,
        ];
        await tester.pumpAndSettle();

        final tiles = find.byType(StyleLogGalleryTile);
        expect(tiles, findsNWidgets(2), reason: '2장으로 늘어났으니 타일도 2개여야 한다');

        final rects = tiles.evaluate().map((e) {
          final size = tester.getSize(find.byWidget(e.widget));
          final topLeft = tester.getTopLeft(find.byWidget(e.widget));
          return (topLeft: topLeft, size: size);
        }).toList();

        expect(
          rects[0].topLeft.dy,
          closeTo(rects[1].topLeft.dy, 1.0),
          reason: '2열이면 두 타일이 같은 행에 있어야 하므로 y좌표가 같아야 한다',
        );
        expect(
          rects[0].topLeft.dx,
          isNot(closeTo(rects[1].topLeft.dx, 1.0)),
          reason: '2열이면 두 타일의 x좌표는 서로 달라야 한다(같은 행 다른 열)',
        );

        final expectedColumnWidth = (contentWidth - 8) / 2; // crossAxisSpacing: AppSpacing.xs(8)
        for (final rect in rects) {
          expect(
            rect.size.width,
            closeTo(expectedColumnWidth, 1.0),
            reason: '2열로 되돌아가면 타일 폭이 다시 절반 수준이어야 한다(1열 전체 폭이 아님)',
          );
          expect(rect.size.width / rect.size.height, closeTo(1, 0.02));
        }
        expect(tester.takeException(), isNull);
      },
    );
  });
}
