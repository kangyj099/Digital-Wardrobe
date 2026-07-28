import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// 회귀 — `closet_item_detail_revisit_setstate_during_build_regression_test.dart`가 다루는
/// "pop 후 재방문" 케이스와 별개로, Review가 지적한 더 넓은 케이스: 이 앱은 전부
/// `context.push`(pop 없이 계속 쌓임)라 같은 itemId의 옷 상세가 **pop되지 않은 채로 스택에
/// 남아있는 상태에서 다른 경로로 또 push**되면 리스너 수가 0으로 안 떨어져
/// `.autoDispose`만으로는 보호되지 않을 수 있다는 우려(실제로 이 테스트로 재현됨 — 아래
/// "확인된 사실" 참고).
///
/// **확인된 사실**: `.autoDispose`만 적용한 상태(구 커밋)에서 이 테스트는 실제로
/// `FlutterError: setState() ... during build`로 크래시했다(실측, `git stash`로 비교
/// 확인) — 리스너가 계속 살아있어도 `compositionsProvider`/`styleLogsProvider` mutate
/// 직후 settle 없이 같은 itemId를 재push하면 여전히 재현 가능했다.
///
/// **근본 수정**: `styleLogsLinkedToItemProvider`가 `compositionsContainingItemProvider`를
/// provider-to-provider로 `ref.watch`하던 의존을 제거하고, 그 필터 로직을
/// `compositionsProvider`에서 직접 인라인하도록 변경(`lib/providers/style_log_providers.dart`
/// 해당 provider 주석 참고) — provider-to-provider watch가 만드는 `invalidateSelf()`
/// 재귀 경로 자체를 없애 리스너 수/pop 여부와 무관하게 안전해진다. `.autoDispose`는 화면
/// 이탈 시 정리를 위해 별도로 유지.
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
      '같은 itemId의 옷 상세 리스너가 pop 없이 계속 살아있는 상태에서, compositionsProvider/'
      'styleLogsProvider를 mutate한 직후 settle 없이 곧바로 그 itemId를 다른 경로로 재push해도 '
      '크래시하지 않는다 — 깊은 push 체인 + 끝까지 뒤로가기 연타까지 포함',
      (tester) async {
    final container = await pumpApp(tester);
    final context = tester.element(find.byType(Scaffold).first);

    // c04를 2개의 살아있는 코디(comp03 + 새로 추가하는 comp_extra)에 쓰이게 만들어
    // "코디 2개 이상에 등록된 옷"이라는 실제 사용자 재연 조건을 충족시킨다.
    final compExtra = Composition(
      id: 'comp_extra',
      name: '테스트용 여분 코디',
      createdAt: DateTime(2026, 3, 1),
      items: const [CompositionItemPlacement(clothingItemId: 'c04', x: 40, y: 40, zIndex: 0)],
    );
    container.read(compositionsProvider.notifier).state = [
      ...container.read(compositionsProvider),
      compExtra,
    ];
    container.read(closetItemsProvider.notifier).softDeleteMany({'c04'});
    await tester.pumpAndSettle();

    // 1) c04 옷 상세 첫 push(리스너 A) — 정착. 이후 절대 pop하지 않는다.
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c04'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2) 중간에 다른 화면들을 몇 개 끼워넣는다(팝 없이 계속 push로 파고듦).
    GoRouter.of(context).push(AppRoute.compositionDetail.replaceFirst(':id', 'comp01'));
    await tester.pumpAndSettle();
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c11'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 3) mutate(comp_extra 소프트삭제, c04가 쓰던 코디) 직후, settle 없이 곧바로 c04를
    //    "다른 경로"로 재push(리스너 B) — 리스너 A는 여전히 스택에 남아있다(안 팝함).
    container.read(compositionsProvider.notifier).softDeleteMany({'comp_extra'});
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c04'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // 4) 한번 더 — style log까지 mutate하며 세번째 재push(리스너 C).
    GoRouter.of(context).push(AppRoute.styleLogViewer.replaceFirst(':id', 'log01'));
    await tester.pump();
    container.read(styleLogsProvider.notifier).linkToComposition('log02', 'comp01');
    GoRouter.of(context).push(AppRoute.closetItemDetail.replaceFirst(':id', 'c04'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 5) 그 상태에서 뒤로가기를 끝까지 연타(각 pop 사이 pumpAndSettle 없이 pump()만 —
    //    "빠르게 연속으로 뒤로가기"에 가깝게). "There is nothing to pop"(GoError)는 스택
    //    바닥에 닿았다는 정상 종료 신호일 뿐이라 크래시로 취급하지 않는다.
    var popCount = 0;
    while (true) {
      final backButtons = find.byTooltip('뒤로가기');
      if (backButtons.evaluate().isEmpty) break;
      await tester.tap(backButtons.first, warnIfMissed: false);
      await tester.pump();
      popCount++;
      final ex = tester.takeException();
      if (ex != null) {
        if (ex.toString().contains('nothing to pop')) break;
        fail('뒤로가기 $popCount번째에서 크래시: $ex');
      }
      if (popCount > 30) fail('뒤로가기가 30번을 넘었다 — 무한루프 의심');
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
