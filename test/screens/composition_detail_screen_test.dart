import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

class _FixedCompositionsNotifier extends CompositionsNotifier {
  _FixedCompositionsNotifier(List<Composition> initial) {
    state = initial;
  }
}

class _FixedStyleLogsNotifier extends StyleLogsNotifier {
  _FixedStyleLogsNotifier(List<StyleLog> initial) {
    state = initial;
  }
}

class _FixedClosetItemsNotifier extends ClosetItemsNotifier {
  _FixedClosetItemsNotifier(List<ClothingItem> initial) {
    state = initial;
  }
}

/// mock_data.dart의 comp01/comp02는 이미 각각 log01/log02에 연결되어 있어 "미연결" 상태를
/// 실제 mock 데이터로 검증할 수 없다(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`
/// Task 7 주의 참고) — 이 화면만 `ProviderScope` override로 격리해 검증한다.
void main() {
  final composition =
      Composition(id: 'test-comp', name: '테스트 코디', items: const [], createdAt: DateTime(2025, 1, 1));

  testWidgets('연결된 스타일일지가 없으면 "스타일일지 연결하기" 바인딩 항목이 보이고, 탭하면 선택 화면으로 이동한다',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/composition/test-comp',
      routes: [
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) =>
              CompositionDetailScreen(compositionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoute.styleLogSelect,
          builder: (context, state) => const Scaffold(body: Text('스타일일지 선택 화면')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier([composition])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier(const [])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스타일일지 연결하기'), findsOneWidget);

    await tester.ensureVisible(find.text('스타일일지 연결하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스타일일지 연결하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('스타일일지 선택 화면'), findsOneWidget);
  });

  testWidgets('연결된 스타일일지가 있으면 바인딩 항목 대신 실제 연결 목록이 보인다', (tester) async {
    final linkedLog = StyleLog(
      id: 'test-log',
      coverImagePath: '',
      wornDate: DateTime(2026, 3, 1),
      linkedCompositionId: 'test-comp',
    );
    final router = GoRouter(
      initialLocation: '/composition/test-comp',
      routes: [
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) =>
              CompositionDetailScreen(compositionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) => const Scaffold(body: Text('스타일일지 열람')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier([composition])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([linkedLog])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스타일일지 연결하기'), findsNothing);
    expect(find.textContaining('2026-03-01'), findsOneWidget); // StyleLogGalleryTile 날짜 라벨 포맷
  });

  testWidgets('삭제된 옷은 "사용된 옷" 목록에서 배지와 함께 그대로 보이고 탭이 막힌다, 정상 옷은 기존대로 탭된다',
      (tester) async {
    final activeItem = ClothingItem(
      id: 'active-item',
      name: '정상 옷',
      imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
      createdAt: DateTime(2025, 1, 1),
    );
    final deletedItem = ClothingItem(
      id: 'deleted-item',
      name: '삭제된 옷',
      imagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png',
      createdAt: DateTime(2025, 1, 1),
      isDeleted: true,
    );
    final compositionWithDeletedItem = Composition(
      id: 'test-comp',
      name: '테스트 코디',
      items: const [
        CompositionItemPlacement(clothingItemId: 'active-item', x: 0, y: 0),
        CompositionItemPlacement(clothingItemId: 'deleted-item', x: 0, y: 0),
      ],
      createdAt: DateTime(2025, 1, 1),
    );
    final router = GoRouter(
      initialLocation: '/composition/test-comp',
      routes: [
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) =>
              CompositionDetailScreen(compositionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoute.closetItemDetail,
          builder: (context, state) => const Scaffold(body: Text('옷 상세')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider
              .overrideWith((ref) => _FixedCompositionsNotifier([compositionWithDeletedItem])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier(const [])),
          closetItemsProvider
              .overrideWith((ref) => _FixedClosetItemsNotifier([activeItem, deletedItem])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 삭제된 옷도 목록에서 제외되지 않고 그대로 보인다.
    expect(find.text('정상 옷'), findsOneWidget);
    expect(find.text('삭제된 옷'), findsOneWidget);

    // 삭제된 옷 타일에만 "삭제됨" 배지가 보인다.
    expect(find.widgetWithText(StatusBadge, '삭제됨'), findsOneWidget);

    // 이미지가 72x72 박스를 꽉 채운다(Stack이 fit: StackFit.expand + Positioned.fill 없이
    // 기본 loose fit을 쓰면, 세로가 긴 mock 에셋의 경우 이미지가 자연 종횡비대로 쪼그라들어
    // 좌상단에만 그려지고 나머지가 빈 여백으로 남는 시각 회귀가 생긴다 — Review 2026-07-29
    // 지적, 배지 유무와 무관하게 두 타일 모두 항상 성립해야 함).
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('active-item')),
          matching: find.byType(ClipRRect),
        ),
      ),
      const Size(72, 72),
    );
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('deleted-item')),
          matching: find.byType(ClipRRect),
        ),
      ),
      const Size(72, 72),
    );

    // 삭제된 옷 타일은 onTap 자체가 null이라 탭이 막힌다 — 이 화면의 헤더(AppMainScaffold)
    // 오버레이가 위젯 테스트 환경(800x600/390x844 등)의 hitTest 좌표와 부딪히는 기존
    // 환경 이슈(이번 변경과 무관, `docs/history/TechnicalDebt.md` 후보)가 있어 물리 탭
    // 시뮬레이션 대신 onTap 콜백 자체를 직접 검증한다.
    final deletedTileTap =
        tester.widget<GestureDetector>(find.byKey(const ValueKey('deleted-item'))).onTap;
    expect(deletedTileTap, isNull);

    // 정상 옷은 기존대로 onTap이 채워져 있고, 실제로 호출하면 상세로 이동한다.
    final activeTileTap =
        tester.widget<GestureDetector>(find.byKey(const ValueKey('active-item'))).onTap;
    expect(activeTileTap, isNotNull);
    activeTileTap!();
    await tester.pumpAndSettle();
    expect(find.text('옷 상세'), findsOneWidget);
  });

  testWidgets(
    '삭제 후 화면이 pop된 뒤에도 토스트의 "실행취소"를 누르면 크래시 없이 실제로 복원된다 '
    '(Review P0 회귀 방지: pop된 화면의 ref로 나중에 읽으면 release에서도 StateError가 나므로, '
    'pop 이전에 캡처해둔 notifier를 써야 함)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier([composition])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier(const [])),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(path: '/list', builder: (context, state) => const Scaffold(body: Text('코디 목록'))),
          GoRoute(
            path: '/composition/:id',
            builder: (context, state) =>
                CompositionDetailScreen(compositionId: state.pathParameters['id']!),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.push('/composition/test-comp');
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // pop되어 목록 화면으로 돌아왔다 — 코디 상세 화면의 element는 이미 dispose된 상태.
      expect(find.text('코디 목록'), findsOneWidget);
      expect(find.byType(CompositionDetailScreen), findsNothing);
      expect(container.read(compositionsProvider).first.isDeleted, isTrue);

      // "실행취소"를 지금(화면이 pop된 뒤) 누른다 — 고친 코드가 pop 이전에 notifier를 캡처해둔
      // 덕에 크래시 없이 복원돼야 한다.
      await tester.tap(find.text('실행취소'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(compositionsProvider).first.isDeleted, isFalse);
    },
  );
}
