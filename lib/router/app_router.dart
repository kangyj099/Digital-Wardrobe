import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/closet_main_screen.dart';
import '../screens/composition_main_screen.dart';

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
  static const settingsTrash = '/settings';
}

Widget _placeholder(String label) => Scaffold(body: Center(child: Text(label)));

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
        builder: (context, state) => _placeholder('옷 추가하기'),
      ),
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) => _placeholder('옷 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => const CompositionMainScreen(),
      ),
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => _placeholder('코디 만들기'),
      ),
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) => _placeholder('코디 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => _placeholder('스타일일지 메인'),
      ),
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => _placeholder('스타일일지 추가'),
      ),
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) => _placeholder('스타일일지 열람 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.settingsTrash,
        builder: (context, state) => _placeholder('설정/휴지통'),
      ),
    ],
  );
});
