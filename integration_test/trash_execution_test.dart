import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/frosted_back_button.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Task 10(휴지통 실행) 검증. `appRouterProvider`가 노출하는 `GoRouter` 인스턴스는
/// `container.read`로 얻어도 위젯 트리가 실제로 쓰는 것과 동일한 객체이고(같은
/// `ProviderContainer`), `GoRouter.push(String location, {extra})`는 `BuildContext`를
/// 요구하지 않는 인스턴스 메서드라(`GoRouter.of(context).push(...)`는 내부적으로 이
/// 메서드를 호출) `container.read(appRouterProvider).push(...)` 패턴이 기존 통합테스트들이
/// 쓰는 `GoRouter.of(context).push(...)` 인위적 push 패턴과 동등하게 동작함을 확인했다
/// (`lib/router/app_router.dart` 검토 결과, plan 3488행 지침대로).
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

  testWidgets('mock_data.dart에 시드된 삭제 항목이 휴지통에 실제로 보인다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();
    expect(find.byType(TrashMainScreen), findsOneWidget);
    expect(find.byType(TrashGalleryTile), findsWidgets);
  });

  testWidgets('타일 탭 시 정보팝업에 이미지+제작일이 표시되고, [복원]을 누르면 실제로 복원된다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TrashGalleryTile).first);
    await tester.pumpAndSettle();
    // c01의 createdAt은 mock_data.dart 기준 2024.3.12 — 정보 팝업이 삭제일이 아니라
    // 제작일을 보여줘야 한다(스펙 §05 31-34행, 홀리스틱 Audit이 이 표시 누락을 지적).
    expect(find.text('2024.3.12 제작'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.text('복원'));
    await tester.pumpAndSettle();

    final stillDeleted = container.read(trashEntriesProvider).any((e) => e.id == 'c01');
    expect(stillDeleted, isFalse);
  });

  testWidgets('다중선택으로 여러 개 골라 [영구 삭제] 확인 시 실제로 지워진다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01', 'c02'});
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    final tiles = find.byType(TrashGalleryTile);
    await tester.longPress(tiles.first);
    await tester.pumpAndSettle();
    await tester.tap(tiles.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('영구 삭제').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('영구 삭제').last); // 확인 모달의 버튼
    await tester.pumpAndSettle();

    final items = container.read(closetItemsProvider);
    expect(items.any((i) => i.id == 'c01'), isFalse);
    expect(items.any((i) => i.id == 'c02'), isFalse);
  });

  testWidgets('비우기 확인 모달에서 확정하면 휴지통이 전부 비워진다', (tester) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    await tester.tap(find.text('비우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비우기').last);
    await tester.pumpAndSettle();

    expect(container.read(trashEntriesProvider), isEmpty);
  });

  testWidgets(
    '다중선택 [복원] 직후(액션 버튼 없는 GlassToast가 떠 있는 4초 타이머 동안) 즉시 '
    '뒤로가기 버튼을 눌러도 실제로 이전 화면으로 돌아간다(회귀: GlassToast의 풀폭 투명 '
    '히트박스가 겹쳐서 뒤로가기 탭을 삼키던 버그)',
    (tester) async {
      final container = await pumpApp(tester);
      container.read(closetItemsProvider.notifier).softDeleteMany({'c01', 'c02'});
      container.read(appRouterProvider).push(AppRoute.trashMain);
      await tester.pumpAndSettle();

      final tiles = find.byType(TrashGalleryTile);
      await tester.longPress(tiles.first); // 다중선택 진입 + 첫 타일 자동 선택
      await tester.pumpAndSettle();
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // [복원]을 누르면 확인 다이얼로그 없이 즉시 복원 + 다중선택 모드 종료(뒤로가기 버튼
      // 재노출) + 액션 버튼 없는 GlassToast 표시가 한 프레임에 일어난다. `pumpAndSettle`
      // 대신 `pump()` 한 번만 써서, toast의 4초 자동소멸 타이머를 절대 기다리지 않고
      // toast가 떠 있는 채로 바로 다음 탭을 진행한다.
      await tester.tap(find.text('복원'));
      await tester.pump();

      expect(find.byType(FrostedBackButton), findsOneWidget, reason: '다중선택 모드 종료로 뒤로가기 버튼이 다시 보여야 한다');

      // toast가 여전히 떠 있는 채로(4초 타이머 대기 없이) 뒤로가기를 누른다 — 버그가
      // 있었다면 toast의 풀폭 투명 히트박스가 이 탭을 가로채 아무 일도 일어나지 않았다.
      await tester.tap(find.byType(FrostedBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(TrashMainScreen), findsNothing, reason: '뒤로가기가 실제로 동작해 휴지통 화면을 벗어나야 한다');

      final closetItems = container.read(closetItemsProvider);
      expect(closetItems.firstWhere((i) => i.id == 'c01').isDeleted, isFalse);
      expect(closetItems.firstWhere((i) => i.id == 'c02').isDeleted, isFalse);
    },
  );
}
