import 'enums.dart';

/// 계정 프로필. **계정을 연동한 뒤에만 존재한다** — 연동 전에는 앱이 로컬 플레이스홀더
/// 스코프(`unlinked_local`)에서만 돌고 이 레코드 자체가 만들어지지 않는다
/// (`docs/reference/data/00_DataSchema.md` §11).
///
/// 그래서 [email]/[authProvider]는 연동 이후에만 채워진다.
class User {
  const User({
    required this.id,
    this.email,
    this.authProvider,
    required this.createdAt,
    required this.lastActiveAt,
    this.lastSyncedAt,
  });

  /// 연동으로 발급된 실제 인증 uid.
  final String id;

  /// 연동한 소셜 제공자의 프로필에서 가져온다(직접 입력받지 않는다).
  final String? email;

  final AuthProvider? authProvider;

  /// 계정 생성 시각 — 연동 시점이지 로컬 최초 사용 시점이 아니다.
  final DateTime createdAt;

  /// 최근 접속 시각. 앱 실행·재개마다 갱신되며 **오프라인에서도 갱신된다**(로컬 이벤트).
  final DateTime lastActiveAt;

  /// 마지막으로 서버 동기화가 실제로 완료된 시각. [lastActiveAt]과 달리 온라인일 때만
  /// 갱신된다 — 연동 직후 최초 동기화 전까지 null이다.
  final DateTime? lastSyncedAt;

  /// `copyWith`의 nullable 필드용 sentinel — "안 넘김"과 "명시적으로 null 넘김"을 구분한다.
  /// 리스트업: email/authProvider/lastSyncedAt 3개.
  static const Object _unset = Object();

  User copyWith({
    String? id,
    Object? email = _unset,
    Object? authProvider = _unset,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Object? lastSyncedAt = _unset,
  }) {
    return User(
      id: id ?? this.id,
      email: identical(email, _unset) ? this.email : email as String?,
      authProvider: identical(authProvider, _unset)
          ? this.authProvider
          : authProvider as AuthProvider?,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastSyncedAt:
          identical(lastSyncedAt, _unset) ? this.lastSyncedAt : lastSyncedAt as DateTime?,
    );
  }
}
