import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
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

/// mock_data.dart의 comp01/comp02는 이미 각각 log01/log02에 연결되어 있어 "미연결" 상태를
/// 실제 mock 데이터로 검증할 수 없다(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`
/// Task 7 주의 참고) — 이 화면만 `ProviderScope` override로 격리해 검증한다.
void main() {
  const composition = Composition(id: 'test-comp', name: '테스트 코디', items: []);

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
}
