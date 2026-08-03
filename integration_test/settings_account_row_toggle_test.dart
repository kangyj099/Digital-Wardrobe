import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/settings_screen.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// `04_설정.md` §2 로우4/§3(2026-08-04 갱신) + `Decision.md`("설정 화면 '로그인' 진입점
/// 위치 확정") 검증. `settings_trash_shell_test.dart`가 이미 다루는 "로그아웃 탭 → Toast
/// 뜸"/"실행취소 탭 → Toast 닫힘"과 겹치지 않게, 이번 변경의 핵심인 **로우 라벨/아이콘 전환
/// 타이밍**(탭 즉시 vs Undo 만료 시점 — Review가 초기 구현의 타이밍 반전을 지적해 정정된
/// 부분)과 "로그인" 상태의 placeholder 다이얼로그를 중심으로 다룬다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const viewportSize = Size(390, 800);

  Future<ProviderContainer> pumpAppAndPush(WidgetTester tester) async {
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SelectableGalleryTile).first);
    GoRouter.of(context).push(AppRoute.settingsMain);
    await tester.pumpAndSettle();
    return container;
  }

  Color? errorIconColor(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(Icons.logout)).color;

  testWidgets('초기 상태: "로그아웃" 로우 1개만 보이고, Error 색상 아이콘+텍스트가 적용된다', (tester) async {
    await pumpAppAndPush(tester);

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('로그인'), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byIcon(Icons.login), findsNothing);

    final context = tester.element(find.byType(SettingsScreen));
    expect(errorIconColor(tester), Theme.of(context).colorScheme.error);
  });

  testWidgets(
    '"로그아웃" 탭 → 딱 한 프레임만 지난 시점에 이미 로우가 "로그인"으로 전환돼 있고, '
    '동시에 Toast(SnackBar)도 함께 보인다(로우 전환이 Toast 만료를 기다리지 않음)',
    (tester) async {
      await pumpAppAndPush(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pump(); // 한 프레임만 — Toast 등장 애니메이션/만료 타이머를 기다리지 않는다.

      expect(tester.takeException(), isNull);
      expect(find.text('로그인'), findsOneWidget, reason: 'Toast가 뜨는 것과 동시에 로우도 즉시 전환되어야 한다');
      expect(find.text('로그아웃'), findsNothing);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('로그아웃되었습니다'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);
    },
  );

  testWidgets('Toast의 "실행취소" 탭 → 로우가 다시 즉시 "로그아웃"으로 복원된다(Error 색상 포함)', (tester) async {
    await pumpAppAndPush(tester);

    await tester.tap(find.text('로그아웃'));
    await tester.pump();
    expect(find.text('로그인'), findsOneWidget);
    // Toast 등장 애니메이션을 끝까지 진행시켜(실제 화면 좌표에 정착) '실행취소' 탭이 hit-test에서
    // 어긋나지 않게 한다 — 즉시 전환 자체는 위 pump() 한 프레임으로 이미 별도 검증됨.
    await tester.pumpAndSettle();

    await tester.tap(find.text('실행취소'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('로그인'), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byIcon(Icons.login), findsNothing);

    final context = tester.element(find.byType(SettingsScreen));
    expect(errorIconColor(tester), Theme.of(context).colorScheme.error);

    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'Toast를 그냥 두고 시간 창(4초)이 만료되면 로우는 "로그인" 상태로 그대로 유지된다'
    '(이미 전환된 상태의 확정일 뿐, 추가 변화 없음)',
    (tester) async {
      await pumpAppAndPush(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pump();
      expect(find.text('로그인'), findsOneWidget);
      // Toast 등장 애니메이션이 끝나야 자동소멸 타이머가 실제로 카운트를 시작한다.
      await tester.pumpAndSettle();

      // Undo 없이 4초+여유를 흘려보내 SnackBar가 자연 만료되게 한다.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('로그인'), findsOneWidget, reason: '만료는 이미 적용된 전환을 확정할 뿐, 되돌리지 않는다');
      expect(find.text('로그아웃'), findsNothing);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
    },
  );

  testWidgets(
    '"로그인" 상태에서 그 로우 탭 → "기능 준비 중입니다." AlertDialog가 뜨고, "확인"으로 닫히며, '
    '로그인 상태는 그대로 유지된다(로우가 다시 "로그아웃"으로 바뀌지 않음)',
    (tester) async {
      await pumpAppAndPush(tester);

      // 먼저 로그아웃 상태로 전환(→ 로우 라벨 "로그인")해두고, Undo/만료를 기다리지 않는다.
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      expect(find.text('로그인'), findsOneWidget);

      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('기능 준비 중입니다.'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('로그인'), findsOneWidget, reason: '준비중 안내만 뜨고 로그인 상태가 바뀌면 안 된다');
      expect(find.text('로그아웃'), findsNothing);
    },
  );

  testWidgets(
    '비정형 흐름: 로그아웃 탭 직후(Toast가 떠 있는 도중) Toast를 무시하고 로우를 연속으로 '
    '빠르게 다시 탭해도 크래시 없이 동작하고, 계정 로우는 항상 정확히 1개만 보인다',
    (tester) async {
      await pumpAppAndPush(tester);

      await tester.tap(find.text('로그아웃'));
      await tester.pump(); // 로우 "로그인"으로 전환, Toast 등장 중
      expect(find.text('로그인'), findsOneWidget);

      // "로그인"으로 바뀐 로우를 Toast가 떠 있는 상태에서 바로 다시 탭 → placeholder 다이얼로그.
      await tester.tap(find.text('로그인'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      // 계정 섹션 로우는 여전히 정확히 1개("로그인")여야 한다 — 다이얼로그 텍스트 자체엔
      // "로그인"/"로그아웃" 단어가 없으므로 카운트가 로우 라벨과 혼동되지 않는다.
      expect(find.text('로그인'), findsOneWidget);
      expect(find.text('로그아웃'), findsNothing);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('로그인'), findsOneWidget);
      expect(find.text('로그아웃'), findsNothing);
    },
  );
}
