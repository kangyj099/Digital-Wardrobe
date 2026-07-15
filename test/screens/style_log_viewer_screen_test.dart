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
  // `StyleLogViewerScreen`은 `coverImagePath`를 빈 값 가드 없이 바로 `Image.asset`으로
  // 렌더링하므로(Task 5 Step 2), 여기서는 실제 존재하는 mock 에셋 경로를 써야
  // 위젯 테스트 중 이미지 로드 실패 예외가 나지 않는다.
  const mockImagePath = 'assets/images/mock/IMG_4259_preview_rev_1.png';
  final unlinkedLog = StyleLog(
    id: 'test-log',
    coverImagePath: mockImagePath,
    wornDate: DateTime(2026, 3, 1),
  );

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

    expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
    expect(find.text('코디 연결하기'), findsOneWidget);

    // 대표이미지(AspectRatio 1)가 기본 테스트 뷰포트보다 커서 하단 크로스 레퍼런스가
    // 스크롤 없이는 화면 밖에 있다 — 탭 전에 스크롤해서 실제로 보이게 한다.
    await tester.ensureVisible(find.text('코디 연결하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('코디 연결하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('코디 선택 화면'), findsOneWidget);
  });

  testWidgets('연결된 코디가 있으면 바인딩 항목 대신 실제 연결 목록이 보인다', (tester) async {
    const linkedComposition = Composition(id: 'test-comp', name: '연결된 코디', items: []);
    final log = StyleLog(
      id: 'test-log',
      coverImagePath: mockImagePath,
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

    expect(find.text('코디 연결하기'), findsNothing);
    expect(find.text('연결된 코디'), findsOneWidget);
  });
}
