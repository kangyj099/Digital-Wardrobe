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

  testWidgets('부팅 시 mock 옷 12개가 렌더링되고 미완성 배지 1개가 표시된다', (tester) async {
    await pumpClosetMain(tester);

    expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.text('미완성'), findsOneWidget);
  });

  testWidgets('계절 드롭다운에 전체 + 4개 계절 옵션이 실제로 나타난다', (tester) async {
    await pumpClosetMain(tester);

    await tester.tap(seasonDropdownFinder());
    await tester.pumpAndSettle();

    final values = tester
        .widgetList<DropdownMenuItem<Season?>>(find.byType(DropdownMenuItem<Season?>))
        .map((w) => w.value)
        .toSet();

    expect(values, {null, ...Season.values});
  });

  testWidgets('여름 계절 필터 선택 시 그리드가 3개로 줄어들고, 전체로 되돌리면 12개로 복원된다', (tester) async {
    await pumpClosetMain(tester);

    await selectSeason(tester, '여름');
    expect(find.byType(SelectableGalleryTile), findsNWidgets(3));

    await selectSeason(tester, '전체');
    expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
  });

  testWidgets('아이템이 0개인 겨울 계절 선택 시 크래시 없이 빈 그리드로 전환된다', (tester) async {
    await pumpClosetMain(tester);

    await selectSeason(tester, '겨울');

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectableGalleryTile), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('밀도 토글 아이콘이 3→5→1→3 순으로 그리드 컬럼 수를 바꾼다 (탭 사이 프레임 반영 O)', (tester) async {
    await pumpClosetMain(tester);

    expect(crossAxisCount(tester), 3);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 5);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 1);

    await tester.tap(find.byTooltip('그리드 밀도 전환'));
    await tester.pump();
    expect(crossAxisCount(tester), 3);
  });

  testWidgets(
    '[회귀 고정] 밀도 아이콘을 프레임 반영 없이 2번 연속 탭해도 3→5→1 순환이 깨지지 않는다 '
    '(stale-closure race, fixed in 10d3643)',
    (tester) async {
      final container = await pumpClosetMain(tester);

      // 비정형 사용 흐름: 탭 사이에 pump()를 넣지 않아, 실제 프레임 렌더링(위젯 리빌드)이
      // 반영되기 전에 연속으로 탭하는 상황(예: 프레임 드랍 중 빠른 연타)을 재현한다.
      // 과거에는 onPressed 클로저가 build() 시점에 캡처된 density 지역 변수를 참조해,
      // 리빌드가 끼어들지 않으면 각 탭이 매번 "같은 이전 값 기준"으로 next를 계산해
      // 3→5→1로 순환하지 않고 첫 탭이 계산한 값(5)에 멈추는 결함이 있었다(commit 10d3643에서
      // onPressed 내부에서 ref.read로 최신값을 다시 조회하도록 수정되어 해결됨). 이 테스트는
      // 그 수정이 회귀하지 않는지를 고정한다.
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();

      // 순환 로직대로라면 두 번째 탭 후 1이어야 한다.
      expect(
        container.read(closetDensityProvider),
        1,
        reason: '프레임 반영 없이 연속 탭해도 순환 로직(3→5→1)대로 진행되어야 한다.',
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

      // 3→5→1→3→5→1 순환대로 5회 후 1이어야 한다.
      expect(
        container.read(closetDensityProvider),
        1,
        reason: '순환 로직대로면 5회 탭 후 1이어야 한다.',
      );
    },
  );

  testWidgets('FAB 탭 시 /closet/add 로 정확히 이동한다', (tester) async {
    await pumpClosetMain(tester);

    await tester.tap(find.byType(FloatingActionButton));
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
}
