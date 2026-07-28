import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// 회귀 — `FlutterError: setState() or markNeedsBuild() called during build`
/// (`docs/history/TechnicalDebt.md` 최상단 버그 항목, P1, 실사용 중 VS Code 디버그
/// 세션에서 실제 스택트레이스로 확인됨).
///
/// 근본원인: `compositionsContainingItemProvider`/`styleLogsLinkedToItemProvider`가
/// 일반 `Provider.family`였을 때, 옷 상세를 한 번 방문하면 그 itemId 전용 provider
/// 인스턴스가 컨테이너에 **영구히** 남는다(위젯이 사라져도 폐기 안 됨). 그 뒤
/// `compositionsProvider`가 변경되면 이 인스턴스가 "dirty"로만 표시되고 즉시 재계산되진
/// 않는데, **같은 itemId로 옷 상세를 settle 없이 곧바로 다시 열면** 위젯의 첫 build가
/// 이 dirty한 provider를 재구독하며 `ProviderElement.flush()`를 동기 호출 — 재계산 결과
/// 이미 살아있던 `styleLogsLinkedToItemProvider(itemId)` 쪽 구독의 `invalidateSelf()` →
/// `scheduleProviderRefresh()`가 `UncontrolledProviderScopeState.setState()`를 호출하는데,
/// 이게 하필 이 위젯 자신의 `BuildScope._flushDirtyElements` 도중이라 크래시한다.
///
/// 수정: 두 provider를 `Provider.autoDispose.family`로 전환 — 마지막 리스너가 사라지면
/// (옷 상세 화면 이탈) 인스턴스 자체가 폐기되어 "dirty한 채로 영구히 남는 구독"이 애초에
/// 존재할 수 없다(`lib/providers/composition_providers.dart`/`style_log_providers.dart`
/// 해당 provider 주석 참고).
///
/// 이 테스트는 fix 이전 코드(`Provider.family`, autoDispose 없음)에서 실제로 위와 동일한
/// 스택트레이스로 크래시함을 `git stash`로 직접 확인한 뒤 작성됨.
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
      '옷 상세를 한 번 방문(provider 인스턴스 생성) -> 뒤로가기 -> compositionsProvider 변경(그 '
      '코디를 소프트삭제) -> settle 없이 곧바로 같은 itemId로 재방문해도 크래시하지 않는다',
      (tester) async {
    final container = await pumpApp(tester);
    final context = tester.element(find.byType(Scaffold).first);

    // c11은 comp01에 쓰이는 옷 — 첫 방문으로 compositionsContainingItemProvider('c11')/
    // styleLogsLinkedToItemProvider('c11')이 생성된다.
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c11'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // comp01을 직접 소프트삭제 — compositionsProvider를 mutate해 위 provider들을 dirty로
    // 만든다(fix 전: 인스턴스가 계속 살아있어 dirty 상태가 남음).
    container.read(compositionsProvider.notifier).softDeleteMany({'comp01'});

    // settle 없이 곧바로 같은 itemId로 재방문 — 이 재구독 시점의 동기 flush가 크래시를
    // 유발했었다(fix 전).
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c11'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
