import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/settings_screen.dart';
import '../widgets/overlay_header.dart';
import '../widgets/profile_icon_button.dart';

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

/// 04_설정.md §1 — 옷장/코디/스타일일지 메인 3개 루트 전용. OverlayHeader(C4)로
/// 감싸고 actions에 프로필 아이콘(Settings 진입점)을 추가한다. 내부 콘텐츠는
/// 아직 placeholder 그대로(실제 화면 구현은 이번 태스크 스코프 밖).
Widget _mainScreenWithHeader(String label) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          OverlayHeader(
            actions: const [ProfileIconButton()],
            child: Text(label),
          ),
          Expanded(child: Center(child: Text(label))),
        ],
      ),
    ),
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.closetMain,
    routes: [
      GoRoute(
        path: AppRoute.closetMain,
        builder: (context, state) => _mainScreenWithHeader('옷장 메인'),
      ),
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) => _placeholder('옷 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => _placeholder('옷 추가하기'),
      ),
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => _mainScreenWithHeader('코디 메인'),
      ),
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) => _placeholder('코디 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => _placeholder('코디 만들기'),
      ),
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => _mainScreenWithHeader('스타일일지 메인'),
      ),
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) => _placeholder('스타일일지 열람 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => _placeholder('스타일일지 추가'),
      ),
      GoRoute(
        path: AppRoute.settingsTrash,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
