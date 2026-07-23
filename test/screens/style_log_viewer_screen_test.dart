import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';

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
}
