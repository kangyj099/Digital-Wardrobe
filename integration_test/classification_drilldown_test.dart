import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/classification_group_card.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// Task 7(옷장/코디 메인 분류 기준 드릴다운 캡슐 배선) Tester 런타임 검증.
///
/// `closet_main_screen_test.dart`/`composition_style_log_main_screen_test.dart`/
/// `selection_modal_test.dart`가 이미 다룬 것(소분류 드롭다운 "직접 선택" 경로, 캡슐
/// 존재 여부만 확인하는 selectionMode 검증)은 반복하지 않는다. 이 파일은 (1) 그룹
/// **카드 탭** 경로로 드릴인했을 때 캡슐 소분류 텍스트가 동기화되는지(스펙 §3.1 "두
/// 진입 경로가 수렴한다"), (2) 미분류 카드의 실제 렌더링·필터링, (3) 날짜·시간(연도)
/// 처럼 고정 enum이 아닌 동적 라벨의 카드 탭 동기화, (4) 정렬 방향 버튼의 실제 방향
/// (전역 단순 규칙 — 기본이 스펙 §3.2 표와 반대), (5) 코디 "날씨" 기준 3상태 + 미분류
/// 카드 부재, (6) selectionMode에서도 카드 탭 상호작용이 동작하는지를 다룬다.
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

  // 옷장/코디 메인 둘 다 첫 PopupMenuButton<int>이 중분류, 있으면 PopupMenuButton<int?>이
  // 소분류 — `closet_main_screen_test.dart`와 동일 패턴(`is` predicate는 공변성 트랩 있음,
  // find.byType만 안전).
  Finder criterionDropdownFinder() => find.byType(PopupMenuButton<int>);
  Finder subCriterionDropdownFinder() => find.byType(PopupMenuButton<int?>);

  Future<void> selectCriterion(WidgetTester tester, String label) async {
    await tester.tap(criterionDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// 앱 부팅 시 기본 화면은 옷장 메인 — 코디 메인을 검증하려면 카테고리 드롭다운으로
  /// 먼저 이동해야 한다(`composition_style_log_main_screen_test.dart`의 `goToCategory`와
  /// 동일 패턴).
  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// 그룹 카드를 라벨(`ClassificationGroupSummary.label`, 곧 `ValueKey`)로 탭한다 —
  /// 소분류 드롭다운을 거치지 않는 "두 번째 진입 경로".
  Future<void> tapGroupCard(WidgetTester tester, String label) async {
    final finder = find.byKey(ValueKey(label));
    expect(finder, findsOneWidget, reason: '그룹 카드 "$label"이 그룹 개요에 존재해야 한다.');
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// 소분류 드롭다운이 닫힌 상태에서 표시하는 텍스트(선택된 값의 라벨) 확인 — 그룹 카드
  /// 탭과 드롭다운 직접 선택이 같은 provider를 갱신하는지의 핵심 증거.
  void expectSubDropdownShows(WidgetTester tester, String label) {
    expect(
      find.descendant(of: subCriterionDropdownFinder(), matching: find.text(label)),
      findsOneWidget,
      reason: '소분류 드롭다운이 닫힌 상태에서 "$label"을 표시해야 한다(카드 탭↔드롭다운 값 동기화).',
    );
  }

  List<String> groupCardLabelsInOrder(WidgetTester tester) {
    final cards = tester.widgetList<ClassificationGroupCard>(find.byType(ClassificationGroupCard));
    return [for (final c in cards) c.summary.label];
  }

  IconData sortIcon(WidgetTester tester, String tooltip) {
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byTooltip(tooltip), matching: find.byType(Icon)),
    );
    return icon.icon!;
  }

  // ── 옷장 메인: "옷 종류" 3상태 + 카드 탭 동기화 ──────────────────────────────

  testWidgets(
    '옷장 메인: 중분류를 "옷 종류"로 바꾸면 그룹 개요로 전환되어 카드 5장(하의/아우터/상의/'
    '한벌옷/미분류)이 나타나고 아이템 타일은 사라진다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');

      expect(find.byType(SelectableGalleryTile), findsNothing);
      expect(find.byType(ClassificationGroupCard), findsNWidgets(5));
      for (final label in ['하의', '아우터', '상의', '한벌옷', '미분류']) {
        expect(find.byKey(ValueKey(label)), findsOneWidget, reason: '"$label" 카드가 있어야 한다.');
      }
    },
  );

  testWidgets(
    '[갱신, Task 7 재검증] 옷장 메인: "옷 종류" 그룹 개요에서 "하의" 카드를 탭(드롭다운이 '
    '아니라)하면 드릴인되어 그리드가 3개 타일로 바뀌고(c07도 bottom이었으나 이미 소프트삭제됨), '
    '캡슐 소분류 텍스트가 자동으로 "하의"로 동기화된다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');
      await tapGroupCard(tester, '하의');

      expect(find.byType(ClassificationGroupCard), findsNothing);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(3));
      expectSubDropdownShows(tester, '하의');

      // "전체 그룹 보기"로 되돌리는 것도 같은 provider(소분류 드롭다운)를 통해 동작해야 한다.
      await tester.tap(subCriterionDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('전체 그룹 보기').last);
      await tester.pumpAndSettle();

      expect(find.byType(ClassificationGroupCard), findsNWidgets(5));
      expect(find.byType(SelectableGalleryTile), findsNothing);
    },
  );

  // ── 미분류 카드 ──────────────────────────────────────────────────────────

  testWidgets(
    '옷장 메인: "옷 종류" 미분류 카드(mock c12) 탭 시 category가 null인 아이템(c12) 1개만 '
    '드릴인된다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');
      await tapGroupCard(tester, '미분류');

      expect(find.byType(SelectableGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('c12')), findsOneWidget);
      expectSubDropdownShows(tester, '미분류');
    },
  );

  testWidgets(
    '옷장 메인: "계절" 그룹 개요에도 미분류 카드가 나타나고(mock c12), 탭 시 season이 '
    'null인 아이템(c12) 1개만 드릴인된다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '계절');
      expect(find.byKey(const ValueKey('미분류')), findsOneWidget);

      await tapGroupCard(tester, '미분류');

      expect(find.byType(SelectableGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('c12')), findsOneWidget);
      expectSubDropdownShows(tester, '미분류');
    },
  );

  // ── 날짜·시간(연도) — 고정 enum이 아닌 동적 라벨 드릴다운 ──────────────────────

  testWidgets(
    '옷장 메인: 중분류를 "날짜·시간"으로 바꾸면 실제 데이터에서 뽑힌 연도별 그룹 카드 '
    '4장(2023년/2024년/2025년/2026년)이 나타난다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '날짜·시간');

      expect(find.byType(ClassificationGroupCard), findsNWidgets(4));
      for (final label in ['2023년', '2024년', '2025년', '2026년']) {
        expect(find.byKey(ValueKey(label)), findsOneWidget, reason: '"$label" 카드가 있어야 한다.');
      }
    },
  );

  testWidgets(
    '옷장 메인: "2026년" 카드 탭 시 그 연도 아이템(c06, c12) 2개만 드릴인되고, 캡슐 '
    '소분류 텍스트도 "2026년"으로 동기화된다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '날짜·시간');
      await tapGroupCard(tester, '2026년');

      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));
      expect(find.byKey(const ValueKey('c06')), findsOneWidget);
      expect(find.byKey(const ValueKey('c12')), findsOneWidget);
      expectSubDropdownShows(tester, '2026년');
    },
  );

  // ── 정렬 방향 실측 ──────────────────────────────────────────────────────

  testWidgets(
    '옷장 메인: 정렬 버튼을 건드리지 않은 기본 상태에서 "옷 종류" 그룹 카드 순서는 '
    '스펙 §3.2 표(머리→발)와 반대인 "미분류→하의→아우터→상의→한벌옷"이고, 정렬 아이콘/'
    '툴팁은 "내림차순"(↓)이다 — 사용자가 확정한 "전역 단순 규칙" tradeoff 실측',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');

      expect(
        groupCardLabelsInOrder(tester),
        ['미분류', '하의', '아우터', '상의', '한벌옷'],
        reason: '기본(ascending=false)은 전역 단순 규칙상 index 내림차순 + null이 맨 앞이어야 한다.',
      );
      expect(find.byTooltip('내림차순'), findsOneWidget);
      expect(find.byTooltip('오름차순'), findsNothing);
      expect(sortIcon(tester, '내림차순'), Icons.arrow_downward);
    },
  );

  testWidgets(
    '옷장 메인: 정렬 버튼을 한 번 탭하면 "옷 종류" 그룹 카드 순서가 스펙 §3.2 표와 일치하는 '
    '"한벌옷→상의→아우터→하의→미분류"(머리→발, 미분류는 맨 뒤)로 바뀌고, 아이콘/툴팁도 '
    '"오름차순"(↑)으로 바뀐다',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');
      await tester.tap(find.byTooltip('내림차순'));
      await tester.pumpAndSettle();

      expect(
        groupCardLabelsInOrder(tester),
        ['한벌옷', '상의', '아우터', '하의', '미분류'],
        reason: 'ascending=true는 index 오름차순 + null이 맨 뒤여야 한다(스펙 §3.2 표와 일치).',
      );
      expect(find.byTooltip('오름차순'), findsOneWidget);
      expect(find.byTooltip('내림차순'), findsNothing);
      expect(sortIcon(tester, '오름차순'), Icons.arrow_upward);
    },
  );

  // ── 코디 메인: "날씨" 3상태 + 미분류 카드 부재 확인 ─────────────────────────

  testWidgets(
    '코디 메인: 중분류를 "날씨"로 바꾸면 그룹 개요로 전환되어 카드 2장(맑음/비)만 나타나고, '
    '미분류 카드는 없다(mock 둘 다 weather가 채워져 있음)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await selectCriterion(tester, '날씨');

      expect(find.byType(CompositionGalleryTile), findsNothing);
      expect(find.byType(ClassificationGroupCard), findsNWidgets(2));
      expect(find.byKey(const ValueKey('맑음')), findsOneWidget);
      expect(find.byKey(const ValueKey('비')), findsOneWidget);
      expect(find.byKey(const ValueKey('미분류')), findsNothing);
      expect(find.byKey(const ValueKey('눈')), findsNothing, reason: '눈에 해당하는 mock 코디가 없어 빈 그룹 카드가 없어야 한다.');
    },
  );

  testWidgets(
    '[갱신, Task 7 재검증] 코디 메인: "맑음" 카드 탭 시 comp01만 드릴인되고 캡슐 소분류 '
    '텍스트가 "맑음"으로 동기화된다, "비" 카드 탭 시 comp03만 드릴인된다(원래는 comp02가 '
    '유일한 비-날씨 코디였으나, comp02가 이후 소프트삭제되어 `filteredCompositionsProvider`에서 '
    '제외됨 — `mock_data.dart`를 확인해보면 comp03이 정확히 comp02와 동일하게 '
    '`weather: Weather.rain`이면서 삭제되지 않은 상태라 이 자리를 이어받는다)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await selectCriterion(tester, '날씨');
      await tapGroupCard(tester, '맑음');

      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget);
      expectSubDropdownShows(tester, '맑음');

      // 전체 그룹 보기로 되돌아간 뒤 "비" 카드로 다시 드릴인.
      await tester.tap(subCriterionDropdownFinder());
      await tester.pumpAndSettle();
      await tester.tap(find.text('전체 그룹 보기').last);
      await tester.pumpAndSettle();

      await tapGroupCard(tester, '비');
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget);
      expectSubDropdownShows(tester, '비');
    },
  );

  // ── selectionMode(선택 모달)에서도 그룹개요/드릴인 카드 상호작용이 동작하는지 ───────

  testWidgets(
    '옷장 선택 모달(/closet/select)에서도 중분류 "옷 종류" → 카드 탭 드릴인이 정상 동작한다',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.closetSelect);
      await tester.pumpAndSettle();

      await selectCriterion(tester, '옷 종류');
      expect(find.byType(ClassificationGroupCard), findsNWidgets(5));

      await tapGroupCard(tester, '아우터');

      expect(tester.takeException(), isNull);
      expect(find.byType(SelectableGalleryTile), findsNWidgets(2));
      expect(find.byKey(const ValueKey('c04')), findsOneWidget);
      expect(find.byKey(const ValueKey('c09')), findsOneWidget);
      expectSubDropdownShows(tester, '아우터');
    },
  );

  testWidgets(
    '[갱신, Task 7 재검증] 코디 선택 모달(/composition/select)에서도 중분류 "날씨" → 카드 탭 '
    '드릴인이 정상 동작하고 드릴인 상태에서도 미분류 카드는 없다("비" 카드 탭 시 comp03만 '
    '드릴인된다 — comp02가 소프트삭제되어 comp03이 그 자리를 이어받음, 위 코디 메인 테스트와 '
    '동일한 이유)',
    (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.compositionSelect);
      await tester.pumpAndSettle();

      await selectCriterion(tester, '날씨');
      expect(find.byType(ClassificationGroupCard), findsNWidgets(2));
      expect(find.byKey(const ValueKey('미분류')), findsNothing);

      await tapGroupCard(tester, '비');

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
      expect(find.byKey(const ValueKey('comp03')), findsOneWidget);
      expectSubDropdownShows(tester, '비');
    },
  );

  // ── 중분류 재선택 시 소분류 초기화(사용자 지시, 2026-07-20) ──────────────────────

  testWidgets(
    '[갱신, Task 7 재검증] 옷장 메인: "옷 종류"에서 "하의"로 드릴인한 뒤 "계절"로 갔다가 '
    '다시 "옷 종류"로 돌아오면, 예전에 골랐던 "하의"가 아니라 그룹 개요(카드 5장)로 초기화되어 '
    '있다(하의 드릴인 개수는 c07이 이미 소프트삭제되어 4개→3개로 갱신)',
    (tester) async {
      await pumpApp(tester);

      await selectCriterion(tester, '옷 종류');
      await tapGroupCard(tester, '하의');
      expect(find.byType(SelectableGalleryTile), findsNWidgets(3));

      await selectCriterion(tester, '계절');
      expect(find.byType(ClassificationGroupCard), findsWidgets); // 계절도 그룹 개요로 시작

      await selectCriterion(tester, '옷 종류');

      expect(tester.takeException(), isNull);
      // 버그였다면 여기서 SelectableGalleryTile 3개(예전 "하의" 드릴인)가 곧장 다시
      // 나타났을 것 — 그룹 개요(카드 5장)로 초기화되어 있어야 한다.
      expect(find.byType(ClassificationGroupCard), findsNWidgets(5));
      expect(find.byType(SelectableGalleryTile), findsNothing);
    },
  );

  testWidgets(
    '코디 메인: "날씨"에서 "맑음"으로 드릴인한 뒤 "계절"로 갔다가 다시 "날씨"로 돌아오면 '
    '그룹 개요(카드 2장)로 초기화되어 있다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await selectCriterion(tester, '날씨');
      await tapGroupCard(tester, '맑음');
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));

      await selectCriterion(tester, '계절');
      await selectCriterion(tester, '날씨');

      expect(tester.takeException(), isNull);
      expect(find.byType(ClassificationGroupCard), findsNWidgets(2));
      expect(find.byType(CompositionGalleryTile), findsNothing);
    },
  );
}
