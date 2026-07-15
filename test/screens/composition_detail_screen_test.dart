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
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';

// `compositionsProvider`/`styleLogsProvider`는 `StateNotifierProvider<CompositionsNotifier, ...>`
// /`StateNotifierProvider<StyleLogsNotifier, ...>`로 선언되어 있어, `overrideWith`가 각각
// `CompositionsNotifier`/`StyleLogsNotifier`의 서브타입만 받는다 — 순수 `StateNotifier<List<T>>`
// 서브클래스로는 컴파일되지 않아, 실제 Notifier 클래스를 상속해 고정 state를 주입한다.
class _FixedCompositionsNotifier extends CompositionsNotifier {
  _FixedCompositionsNotifier(List<Composition> compositions) {
    state = compositions;
  }
}

class _FixedStyleLogsNotifier extends StyleLogsNotifier {
  _FixedStyleLogsNotifier(List<StyleLog> logs) {
    state = logs;
  }
}

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

    expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
    expect(find.text('스타일일지 연결하기'), findsOneWidget);

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
    expect(find.textContaining('2026.3.1'), findsOneWidget);
  });
}
