import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/widgets/app_scroll_container.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// Task(Step② Component Library 8종) Tester 검증 — Review 통과 후 실제 앱 구동 확인.
/// `closet_main_screen_test.dart`(28개, 기존 회귀축)가 이미 커버하는 계절/밀도/FAB/개별
/// 카테고리 이동 시나리오는 중복 작성하지 않고, 이번 라운드(FrostedBackButton/
/// CategoryToggleDropdown/FadingScrollEdge/AppGalleryGrid+GroupedGalleryGrid 분리)가
/// 실제 앱 실행에서 아직 검증되지 않았던 항목만 추가한다:
/// 1) 옷장 메인에서 자기 자신(옷장)을 재선택하면 실제 무동작인지(자기 자신 재선택 무시)가
///    real app router 컨텍스트에서도 유지되는지.
/// 2) 코디로 이동한 뒤 실제로 옷장으로 되돌아올 UI 경로가 현재 존재하는지 실측 확인.
///    작성 당시(Step② 시점)에는 `CompositionMainScreen`이 Step① skeleton이라
///    `CategoryToggleDropdown` 자체가 없어 '경로 없음'이 사실이었지만, Step③(코디/
///    스타일일지 메인 `AppMainScaffold` 마이그레이션)로 실제 배선되어 이 전제가 바뀌었다 —
///    아래 테스트를 그 최신 동작(경로가 실제로 있음)으로 갱신한다. 이 화면 쌍에 대한
///    나머지 상세 시나리오(계절/밀도/FAB/그리드 탭 등)는
///    `composition_style_log_main_screen_test.dart`가 담당한다.
/// 3) 그리드 아이템 탭으로 진입한 실제 옷 상세 화면(`ClosetItemDetailScreen`)에
///    FrostedBackButton이 실제로 나타나는지 실측 확인 — Step④(Detail 3화면
///    `AppMainScaffold` 마이그레이션) 완료 후 갱신된 동작을 코드 추측이 아니라 실제
///    위젯 트리로 확인.
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
      find.byType(CategoryToggleDropdown);

  testWidgets(
    '[갱신됨, 2026-07-20 최종] 옷장 메인(자기 자신의 메인 화면)에서 카테고리 드롭다운으로 '
    '옷장을 재선택하면 네비게이션이 전혀 일어나지 않고(뒤로가기 스택 그대로) 분류 캡슐의 '
    '중분류/소분류 선택만 초기화된다 — 이전엔 GoRouter.refresh()로 새로고침하는 방식이었으나 '
    '사용자가 "메인에서는 스택 유지 + 상태 초기화, 메인이 아닌 화면에서는 메인으로 이동"으로 '
    '동작을 더 구체화해 최종 확정',
    (tester) async {
      final container = await pumpApp(tester);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      // [갱신, Task 7 재검증] 10개(c07/c08는 이미 소프트삭제되어 휴지통으로 이동됨).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(10));

      // 중분류를 "옷 종류"로 바꾸고 "하의"로 드릴인해서, 재선택으로 초기화될 상태를 만든다.
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷 종류').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('하의')));
      await tester.pumpAndSettle();
      expect(container.read(closetSortCriterionProvider), ClosetSortCriterion.clothingType);
      // [갱신, Task 7 재검증] 3개(c07도 bottom이었으나 이미 소프트삭제됨).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(3));

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷장').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(container.read(closetSortCriterionProvider), ClosetSortCriterion.all);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(10));
      // 네비게이션 자체가 안 일어나므로 뒤로가기 스택도 당연히 안 쌓인다.
      expect(find.byTooltip('뒤로가기'), findsNothing);
    },
  );

  testWidgets(
    '[신규, 2026-07-20] 옷 상세 화면(메인이 아님)에서 헤더 드롭다운으로 "옷장"(현재와 같은 '
    '카테고리)을 재선택하면, 메인이 아닌 화면에서의 재선택이라 실제로 옷장 메인으로 '
    '이동하고 뒤로가기 스택이 리셋된다(다른 카테고리를 골랐을 때와 동일 동작)',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(SelectableGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.byTooltip('뒤로가기'), findsOneWidget); // push로 스택에 쌓인 상태

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷장').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
      // go()가 스택을 리셋했으니 더 이상 뒤로 갈 곳이 없어야 한다.
      expect(find.byTooltip('뒤로가기'), findsNothing);
    },
  );

  testWidgets(
    '[갱신됨, Step③ 재검증] 코디로 이동한 뒤 실제로 옷장으로 되돌아올 UI 경로가 이제 존재한다 '
    '(CompositionMainScreen이 AppMainScaffold로 마이그레이션되며 CategoryToggleDropdown이 '
    '실제 배선됨 — 과거 "발견 사항"이었던 부재 상태는 해소됨)',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('코디').last);
      await tester.pumpAndSettle();

      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);

      await tester.tap(categoryDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('옷장').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      // [갱신, Task 7 재검증] 10개(c07/c08는 이미 소프트삭제되어 휴지통으로 이동됨).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(10));
    },
  );

  testWidgets(
    '[갱신됨, Task 6 재검증] 그리드 아이템 탭으로 진입한 실제 옷 상세 화면에서는 FrostedBackButton이 '
    '실제로 나타난다(ClosetItemDetailScreen이 Step④에서 AppMainScaffold로 마이그레이션되어 '
    'canPop()이 true인 이 상황에서 뒤로가기가 렌더링됨 — 실측 확인). ClosetItemDetailScreen이 Task '
    '6에서 실제 데이터 바인딩으로 교체되어 raw id를 그대로 echo하던 과거 skeleton 동작은 더 이상 '
    '유효하지 않아, 실제 렌더링된 옷 이름 확인으로 갱신한다.',
    (tester) async {
      await pumpApp(tester);

      final firstTile = find.byType(SelectableGalleryTile).first;
      final ClothingItem tappedItem =
          tester.widget<SelectableGalleryTile>(firstTile).item;
      await tester.tap(firstTile);
      await tester.pumpAndSettle();

      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text(tappedItem.name), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsOneWidget);
      expect(find.byTooltip('뒤로가기'), findsOneWidget);
    },
  );

  testWidgets(
    '옷장 메인 실제 렌더 트리에서 AppScrollContainer가 그리드를 감싸고 있다(구조적 확인 — '
    'ShaderMask 기반 FadingScrollEdge는 폐기되고 스크롤 위치 기반 Overlay 컨테이너로 교체됨)',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(AppScrollContainer), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppScrollContainer), matching: find.byType(GridView)),
        findsOneWidget,
      );
    },
  );
}
