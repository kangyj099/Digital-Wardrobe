import 'package:flutter_riverpod/legacy.dart';

/// 알림 on/off 토글 — 04_설정.md §2 로우1. 저장 대상(로컬/서버, 권한 연동)은
/// Data/Architecture 레이어 결정 사항으로 스코프 밖 — 화면 내 상태 유지만 다룬다.
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

/// 로그인 상태 — 04_설정.md §3/§5. 실제 인증/세션 연동 없는 UI 셸 상태이며,
/// 로그아웃 Toast+Undo의 backing store. 기존 삭제-항목 상태 스토어(closet/composition/
/// style-log)와는 독립된 별도 스토어(§3 "C7 스코프 확장" 근거 참고).
final isLoggedInProvider = StateProvider<bool>((ref) => true);
