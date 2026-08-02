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
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Task 11 Tester 보강 — Worker의 `detail_delete_menu_test.dart`(더보기→삭제 메뉴 자체의
/// 확인 팝업/토스트/뒤로가기/provider isDeleted 반영)와 중복되지 않는, 그 뒤에 이어지는
/// end-to-end 파이프라인만 검증한다:
/// 1) 삭제 후 목록 화면(옷장/코디 메인)에서 실제로 그 항목 타일이 사라지는가(제외 필터가
///    실제로 화면에도 반영되는가, provider 값만이 아니라).
/// 2) 그 뒤 실제로 설정→휴지통까지 실제 탭 네비게이션으로 들어가, 방금 삭제한 항목이 3개
///    도메인 전부 실제 타일로 나타나는가(Group B Task 3/10 휴지통 파이프라인과의 연결 확인).
/// 3) [비정형 흐름] 더보기 메뉴를 열고 [삭제]를 누르지 않은 채 바깥을 탭해 닫으면 아무
///    일도 안 일어나는가.
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

  Future<void> goToTrash(WidgetTester tester) async {
    await goToCategory(tester, '설정');
    await tester.tap(find.text('휴지통'));
    await tester.pumpAndSettle();
    expect(find.byType(TrashMainScreen), findsOneWidget);
  }

  testWidgets(
    '옷(c02, 미사용) 삭제 — 옷장 메인 그리드에서 실제로 사라지고, 실제 탭 네비게이션으로 '
    '설정→휴지통까지 들어가면 c02가 실제 타일로 보인다',
    (tester) async {
      await pumpApp(tester);

      expect(find.byKey(const ValueKey('c02')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('c02')));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(ClosetMainScreen), findsOneWidget);
      // 옷장 메인 그리드에서 c02 타일 자체가 실제로 사라졌다(단순 isDeleted 플래그가
      // 아니라 화면 반영까지).
      expect(find.byKey(const ValueKey('c02')), findsNothing);

      await goToTrash(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('c02')), findsOneWidget, reason: '휴지통에 c02가 실제로 보여야 한다');
    },
  );

  testWidgets(
    '코디(comp01) 삭제 — 코디 메인 그리드에서 실제로 사라지고, 설정→휴지통까지 들어가면 '
    'comp01이 실제 타일로 보인다',
    (tester) async {
      await pumpApp(tester);
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
      expect(find.byKey(const ValueKey('comp01')), findsNothing);

      await goToTrash(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget,
          reason: '휴지통에 comp01이 실제로 보여야 한다');
    },
  );

  testWidgets(
    '스타일일지(log01) 삭제 — 연결된 코디(comp01) 상세의 크로스 레퍼런스 갤러리에서 실제로 '
    '사라지고, 설정→휴지통까지 들어가면 log01이 실제 타일로 보인다',
    (tester) async {
      await pumpApp(tester);
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

      // 뒤로가기(pop)로 comp01 상세로 돌아옴 — log01이 삭제됐으니 크로스 레퍼런스
      // 갤러리에서 실제로 사라지고 "+" 바인딩 타일로 바뀌어야 한다.
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.byType(StyleLogGalleryTile), findsNothing);
      expect(find.text('스타일일지 연결하기'), findsOneWidget);

      await goToTrash(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('log01')), findsOneWidget,
          reason: '휴지통에 log01이 실제로 보여야 한다');
    },
  );

  testWidgets(
    '[비정형 흐름] 더보기 메뉴를 열고 [삭제]를 누르지 않은 채 바깥을 탭해 닫으면 아무 일도 '
    '일어나지 않는다(화면 그대로, provider 상태 불변)',
    (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.byKey(const ValueKey('c04')));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      expect(find.text('삭제'), findsOneWidget, reason: '메뉴가 실제로 열려 있어야 한다');

      // 메뉴 바깥(화면 좌상단 구석, 메뉴/버튼과 겹치지 않는 위치)을 탭해 선택 없이 닫는다.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('삭제'), findsNothing, reason: '메뉴가 닫혔어야 한다');
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget, reason: '여전히 같은 화면이어야 한다');
      expect(find.text('휴지통으로 이동됨'), findsNothing);
      expect(container.read(closetItemsProvider).firstWhere((i) => i.id == 'c04').isDeleted, isFalse);
    },
  );
}
