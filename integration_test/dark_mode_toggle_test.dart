import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/theme_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/settings_screen.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// 다크 모드 토글(Task) Tester 검증.
///
/// `themeModeProvider`(신규)가 `MaterialApp.themeMode`에 실제로 연결됐는지, Settings의
/// 다크모드 `Switch`를 탭했을 때 앱 전역 렌더링 테마(Brightness/배경색)가 실제로 바뀌는지를
/// 확인한다. `settings_trash_shell_test.dart`가 이미 두 Switch의 "탭하면 값이 반전된다"는
/// 확인했으므로(중복 방지), 이 파일은 그 토글이 실제 테마 렌더링에 반영되는지, 다른 화면에도
/// 일관되게 반영되는지, 화면 이동 후에도 세션 내 유지되는지, 빠른 연속 탭에도 깨지지 않는지에
/// 집중한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const defaultSize = Size(390, 800);

  Future<ProviderContainer> pumpAppAndPush(
    WidgetTester tester,
    String route,
  ) async {
    tester.view.physicalSize = defaultSize;
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
    GoRouter.of(context).push(route);
    await tester.pumpAndSettle();
    return container;
  }

  Finder darkSwitchFinder() => find.byType(Switch).at(1);
  Finder notificationSwitchFinder() => find.byType(Switch).at(0);

  Brightness currentBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

  Color currentSurfaceColor(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.surface;

  group('Dark mode toggle', () {
    testWidgets(
      '다크 모드 Switch는 초기 off(라이트)이고, 탭하면 실제 렌더링 테마가 dark로 바뀌며'
      '(Brightness + 배경색 둘 다 확인), 다시 탭하면 라이트로 복귀한다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        expect(
          tester.widget<Switch>(darkSwitchFinder()).value,
          isFalse,
          reason: '앱 시작 시 다크 모드는 꺼져 있어야 한다(ThemeModeNotifier 기본값 ThemeMode.light)',
        );
        expect(currentBrightness(tester), Brightness.light);
        expect(currentSurfaceColor(tester), AppColors.light.surface);

        await tester.tap(darkSwitchFinder());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tester.widget<Switch>(darkSwitchFinder()).value, isTrue);
        expect(
          currentBrightness(tester),
          Brightness.dark,
          reason: '토글 직후 실제 렌더링된 MaterialApp 테마의 Brightness가 dark여야 한다',
        );
        expect(
          currentSurfaceColor(tester),
          AppColors.dark.surface,
          reason: '배경/표면 색상도 dark 팔레트 값으로 실제 반영되어야 한다',
        );

        // 왕복 확인.
        await tester.tap(darkSwitchFinder());
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(darkSwitchFinder()).value, isFalse);
        expect(currentBrightness(tester), Brightness.light);
        expect(currentSurfaceColor(tester), AppColors.light.surface);
      },
    );

    testWidgets(
      '다크 모드를 켠 채 뒤로가기로 다른 화면(옷장 메인)으로 이동해도 전역 테마가 그대로 dark로 '
      '유지되고, 설정 화면에 재진입해도 같은 세션 내에서는 Switch가 여전히 on이다',
      (tester) async {
        final container = await pumpAppAndPush(tester, AppRoute.settingsMain);

        await tester.tap(darkSwitchFinder());
        await tester.pumpAndSettle();
        expect(currentBrightness(tester), Brightness.dark);

        await tester.tap(find.byTooltip('뒤로가기'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(ClosetMainScreen), findsOneWidget);
        final closetContext = tester.element(find.byType(ClosetMainScreen));
        expect(
          Theme.of(closetContext).brightness,
          Brightness.dark,
          reason: '테마는 전역 상태라 설정 화면이 아닌 옷장 메인에도 동일하게 반영되어야 한다',
        );

        final ctx = tester.element(find.byType(SelectableGalleryTile).first);
        GoRouter.of(ctx).push(AppRoute.settingsMain);
        await tester.pumpAndSettle();

        expect(
          tester.widget<Switch>(darkSwitchFinder()).value,
          isTrue,
          reason: '같은 앱 실행(세션) 중 화면을 오간 것뿐이라 in-memory 상태가 유지되어야 한다',
        );
        expect(currentBrightness(tester), Brightness.dark);
        expect(container.read(themeModeProvider), ThemeMode.dark);
      },
    );

    testWidgets(
      '알림 Switch를 먼저 탭해도 다크 모드 값/실제 테마에는 영향이 없다(두 Switch의 독립성 —'
      '테마 관점에서 재확인)',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        await tester.tap(notificationSwitchFinder());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<Switch>(darkSwitchFinder()).value,
          isFalse,
          reason: '알림 토글이 다크 모드 값에 영향을 주면 안 된다',
        );
        expect(currentBrightness(tester), Brightness.light);
      },
    );

    testWidgets(
      '다크 모드 Switch를 빠르게 연속으로 여러 번 탭해도(settle을 기다리지 않는 빠른 연속 조작) '
      '크래시 없이 매 탭마다 실제로 반전되며, 최종 상태가 탭 횟수의 홀짝과 정확히 일치한다',
      (tester) async {
        await pumpAppAndPush(tester, AppRoute.settingsMain);

        for (var i = 0; i < 5; i++) {
          await tester.tap(darkSwitchFinder());
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // 5번 탭(홀수) → 시작이 off였으므로 최종은 on(dark)이어야 한다.
        expect(tester.widget<Switch>(darkSwitchFinder()).value, isTrue);
        expect(currentBrightness(tester), Brightness.dark);

        await tester.tap(darkSwitchFinder());
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(darkSwitchFinder()).value, isFalse);
        expect(currentBrightness(tester), Brightness.light);
      },
    );
  });
}
