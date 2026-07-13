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
  static const compositionMain = '/composition';
  static const compositionDetail = '/composition/:id';
  static const compositionEditor = '/composition/editor';
  static const styleLogMain = '/style-log';
  static const styleLogViewer = '/style-log/:id';
  static const styleLogAdd = '/style-log/add';
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
