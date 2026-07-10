import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

/// Task 7(옷장 메인 화면) 검증. Review 통과분(commit 8145d3f) 대상 Tester 시나리오.
/// Task 1(Season enum 4종→3종 개편, commit fb15a84) 재검증 시 계절 드롭다운 순서 assertion 추가.
/// Task 2(Design Tokens 확정, commit 6505fea/46052bc) 재검증 시 밀도 순환 방향이
/// 오름차순(3→5→1)에서 내림차순(5→3→1)으로 반전되어 순환 테스트 3개의 기대값을 갱신.
/// 화면 기본값은 mid(3)이라, 실제 탭 시퀀스는 3→1→5→3→1→5...로 관찰된다(직접 실행해 확인).
/// Task 3(화면 레이아웃 재구축, commit e91d059+5bea4bd) 재검증 시:
/// - 카테고리 드롭다운(옷장/코디/스타일일지) 이동 시나리오 2개 신설.
/// - FAB가 탭 즉시 이동하지 않고 "한 장/여러 장 추가하기" 펼침 메뉴부터 뜨는 것으로 동작이
///   바뀌어(의도된 변화), 기존 "FAB 탭 시 /closet/add 로 정확히 이동한다" 테스트를
///   펼침→옵션탭→이동 흐름으로 갱신하고, 펼침/접힘 토글·계절별 라벨 전환 테스트를 신설.
/// - 그리드 타일 라벨이 상품명 대신 옷 종류로 바뀐 것을 확인하는 테스트 신설.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpClosetMain(WidgetTester tester) async {
    // 12개 아이템이 스크롤 없이 한 화면에 모두 빌드되도록 뷰포트를 충분히 키운다
    // (실제 창 크기 제약 때문에 GridView.builder가 화면 밖 아이템을 지연 생성하지 않게 함).
    tester.view.physicalSize = const Size(1400, 3000);
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

  Finder seasonDropdownFinder() =>
      find.byWidgetPredicate((w) => w is DropdownButton<Season?>);

  Finder categoryDropdownFinder() =>
      find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>);

  Future<void> selectSeason(WidgetTester tester, String label) async {
    await tester.tap(seasonDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
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

  testWidgets('부팅 시 mock 옷 12개가 렌더링되고 미완성 배지 1개가 표시된다', (tester) async {
    await pumpClosetMain(tester);

    expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.text('미완성'), findsOneWidget);
  });

  testWidgets('계절 드롭다운에 전체 + 3개 계절 옵션이 실제로 나타나고, 봄가을→여름→겨울 순으로 정렬된다', (tester) async {
    await pumpClosetMain(tester);

    await tester.tap(seasonDropdownFinder());
    await tester.pumpAndSettle();

    final rawItems = tester
        .widgetList<DropdownMenuItem<Season?>>(find.byType(DropdownMenuItem<Season?>));

    final values = rawItems.map((w) => w.value).toSet();
    expect(values, {null, ...Season.values});

    // 정렬 기본순서 표(_공통 규칙.md: "봄가을 → 여름 → 겨울")를 실제 렌더링 순서로 확인.
    // 주의: 열린 DropdownButton 오버레이는 선택된 항목의 DropdownMenuItem을 내부적으로
    // 중복 렌더링하는 Flutter 프레임워크 동작이 있어(현재 선택값=전체), 순서 비교 전
    // 최초 등장 순서를 보존한 채 중복을 제거한다(LinkedHashSet).
    final orderedLabels =
        LinkedHashSet<String>.from(rawItems.map((w) => w.value?.label ?? '전체')).toList();

    expect(orderedLabels, ['전체', '봄가을', '여름', '겨울']);
  });

  testWidgets('여름 계절 필터 선택 시 그리드가 3개로 줄어들고, 전체로 되돌리면 12개로 복원된다', (tester) async {
    await pumpClosetMain(tester);

    await selectSeason(tester, '여름');
    expect(find.byType(SelectableGalleryTile), findsNWidgets(3));

    await selectSeason(tester, '전체');
    expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
  });

  testWidgets('봄가을 계절 필터 선택 시 그리드가 9개로 줄어든다', (tester) async {
    await pumpClosetMain(tester);

    await selectSeason(tester, '봄가을');
    expect(find.byType(SelectableGalleryTile), findsNWidgets(9));
  });

  testWidgets('아이템이 0개인 겨울 계절 선택 시 크래시 없이 빈 그리드로 전환된다', (tester) async {
    await pumpClosetMain(tester);

    await selectSeason(tester, '겨울');

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectableGalleryTile), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('밀도 토글 아이콘이 3→1→5→3 순으로 그리드 컬럼 수와 아이콘을 함께 바꾼다 (탭 사이 프레임 반영 O)', (tester) async {
    await pumpClosetMain(tester);

    // Task 2에서 순환 방향이 내림차순(5→3→1)으로 반전됨. 화면 기본값이 mid(3)이라
    // 실제 탭 시퀀스는 3(시작, view_comfy) → 1(crop_square) → 5(grid_view) → 3(view_comfy)이다.
    expect(crossAxisCount(tester), 3);
    expect(densityToggleIcon(tester), Icons.view_comfy);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 1);
    expect(densityToggleIcon(tester), Icons.crop_square);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 5);
    expect(densityToggleIcon(tester), Icons.grid_view);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 3);
    expect(densityToggleIcon(tester), Icons.view_comfy);
  });

  testWidgets(
    '[회귀 고정] 밀도 아이콘을 프레임 반영 없이 2번 연속 탭해도 5→3→1 순환이 깨지지 않는다 '
    '(stale-closure race, fixed in 10d3643)',
    (tester) async {
      final container = await pumpClosetMain(tester);

      // 비정형 사용 흐름: 탭 사이에 pump()를 넣지 않아, 실제 프레임 렌더링(위젯 리빌드)이
      // 반영되기 전에 연속으로 탭하는 상황(예: 프레임 드랍 중 빠른 연타)을 재현한다.
      // 과거에는 onPressed 클로저가 build() 시점에 캡처된 density 지역 변수를 참조해,
      // 리빌드가 끼어들지 않으면 각 탭이 매번 "같은 이전 값 기준"으로 next를 계산해
      // 순환하지 않고 첫 탭이 계산한 값에 멈추는 결함이 있었다(commit 10d3643에서
      // onPressed 내부에서 ref.read로 최신값을 다시 조회하도록 수정되어 해결됨). 이 테스트는
      // 그 수정이 회귀하지 않는지를, Task 2에서 반전된 새 순환 방향(5→3→1) 기준으로 고정한다.
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();

      // 기본값 3에서 시작해 순환 로직대로면 두 번째 탭 후 5여야 한다(3→1→5).
      expect(
        container.read(closetDensityProvider),
        5,
        reason: '프레임 반영 없이 연속 탭해도 순환 로직(3→1→5)대로 진행되어야 한다.',
      );
    },
  );

  testWidgets(
    '[회귀 고정] 밀도 아이콘을 프레임 반영 없이 5번 연속 탭해도 순환 로직대로 수렴한다 '
    '(stale-closure race, fixed in 10d3643)',
    (tester) async {
      final container = await pumpClosetMain(tester);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byTooltip('그리드 밀도 전환'));
      }
      await tester.pumpAndSettle();

      // 기본값 3에서 시작해 3→1→5→3→1→5 순환대로면 5회 탭 후 5여야 한다.
      expect(
        container.read(closetDensityProvider),
        5,
        reason: '순환 로직대로면 5회 탭 후 5여야 한다.',
      );
    },
  );

  testWidgets('카테고리 드롭다운에서 코디 선택 시 코디 메인(/composition)으로 실제 이동한다', (tester) async {
    await pumpClosetMain(tester);

    await selectCategory(tester, '코디');

    expect(find.text('코디 메인'), findsOneWidget);
    expect(find.byType(SelectableGalleryTile), findsNothing);
  });

  testWidgets('카테고리 드롭다운에서 스타일일지 선택 시 스타일일지 메인(/style-log)으로 실제 이동한다', (tester) async {
    await pumpClosetMain(tester);

    await selectCategory(tester, '스타일일지');

    expect(find.text('스타일일지 메인'), findsOneWidget);
    expect(find.byType(SelectableGalleryTile), findsNothing);
  });

  testWidgets('FAB 탭 시 "한 장/여러 장 추가하기" 펼침 메뉴가 나타나고, 다시 탭하면 접힌다', (tester) async {
    await pumpClosetMain(tester);

    // 초기 상태(접힘)에는 옵션 라벨이 보이지 않아야 한다.
    expect(find.text('한 장 추가하기'), findsNothing);
    expect(find.text('여러 장 추가하기'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('한 장 추가하기'), findsOneWidget);
    expect(find.text('여러 장 추가하기'), findsOneWidget);
    // 펼침 상태에서도 여전히 옷장 메인 화면(이동하지 않음).
    expect(find.byType(SelectableGalleryTile), findsNWidgets(12));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('한 장 추가하기'), findsNothing);
    expect(find.text('여러 장 추가하기'), findsNothing);
  });

  testWidgets('FAB 펼침 상태에서 계절을 전체→특정 계절로 바꾸면 옵션 라벨이 "이 분류에 ~"로 바뀐다', (tester) async {
    await pumpClosetMain(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('한 장 추가하기'), findsOneWidget);
    expect(find.text('여러 장 추가하기'), findsOneWidget);

    await selectSeason(tester, '여름');

    expect(find.text('이 분류에 한 장 추가하기'), findsOneWidget);
    expect(find.text('이 분류에 여러 장 추가하기'), findsOneWidget);
    expect(find.text('한 장 추가하기'), findsNothing);
    expect(find.text('여러 장 추가하기'), findsNothing);

    await selectSeason(tester, '전체');

    expect(find.text('한 장 추가하기'), findsOneWidget);
    expect(find.text('여러 장 추가하기'), findsOneWidget);
    expect(find.text('이 분류에 한 장 추가하기'), findsNothing);
  });

  testWidgets('FAB 펼침 메뉴에서 옵션을 탭하면 /closet/add 로 이동한다', (tester) async {
    await pumpClosetMain(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('한 장 추가하기'));
    await tester.pumpAndSettle();

    expect(find.text('옷 추가하기'), findsOneWidget);
    expect(find.byType(SelectableGalleryTile), findsNothing);
  });

  testWidgets('그리드 아이템 탭 시 올바른 id로 /closet/:id 이동한다', (tester) async {
    await pumpClosetMain(tester);

    // c01(플로럴 원피스)은 isIncomplete=false라 탭 가능한 아이템.
    await tester.tap(find.byKey(const ValueKey('c01')));
    await tester.pumpAndSettle();

    expect(find.text('옷 상세 c01'), findsOneWidget);
  });

  testWidgets('그리드 타일 라벨이 상품명이 아닌 옷 종류(카테고리)로 표시된다', (tester) async {
    await pumpClosetMain(tester);

    // c01(플로럴 원피스), c08(슬립 드레스)은 둘 다 category=dress → "원피스" 라벨.
    expect(find.text('원피스'), findsNWidgets(2));
    // 상품명 자체는 화면 어디에도 노출되지 않아야 한다.
    expect(find.text('플로럴 원피스'), findsNothing);
    expect(find.text('슬립 드레스'), findsNothing);
  });
}
