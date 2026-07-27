import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/classification_drilldown_capsule.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

/// Tester 런타임 검증 — 스타일일지 메인 `GalleryMainScreen<StyleLog>` 이관
/// (`classification: null` 첫 실사용례) Review 통과분.
///
/// `style_log_multi_select_test.dart`(Worker/Review 자체 테스트)는 단일 선택 경로만
/// 다룬다(`composition_multi_select_test.dart`와 동일 gap 패턴). 이 파일은 mock 데이터에
/// 실제로 존재하는 2개 스타일일지(log01/log02)를 이용한 2건 다중선택/해제/삭제/실행취소
/// 경로, X-취소 경로, 다중선택 중 FAB 은닉, 그리고 헤더에 분류 캡슐·밀도/정렬 토글이
/// 실제로 렌더링되지 않는지(구조가 아니라 실행 결과로) 다룬다.
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
    await tester.tap(find.text('스타일일지').last);
    await tester.pumpAndSettle();
    return container;
  }

  int selectedCheckmarkCount(WidgetTester tester) {
    return tester
        .widgetList<MultiSelectCheckmark>(find.byType(MultiSelectCheckmark))
        .where((c) => c.selected)
        .length;
  }

  testWidgets(
    '스타일일지 메인 헤더에는 분류 드릴다운 캡슐과 밀도/정렬 토글 버튼이 실제로 렌더링되지 '
    '않는다(classification:null 경로 — 구조가 아니라 실행 결과로 확인)',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(ClassificationDrilldownCapsule), findsNothing);
      expect(find.byTooltip('그리드 밀도 전환'), findsNothing);
      expect(find.byTooltip('오름차순'), findsNothing);
      expect(find.byTooltip('내림차순'), findsNothing);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));
    },
  );

  testWidgets(
    'log02(최신) 롱프레스로 진입 후 log01을 탭해 순차 선택하면 "2개 선택"이 되고 체크마크도 '
    '실제로 2개가 선택 상태로 표시된다. log02를 다시 탭해 해제하면 "1개 선택"으로 줄고 '
    'log01만 선택 상태로 남는다',
    (tester) async {
      await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 1);

      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 2);

      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(selectedCheckmarkCount(tester), 1);
      final log01Tile = tester.widget<StyleLogGalleryTile>(find.byKey(const ValueKey('log01')));
      expect(log01Tile.selected, isTrue, reason: '해제된 것은 log02여야 하고 log01은 계속 선택 상태여야 한다.');
    },
  );

  testWidgets(
    'log01/log02 둘 다 선택 후 다중선택 모드에서는 FAB가 보이지 않고, [삭제] 탭 시 즉시 둘 다 '
    '휴지통 이동되어 GlassToast에 "2개 항목이 휴지통으로 이동됨"과 실행취소 액션이 뜬다 — '
    '실행취소 탭 시 둘 다 provider 상태 및 그리드 화면 양쪽에서 복구 확인된다',
    (tester) async {
      final container = await pumpApp(tester);

      // 다중선택 진입 전엔 FAB가 존재한다.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log02')));
      await tester.pumpAndSettle();
      expect(find.text('2개 선택'), findsOneWidget);

      // 다중선택 모드 진입 중에는 FAB가 은닉된다.
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('2개 선택'), findsNothing);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isTrue);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02').isDeleted, isTrue);
      expect(find.byKey(const ValueKey('log01')), findsNothing);
      expect(find.byKey(const ValueKey('log02')), findsNothing);
      expect(find.text('2개 항목이 휴지통으로 이동됨'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);
      // 다중선택 종료 후 정상 화면으로 복귀했으니 FAB도 다시 보인다.
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01').isDeleted, isFalse);
      expect(container.read(styleLogsProvider).firstWhere((l) => l.id == 'log02').isDeleted, isFalse);
      expect(find.byKey(const ValueKey('log01')), findsOneWidget);
      expect(find.byKey(const ValueKey('log02')), findsOneWidget);
    },
  );

  testWidgets(
    '다중선택 진입 후 X(닫기)로 취소하면 선택은 비워지고 정상 헤더(카테고리 토글/FAB)로 '
    '돌아오며 아무 항목도 삭제되지 않는다',
    (tester) async {
      final container = await pumpApp(tester);

      await tester.longPress(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(find.text('1개 선택'), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsNothing);

      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('1개 선택'), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));
      expect(container.read(styleLogsProvider).where((l) => l.isDeleted).length, 0);
    },
  );
}
