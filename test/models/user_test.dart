import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/models/user.dart';

void main() {
  User linked() => User(
        id: 'uid-1',
        email: 'someone@example.com',
        authProvider: AuthProvider.google,
        createdAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 2),
        lastSyncedAt: DateTime(2026, 1, 2),
      );

  test('연동 전 상태는 email/authProvider/lastSyncedAt이 전부 null이다', () {
    final unlinked = User(
      id: 'unlinked_local',
      createdAt: DateTime(2026, 1, 1),
      lastActiveAt: DateTime(2026, 1, 1),
    );
    expect(unlinked.email, isNull);
    expect(unlinked.authProvider, isNull);
    expect(unlinked.lastSyncedAt, isNull);
  });

  test('copyWith()에 아무것도 안 넘기면 기존 값이 전부 유지된다', () {
    final copy = linked().copyWith();
    expect(copy.email, 'someone@example.com');
    expect(copy.authProvider, AuthProvider.google);
    expect(copy.lastSyncedAt, DateTime(2026, 1, 2));
  });

  test('copyWith(lastSyncedAt: null)은 동기화 기록을 실제로 지운다', () {
    expect(linked().copyWith(lastSyncedAt: null).lastSyncedAt, isNull);
  });

  test('lastActiveAt만 갱신해도 lastSyncedAt은 안 딸려간다', () {
    // 최근 접속은 오프라인에서도 갱신되지만 동기화 시각은 온라인일 때만 갱신된다.
    final touched = linked().copyWith(lastActiveAt: DateTime(2026, 3, 9));
    expect(touched.lastActiveAt, DateTime(2026, 3, 9));
    expect(touched.lastSyncedAt, DateTime(2026, 1, 2));
  });

  test('copyWith(email: null)/copyWith(authProvider: null)은 연동 해제를 표현한다', () {
    final unlinked = linked().copyWith(email: null, authProvider: null);
    expect(unlinked.email, isNull);
    expect(unlinked.authProvider, isNull);
  });
}
