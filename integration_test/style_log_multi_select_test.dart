import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

// [편차, Task 9] plan 원안(2026-07-21)의 pumpApp은 `find.byType(PopupMenuButton<Object>).first`로
// 스타일일지 이동을 가정했으나, 실제 카테고리 이동 UI는 `CategoryToggleDropdown`이다
// (`composition_style_log_main_screen_test.dart`/`composition_multi_select_test.dart`의
// 실제 통과 패턴을 그대로 이식 — plan 3034줄이 명시적으로 허용한 대체).
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
    // 스타일일지로 이동.
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스타일일지').last);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('스타일일지도 롱프레스로 다중선택 진입 후 삭제하면 휴지통으로 이동한다', (tester) async {
    final container = await pumpApp(tester);
    await tester.longPress(find.byType(StyleLogGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    final deletedCount = container.read(styleLogsProvider).where((l) => l.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(1));
  });
}
