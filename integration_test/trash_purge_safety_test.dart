import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// 그룹 B Task 3(휴지통 집계 재작성 + 자동 영구삭제 + 안전가드) Tester 검증.
///
/// `app_smoke_test.dart`는 `ProviderScope(child: DigitalWardrobeApp())`로 부팅해
/// `purgeExpiredTrash`가 실행되지 않는 별도 컨테이너를 쓴다(main() 함수 자체를 호출하지
/// 않음). 이 파일은 `main()`과 동일한 부팅 시퀀스(ProviderContainer 생성 →
/// `purgeExpiredTrash(container)` → `UncontrolledProviderScope`로 pump)를 그대로
/// 재현해, "c08(20일 경과)이 앱 실행 즉시 자동 영구삭제되는" 실제 흐름을 검증한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> bootAppLikeMain(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    purgeExpiredTrash(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    '시나리오1 — main()과 동일한 부팅 시퀀스(purgeExpiredTrash 포함)로 크래시 없이 부팅되고, '
    'c08(20일 경과)은 실제로 purge되어 closetItemsProvider에서 사라지며, c07(3일 경과)은 '
    '아직 유효 기간 내라 남아있다',
    (tester) async {
      final container = await bootAppLikeMain(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);

      final closetItems = container.read(closetItemsProvider);
      expect(
        closetItems.any((i) => i.id == 'c08'),
        isFalse,
        reason: 'c08은 20일 경과로 purgeExpiredTrash가 실행되면 영구삭제되어야 한다',
      );
      expect(
        closetItems.any((i) => i.id == 'c07'),
        isTrue,
        reason: 'c07은 3일 경과로 아직 유효 기간(15일) 내라 purge되지 않아야 한다',
      );
    },
  );

  testWidgets('시나리오2 — 휴지통 화면에 진입하면 새 파생 집계(trashEntriesProvider) 구조로도 크래시 없이 렌더링된다', (
    tester,
  ) async {
    final container = await bootAppLikeMain(tester);

    final context = tester.element(find.byType(SelectableGalleryTile).first);
    GoRouter.of(context).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TrashMainScreen), findsOneWidget);

    // c08은 purge됐으니 휴지통에도 더 이상 없어야 하고, 아직 유효기간 내인 c07/comp02는
    // 휴지통 파생 집계에 남아있어야 한다.
    final entries = container.read(trashEntriesProvider);
    expect(entries.any((e) => e.id == 'c08'), isFalse);
    expect(entries.any((e) => e.id == 'c07'), isTrue);
    expect(entries.any((e) => e.id == 'comp02'), isTrue);
  });

  testWidgets('시나리오3 — 코디 메인 → 코디 상세 화면 진입 시 크래시 없이 렌더링된다(usedItems 안전가드 경로)', (
    tester,
  ) async {
    await bootAppLikeMain(tester);

    final context = tester.element(find.byType(SelectableGalleryTile).first);
    GoRouter.of(context).push(AppRoute.compositionMain);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionMainScreen), findsOneWidget);

    // comp01(soft-deleted된 c07을 포함하는, 아직 삭제되지 않은 코디)의 상세로 진입한다 —
    // 코디 메인의 실제 탭 흐름은 이 검증 범위 밖이라 URL push로 접근한다
    // (`settings_trash_shell_test.dart`와 동일 패턴).
    GoRouter.of(context).push(AppRoute.compositionDetail.replaceFirst(':id', 'comp01'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CompositionDetailScreen), findsOneWidget);
  });

  testWidgets(
    '시나리오4 — 스타일일지 메인 → 스타일일지 열람 화면 진입 시 크래시 없이 렌더링된다'
    '(linkedComposition 안전가드 경로, log02→comp02는 soft-delete됐지만 아직 purge되지 않은 상태)',
    (tester) async {
      await bootAppLikeMain(tester);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push(AppRoute.styleLogMain);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);

      GoRouter.of(context).push(AppRoute.styleLogViewer.replaceFirst(':id', 'log02'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
    },
  );

  testWidgets(
    '시나리오5 — 옷장 메인 화면(초기 진입 라우트) 렌더링에 크래시가 없고, purge된 c08은 '
    'closetItemsProvider에서 완전히 사라진 상태로 반영된다',
    (tester) async {
      final container = await bootAppLikeMain(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(container.read(closetItemsProvider).any((i) => i.id == 'c08'), isFalse);
    },
  );
}
