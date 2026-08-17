import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_grid.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/grouped_gallery_grid.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_grid.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Group B "다중선택 시각 지원(타일 4종 + 그리드 어댑터 3종)" Task Tester 검증.
///
/// 이번 Task는 아직 어떤 화면도 `multiSelectMode: true`를 실제로 켜지 않는 순수 배선
/// 단계라 실제 앱 UI로는 "롱프레스 → 모드 진입" 흐름 자체를 탈 수 없다. 대신:
/// 1) Worker의 unit test(`test/widgets/selectable_gallery_tile_test.dart`)가 이미 다룬
///    `SelectableGalleryTile`은 여기서 반복하지 않고, 나머지 3개 타일
///    (`CompositionGalleryTile`/`StyleLogGalleryTile`/`TrashGalleryTile`)이 실제 위젯
///    트리에서 동일하게 동작하는지 직접 pump해 확인한다.
/// 2) 그리드 어댑터 3종이 `multiSelectMode`/`selectedIds`/`onItemLongPress`를 각 타일에
///    정확히 항목별로 매핑해 전달하는지(체크서클 개수, 선택된 항목만 채워짐, 롱프레스 시
///    올바른 항목 식별)를 그리드 레벨에서 확인한다 — 타일 단위 테스트만으론 그리드의
///    "리스트 항목 → 타일 콜백/selected" 매핑 로직 자체는 검증되지 않기 때문이다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 1) 타일 3종 직접 pump ──────────────────────────────────────────────────

  group('CompositionGalleryTile', () {
    final composition = Composition(
      id: 'comp-t1',
      name: '테스트 코디',
      items: const [],
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('multiSelectMode=false면 selected=true여도 체크서클이 안 보인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CompositionGalleryTile(composition: composition, onTap: () {}, selected: true),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsNothing);
    });

    testWidgets('multiSelectMode=true, selected=true면 체크서클이 보이고 롱프레스가 onLongPress를 호출한다', (
      tester,
    ) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CompositionGalleryTile(
            composition: composition,
            onTap: () {},
            multiSelectMode: true,
            selected: true,
            onLongPress: () => longPressed = true,
          ),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.longPress(find.byType(CompositionGalleryTile));
      expect(longPressed, isTrue);
    });
  });

  group('StyleLogGalleryTile', () {
    final styleLog = StyleLog(id: 'log-t1', coverImagePath: '', createdAt: DateTime(2026, 1, 1), wornDate: DateTime(2026, 1, 1));

    testWidgets('multiSelectMode=false면 selected=true여도 체크서클이 안 보인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StyleLogGalleryTile(styleLog: styleLog, onTap: () {}, selected: true),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsNothing);
    });

    testWidgets('multiSelectMode=true, selected=true면 체크서클이 보이고 롱프레스가 onLongPress를 호출한다', (
      tester,
    ) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StyleLogGalleryTile(
            styleLog: styleLog,
            onTap: () {},
            multiSelectMode: true,
            selected: true,
            onLongPress: () => longPressed = true,
          ),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.longPress(find.byType(StyleLogGalleryTile));
      expect(longPressed, isTrue);
    });
  });

  group('TrashGalleryTile', () {
    testWidgets('multiSelectMode=false면 selected=true여도 체크서클이 안 보인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TrashGalleryTile(
            imagePath: '',
            category: AppCategory.closet,
            daysUntilPurge: 5,
            onTap: () {},
            selected: true,
          ),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsNothing);
    });

    testWidgets('multiSelectMode=true, selected=true면 체크서클이 보이고 롱프레스가 onLongPress를 호출한다', (
      tester,
    ) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TrashGalleryTile(
            imagePath: '',
            category: AppCategory.closet,
            daysUntilPurge: 5,
            onTap: () {},
            multiSelectMode: true,
            selected: true,
            onLongPress: () => longPressed = true,
          ),
        ),
      );
      expect(find.byType(MultiSelectCheckmark), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.longPress(find.byType(TrashGalleryTile));
      expect(longPressed, isTrue);
    });
  });

  // ── 2) 그리드 어댑터 3종 — 항목별 매핑 확인 ───────────────────────────────────

  group('GroupedGalleryGrid 어댑터 매핑', () {
    final items = [
      ClothingItem(id: 'gi1', name: '아이템1', imagePath: '', createdAt: DateTime(2026, 1, 1)),
      ClothingItem(id: 'gi2', name: '아이템2', imagePath: '', createdAt: DateTime(2026, 1, 1)),
      ClothingItem(id: 'gi3', name: '아이템3', imagePath: '', createdAt: DateTime(2026, 1, 1)),
    ];

    testWidgets(
      'multiSelectMode=true면 항목 수만큼 체크서클이 뜨고, selectedIds에 포함된 항목만 채워진 '
      '체크(선택됨)로 렌더링되며, 특정 타일 롱프레스 시 그 항목 자신이 콜백으로 전달된다',
      (tester) async {
        ClothingItem? longPressedItem;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: GroupedGalleryGrid(
                items: items,
                density: 3,
                onItemTap: (_) {},
                multiSelectMode: true,
                selectedIds: const {'gi2'},
                onItemLongPress: (item) => longPressedItem = item,
              ),
            ),
          ),
        );

        expect(find.byType(MultiSelectCheckmark), findsNWidgets(3));
        // selectedIds에 딱 하나만 있으니 채워진 체크 아이콘도 하나여야 한다.
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.longPress(find.byKey(const ValueKey('gi3')));
        expect(longPressedItem?.id, 'gi3');
      },
    );

    testWidgets('multiSelectMode=false(기본값)면 selectedIds가 채워져 있어도 체크서클이 전혀 안 보인다', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: GroupedGalleryGrid(
              items: items,
              density: 3,
              onItemTap: (_) {},
              selectedIds: const {'gi1', 'gi2'},
            ),
          ),
        ),
      );

      expect(find.byType(MultiSelectCheckmark), findsNothing);
    });
  });

  group('CompositionGalleryGrid 어댑터 매핑', () {
    final compositions = [
      Composition(id: 'ci1', name: '코디1', items: const [], createdAt: DateTime(2026, 1, 1)),
      Composition(id: 'ci2', name: '코디2', items: const [], createdAt: DateTime(2026, 1, 1)),
    ];

    testWidgets(
      'multiSelectMode=true면 항목 수만큼 체크서클이 뜨고, selectedIds 매칭 항목만 채워지며, '
      '롱프레스 시 올바른 composition이 콜백으로 전달된다',
      (tester) async {
        Composition? longPressedComposition;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: CompositionGalleryGrid(
                compositions: compositions,
                density: 2,
                onItemTap: (_) {},
                multiSelectMode: true,
                selectedIds: const {'ci1'},
                onItemLongPress: (c) => longPressedComposition = c,
              ),
            ),
          ),
        );

        expect(find.byType(MultiSelectCheckmark), findsNWidgets(2));
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.longPress(find.byKey(const ValueKey('ci2')));
        expect(longPressedComposition?.id, 'ci2');
      },
    );
  });

  group('StyleLogGalleryGrid 어댑터 매핑', () {
    final logs = [
      StyleLog(id: 'sl1', coverImagePath: '', createdAt: DateTime(2026, 1, 1), wornDate: DateTime(2026, 1, 1)),
      StyleLog(id: 'sl2', coverImagePath: '', createdAt: DateTime(2026, 1, 2), wornDate: DateTime(2026, 1, 2)),
    ];

    testWidgets(
      'multiSelectMode=true면 항목 수만큼 체크서클이 뜨고, selectedIds 매칭 항목만 채워지며, '
      '롱프레스 시 올바른 styleLog가 콜백으로 전달된다',
      (tester) async {
        StyleLog? longPressedLog;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: StyleLogGalleryGrid(
                logs: logs,
                onItemTap: (_) {},
                multiSelectMode: true,
                selectedIds: const {'sl2'},
                onItemLongPress: (l) => longPressedLog = l,
              ),
            ),
          ),
        );

        expect(find.byType(MultiSelectCheckmark), findsNWidgets(2));
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.longPress(find.byKey(const ValueKey('sl1')));
        expect(longPressedLog?.id, 'sl1');
      },
    );
  });
}
