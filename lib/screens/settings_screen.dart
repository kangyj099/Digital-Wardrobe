import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import '../theme/app_spacing.dart';

/// 04_설정.md — Utility형 단일 화면(L9), 리스트-로우 2개(알림 토글, 로그아웃).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          SwitchListTile(
            title: const Text('알림'),
            value: notificationsEnabled,
            onChanged: (value) =>
                ref.read(notificationEnabledProvider.notifier).state = value,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('로그아웃', style: TextStyle(color: colorScheme.error)),
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    );
  }

  // 04_설정.md §3 — 블로킹 confirm 없이 즉시 로그아웃 + Toast+Undo.
  void _handleLogout(BuildContext context, WidgetRef ref) {
    ref.read(isLoggedInProvider.notifier).state = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('로그아웃되었습니다'),
        action: SnackBarAction(
          label: '실행취소',
          onPressed: () => ref.read(isLoggedInProvider.notifier).state = true,
        ),
      ),
    );
  }
}
