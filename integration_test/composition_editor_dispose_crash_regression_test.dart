// integration_test/composition_editor_dispose_crash_regression_test.dart
//
// Tester가 Task A(코디 편집기에 InteractiveArtboard 연결) 런타임 검증 중 발견했던 회귀의
// 재발 방지 테스트.
//
// 과거 버그: `CompositionEditorScreen._CompositionEditorScreenState.dispose()`가
// `ref.read(selectedArtboardItemIdProvider.notifier).state = null;`을 직접 호출했는데,
// Riverpod은 `State.dispose()` 안에서 `ref`를 쓰는 것을 원천적으로 금지한다 — Element가
// unmount되는 시점엔 BuildContext가 이미 안전하지 않다는 프레임워크 계약(에러 메시지
// 원문: "Using \"ref\" when a widget is about to or has been unmounted is unsafe. ...
// To safely refer to the state of providers inside State.dispose(), save the provider
// state in a field of your State class."). 이 화면을 벗어날 때(취소/뒤로가기 등 경로
// 무관)마다 매번 처리되지 않은 StateError가 발생했고, 예외가 `ref.read(...)` 호출
// 자체에서 던져지는 바람에 그 뒤의 `.state = null` 대입도 한 번도 실행되지 않아
// 선택 리셋 자체가 무력화됐었다.
//
// Worker 수정: `initState()` 시점(아직 `ref`가 안전할 때)에 notifier 인스턴스를
// `late final` 필드에 미리 저장해두고, `dispose()`에서는 그 저장해둔 notifier를 통해
// (재차 `ref`에 접근하지 않고) `Future(() { notifier.state = null; })`로 감싸 현재
// build/unmount 패스가 끝난 다음 마이크로태스크에서 지연 대입한다.
//
// 이 테스트는 컨테이너를 절대 dispose하지 않고(실제 앱의 루트 컨테이너처럼 프로세스
// 수명 내내 유지) 순수하게 화면을 pop하는 것만으로 재검증한다 — 테스트 하네스의
// `addTearDown(container.dispose)` 관례에 기댄 우회가 아니라 실제 앱과 동일 조건임을
// 보장하기 위함(과거 버그를 처음 재현할 때와 동일한 설계).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/composition_editor_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_editor_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `IntegrationTestWidgetsFlutterBinding`(실제 vsync 프레임을 쓰는 "live" 바인딩)은
  // Element unmount 마무리 및 수정된 코드의 지연 `Future(() {...})` 콜백 실행을 다음
  // 실제 프레임/마이크로태스크로 미룰 수 있다 — `pumpAndSettle()` 한 번만으로는 안 잡힐
  // 수 있어 여분의 프레임을 몇 차례 더 펌프해 강제로 흘려보낸다.
  Future<void> drainDeferredFrames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
      '컨테이너가 살아있는 상태로 코디 편집기에서 취소(pop)해도 더 이상 예외가 발생하지 않고, '
      '선택 상태도 실제로 리셋된다(과거 dispose() ref 크래시 회귀 방지)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 의도적으로 addTearDown(container.dispose)를 쓰지 않는다 — 실제 앱처럼 컨테이너가
    // 테스트가 끝날 때까지 살아있는 채로도 문제없는지 확인하기 위함(테스트 하네스
    // 아티팩트가 아니라 실제 앱 조건과 동일하게 검증).
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).push('/composition/editor/comp01');
    await tester.pumpAndSettle();
    expect(find.byType(CompositionEditorScreen), findsOneWidget);

    // 아이템을 선택 — dispose()가 실제로 하려는 일(선택 리셋)이 이제 정상적으로
    // 일어나는지도 함께 검증.
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('c11:visual'))));
    await tester.pumpAndSettle();
    expect(container.read(selectedArtboardItemIdProvider), 'c11');

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await drainDeferredFrames(tester);

    // 화면 전환(pop) 정상 동작.
    expect(find.byType(CompositionEditorScreen), findsNothing);
    expect(find.byType(ClosetMainScreen), findsOneWidget);

    // 핵심 회귀 확인: 더 이상 처리되지 않은 예외가 없어야 한다.
    expect(tester.takeException(), isNull,
        reason: 'dispose()의 ref 사용 크래시가 재발했다면 여기서 잡혀야 함');

    // 파급 효과도 함께 확인: 지연된(microtask) `.state = null` 대입이 실제로 실행돼
    // 선택 상태가 리셋됐는지.
    expect(
      container.read(selectedArtboardItemIdProvider),
      isNull,
      reason: 'dispose()의 리셋 로직이 실제로 실행돼 선택 상태가 초기화돼야 함',
    );
  });
}
