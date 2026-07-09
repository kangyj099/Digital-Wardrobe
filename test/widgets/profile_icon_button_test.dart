import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/widgets/profile_icon_button.dart';

void main() {
  testWidgets('탭하면 Settings 라우트로 push된다', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: ProfileIconButton()),
        ),
        GoRoute(
          path: AppRoute.settingsTrash,
          builder: (context, state) => const Scaffold(body: Text('설정 화면')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('설정 화면'), findsOneWidget);
  });
}
