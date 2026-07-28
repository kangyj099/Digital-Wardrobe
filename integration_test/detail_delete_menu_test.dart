import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Task 11 — Detail 3화면 "더보기" 메뉴의 [삭제] 실제 연결 검증.
/// mock_data.dart 기준(`lib/mock/mock_data.dart`) c01은 comp01이 참조 중이라 삭제 시
/// "사용 중인 코디가 있어요" 확인 팝업이 뜨고, c02는 어느 코디에도 안 쓰여 바로 삭제된다.
/// 코디/스타일일지 삭제는 "사용 중" 개념이 없어 확인 없이 바로 삭제된다
/// (`docs/history/TechnicalDebt.md` 관련 항목 참고).
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

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('코디에 안 쓰이는 옷(c02) 상세의 더보기→삭제는 확인 팝업 없이 바로 휴지통 이동+뒤로가기+토스트', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('c02')));
    await tester.pumpAndSettle();
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('사용 중인 코디가 있어요'), findsNothing);
    expect(find.byType(ClosetMainScreen), findsOneWidget);
    expect(find.byType(ClosetItemDetailScreen), findsNothing);
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c02').isDeleted, isTrue);
  });

  testWidgets('코디에 쓰이는 옷(c01) 상세의 더보기→삭제는 확인 팝업이 뜨고, 확정해야 실제로 삭제+뒤로가기된다', (tester) async {
    final container = await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('c01')));
    await tester.pumpAndSettle();
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('사용 중인 코디가 있어요'), findsOneWidget);
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget); // 아직 안 지워짐, 화면 그대로
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').isDeleted, isFalse);

    // 취소를 먼저 눌러도 삭제되지 않는지 검증(다이얼로그가 뜬 채로 재확인).
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').isDeleted, isFalse);

    // 다시 더보기→삭제→이번엔 확정.
    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴지통으로 이동'));
    await tester.pumpAndSettle();

    expect(find.byType(ClosetMainScreen), findsOneWidget);
    expect(find.byType(ClosetItemDetailScreen), findsNothing);
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01').isDeleted, isTrue);
  });

  testWidgets('코디 상세의 더보기→삭제는 확인 팝업 없이 바로 휴지통 이동+뒤로가기+토스트', (tester) async {
    final container = await pumpApp(tester);

    await goToCategory(tester, '코디');
    expect(find.byKey(const ValueKey('comp01')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('comp01')));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.byType(CompositionMainScreen), findsOneWidget);
    expect(find.byType(CompositionDetailScreen), findsNothing);
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(
      container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01').isDeleted,
      isTrue,
    );
  });

  testWidgets('스타일일지 열람의 더보기→삭제는 확인 팝업 없이 바로 휴지통 이동+뒤로가기+토스트', (tester) async {
    final container = await pumpApp(tester);

    await goToCategory(tester, '코디');
    await tester.tap(find.byKey(const ValueKey('comp01')));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionDetailScreen), findsOneWidget);

    final logTile = find.byType(StyleLogGalleryTile);
    expect(logTile, findsOneWidget);
    await tester.ensureVisible(logTile);
    await tester.tap(logTile);
    await tester.pumpAndSettle();
    expect(find.byType(StyleLogViewerScreen), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.byType(CompositionDetailScreen), findsOneWidget);
    expect(find.byType(StyleLogViewerScreen), findsNothing);
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isTrue);
  });
}
