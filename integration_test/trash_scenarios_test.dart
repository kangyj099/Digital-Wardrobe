import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/providers/theme_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Tester가 직접 설계한 Task 10(휴지통 실행) 회귀 시나리오 — Worker의
/// `trash_execution_test.dart`/`settings_trash_shell_test.dart`가 이미 다룬 것(단일
/// 복원/다중선택 영구삭제/비우기 확인)과 겹치지 않는 축만 추가로 검증한다:
/// 카테고리 필터칩의 실제 좁힘+하이라이트, 복원 후 홈 화면 반영, 다른 도메인(스타일일지)
/// 영구삭제의 완전성, 다중선택 [복원](확인 없음), 필터 활성 상태에서의 다중선택 영향범위,
/// 0개 선택 시 하단 버튼 비활성 상태.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1400, 4600),
    bool darkTheme = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (darkTheme) container.read(themeModeProvider.notifier).set(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Color? chipBackground(WidgetTester tester, String label) {
    final button = tester.widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)).first,
    );
    return button.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  testWidgets(
    '카테고리 필터칩은 다중선택이다 — 여러 칩을 동시에 켜면 선택된 카테고리들의 합집합만 '
    '보이고, 각 칩은 독립적으로 토글되며(다른 칩에 영향 없음), "전체"를 탭하면 개별 선택이 '
    '전부 해제된다',
    (tester) async {
      final container = await pumpApp(tester);
      // mock_data 기본 삭제 항목: c07/c08(옷장), comp02(코디) — 3개 도메인을 다 검증하기 위해
      // log01(스타일일지)을 추가로 소프트삭제한다.
      container.read(styleLogsProvider.notifier).softDeleteMany({'log01'});
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final semantic = Theme.of(tester.element(find.byType(TrashMainScreen))).extension<AppSemanticColors>()!;

      expect(find.byType(TrashGalleryTile), findsNWidgets(4));
      expect(chipBackground(tester, '전체'), semantic.primaryLight, reason: '기본 필터는 전체가 활성 상태여야 한다(빈 Set)');

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(2), reason: '옷장 항목(c07,c08) 2개만 남아야 한다');
      expect(chipBackground(tester, '옷장'), semantic.primaryLight);
      expect(chipBackground(tester, '전체'), isNot(semantic.primaryLight));

      // 다중선택: "코디"를 추가로 켜면 "옷장"은 그대로 유지된 채 합집합(옷장+코디)이 보여야 한다.
      await tester.tap(find.text('코디'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(3), reason: '옷장(2)+코디(1) 합집합 3개가 보여야 한다');
      expect(chipBackground(tester, '옷장'), semantic.primaryLight, reason: '코디를 추가로 켜도 옷장 선택은 유지되어야 한다');
      expect(chipBackground(tester, '코디'), semantic.primaryLight);

      // "옷장"을 다시 탭해 해제하면 "코디"에는 영향 없이 옷장만 빠져야 한다(독립 토글).
      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(1), reason: '코디 항목(comp02) 1개만 남아야 한다');
      expect(chipBackground(tester, '옷장'), isNot(semantic.primaryLight));
      expect(chipBackground(tester, '코디'), semantic.primaryLight);

      await tester.tap(find.text('스타일일지'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(2), reason: '코디(comp02)+스타일일지(log01) 합집합 2개가 보여야 한다');
      expect(chipBackground(tester, '스타일일지'), semantic.primaryLight);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(4), reason: '"전체"는 개별 선택을 모두 해제해야 한다');
      expect(chipBackground(tester, '전체'), semantic.primaryLight);
      expect(chipBackground(tester, '코디'), isNot(semantic.primaryLight));
      expect(chipBackground(tester, '스타일일지'), isNot(semantic.primaryLight));
    },
  );

  testWidgets(
    '다크 테마에서도 필터칩의 선택 배경(primaryLight)이 기본 전경색(colorScheme.primary)과 '
    '같은 값으로 겹치지 않는다(Audit 2026-07-29: 다크 팔레트에서 둘이 동일값이라 칩 텍스트가 '
    '배경에 완전히 묻혔던 회귀)',
    (tester) async {
      final container = await pumpApp(tester, darkTheme: true);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(TrashMainScreen));
      final semantic = Theme.of(context).extension<AppSemanticColors>()!;
      final defaultForeground = Theme.of(context).colorScheme.primary;

      expect(chipBackground(tester, '전체'), semantic.primaryLight, reason: '기본 필터는 전체가 활성 상태여야 한다(빈 Set)');
      expect(
        semantic.primaryLight,
        isNot(defaultForeground),
        reason:
            'TextButton 기본 전경색(colorScheme.primary)과 배경색이 같으면 칩 텍스트가 배경에 '
            '완전히 묻힌다 — 다크 팔레트에서 이 둘이 우연히 같은 값이 되지 않아야 한다',
      );
    },
  );

  testWidgets(
    '휴지통에서 복원한 옷장 항목이 실제로 옷장 메인 화면에 다시 나타난다(도메인 간 데이터 '
    '일관성)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      // c07(옷장, 12일)이 첫 타일 — settings_trash_shell_test.dart와 동일 전제.
      await tester.tap(find.byType(TrashGalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.text('옷장 · 영구 삭제까지 12일'), findsOneWidget);

      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();

      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c07').isDeleted, isFalse);

      container.read(appRouterProvider).push(AppRoute.closetMain);
      await tester.pumpAndSettle();

      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/mock/IMG_4275.PNG')),
        findsOneWidget,
        reason: '복원된 c07(리넨 반바지)이 옷장 메인 그리드에 실제로 다시 보여야 한다',
      );
    },
  );

  testWidgets(
    '스타일일지 항목을 영구 삭제하면 styleLogsProvider 목록에서 완전히 사라진다(단순 재삭제가 '
    '아니라 실제 purge)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(styleLogsProvider.notifier).softDeleteMany({'log01'});
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      await tester.tap(find.text('스타일일지'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsOneWidget);

      await tester.tap(find.byType(TrashGalleryTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget, reason: '영구삭제는 확인 다이얼로그를 거쳐야 한다');
      await tester.tap(find.text('영구 삭제').last);
      await tester.pumpAndSettle();

      final logs = container.read(styleLogsProvider);
      expect(logs.any((l) => l.id == 'log01'), isFalse, reason: '목록에서 id 자체가 완전히 사라져야 한다(soft-delete 아님)');

      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '다중선택으로 옷장 항목 2개를 골라 [복원]하면 확인 다이얼로그 없이 즉시 복원되고 '
    '다중선택 모드가 종료된다',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      final tiles = find.byType(TrashGalleryTile);
      expect(tiles, findsNWidgets(2));

      await tester.longPress(tiles.first); // 진입과 동시에 첫 타일 자동 선택
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing, reason: '복원은 되돌릴 수 있어 확인 다이얼로그가 없어야 한다');
      final closetItems = container.read(closetItemsProvider);
      expect(closetItems.firstWhere((i) => i.id == 'c07').isDeleted, isFalse);
      expect(closetItems.firstWhere((i) => i.id == 'c08').isDeleted, isFalse);
      expect(find.text('선택'), findsOneWidget, reason: '다중선택 모드가 종료되어 일반 헤더로 돌아와야 한다');
    },
  );

  testWidgets(
    '카테고리 필터가 활성화된 상태로 다중선택하면 필터된 부분집합만 대상이 되고, 다른 '
    '도메인 항목은 영향받지 않는다',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      final tiles = find.byType(TrashGalleryTile);
      expect(tiles, findsNWidgets(2));

      await tester.longPress(tiles.first);
      await tester.pumpAndSettle();
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('영구 삭제'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('영구 삭제').last);
      await tester.pumpAndSettle();

      final closetItems = container.read(closetItemsProvider);
      expect(closetItems.any((i) => i.id == 'c07'), isFalse);
      expect(closetItems.any((i) => i.id == 'c08'), isFalse);

      // comp02(코디)는 옷장 필터 다중선택/영구삭제의 영향을 받지 않고 휴지통에 그대로 남아야 한다.
      final compositions = container.read(compositionsProvider);
      expect(compositions.firstWhere((c) => c.id == 'comp02').isDeleted, isTrue);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsOneWidget, reason: '옷장 2개는 사라지고 코디 comp02 1개만 남아야 한다');
    },
  );

  testWidgets(
    '다중선택 모드에서 0개 선택 상태면 [복원]/[영구 삭제] 버튼이 흐리게 표시되고 탭해도 '
    '아무 동작 없이 크래시도 나지 않는다',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final tiles = find.byType(TrashGalleryTile);
      await tester.longPress(tiles.first); // 자동 선택됨(1개)
      await tester.pumpAndSettle();
      await tester.tap(tiles.first); // 다시 탭해 선택 해제 → 0개
      await tester.pumpAndSettle();
      expect(find.text('0개 선택'), findsOneWidget);

      final restoreButton = tester.widget<TextButton>(
        find.ancestor(of: find.text('복원'), matching: find.byType(TextButton)).first,
      );
      expect(restoreButton.onPressed, isNull);
      final restoreOpacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('복원'), matching: find.byType(Opacity)).first,
      );
      expect(restoreOpacity.opacity, 0.4);

      final purgeButton = tester.widget<TextButton>(
        find.ancestor(of: find.text('영구 삭제'), matching: find.byType(TextButton)).first,
      );
      expect(purgeButton.onPressed, isNull);
      final purgeOpacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('영구 삭제'), matching: find.byType(Opacity)).first,
      );
      expect(purgeOpacity.opacity, 0.4);

      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('영구 삭제'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(TrashGalleryTile), findsNWidgets(3), reason: '비활성 버튼 탭은 아무 항목도 지우거나 복원하지 않아야 한다');
      final closetItems = container.read(closetItemsProvider);
      expect(closetItems.firstWhere((i) => i.id == 'c07').isDeleted, isTrue);
    },
  );

  testWidgets(
    '좁은 화면(폭 300)에서 필터칩 4개(전체/옷장/코디/스타일일지)가 화면 밖으로 넘치지 않고 '
    '가로 스크롤 컨테이너 폭 안에 담기며, 실제로 좌우 드래그하면 스크롤되어 뒤에 가려졌던 '
    '칩까지 눌러 필터를 바꿀 수 있다',
    (tester) async {
      final container = await pumpApp(tester, size: const Size(300, 800));
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final scrollViewFinder = find.byType(SingleChildScrollView);
      expect(scrollViewFinder, findsOneWidget, reason: '필터칩 Row를 감싸는 가로 스크롤 컨테이너가 정확히 1개 있어야 한다');

      final viewportWidth = tester.getSize(scrollViewFinder).width;
      const screenWidth = 300.0;
      expect(
        viewportWidth,
        lessThanOrEqualTo(screenWidth),
        reason: '스크롤 컨테이너 자체는 화면 폭을 넘지 않도록 ConstrainedBox로 제약되어야 한다',
      );

      final chipsRowFinder = find.descendant(of: scrollViewFinder, matching: find.byType(Row)).first;
      final chipsRowWidth = tester.getSize(chipsRowFinder).width;
      expect(
        chipsRowWidth,
        greaterThan(viewportWidth),
        reason: '이 뷰포트에서는 칩 4개의 실제 내용 폭이 뷰포트보다 넓어야(=진짜로 넘치는 상황) 이 테스트가 의미가 있다',
      );

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: scrollViewFinder, matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.pixels, 0, reason: '초기 상태는 스크롤 안 된 맨 앞이어야 한다');

      await tester.drag(scrollViewFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(scrollable.position.pixels, greaterThan(0), reason: '가로 드래그로 실제 스크롤이 이동해야 한다');

      // 끝까지 스크롤된 상태에서 마지막 칩("스타일일지")이 실제로 탭 가능해야 한다(넘쳐서
      // 가려졌던 칩도 스크롤 후엔 눌러서 필터를 바꿀 수 있어야 함).
      await tester.tap(find.text('스타일일지'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final semantic = Theme.of(tester.element(find.byType(TrashMainScreen))).extension<AppSemanticColors>()!;
      final styleLogChip = tester.widget<TextButton>(
        find.ancestor(of: find.text('스타일일지'), matching: find.byType(TextButton)).first,
      );
      expect(
        styleLogChip.style?.backgroundColor?.resolve(<WidgetState>{}),
        semantic.primaryLight,
        reason: '스크롤 후 탭한 "스타일일지" 칩이 실제로 선택 상태(하이라이트)가 되어야 한다',
      );
      final compositions = container.read(compositionsProvider);
      expect(find.byType(TrashGalleryTile), findsNothing, reason: 'comp02(코디)만 삭제되어 있어 스타일일지 필터엔 항목이 없어야 한다');
      expect(compositions.firstWhere((c) => c.id == 'comp02').isDeleted, isTrue, reason: '필터 조작이 실제 데이터를 건드리지는 않아야 한다');
    },
  );
}
