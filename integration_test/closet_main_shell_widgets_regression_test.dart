import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/fading_scroll_edge.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// Task(Step② Component Library 8종) Tester 검증 — Review 통과 후 실제 앱 구동 확인.
/// `closet_main_screen_test.dart`(28개, 기존 회귀축)가 이미 커버하는 계절/밀도/FAB/개별
/// 카테고리 이동 시나리오는 중복 작성하지 않고, 이번 라운드(FrostedBackButton/
/// CategoryToggleDropdown/FadingScrollEdge/AppGalleryGrid+GroupedGalleryGrid 분리)가
/// 실제 앱 실행에서 아직 검증되지 않았던 항목만 추가한다:
/// 1) 옷장 메인에서 자기 자신(옷장)을 재선택하면 실제 무동작인지(자기 자신 재선택 무시)가
///    real app router 컨텍스트에서도 유지되는지.
/// 2) 코디로 이동한 뒤 실제로 옷장으로 되돌아올 UI 경로가 현재 존재하는지 실측 확인
///    (`CompositionMainScreen`이 아직 Step① skeleton이라 `CategoryToggleDropdown`
///    자체가 없다 — 코드 추측이 아니라 실제 위젯 트리로 확인. 발견 사항, Worker 스코프
///    밖의 기존 상태).
/// 3) 그리드 아이템 탭으로 진입한 실제 옷 상세 화면(`ClosetItemDetailScreen`)에
///    FrostedBackButton이 (아직) 존재하는지 실측 확인 — Step④ 미착수 상태를 코드
///    추측이 아니라 실제 위젯 트리로 확인.
/// 4) FadingScrollEdge가 실제 옷장 메인 렌더 트리에서 그리드를 감싸고 있는지 구조적 확인.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
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

  Finder categoryDropdownFinder() =>
      find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>);

  testWidgets(
    '옷장 메인에서 카테고리 드롭다운으로 옷장 자신을 재선택하면 실제로 아무 화면 전환도 일어나지 않는다',
    (tester) async {
      await pumpApp(tester);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷장').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    },
  );

  testWidgets(
    '[발견 사항] 코디로 이동한 뒤에는 실제로 옷장으로 되돌아올 UI 경로가 현재 없다 '
    '(CompositionMainScreen이 아직 Step① skeleton이라 CategoryToggleDropdown 자체가 없음 — 실측 확인, Worker 스코프 밖의 기존 상태)',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('코디').last);
      await tester.pumpAndSettle();

      expect(find.byType(CompositionMainScreen), findsOneWidget);
      // 코디 메인엔 아직 CategoryToggleDropdown이 배선되지 않아 옷장으로 돌아갈 UI가 없다.
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(categoryDropdownFinder(), findsNothing);
    },
  );

  testWidgets(
    '그리드 아이템 탭으로 진입한 실제 옷 상세 화면에서는 FrostedBackButton이 아직 나타나지 않는다 '
    '(ClosetItemDetailScreen이 Step① skeleton 그대로이고 이번 라운드는 옷장 메인에만 배선됨 — 실측 확인)',
    (tester) async {
      await pumpApp(tester);

      final firstTile = find.byType(SelectableGalleryTile).first;
      final ClothingItem tappedItem =
          tester.widget<SelectableGalleryTile>(firstTile).item;
      await tester.tap(firstTile);
      await tester.pumpAndSettle();

      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.textContaining(tappedItem.id), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsNothing);
      expect(find.byTooltip('뒤로가기'), findsNothing);
    },
  );

  testWidgets(
    '옷장 메인 실제 렌더 트리에서 FadingScrollEdge가 그리드를 감싸고 있다(구조적 확인)',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(FadingScrollEdge), findsOneWidget);
      expect(
        find.descendant(of: find.byType(FadingScrollEdge), matching: find.byType(GridView)),
        findsOneWidget,
      );
    },
  );
}
