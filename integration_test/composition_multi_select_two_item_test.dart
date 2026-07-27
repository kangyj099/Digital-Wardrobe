import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';

/// Tester 런타임 검증 — Group B Task 8(코디 메인 `GalleryMainScreen<T>` 이관, Review 통과분).
///
/// `composition_multi_select_test.dart`(Worker/Review 자체 테스트)는 단일 선택 경로만
/// 다룬다(테스트 파일 자체의 근거 주석이 "코디가 1개만 활성"이라 가정했으나 실제로는
/// comp01/comp03 2개가 활성 — stale comment, 기능 버그 아님). 이 파일은 그 gap을 메워
/// mock 데이터에 실제로 존재하는 2개 활성 코디를 이용한 2건 다중선택 경로, 그리고
/// 드릴다운 필터 상태와 다중선택 취소의 상호작용을 다룬다.
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
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디').last);
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

  /// 그리드에 렌더링된 [MultiSelectCheckmark] 중 실제로 "선택됨"으로 표시된 개수 —
  /// 다중선택 모드에선 모든 타일이 체크서클을 렌더링하므로(미선택=아웃라인), 위젯
  /// 개수 자체가 아니라 `selected == true`인 것만 세야 선택 개수를 의미한다.
  int selectedCheckmarkCount(WidgetTester tester) {
    return tester
        .widgetList<MultiSelectCheckmark>(find.byType(MultiSelectCheckmark))
        .where((c) => c.selected)
        .length;
  }

  testWidgets(
    'comp01 롱프레스로 진입 후 comp03을 탭해 순차 선택하면 "2개 선택"이 되고 체크마크도 '
    '실제로 2개가 선택 상태로 표시된다, comp01을 다시 탭해 해제하면 "1개 선택"으로 줄고 '
    'comp03만 선택 상태로 남는다',
    (tester) async {
      await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 1);

      await tester.tap(find.byKey(const ValueKey('comp03')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 2);

      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 1);
      final comp03Tile = tester.widget<CompositionGalleryTile>(find.byKey(const ValueKey('comp03')));
      expect(comp03Tile.selected, isTrue, reason: '해제된 것은 comp01이어야 하고 comp03은 계속 선택 상태여야 한다.');
    },
  );

  testWidgets(
    'comp01/comp03 둘 다 선택 후 [삭제] 탭 시 확인 팝업 없이(코디는 링크 확인 개념 자체가 '
    '없음) 즉시 둘 다 휴지통 이동되고 GlassToast에 "2개 항목이 휴지통으로 이동됨"과 '
    '실행취소 액션이 뜬다 — 실행취소 탭 시 둘 다 provider 상태 및 그리드 화면 양쪽에서 '
    '복구 확인된다',
    (tester) async {
      final container = await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('comp03')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('2개 선택'), findsNothing);
      expect(find.text('사용 중인 코디가 있어요'), findsNothing);
      expect(container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isDeleted, isTrue);
      expect(container.read(compositionsProvider).firstWhere((c) => c.id == 'comp03').isDeleted, isTrue);
      expect(find.byKey(const ValueKey('comp01')), findsNothing);
      expect(find.byKey(const ValueKey('comp03')), findsNothing);
      expect(find.text('2개 항목이 휴지통으로 이동됨'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isDeleted, isFalse);
      expect(container.read(compositionsProvider).firstWhere((c) => c.id == 'comp03').isDeleted, isFalse);
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget);
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget);
    },
  );

  testWidgets(
    '날씨="비" 드릴다운(comp03만 남는 필터) 상태에서 다중선택 진입 후 X로 취소하면, '
    '선택은 비워지고 정상 헤더로 돌아오되 드릴다운 필터는 리셋되지 않고 그대로 유지된다 '
    '(전체 목록으로 되돌아가지 않아야 함)',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '날씨');
      await selectSubOption(tester, '비');
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('comp03')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('1개 선택'), findsNothing);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget);
    },
  );
}
