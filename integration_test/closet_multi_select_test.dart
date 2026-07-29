import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

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

  testWidgets('타일 롱프레스로 다중선택 모드 진입 + 그 타일 즉시 1개 선택된다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(SelectableGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
    expect(find.byType(MultiSelectCheckmark), findsWidgets);
  });

  testWidgets('코디에 안 쓰이는 항목 여러 개 선택 후 [삭제] 탭 시 확인 팝업 없이 바로 휴지통 이동되고 모드가 종료된다', (tester) async {
    // c02/c09는 mock_data.dart의 어느 (비삭제) 코디(comp01/comp03)에도 안 쓰임 — 확인 팝업
    // 없이 즉시 삭제되는 경로를 검증(`ValueKey`로 정확히 지정, 그리드 순서에 안 기댐).
    // (plan 원안은 c06을 썼으나, c06은 `isIncomplete:true`라 `SelectableGalleryTile`이
    // `onIncompleteTap`(이 화면은 null)로만 탭을 받고 일반 `onTap`을 아예 안 태우는 기존
    // 동작 때문에 다중선택 토글 탭 자체가 씹힌다 — 미완성 항목 게이팅은 Task 4/5/6 스코프라
    // 이 Task에서 건드리지 않고, 미완성이 아닌 c09로 교체해 테스트 의도(코디에 안 쓰이는
    // 두 항목 선택)를 그대로 유지한다.)
    final container = await pumpApp(tester);
    await tester.longPress(find.byKey(const ValueKey('c02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('c09')));
    await tester.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('사용 중인 코디가 있어요'), findsNothing);
    expect(find.text('1개 선택'), findsNothing);
    final deletedCount = container.read(closetItemsProvider).where((i) => i.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(2));
  });

  testWidgets('코디에 쓰이는 항목(c01) 선택 후 [삭제] 탭 시 확인 팝업이 뜨고, 확정해야 실제로 삭제된다', (tester) async {
    // c01은 mock_data.dart의 comp01이 참조 중 — 사전 경고가 떠야 한다(스펙 §05 42행).
    final container = await pumpApp(tester);
    await tester.longPress(find.byKey(const ValueKey('c01')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('사용 중인 코디가 있어요'), findsOneWidget);
    // 아직 삭제 안 됨 — 확인 모달이 막고 있음.
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').isDeleted, isFalse);

    await tester.tap(find.text('휴지통으로 이동'));
    await tester.pumpAndSettle();

    expect(find.text('1개 선택'), findsNothing);
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').isDeleted, isTrue);
  });

  testWidgets('X 탭으로 다중선택 모드를 취소하면 선택이 비워진다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(SelectableGalleryTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsNothing);
  });

  testWidgets('다중선택 모드 중에는 미완성 배지 항목(c06)을 탭해도 정상적으로 선택 토글된다', (tester) async {
    // 회귀 재발 방지: SelectableGalleryTile.onTap이 multiSelectMode를 무시하고
    // isIncomplete만으로 onIncompleteTap(이 화면에선 null)에 라우팅되던 버그가 있었음
    // (그래서 위 다른 테스트들이 c06 대신 c09를 써야 했던 우회 코멘트가 남아 있다).
    // c02(정상 항목) 롱프레스로 모드 진입 → c06(미완성) 탭 시 선택 개수가 늘어나야 한다.
    await pumpApp(tester);
    await tester.longPress(find.byKey(const ValueKey('c02')));
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('c06')));
    await tester.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);

    // 같은 항목을 다시 탭하면 선택 해제된다(토글 왕복 확인).
    await tester.tap(find.byKey(const ValueKey('c06')));
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
  });

  testWidgets('다중선택 모드가 아닐 때 미완성 배지 항목(c06)을 탭해도 아무 반응이 없다(회귀 없음)', (tester) async {
    // 옷장 메인은 selectionMode(피커 모달)가 아니므로 onIncompleteTap이 null로 배선된다
    // (closet_main_screen.dart) — 일반 브라우징 중 미완성 항목 탭은 여전히 무반응이어야 한다.
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('c06')));
    await tester.pumpAndSettle();
    // 다중선택 모드로 진입하지도, 상세 화면으로 이동하지도 않아야 한다.
    expect(find.text('1개 선택'), findsNothing);
    expect(find.byType(SelectableGalleryTile), findsWidgets);
  });
}
