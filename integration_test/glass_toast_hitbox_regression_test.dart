import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';
import 'package:digittal_wardrobe/widgets/glass_pill.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Tester가 직접 설계한 `GlassToast` 히트박스 축소 fix(`Center(child: IntrinsicWidth(...))`
/// 도입, `lib/widgets/glass_toast.dart`) 런타임 회귀 검증.
///
/// Worker/Review가 이미 커버한 축(단위 테스트 `test/widgets/glass_toast_test.dart`의 pill
/// 바깥 히트테스트 통과 확인, `integration_test/trash_execution_test.dart`의 "휴지통 다중선택
/// [복원] 직후 뒤로가기" 케이스)과 겹치지 않게, 아래 축만 추가로 다룬다:
/// 1) 액션 버튼이 있는 GlassToast(실행취소)가 떠 있는 동안에도, 트러시가 아닌 다른 화면
///    (스타일일지 메인, 실제 라우트 push 기준)에서 뒤로가기가 실제로 동작하는지
/// 2) 그 실행취소 버튼 자체가(히트박스가 pill 크기로 줄어든 뒤에도) 실제로 눌리는지
/// 3) 토스트가 떠 있는 동안 같은 화면 하단의 다른 인터랙티브 요소(FAB, 휴지통 필터칩)가
///    여전히 정상 동작하는지
/// 4) pill의 실제 렌더 크기/위치가 화면 폭 전체로 늘어나지 않고 하단 중앙 부근에 위치하는지
/// 5) 액션 없는 토스트를 방치하면 ~4초 뒤 실제로 자동 소멸하는지(회귀 없음)
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

  testWidgets(
    '스타일일지 메인에서 다중선택 [삭제] 직후(실행취소 액션이 있는 GlassToast가 떠 있는 4초 '
    '타이머 동안) 즉시 뒤로가기 버튼을 눌러도 실제로 이전 화면(옷장 메인)으로 돌아간다 — '
    '휴지통이 아닌 다른 화면, 액션 버튼이 있는 토스트 조합에서도 히트박스 fix가 재현되는지 확인',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogMainScreen), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('삭제'));
      // pumpAndSettle 대신 pump() 한 번만 — toast의 4초 자동소멸 타이머를 기다리지 않고
      // toast(실행취소 액션 포함)가 떠 있는 채로 바로 뒤로가기를 누른다.
      await tester.pump();

      expect(find.text('2개 항목이 휴지통으로 이동됨'), findsOneWidget, reason: '토스트가 아직 떠 있어야 한다');
      expect(find.text('실행취소'), findsOneWidget);
      expect(find.byType(FrostedBackButton), findsOneWidget, reason: '다중선택 종료로 뒤로가기 버튼이 다시 보여야 한다');

      await tester.tap(find.byType(FrostedBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(StyleLogMainScreen), findsNothing, reason: '뒤로가기가 실제로 동작해 스타일일지 메인을 벗어나야 한다');
      expect(find.byType(ClosetMainScreen), findsOneWidget);

      // 삭제 자체는 뒤로가기 여부와 무관하게 이미 반영돼 있어야 한다.
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isTrue);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02').isDeleted, isTrue);
    },
  );

  testWidgets(
    '같은 액션형 GlassToast가 떠 있는 동안(자동소멸 타이머 대기 없이) "실행취소" 버튼 자체를 '
    '탭하면 실제로 복원되고 토스트가 즉시 닫힌다 — 히트박스가 pill 크기로 줄어든 뒤에도 pill '
    '내부 버튼은 정상적으로 눌린다',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pump();
      expect(find.text('실행취소'), findsOneWidget, reason: '토스트가 아직 떠 있어야 한다');

      await tester.tap(find.text('실행취소'));
      await tester.pump();

      expect(find.text('실행취소'), findsNothing, reason: '실행취소 탭으로 토스트가 즉시 닫혀야 한다');
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isFalse);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02').isDeleted, isFalse);
    },
  );

  testWidgets(
    '토스트(실행취소 액션 포함)가 떠 있는 동안에도 화면 하단 우측의 FAB(추가 버튼)는 여전히 '
    '정상 동작한다(같은 화면 하단 영역의 다른 인터랙티브 요소가 잘못 막히지 않는지 확인)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pump();
      // FAB는 다중선택 종료와 동시에 null→non-null로 바뀌어 Scaffold 자체의 내장
      // 등장 트랜지션(스케일인)을 탄다 — 그 트랜지션이 완전히 끝나야 실제 히트테스트
      // 가능한 위치/크기가 확정된다. 토스트의 4초 자동소멸보다 훨씬 짧은(300ms) 시간만
      // 흘려보내 "토스트는 여전히 떠 있지만 FAB 트랜지션은 끝난" 상태를 만든다.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('실행취소'), findsOneWidget, reason: '토스트가 아직 떠 있어야 한다(다중선택 종료로 FAB도 이미 다시 보임)');
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('1카드 추가'), findsOneWidget, reason: 'FAB 탭이 토스트에 가로채이지 않고 실제로 옵션을 펼쳐야 한다');
      expect(find.text('여러카드에 분할 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '휴지통 다중선택 [복원] 직후(액션 없는 GlassToast가 떠 있는 동안) 카테고리 필터칩을 눌러도 '
    '실제로 필터링된다 — 같은 화면 하단 영역의 다른 인터랙티브 요소(필터칩)가 토스트에 가로채이지 '
    '않는지 확인(트러시 화면 전용 축)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();
      // mock 기본 삭제 항목: c07/c08(옷장), comp02(코디) — 3개.
      expect(find.byType(TrashGalleryTile), findsNWidgets(3));

      final tiles = find.byType(TrashGalleryTile);
      await tester.longPress(tiles.first); // c07 자동 선택 + 다중선택 진입
      await tester.pumpAndSettle();
      await tester.tap(tiles.at(1)); // c08 추가 선택
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      await tester.tap(find.text('복원'));
      // pumpAndSettle 대신 pump() 한 번만 — toast(액션 없음)가 떠 있는 채로 바로 필터칩을
      // 누른다. 필터칩은 (FAB와 달리) Scaffold 내장 트랜지션 없이 처음부터 항상 렌더링되어
      // 있던 위치이므로 추가 pump 없이도 안정적으로 히트테스트 가능하다.
      await tester.pump();
      expect(find.text('2개 항목이 복원됨'), findsOneWidget, reason: '토스트가 아직 떠 있어야 한다');

      await tester.tap(find.text('코디'));
      await tester.pumpAndSettle();

      expect(
        find.byType(TrashGalleryTile),
        findsOneWidget,
        reason: '필터칩 탭이 토스트에 가로채이지 않고 실제로 코디(comp02) 1개로 좁혀야 한다',
      );
      final closetItems = container.read(closetItemsProvider);
      expect(closetItems.firstWhere((i) => i.id == 'c07').isDeleted, isFalse);
      expect(closetItems.firstWhere((i) => i.id == 'c08').isDeleted, isFalse);
    },
  );

  testWidgets(
    '액션형 GlassToast의 pill은 화면 폭 전체로 늘어나지 않고 실제 콘텐츠 크기만큼만 렌더링되며, '
    '화면 하단 중앙 부근에 위치한다(레이아웃 회귀 확인 — 히트박스만 좁아지고 시각적으로는 '
    '찌그러지거나 잘못된 위치로 옮겨가지 않았는지)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pump();

      const message = '2개 항목이 휴지통으로 이동됨';
      expect(find.text(message), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget, reason: '메시지+액션 버튼 둘 다 잘리지 않고 실제로 보여야 한다');

      final toastPill = find.ancestor(of: find.text(message), matching: find.byType(GlassPill)).first;
      final pillSize = tester.getSize(toastPill);
      final pillCenter = tester.getCenter(toastPill);
      final screenSize = tester.view.physicalSize; // devicePixelRatio 1.0이라 logical과 동일.

      expect(pillSize.width, lessThan(screenSize.width * 0.9), reason: 'pill이 화면 폭 전체로 늘어나면 안 된다');
      expect(
        pillCenter.dx,
        closeTo(screenSize.width / 2, screenSize.width * 0.1),
        reason: '가로 중앙 부근에 위치해야 한다',
      );
      expect(pillCenter.dy, greaterThan(screenSize.height * 0.8), reason: '화면 하단 부근에 위치해야 한다');
    },
  );

  testWidgets(
    '액션 버튼이 없는 GlassToast(휴지통 [복원])를 그대로 방치하면 ~4초 뒤 실제로 자동 소멸한다'
    '(히트박스 fix가 자동소멸 자체를 깨지 않았는지 회귀 확인)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final tiles = find.byType(TrashGalleryTile);
      await tester.longPress(tiles.first);
      await tester.pumpAndSettle();
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('복원'));
      await tester.pump();
      expect(find.text('2개 항목이 복원됨'), findsOneWidget, reason: '탭 직후엔 토스트가 떠 있어야 한다');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('2개 항목이 복원됨'), findsNothing, reason: '~4초 뒤 자동으로 소멸해야 한다');
    },
  );
}
