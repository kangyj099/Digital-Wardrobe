import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_add_screen.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// `GalleryMainScreen<T>` 셸 도입 + 옷장 메인 마이그레이션(Review 통과분) Tester 검증.
///
/// Worker가 이미 작성한 `closet_multi_select_test.dart`(롱프레스 진입, 무확인/확인필요
/// 삭제 경로, X 취소)는 반복하지 않는다. 이 파일은 그 위에서 놓쳤을 수 있는 것들 —
/// (1) 다중선택을 한 번 썼다가 취소한 뒤에도 이 대형 리라이트 이전의 일반 기능(탭 네비게이션/
/// 분류 드릴다운/밀도 토글/추가FAB)이 회귀 없이 그대로 동작하는지, (2) 다중선택
/// 토글(추가/해제)이 실제로 헤더 카운트와 체크서클에 반영되는 end-to-end 흐름, (3) 선택
/// 0개 상태에서 삭제 버튼이 크래시/오삭제 없이 비활성인지, (4) 분류 드릴다운으로 필터된
/// 부분집합 위에서 다중선택이 정확히 그 부분집합만 대상으로 하고 X 취소 후 드릴다운
/// 상태가 그대로 유지되는지, (5) GlassToast의 "실행취소"가 실제로 그리드에 항목을
/// 되돌리는지를 다룬다.
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

  Finder criterionDropdownFinder() => find.byType(PopupMenuButton<int>);
  Finder subCriterionDropdownFinder() => find.byType(PopupMenuButton<int?>);

  Future<void> selectCriterion(WidgetTester tester, String label) async {
    await tester.tap(criterionDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectSubOption(WidgetTester tester, String label) async {
    await tester.tap(subCriterionDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  int crossAxisCount(WidgetTester tester) {
    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    return delegate.crossAxisCount;
  }

  testWidgets(
    '다중선택을 한 번 진입했다가 X로 취소한 뒤에도, 일반 탭이 여전히 상세 화면으로 '
    '이동시킨다(다중선택 종료 후 onItemTap이 원래 콜백으로 정확히 되돌아오는지 확인)',
    (tester) async {
      await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('c05')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);

      // 다중선택 잔여 상태 없이 일반 탭이 여전히 상세 화면으로 이동해야 한다.
      await tester.tap(find.byKey(const ValueKey('c05')));
      await tester.pumpAndSettle();

      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    '다중선택을 한 번 진입했다가 X로 취소한 뒤에도, 분류 드릴다운/밀도 토글/카테고리 '
    '드롭다운/추가FAB가 모두 회귀 없이 동작한다',
    (tester) async {
      await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('c05')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      // 분류 드릴다운: 계절→여름 (2개: c06, c10)로 정상 축소.
      await selectCriterion(tester, '계절');
      await selectSubOption(tester, '여름');
      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));
      await selectCriterion(tester, '전체보기');
      expect(find.byType(SelectableGalleryTile), findsNWidgets(10));

      // 밀도 토글: 기본 2 → 1.
      expect(crossAxisCount(tester), 2);
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(crossAxisCount(tester), 1);

      // 카테고리 드롭다운 존재(다중선택 취소 후 카테고리 토글이 다시 보여야 함).
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);

      // 추가FAB 펼침 → 옵션 탭 → /closet/add 이동.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('한 장 추가하기'), findsOneWidget);
      await tester.tap(find.text('한 장 추가하기'));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetAddScreen), findsOneWidget);
    },
  );

  testWidgets(
    '롱프레스로 진입 후 다른 타일 탭으로 선택 추가, 이미 선택된 타일 재탭으로 해제, '
    'X 탭으로 취소하면 선택이 완전히 비워지고 일반 헤더(카테고리 토글 포함)로 되돌아온다',
    (tester) async {
      await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('c02')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // 다른 타일 탭 → 선택 추가.
      await tester.tap(find.byKey(const ValueKey('c09')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // 이미 선택된 타일 재탭 → 해제.
      await tester.tap(find.byKey(const ValueKey('c09')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // X 탭 → 완전 취소, 정상 헤더 복귀.
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsNothing);
      expect(find.text('선택'), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.byType(MultiSelectCheckmark), findsNothing);
    },
  );

  testWidgets(
    '롱프레스로 진입 후 그 타일을 재탭해 0개로 만들면 삭제 버튼이 비활성 상태가 되어 탭해도 '
    '크래시나 삭제 없이 무시된다(다중선택 모드 자체는 유지)',
    (tester) async {
      final container = await pumpApp(tester);
      final beforeCount = container.read(closetItemsProvider).where((i) => !i.isDeleted).length;

      await tester.longPress(find.byKey(const ValueKey('c05')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('c05')));
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 비활성 버튼이라 탭이 무시되어 여전히 다중선택 모드(0개 선택)여야 한다.
      expect(find.text('0개 선택'), findsOneWidget);
      expect(
        container.read(closetItemsProvider).where((i) => !i.isDeleted).length,
        beforeCount,
        reason: '삭제 버튼이 비활성 상태였으므로 어떤 항목도 삭제되면 안 된다.',
      );
    },
  );

  testWidgets(
    '계절 드릴다운("여름", 2개: c06/c10)이 활성인 상태에서 다중선택에 진입하면 필터된 '
    '부분집합(2개)만 대상이 되고, X로 취소하면 전체 목록이 아니라 드릴다운 상태(2개, '
    '소분류 "여름" 표시)가 그대로 유지된다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '계절');
      await selectSubOption(tester, '여름');
      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));

      await tester.longPress(find.byKey(const ValueKey('c10')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      // 다중선택 중에도 여전히 드릴다운된 2개만 보여야 한다(전체 10개로 돌아가면 안 됨).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('1개 선택'), findsNothing);
      // 드릴다운 상태가 다중선택 취소로 인해 리셋되지 않고 그대로 유지되어야 한다.
      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));
      expect(
        find.descendant(of: subCriterionDropdownFinder(), matching: find.text('여름')),
        findsOneWidget,
        reason: '다중선택 취소 후에도 소분류 드릴다운("여름")이 유지되어야 한다.',
      );
    },
  );

  testWidgets(
    '코디에 안 쓰이는 항목(c02/c09) 삭제 후 GlassToast의 "실행취소"를 탭하면 실제로 '
    '그리드에 항목이 되돌아온다(토스트가 사라지는 것만으로 판단하지 않고 provider/그리드 '
    '양쪽을 확인)',
    (tester) async {
      final container = await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('c02')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c09')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // 삭제 직후 — 그리드에서 사라졌어야 한다.
      expect(find.byKey(const ValueKey('c02')), findsNothing);
      expect(find.byKey(const ValueKey('c09')), findsNothing);
      expect(find.text('실행취소'), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      // provider 상태 복원 확인.
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c02').isDeleted, isFalse);
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c09').isDeleted, isFalse);
      // 그리드에도 실제로 다시 나타나야 한다(토스트 소멸만으로 판단하지 않음).
      expect(find.byKey(const ValueKey('c02')), findsOneWidget);
      expect(find.byKey(const ValueKey('c09')), findsOneWidget);
    },
  );
}
