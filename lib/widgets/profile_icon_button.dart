import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// 04_설정.md §1 — 헤더 우측 `actions` 슬롯에 배치되는 Settings 진입점.
/// 옷장/코디/스타일일지 메인 3개 화면의 OverlayHeader에서 재사용한다.
class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(AppRoute.settingsTrash),
      icon: const Icon(Icons.person_outline),
      tooltip: '설정',
    );
  }
}
