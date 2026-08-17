import '../models/enums.dart';
import '../models/user.dart';
import 'firestore_codec.dart';

/// `users/{uid}` 프로필 문서 ↔ [User].
///
/// 필드 목록의 정본은 `docs/reference/data/00_DataSchema.md` §2다.
///
/// **이 문서는 계정 연동 이후에만 존재한다**(§11). 연동 전에는 `unlinked_local` 스코프에서
/// 도메인 컬렉션만 쓰고 이 프로필 문서 자체를 만들지 않는다.
class UserMapper {
  const UserMapper._();

  static Map<String, Object?> toFirestore(User user) {
    return {
      'email': user.email,
      'authProvider': enumToName(user.authProvider),
      'createdAt': user.createdAt,
      'lastActiveAt': user.lastActiveAt,
      'lastSyncedAt': user.lastSyncedAt,
    };
  }

  static User fromFirestore(String id, Map<String, Object?> data) {
    return User(
      id: id,
      email: data['email'] is String ? data['email'] as String : null,
      authProvider: enumFromName(AuthProvider.values, data['authProvider']),
      createdAt: requiredDateTime(data['createdAt'], field: 'createdAt', documentId: id),
      lastActiveAt:
          requiredDateTime(data['lastActiveAt'], field: 'lastActiveAt', documentId: id),
      lastSyncedAt: dateTimeFromFirestore(data['lastSyncedAt']),
    );
  }
}
