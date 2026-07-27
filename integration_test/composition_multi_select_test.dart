import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';

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
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디').last);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('코디 타일 롱프레스로 다중선택 진입 + 즉시 1개 선택된다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(CompositionGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
  });

  testWidgets('선택 후 [삭제] 탭 시 실제로 휴지통 이동되고 모드가 종료된다', (tester) async {
    final container = await pumpApp(tester);
    await tester.longPress(find.byType(CompositionGalleryTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('1개 선택'), findsNothing);
    final deletedCount = container.read(compositionsProvider).where((c) => c.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(1));
  });

  testWidgets('X 탭으로 다중선택 모드를 취소하면 선택이 비워진다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(CompositionGalleryTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsNothing);
  });
}
