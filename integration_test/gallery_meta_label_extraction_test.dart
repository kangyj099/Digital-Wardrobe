import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/gallery_meta_label.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// UI/Screen×Implementation 리팩터(`GalleryMetaLabel` 4곳 추출) Tester 검증 — 특히
/// `TrashGalleryTile`. Worker 보고에 따르면 이 리팩터 과정에서 `TrashGalleryTile`이
/// 리팩터 이전엔 다른 3개 타일과 달리 `LayoutBuilder`/`ConstrainedBox(maxWidth: ...)` 없이
/// "N일" 라벨을 그렸다(폭 제약이 아예 없었음) — `GalleryMetaLabel`로 통일되며 처음으로
/// 타일 폭 기준 ellipsis 제약이 생겼다. `closet_main_screen_test.dart`가 `SelectableGalleryTile`
/// 라벨의 동일한 제약(짧은/긴 라벨, 좁은 타일)을 이미 광범위하게 검증했으므로, 이 파일은
/// 그와 동일한 시나리오를 이번에 구조가 바뀐 `TrashGalleryTile`에 한정해 다룬다(다른 3개
/// 타일은 리팩터 이전에도 이미 같은 구조였으므로 재검증하지 않음, 과설계 방지).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpIsolatedTrashTile(
    WidgetTester tester, {
    required int remainingDays,
    required double tileSize,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: TrashGalleryTile(
                imagePath: '',
                category: AppCategory.closet,
                daysUntilPurge: remainingDays,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'TrashGalleryTile이 GalleryMetaLabel로 라벨을 그리고, 넉넉한 타일(300px)에서는 '
    '텍스트 크기만큼만 좁게 표시되어 타일 전체 폭을 채우지 않는다',
    (tester) async {
      await pumpIsolatedTrashTile(tester, remainingDays: 12, tileSize: 300);

      expect(tester.takeException(), isNull);
      expect(find.byType(GalleryMetaLabel), findsOneWidget);
      expect(find.text('12일'), findsOneWidget);

      final labelBoxFinder = find.descendant(
        of: find.byType(TrashGalleryTile),
        matching: find.byType(ConstrainedBox),
      );
      expect(labelBoxFinder, findsOneWidget);
      final labelWidth = tester.getRect(labelBoxFinder).width;
      expect(
        labelWidth,
        lessThan(100),
        reason: '라벨박스가 타일 폭(300)을 채우지 않고 텍스트 크기에 맞춰 좁게 표시되어야 한다. 실측 폭=$labelWidth',
      );
    },
  );

  testWidgets(
    '[회귀 고정] 매우 긴 remainingDays 라벨("9999일")을 가진 TrashGalleryTile이 좁은 타일(40px)에서도 '
    '크래시 없이 렌더링되고, 라벨박스가 타일 경계를 넘지 않는다 — 리팩터 이전엔 이 타일만 '
    'ConstrainedBox/maxWidth 제약이 없어 라벨이 타일 경계를 넘어 그려질 수 있었다',
    (tester) async {
      // 1) 넉넉한 타일에서 이 라벨의 자연 폭을 먼저 측정.
      await pumpIsolatedTrashTile(tester, remainingDays: 9999, tileSize: 500);
      final labelBoxFinder = find.descendant(
        of: find.byType(TrashGalleryTile),
        matching: find.byType(ConstrainedBox),
      );
      final naturalWidth = tester.getRect(labelBoxFinder).width;

      // 2) 같은 라벨을 좁은 타일(40px)에 다시 그린다.
      await pumpIsolatedTrashTile(tester, remainingDays: 9999, tileSize: 40);

      expect(tester.takeException(), isNull);
      expect(find.text('9999일'), findsOneWidget);

      final tileRect = tester.getRect(find.byType(TrashGalleryTile));
      expect(labelBoxFinder, findsOneWidget);
      final labelRect = tester.getRect(labelBoxFinder);

      // 자연 폭이 좁은 타일의 여유 폭보다 커야, 실제로 이 테스트가 "잘림"을 검증하는 게 된다.
      expect(
        naturalWidth,
        greaterThan(tileRect.width),
        reason: '이 라벨의 자연 폭($naturalWidth)이 좁은 타일 폭(${tileRect.width})보다 커야 '
            'ellipsis 잘림이 실제로 검증된다.',
      );

      expect(
        labelRect.right,
        lessThanOrEqualTo(tileRect.right + 0.5),
        reason: '라벨박스 우측 끝이 타일 경계를 넘으면 안 된다. tileRect=$tileRect labelRect=$labelRect',
      );
      expect(
        labelRect.left,
        greaterThanOrEqualTo(tileRect.left - 0.5),
        reason: '라벨박스 좌측 끝이 타일 경계 밖으로 나가면 안 된다. tileRect=$tileRect labelRect=$labelRect',
      );
    },
  );

  testWidgets(
    '[갱신, Task 7 재검증] 실제 앱(/trash)에서 좁은 실제 모바일 폭(360px)에서도 TrashGalleryTile '
    '3개가(mock 삭제 항목이 실제로는 c07/c08/comp02 3개뿐임) 오버플로 렌더 에러 없이 렌더링되고 '
    '라벨이 각 타일 경계 안에 들어맞는다. 옛 "mock t3=27일" 전제는 이제 존재하지 않는 mock — '
    '`daysUntilPurge`가 보존 기간 15일로 clamp되어(`lib/providers/trash_providers.dart`) 어떤 '
    '항목도 15일을 넘는 라벨을 표시할 수 없고, c07(3일 전 삭제 → 12일)이 그 자리를 이어받는다.',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TrashMainScreen), findsOneWidget);
      expect(find.byType(TrashGalleryTile), findsNWidgets(3));
      // c07은 3일 전 소프트삭제됨(`mock_data.dart`) → daysUntilPurge = 15 - 3 = 12.
      expect(find.text('12일'), findsOneWidget);

      for (final tileFinder in tester.widgetList(find.byType(TrashGalleryTile))) {
        final key = (tileFinder as TrashGalleryTile).key;
        final tileRect = tester.getRect(find.byKey(key!));
        final labelBoxFinder = find.descendant(
          of: find.byKey(key),
          matching: find.byType(ConstrainedBox),
        );
        expect(labelBoxFinder, findsOneWidget);
        final labelRect = tester.getRect(labelBoxFinder);
        expect(labelRect.right, lessThanOrEqualTo(tileRect.right + 0.5));
        expect(labelRect.left, greaterThanOrEqualTo(tileRect.left - 0.5));
      }
    },
  );
}
