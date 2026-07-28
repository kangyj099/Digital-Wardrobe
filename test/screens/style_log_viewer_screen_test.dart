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
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
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

/// mock_data.dart의 log01/log02는 이미 각각 comp01/comp02에 연결되어 있어 "미연결" 상태를
/// 실제 mock 데이터로 검증할 수 없다(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`
/// Task 7 주의 참고) — 이 화면만 `ProviderScope` override로 격리해 검증한다.
void main() {
  final unlinkedLog = StyleLog(id: 'test-log', coverImagePath: '', wornDate: DateTime(2026, 3, 1));

  testWidgets('연결된 코디가 없으면 "코디 연결하기" 바인딩 항목이 보이고, 탭하면 선택 화면으로 이동한다',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/style-log/test-log',
      routes: [
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) =>
              StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoute.compositionSelect,
          builder: (context, state) => const Scaffold(body: Text('코디 선택 화면')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier(const [])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([unlinkedLog])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 코디 슬롯은 캐러셀의 2번째 페이지 — 기본 PageView(viewportFraction 1.0)는 인접 페이지를
    // 미리 빌드해두지 않으므로, 실제로 보려면 컨트롤러로 명시적으로 넘겨야 한다.
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(find.text('코디 연결하기'), findsOneWidget);

    await tester.ensureVisible(find.text('코디 연결하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('코디 연결하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('코디 선택 화면'), findsOneWidget);
  });

  testWidgets('연결된 코디가 있으면 바인딩 항목 대신 실제 연결 목록이 보인다', (tester) async {
    final linkedComposition =
        Composition(id: 'test-comp', name: '연결된 코디', items: const [], createdAt: DateTime(2025, 1, 1));
    final log = StyleLog(
      id: 'test-log',
      coverImagePath: '',
      wornDate: DateTime(2026, 3, 1),
      linkedCompositionId: 'test-comp',
    );
    final router = GoRouter(
      initialLocation: '/style-log/test-log',
      routes: [
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) =>
              StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) => const Scaffold(body: Text('코디 상세')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith(
            (ref) => _FixedCompositionsNotifier([linkedComposition]),
          ),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([log])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
    await tester.pumpAndSettle();

    expect(find.text('코디 연결하기'), findsNothing);
    expect(find.text('연결된 코디'), findsOneWidget);
  });

  testWidgets('삭제된 옷은 "착용 옷" 목록에서 배지와 함께 그대로 보이고 탭이 막힌다, 정상 옷은 기존대로 탭된다',
      (tester) async {
    const activePath = 'assets/images/mock/IMG_4259_preview_rev_1.png';
    const deletedPath = 'assets/images/mock/IMG_4260_preview_rev_1.png';
    final activeItem = ClothingItem(
      id: 'active-item',
      name: '정상 옷',
      imagePath: activePath,
      createdAt: DateTime(2025, 1, 1),
    );
    final deletedItem = ClothingItem(
      id: 'deleted-item',
      name: '삭제된 옷',
      imagePath: deletedPath,
      createdAt: DateTime(2025, 1, 1),
      isDeleted: true,
    );
    final log = StyleLog(
      id: 'test-log',
      coverImagePath: '',
      wornDate: DateTime(2026, 3, 1),
      additionalImagePaths: const [activePath, deletedPath],
    );
    final router = GoRouter(
      initialLocation: '/style-log/test-log',
      routes: [
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) =>
              StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
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
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier(const [])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([log])),
          closetItemsProvider
              .overrideWith((ref) => _FixedClosetItemsNotifier([activeItem, deletedItem])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 삭제된 옷도 목록에서 제외되지 않고 그대로 보인다.
    expect(find.image(const AssetImage(activePath)), findsOneWidget);
    expect(find.image(const AssetImage(deletedPath)), findsOneWidget);

    // 삭제된 옷 타일에만 "삭제됨" 배지가 보인다.
    expect(find.widgetWithText(StatusBadge, '삭제됨'), findsOneWidget);

    // 이미지가 96x96 박스를 꽉 채운다(Stack이 fit: StackFit.expand + Positioned.fill 없이
    // 기본 loose fit을 쓰면, 세로가 긴 mock 에셋의 경우 이미지가 자연 종횡비대로 쪼그라들어
    // 좌상단에만 그려지고 나머지가 빈 여백으로 남는 시각 회귀가 생긴다 — Review 2026-07-29 지적).
    expect(
      tester.getSize(
        find.descendant(
          of: find.ancestor(
            of: find.image(const AssetImage(activePath)),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byType(ClipRRect),
        ),
      ),
      const Size(96, 96),
    );
    expect(
      tester.getSize(
        find.descendant(
          of: find.ancestor(
            of: find.image(const AssetImage(deletedPath)),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byType(ClipRRect),
        ),
      ),
      const Size(96, 96),
    );

    // 삭제된 옷 타일은 onTap 자체가 null이라 탭이 막힌다 — 이 화면의 헤더(AppMainScaffold)
    // 오버레이가 위젯 테스트 환경의 hitTest 좌표와 부딪히는 기존 환경 이슈(이번 변경과
    // 무관, `docs/history/TechnicalDebt.md` 후보)가 있어 물리 탭 시뮬레이션 대신 onTap
    // 콜백 자체를 직접 검증한다.
    final deletedTileTap = tester
        .widget<GestureDetector>(
          find.ancestor(
            of: find.image(const AssetImage(deletedPath)),
            matching: find.byType(GestureDetector),
          ),
        )
        .onTap;
    expect(deletedTileTap, isNull);

    // 정상 옷은 기존대로 onTap이 채워져 있고, 실제로 호출하면 상세로 이동한다.
    final activeTileTap = tester
        .widget<GestureDetector>(
          find.ancestor(
            of: find.image(const AssetImage(activePath)),
            matching: find.byType(GestureDetector),
          ),
        )
        .onTap;
    expect(activeTileTap, isNotNull);
    activeTileTap!();
    await tester.pumpAndSettle();
    expect(find.text('옷 상세'), findsOneWidget);
  });
}
