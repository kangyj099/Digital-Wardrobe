import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/trash_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  final container = ProviderContainer();
  purgeExpiredTrash(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DigitalWardrobeApp(),
    ),
  );
}

class DigitalWardrobeApp extends ConsumerWidget {
  const DigitalWardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Digital Wardrobe',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
