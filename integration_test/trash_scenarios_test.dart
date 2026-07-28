import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
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

  Color? chipBackground(WidgetTester tester, String label) {
    final button = tester.widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)).first,
    );
    return button.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  testWidgets(
    '카테고리 필터칩 4개(전체/옷장/코디/스타일일지)를 각각 탭하면 그리드가 해당 도메인으로만 '
    '실제로 좁혀지고, 활성 칩만 배경색이 primaryLight로 바뀐다',
    (tester) async {
      final container = await pumpApp(tester);
      // mock_data 기본 삭제 항목: c07/c08(옷장), comp02(코디) — 3개 도메인을 다 검증하기 위해
      // log01(스타일일지)을 추가로 소프트삭제한다.
      container.read(styleLogsProvider.notifier).softDeleteMany({'log01'});
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final semantic = Theme.of(tester.element(find.byType(TrashMainScreen))).extension<AppSemanticColors>()!;

      expect(find.byType(TrashGalleryTile), findsNWidgets(4));
      expect(chipBackground(tester, '전체'), semantic.primaryLight, reason: '기본 필터는 전체가 활성 상태여야 한다');

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(2), reason: '옷장 항목(c07,c08) 2개만 남아야 한다');
      expect(chipBackground(tester, '옷장'), semantic.primaryLight);
      expect(chipBackground(tester, '전체'), isNot(semantic.primaryLight));

      await tester.tap(find.text('코디'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(1), reason: '코디 항목(comp02) 1개만 남아야 한다');
      expect(chipBackground(tester, '코디'), semantic.primaryLight);

      await tester.tap(find.text('스타일일지'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(1), reason: '스타일일지 항목(log01) 1개만 남아야 한다');
      expect(chipBackground(tester, '스타일일지'), semantic.primaryLight);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashGalleryTile), findsNWidgets(4));
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
}
