import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';

class _FixedClosetItemsNotifier extends ClosetItemsNotifier {
  _FixedClosetItemsNotifier(List<ClothingItem> initial) {
    state = initial;
  }
}

/// 옷 상세 화면의 삭제→실행취소 흐름 회귀 테스트 — Review P0(2026-08-12): `context.pop()` 이후
/// 팝된 화면의 element는 dispose되고, 그 element에 묶인 `ref`로 나중(토스트 액션 탭 시점)에
/// `ref.read(...)`를 호출하면 `ConsumerStatefulElement._assertNotDisposed()`가 release
/// 빌드에서도 `StateError`를 던진다. `ref`가 아니라 pop 이전에 캡처해둔 notifier 객체를
/// 써야 한다(`flutter_riverpod` 실제 소스로 확인된 버그, `docs/history/Decision.md` 참고).
void main() {
  final item = ClothingItem(
    id: 'test-item',
    name: '테스트 옷',
    imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
    createdAt: DateTime(2025, 1, 1),
  );

  testWidgets(
    '삭제 후 화면이 pop된 뒤에도 토스트의 "실행취소"를 누르면 크래시 없이 실제로 복원된다 '
    '(Review P0 회귀 방지: pop된 화면의 ref로 나중에 읽으면 release에서도 StateError가 나므로, '
    'pop 이전에 캡처해둔 notifier를 써야 함)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          closetItemsProvider.overrideWith((ref) => _FixedClosetItemsNotifier([item])),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(path: '/list', builder: (context, state) => const Scaffold(body: Text('옷장 목록'))),
          GoRoute(
            path: '/closet/:id',
            builder: (context, state) =>
                ClosetItemDetailScreen(itemId: state.pathParameters['id']!),
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

      router.push('/closet/test-item');
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      // 이 옷은 어떤 코디에도 안 쓰여 사용 중 확인 팝업 없이 바로 삭제된다(linkedCount == 0).
      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // pop되어 목록 화면으로 돌아왔다 — 옷 상세 화면의 element는 이미 dispose된 상태.
      expect(find.text('옷장 목록'), findsOneWidget);
      expect(find.byType(ClosetItemDetailScreen), findsNothing);
      expect(container.read(closetItemsProvider).first.isDeleted, isTrue);

      // "실행취소"를 지금(화면이 pop된 뒤) 누른다 — 고친 코드가 pop 이전에 notifier를 캡처해둔
      // 덕에 크래시 없이 복원돼야 한다.
      await tester.tap(find.text('실행취소'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(closetItemsProvider).first.isDeleted, isFalse);
    },
  );
}
