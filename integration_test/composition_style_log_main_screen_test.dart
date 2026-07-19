import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_add_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/app_scroll_container.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Step③(코디 메인/스타일일지 메인 → `AppMainScaffold` 마이그레이션, Review 통과분) Tester
/// 검증. `closet_main_screen_test.dart`/`app_main_scaffold_shell_migration_test.dart`가 이미
/// 다룬 셸 공통 동작(뒤로가기 버튼 조건부 렌더링 메커니즘 자체, groupingBar=null 레이아웃 등)은
/// 중복 검증하지 않고, 이번 마이그레이션에서 코디/스타일일지 메인에 처음 실제로 배선된
/// 항목만 다룬다: 계절 필터↔그리드 반영, 밀도 토글↔그리드 컬럼 반영, 그리드 탭→상세/뷰어
/// 이동(id 보간), FAB 동작 차이(코디=팝업 없이 즉시 이동 / 스타일일지=2-옵션 팝업),
/// groupingBar 유무 차이, 코디/스타일일지 메인에 이제 실제로 카테고리 토글이 배선되어 옷장으로
/// 되돌아올 수 있게 된 것.
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

  Finder seasonDropdownFinder() => find.byWidgetPredicate((w) => w is DropdownButton<Season?>);

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectSeason(WidgetTester tester, String label) async {
    await tester.tap(seasonDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  int crossAxisCount(WidgetTester tester) {
    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    return delegate.crossAxisCount;
  }

  IconData densityToggleIcon(WidgetTester tester) {
    final icon = tester.widget<Icon>(
      find.descendant(of: find.byTooltip('그리드 밀도 전환'), matching: find.byType(Icon)),
    );
    return icon.icon!;
  }

  // ── 코디 메인(/composition) ────────────────────────────────────────────────

  testWidgets(
    '옷장에서 카테고리 드롭다운으로 코디로 이동하면 AppMainScaffold 크롬(카테고리 토글, '
    'groupingBar skeleton, mock 코디 2개)이 정상 렌더링되고, 스택 최상단(canPop==false)이라 '
    '뒤로가기 버튼은 나타나지 않는다',
    (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '코디');

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.byTooltip('뒤로가기'), findsNothing);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(2));
      expect(find.textContaining('분류 선택 바'), findsOneWidget);
      expect(find.text('데일리 룩'), findsOneWidget);
      expect(find.text('포멀 코디'), findsOneWidget);
    },
  );

  testWidgets(
    '[회귀 확인] 코디 메인에 이제 실제로 카테고리 토글이 배선되어, 코디→옷장으로 되돌아오는 '
    'UI 경로가 실제로 동작한다 (과거 closet_main_shell_widgets_regression_test.dart의 '
    '"발견 사항" 테스트가 전제했던 스켈레톤 상태는 이번 마이그레이션으로 해소됨)',
    (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);

      await goToCategory(tester, '옷장');
      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
    },
  );

  testWidgets(
    '코디 메인 계절 드롭다운에서 여름/겨울 선택 시 mock 코디 중 계절이 매칭되는 게 없어 그리드가 '
    '0개로 줄고(크래시 없음), 봄가을 선택 시 1개(comp01만 봄가을, comp02는 계절 nullable화 이후 '
    '미분류)로, 전체 선택 시 다시 2개로 돌아온다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await selectSeason(tester, '여름');
      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionGalleryTile), findsNothing);
      expect(find.byType(GridView), findsOneWidget);

      await selectSeason(tester, '겨울');
      expect(find.byType(CompositionGalleryTile), findsNothing);

      await selectSeason(tester, '봄가을');
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));

      await selectSeason(tester, '전체');
      expect(find.byType(CompositionGalleryTile), findsNWidgets(2));
    },
  );

  testWidgets(
    '코디 메인 밀도 토글 아이콘 탭 시 실제 그리드 컬럼 수가 2(view_comfy)→1(crop_square)→'
    '4(grid_view)→2 순으로 바뀐다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      expect(crossAxisCount(tester), 2);
      expect(densityToggleIcon(tester), Icons.view_comfy);

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pump();
      expect(crossAxisCount(tester), 1);
      expect(densityToggleIcon(tester), Icons.crop_square);

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pump();
      expect(crossAxisCount(tester), 4);
      expect(densityToggleIcon(tester), Icons.grid_view);

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pump();
      expect(crossAxisCount(tester), 2);
      expect(densityToggleIcon(tester), Icons.view_comfy);
    },
  );

  testWidgets(
    '[갱신됨, Task 6 재검증] 코디 타일 탭 시 올바른 id로 /composition/:id 로 이동하고, id로 조회된 '
    '실제 코디 데이터가 렌더링된다 (CompositionDetailScreen이 Task 6에서 실제 데이터 바인딩으로 '
    '교체되어, id를 raw text로 그대로 echo하던 과거 skeleton 동작은 더 이상 유효하지 않다 — mock '
    'comp01의 실제 이름("데일리 룩") 렌더링 확인으로 갱신)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text('데일리 룩'), findsOneWidget);
    },
  );

  testWidgets(
    '코디 메인 FAB는 (옷장/스타일일지와 달리) 옵션 팝업 없이 탭 즉시 /composition/editor로 '
    '이동한다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionEditorScreen), findsOneWidget);
      // 옷장/스타일일지식 2-옵션 팝업 라벨이 뜬 적 없이 곧장 이동했어야 한다.
      expect(find.textContaining('추가하기'), findsNothing);
    },
  );

  testWidgets(
    '코디 메인에서 계절 필터·밀도를 바꾼 뒤 옷장으로 갔다가 다시 코디로 돌아와도(같은 앱 실행 '
    '중 in-memory 상태) 바꿔둔 값이 그대로 유지된다',
    (tester) async {
      final container = await pumpApp(tester);
      await goToCategory(tester, '코디');

      await selectSeason(tester, '봄가을');
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(container.read(compositionDensityProvider), 1);
      expect(container.read(selectedCompositionSeasonFilterProvider), Season.springFall);

      await goToCategory(tester, '옷장');
      await goToCategory(tester, '코디');

      expect(container.read(compositionDensityProvider), 1);
      expect(container.read(selectedCompositionSeasonFilterProvider), Season.springFall);
      expect(crossAxisCount(tester), 1);
      // comp02는 계절 nullable화(2026-07-19) 이후 season이 null(미분류)이라 봄가을 필터에
      // 더 이상 매칭되지 않는다 — comp01만 남아 1개.
      expect(find.byType(CompositionGalleryTile), findsNWidgets(1));
    },
  );

  // ── 스타일일지 메인(/style-log) ─────────────────────────────────────────────

  testWidgets(
    '옷장에서 카테고리 드롭다운으로 스타일일지로 이동하면 AppMainScaffold 크롬(카테고리 토글, '
    'mock 스타일일지 2개)이 정상 렌더링되고, groupingBar 자리 자체가 없다(코디 메인과 달리 '
    '"분류 선택 바" skeleton 텍스트가 없음)',
    (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '스타일일지');

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.byTooltip('뒤로가기'), findsNothing);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));
      expect(find.textContaining('분류 선택 바'), findsNothing);
      // 계절 드롭다운/밀도 토글은 스타일일지 메인에 없는 UI(스펙에 명시된 의도된 차이).
      expect(seasonDropdownFinder(), findsNothing);
      expect(find.byTooltip('그리드 밀도 전환'), findsNothing);
    },
  );

  testWidgets(
    '스타일일지 타일에 wornDate·location이 "YYYY-MM-DD · 장소" 형식으로 표시되고, 최신순(내림차순, '
    'log02가 log01보다 먼저)으로 정렬된다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      expect(find.textContaining('2026-01-10 · 회사'), findsOneWidget);
      expect(find.textContaining('2026-01-05 · 집'), findsOneWidget);

      final log02Rect = tester.getRect(find.byKey(const ValueKey('log02')));
      final log01Rect = tester.getRect(find.byKey(const ValueKey('log01')));
      // 최신(log02, 2026-01-10)이 더 앞(그리드 상단/좌측)에 배치되어야 한다.
      expect(
        log02Rect.top < log01Rect.top ||
            (log02Rect.top == log01Rect.top && log02Rect.left < log01Rect.left),
        isTrue,
        reason: 'log02Rect=$log02Rect, log01Rect=$log01Rect',
      );
    },
  );

  testWidgets(
    '스타일일지 타일 탭 시 올바른 id로 /style-log/:id로 이동하고, 실제 콘텐츠(착용일자)가 렌더링된다 '
    '(Task 7 — 스타일일지 열람 실데이터 바인딩 완료로 skeleton id echo는 더 이상 유효하지 않음)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.textContaining('2026.1.5'), findsOneWidget); // log01.wornDate
    },
  );

  testWidgets(
    '스타일일지 메인 FAB 탭 시 "1카드 추가"/"여러카드에 분할 추가" 2-옵션 팝업이 펼쳐지고, '
    '다시 탭하면 접힌다(초기 상태에는 옵션 라벨이 보이지 않음)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      expect(find.text('1카드 추가'), findsNothing);
      expect(find.text('여러카드에 분할 추가'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('1카드 추가'), findsOneWidget);
      expect(find.text('여러카드에 분할 추가'), findsOneWidget);
      // 펼침 상태에서도 여전히 스타일일지 메인(이동하지 않음).
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('1카드 추가'), findsNothing);
      expect(find.text('여러카드에 분할 추가'), findsNothing);
    },
  );

  testWidgets(
    '스타일일지 FAB 펼침 메뉴에서 "1카드 추가"를 탭하면 /style-log/add 로 이동하고 팝업이 '
    '닫힌다(뒤로 돌아왔을 때 펼침 상태가 남아있지 않아야 함)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1카드 추가'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogAddScreen), findsOneWidget);
      expect(find.byType(StyleLogGalleryTile), findsNothing);
    },
  );

  testWidgets(
    '스타일일지 FAB 펼침 메뉴에서 "여러카드에 분할 추가"를 탭해도 동일하게 /style-log/add 로 '
    '이동한다(두 옵션이 현재 같은 라우트로 연결된 의도된 상태)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('여러카드에 분할 추가'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogAddScreen), findsOneWidget);
    },
  );

  testWidgets(
    '[비정형 사용 흐름] 스타일일지 FAB를 프레임 반영 없이 2번 연속 탭해도 크래시 없이 '
    '펼침→접힘으로 정상 수렴한다(로컬 bool 필드 토글이라 옷장의 stale-closure 레이스와 무관)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1카드 추가'), findsNothing);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));
    },
  );

  testWidgets(
    '[회귀] 스타일일지에서 자기 자신을 카테고리 드롭다운으로 재선택하면 아무 화면 전환도 '
    '일어나지 않는다(옷장 메인과 동일한 자기 자신 재선택 무시 동작)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      await goToCategory(tester, '스타일일지');

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));
    },
  );

  testWidgets(
    '코디 그리드 아이템 폭 오버플로 없이, AppScrollContainer가 코디/스타일일지 메인 그리드를 '
    '모두 감싸고 있다(구조적 회귀 확인 — 옷장 메인과 동일 패턴 유지, ShaderMask 기반 '
    'FadingScrollEdge는 폐기됨)',
    (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '코디');
      expect(
        find.descendant(of: find.byType(AppScrollContainer), matching: find.byType(GridView)),
        findsOneWidget,
      );

      await goToCategory(tester, '스타일일지');
      expect(
        find.descendant(of: find.byType(AppScrollContainer), matching: find.byType(GridView)),
        findsOneWidget,
      );
    },
  );
}
