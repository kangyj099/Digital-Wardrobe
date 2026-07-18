import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/closet_add_screen.dart';
import '../screens/closet_item_detail_screen.dart';
import '../screens/closet_main_screen.dart';
import '../screens/composition_detail_screen.dart';
import '../screens/composition_editor_screen.dart';
import '../screens/composition_main_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/style_log_add_screen.dart';
import '../screens/style_log_main_screen.dart';
import '../screens/style_log_viewer_screen.dart';
import '../screens/trash_main_screen.dart';

class AppRoute {
  AppRoute._();

  static const closetMain = '/closet';
  static const closetItemDetail = '/closet/:id';
  static const closetAdd = '/closet/add';
  static const closetSelect = '/closet/select';
  static const compositionMain = '/composition';
  static const compositionDetail = '/composition/:id';
  static const compositionEditor = '/composition/editor';
  static const compositionSelect = '/composition/select';
  static const styleLogMain = '/style-log';
  static const styleLogViewer = '/style-log/:id';
  static const styleLogAdd = '/style-log/add';
  static const styleLogSelect = '/style-log/select';
  static const settingsMain = '/settings';
  static const trashMain = '/trash';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.closetMain,
    routes: [
      GoRoute(
        path: AppRoute.closetMain,
        builder: (context, state) => const ClosetMainScreen(),
      ),
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => const ClosetAddScreen(),
      ),
      GoRoute(
        // 선택 모달(옷장 재호출) — 별도 화면 없이 옷장 메인을 selectionMode:true로 재호출
        // (`docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1). 실제
        // 호출부(Composition Editor 등) 연결은 Step⑦ 몫 — 지금은 URL 직접 진입으로만 확인.
        path: AppRoute.closetSelect,
        builder: (context, state) => const ClosetMainScreen(selectionMode: true),
      ),
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) =>
            ClosetItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => const CompositionMainScreen(),
      ),
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => const CompositionEditorScreen(),
      ),
      GoRoute(
        // 선택 모달(코디 재호출).
        path: AppRoute.compositionSelect,
        builder: (context, state) => const CompositionMainScreen(selectionMode: true),
      ),
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) =>
            CompositionDetailScreen(compositionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => const StyleLogMainScreen(),
      ),
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => const StyleLogAddScreen(),
      ),
      GoRoute(
        // 선택 모달(스타일일지 재호출).
        path: AppRoute.styleLogSelect,
        builder: (context, state) => const StyleLogMainScreen(selectionMode: true),
      ),
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) =>
            StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.settingsMain,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.trashMain,
        builder: (context, state) => const TrashMainScreen(),
      ),
    ],
  );
});
