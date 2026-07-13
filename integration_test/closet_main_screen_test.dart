import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/theme/app_spacing.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

/// Task 7(옷장 메인 화면) 검증. Review 통과분(commit 8145d3f) 대상 Tester 시나리오.
/// Task 1(Season enum 4종→3종 개편, commit fb15a84) 재검증 시 계절 드롭다운 순서 assertion 추가.
/// Task 2(Design Tokens 확정, commit 6505fea/46052bc) 재검증 시 밀도 순환 방향이
/// 오름차순(3→5→1)에서 내림차순(5→3→1)으로 반전되어 순환 테스트 3개의 기대값을 갱신.
/// Task 3(화면 레이아웃 재구축, commit e91d059+5bea4bd) 재검증 시:
/// - 카테고리 드롭다운(옷장/코디/스타일일지) 이동 시나리오 2개 신설.
/// - FAB가 탭 즉시 이동하지 않고 "한 장/여러 장 추가하기" 펼침 메뉴부터 뜨는 것으로 동작이
///   바뀌어(의도된 변화), 기존 "FAB 탭 시 /closet/add 로 정확히 이동한다" 테스트를
///   펼침→옵션탭→이동 흐름으로 갱신하고, 펼침/접힘 토글·계절별 라벨 전환 테스트를 신설.
/// - 그리드 타일 라벨이 상품명 대신 옷 종류로 바뀐 것을 확인하는 테스트 신설.
/// 밀도 값 변경(commit 8b6bcab, AppDensity.min/mid/max = 1/3/5 → 1/2/4, 순환 방향은
/// 그대로 내림차순) 재검증 시:
/// - 순환 테스트 3개의 기대값을 3→1→5→3 계열에서 2→1→4→2 계열로 갱신(화면 기본값이
///   mid=2로 바뀌어 실제 탭 시퀀스는 2(시작)→1→4→2).
/// - 기본 밀도가 mid(2, 2컬럼)로 바뀌면서 12개 mock 아이템 전부가 한 화면에 들어가려면
///   행이 늘어나(2컬럼×6행) 이전 physicalSize(1400×3000)로는 부족해짐 → height를
///   실측으로 늘려 12개 전부 lazy-build 되도록 조정.
///
/// 아래는 라벨박스 크기조절 리팩터(commit 0da0cee+30a90e5)와 ColorPalette 리팩터
/// (commit 399d3ef) 재검증 시 신설한 테스트(16~19번). 기존 1~15번은 위 이력 그대로이며
/// 재확인 결과(2026-07-12) 현재 코드(Season 3종, AppDensity.levels=[1,2,4]) 기준으로도
/// 그대로 유효해 별도 갱신이 필요하지 않았다.
///
/// 아래는 하단 좌측 뒤로가기 버튼(`_FrostedBackButton`, Review 통과분 P2 2건 비차단) 검증 시
/// 신설한 테스트(20~22번). Review가 지적한 대로 `app_router.dart`가 flat GoRoute 목록이라
/// 정상 UI 플로우에서는 `ClosetMainScreen` 위에 아무것도 push되지 않아 `canPop()`이 평소
/// 항상 false다(체크리스트에 기록된 의도된 임시 상태). 20번은 이 평소 상태를 확인하고,
/// 21~22번은 `GoRouter.of(context).push(AppRoute.closetMain)`으로 `canPop()==true` 상황을
/// 인위적으로 만들어 버튼 노출·pop 동작·기존 컨트롤과의 회귀 없음을 확인한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpClosetMain(WidgetTester tester) async {
    // 12개 아이템이 스크롤 없이 한 화면에 모두 빌드되도록 뷰포트를 충분히 키운다
    // (실제 창 크기 제약 때문에 GridView.builder가 화면 밖 아이템을 지연 생성하지 않게 함).
    // 기본 밀도가 mid(2컬럼)라 타일이 커지고 12개가 6행에 걸쳐 배치되므로, 이전(3000)보다
    // 훨씬 큰 세로 길이가 필요하다(실측으로 결정한 값).
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

  /// SelectableGalleryTile 하나만 정사각형 타일(tileSize x tileSize) 안에 격리해서
  /// 렌더링한다. 라벨박스 크기조절 로직을 mock 데이터에 없는 카테고리(가방·액세서리 등)로도
  /// 검증하기 위한 최소 하네스 — 실제 위젯 코드(SelectableGalleryTile)를 그대로 구동한다.
  Future<void> pumpIsolatedTile(WidgetTester tester, ClothingItem item, double tileSize) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: SelectableGalleryTile(item: item, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('밀도 토글 아이콘이 4→2→1→4 순으로 그리드 컬럼 수와 아이콘을 함께 바꾼다 (탭 사이 프레임 반영 O)', (tester) async {
    await pumpClosetMain(tester);

    // Task 2에서 순환 방향이 내림차순으로 반전되었고, 이번 밀도 값 변경(1/3/5→1/2/4)으로
    // 화면 기본값이 mid(2)이라 실제 탭 시퀀스는 2(시작, view_comfy) → 1(crop_square)
    // → 4(grid_view) → 2(view_comfy)이다.
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
  });

  testWidgets(
    '[회귀 고정] 밀도 아이콘을 프레임 반영 없이 2번 연속 탭해도 4→2→1 순환이 깨지지 않는다 '
    '(stale-closure race, fixed in 10d3643)',
    (tester) async {
      final container = await pumpClosetMain(tester);

      // 비정형 사용 흐름: 탭 사이에 pump()를 넣지 않아, 실제 프레임 렌더링(위젯 리빌드)이
      // 반영되기 전에 연속으로 탭하는 상황(예: 프레임 드랍 중 빠른 연타)을 재현한다.
      // 과거에는 onPressed 클로저가 build() 시점에 캡처된 density 지역 변수를 참조해,
      // 리빌드가 끼어들지 않으면 각 탭이 매번 "같은 이전 값 기준"으로 next를 계산해
      // 순환하지 않고 첫 탭이 계산한 값에 멈추는 결함이 있었다(commit 10d3643에서
      // onPressed 내부에서 ref.read로 최신값을 다시 조회하도록 수정되어 해결됨). 이 테스트는
      // 그 수정이 회귀하지 않는지를, 새 밀도 값(1/2/4) 기준 순환 방향(2→1→4)으로 고정한다.
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();

      // 기본값 2에서 시작해 순환 로직대로면 두 번째 탭 후 4여야 한다(2→1→4).
      expect(
        container.read(closetDensityProvider),
        4,
        reason: '프레임 반영 없이 연속 탭해도 순환 로직(2→1→4)대로 진행되어야 한다.',
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

      // 기본값 2에서 시작해 2→1→4→2→1→4 순환대로면 5회 탭 후 4여야 한다.
      expect(
        container.read(closetDensityProvider),
        4,
        reason: '순환 로직대로면 5회 탭 후 4여야 한다.',
      );
    },
  );

  testWidgets('카테고리 드롭다운에서 코디 선택 시 코디 메인(/composition)으로 실제 이동한다', (tester) async {
    await pumpClosetMain(tester);

    await selectCategory(tester, '코디');

    expect(find.byType(CompositionMainScreen), findsOneWidget);
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

  // ── 아래부터 라벨박스 크기조절 리팩터(0da0cee+30a90e5) 검증 ──────────────────

  testWidgets(
    '짧은 카테고리 라벨(상의)은 넓은 타일(300px)에서도 텍스트 크기만큼만 좁게 표시되고 '
    '타일 전체 폭을 채우지 않는다',
    (tester) async {
      const item = ClothingItem(
        id: 'label-short',
        name: '테스트용 상의',
        category: ClothingCategory.top,
        color: 'white',
        season: Season.springFall,
        material: ClothingMaterial.cotton,
        imagePath: '',
      );
      await pumpIsolatedTile(tester, item, 300);

      expect(tester.takeException(), isNull);
      expect(find.text('상의'), findsOneWidget);

      final labelBoxFinder = find.descendant(
        of: find.byType(SelectableGalleryTile),
        matching: find.byType(ConstrainedBox),
      );
      expect(labelBoxFinder, findsOneWidget);

      final labelWidth = tester.getRect(labelBoxFinder).width;
      // 예전(고정폭) 구조였다면 300 - AppSpacing.xxs*2 = 292에 가까운 폭이 됐을 것.
      // 지금은 텍스트("상의" 2글자, labelSmall 11px) + 좌우 패딩만큼만 차지해야 한다.
      expect(
        labelWidth,
        lessThan(100),
        reason: '라벨박스가 타일 폭(300)을 채우지 않고 텍스트 크기에 맞춰 좁게 표시되어야 한다. 실측 폭=$labelWidth',
      );
    },
  );

  testWidgets(
    '가장 긴 카테고리 라벨("가방·액세서리")을 가진 아이템이 밀도4 상당의 좁은 타일(50px)에서도 '
    '타일 경계를 넘어 튀어나오지 않고 ellipsis로 실제 truncation이 일어난다',
    (tester) async {
      const item = ClothingItem(
        id: 'label-long',
        name: '테스트용 가방',
        category: ClothingCategory.bagAccessory,
        color: 'black',
        season: Season.springFall,
        material: ClothingMaterial.cotton,
        imagePath: '',
      );

      // 1) 넉넉한 타일(500px)에서 이 라벨의 "자연 폭"(줄바꿈/잘림 없이 필요한 실제 폭)을 먼저 측정.
      await pumpIsolatedTile(tester, item, 500);
      final labelBoxFinder = find.descendant(
        of: find.byType(SelectableGalleryTile),
        matching: find.byType(ConstrainedBox),
      );
      final naturalWidth = tester.getRect(labelBoxFinder).width;

      // 2) 같은 아이템을 밀도4 상당의 좁은 타일(50px)에 다시 그린다.
      await pumpIsolatedTile(tester, item, 50);

      // 오버플로 렌더 에러(RenderFlex overflowed 등) 없이 크래시 없이 렌더링되어야 한다.
      expect(tester.takeException(), isNull);

      final tileRect = tester.getRect(find.byType(SelectableGalleryTile));
      expect(labelBoxFinder, findsOneWidget);
      final labelRect = tester.getRect(labelBoxFinder);
      final constrainedWidth = labelRect.width;

      // 자연 폭이 50px 타일의 여유 폭보다 커야, 실제로 이 테스트가 "잘림"을 검증하는 게 된다
      // (아니라면 그냥 우연히 다 들어간 것이지 ellipsis 로직을 검증한 게 아니다).
      final available = 50 - AppSpacing.xxs * 2;
      expect(
        naturalWidth,
        greaterThan(available),
        reason: '이 텍스트의 자연 폭($naturalWidth)이 좁은 타일의 여유 폭($available)보다 커야 '
            'ellipsis 잘림이 실제로 검증된다. 그렇지 않다면 타일이 이미 충분히 넓다는 뜻.',
      );

      // 라벨박스가 타일의 우측 경계를 넘지 않아야 한다(ConstrainedBox의
      // maxWidth: constraints.maxWidth - AppSpacing.xxs*2 로 제한된 만큼).
      expect(
        labelRect.right,
        lessThanOrEqualTo(tileRect.right + 0.5),
        reason: '라벨박스 우측 끝이 타일 경계를 넘으면 안 된다. tileRect=$tileRect labelRect=$labelRect',
      );
      expect(
        constrainedWidth,
        lessThanOrEqualTo(available + 0.5),
        reason: 'ConstrainedBox maxWidth 제약(타일폭 - xxs*2)을 넘으면 안 된다.',
      );
    },
  );

  testWidgets(
    '실제 mock 아이템(c04, 아우터)의 라벨이 밀도 2→1→4 전환 전 구간에서 항상 타일 경계 안에 들어맞고 '
    '크래시 없다 (밀도4=가장 좁은 타일에서 가장 위험)',
    (tester) async {
      await pumpClosetMain(tester);

      Future<void> assertLabelFitsTile() async {
        expect(tester.takeException(), isNull);
        final tileFinder = find.byKey(const ValueKey('c04'));
        expect(tileFinder, findsOneWidget);
        final tileRect = tester.getRect(tileFinder);
        final labelBoxFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(ConstrainedBox),
        );
        expect(labelBoxFinder, findsOneWidget);
        final labelRect = tester.getRect(labelBoxFinder);

        expect(labelRect.left, greaterThanOrEqualTo(tileRect.left - 0.5));
        expect(labelRect.right, lessThanOrEqualTo(tileRect.right + 0.5));
        expect(labelRect.top, greaterThanOrEqualTo(tileRect.top - 0.5));
        expect(labelRect.bottom, lessThanOrEqualTo(tileRect.bottom + 0.5));
      }

      // 기본값 mid(2)에서 시작. c04(트렌치코트)는 category=outer → "아우터" 라벨
      // (c09 레더 재킷도 같은 카테고리라 텍스트 자체는 화면에 2개 있으므로, 텍스트가
      // 아니라 c04 타일 하나로 범위를 좁혀서 검증한다).
      await assertLabelFitsTile();

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(crossAxisCount(tester), 1);
      await assertLabelFitsTile();

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(crossAxisCount(tester), 4);
      await assertLabelFitsTile();
    },
  );

  // ── 아래부터 ColorPalette 리팩터(399d3ef) 검증 ──────────────────────────────

  testWidgets(
    'ColorPalette 리팩터 후에도 옷장 메인 실제 렌더링 색상이 팔레트 리팩터 이전 고정값과 '
    '동일하고, 테마 적용이 크래시 없이 된다',
    (tester) async {
      await pumpClosetMain(tester);

      expect(tester.takeException(), isNull);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      final colorScheme = Theme.of(context).colorScheme;
      final semantic = Theme.of(context).extension<AppSemanticColors>()!;

      // Decision.md: "이번 결정으로 색이 바뀐 것은 아니다"(activePalette가 여전히
      // current를 가리킴) — 리팩터 이전 하드코딩 값과 실제 런타임 값이 일치해야 한다.
      expect(colorScheme.primary, const Color(0xFF394550));
      expect(colorScheme.onPrimary, const Color(0xFFF7F6F3));
      expect(colorScheme.secondary, const Color(0xFFC5D3C7));
      expect(colorScheme.surface, const Color(0xFFF7F6F3));
      expect(colorScheme.onSurface, const Color(0xFF2B2D30));

      expect(semantic.gray50, const Color(0xFFF7F6F3));
      expect(semantic.gray100, const Color(0xFFDDD4C8));
      expect(semantic.gray200, const Color(0xFFCBC0B0));
      expect(semantic.background, const Color(0xFFF7F6F3));
      expect(semantic.onBackground, const Color(0xFF2B2D30));
      expect(semantic.primaryLight, const Color(0xFFC5D3C7));
      expect(semantic.accent, const Color(0xFFC5D3C7));

      // 실제 타일 배경(semantic.gray200)이 런타임에 그 값 그대로 렌더링되는지도 확인.
      final tileContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(SelectableGalleryTile).first,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = tileContainer.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFCBC0B0));
    },
  );

  // ── 아래부터 하단 좌측 뒤로가기 버튼(_FrostedBackButton) 검증 ─────────────────

  Finder backButtonFinder() => find.byTooltip('뒤로가기');

  testWidgets(
    '평소 상태(앱 최초 진입, 스택 최상단이면서 canPop()==false)에서는 뒤로가기 버튼이 '
    '위젯 트리에 렌더링되지 않는다',
    (tester) async {
      await pumpClosetMain(tester);

      expect(backButtonFinder(), findsNothing);
    },
  );

  testWidgets(
    '옷장 메인 위에 다른 화면이 push된 상태에서 그 위에 옷장 메인을 다시 push하면 '
    '(canPop()==true) 뒤로가기 버튼이 나타나고, 탭하면 실제 context.pop()이 동작해 '
    '바로 아래 화면(옷 상세)으로 돌아간다',
    (tester) async {
      await pumpClosetMain(tester);

      // 1) 정상 UI 플로우로 상세 화면을 push한다. 이 시점에는 옷장 메인이 스택 최하단이라
      // 뒤로가기 버튼이 검증 대상이 아니다 — 아래 2)에서 canPop()==true 상황을 만들기 위한
      // 준비 단계(옷장 메인 "아래"에 화면을 하나 깔아 둠).
      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      expect(find.text('옷 상세 c01'), findsOneWidget);

      // 2) Review가 지적한 라우터 토폴로지 문제(flat GoRoute 목록, 카테고리 전환은
      // context.go()로 스택을 교체) 때문에 정상 UI 플로우만으로는 옷장 메인 위에 아무것도
      // 쌓이지 않는다. 옷 상세 화면(현재 최상단) 위에 옷장 메인을 인위적으로 한 번 더
      // push해, "옷장 메인이 최상단이면서 아래에 다른 화면이 있는" 상황을 만든다.
      final detailContext = tester.element(find.text('옷 상세 c01'));
      GoRouter.of(detailContext).push(AppRoute.closetMain);
      await tester.pumpAndSettle();

      // 3) 새로 push된 옷장 메인 인스턴스가 최상단에 보이고, 뒤로가기 버튼이 정확히 1개
      // 나타난다(스택 아래 깔린 이전 옷장 메인 인스턴스가 아니라 최상단 인스턴스만).
      expect(find.byType(SelectableGalleryTile), findsNWidgets(12));
      expect(backButtonFinder(), findsOneWidget);

      // 4) 탭하면 context.pop()이 실제로 동작해 바로 아래(옷 상세 c01)로 돌아간다.
      await tester.tap(backButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text('옷 상세 c01'), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNothing);
    },
  );

  testWidgets(
    '뒤로가기 버튼이 보이는 상태(canPop()==true)에서도 기존 FAB 펼침/접힘, 밀도 토글, '
    '계절 필터, 카테고리 이동이 회귀 없이 그대로 동작한다',
    (tester) async {
      await pumpClosetMain(tester);

      await tester.tap(find.byKey(const ValueKey('c01')));
      await tester.pumpAndSettle();
      final detailContext = tester.element(find.text('옷 상세 c01'));
      GoRouter.of(detailContext).push(AppRoute.closetMain);
      await tester.pumpAndSettle();

      expect(backButtonFinder(), findsOneWidget);

      // FAB 펼침 — 뒤로가기 버튼(좌하단)과 FAB(우하단)는 서로 다른 위치라 레이아웃
      // 충돌 없이 공존해야 한다.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('한 장 추가하기'), findsOneWidget);
      expect(find.text('여러 장 추가하기'), findsOneWidget);
      expect(backButtonFinder(), findsOneWidget);

      // FAB 접힘.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('한 장 추가하기'), findsNothing);
      expect(backButtonFinder(), findsOneWidget);

      // 밀도 토글 정상 동작(기본값 2 → 1).
      expect(crossAxisCount(tester), 2);
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(crossAxisCount(tester), 1);
      expect(backButtonFinder(), findsOneWidget);

      // 계절 필터 정상 동작(여름 선택 시 3개로 축소).
      await selectSeason(tester, '여름');
      expect(find.byType(SelectableGalleryTile), findsNWidgets(3));
      expect(backButtonFinder(), findsOneWidget);

      // 카테고리 드롭다운으로 다른 화면 이동(context.go, 스택 전체 교체)도 회귀 없이 동작.
      await selectCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.byType(SelectableGalleryTile), findsNothing);
    },
  );
}
