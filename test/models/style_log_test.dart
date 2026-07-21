import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/style_log.dart';

void main() {
  StyleLog base() => StyleLog(
        id: 'l1',
        coverImagePath: 'x.png',
        wornDate: DateTime(2026, 1, 1),
        linkedCompositionId: 'comp01',
      );

  test('copyWith()에 아무것도 안 넘기면 기존 값 유지', () {
    expect(base().copyWith().linkedCompositionId, 'comp01');
  });

  test('copyWith(linkedCompositionId: null)은 실제로 연결을 끊는다', () {
    expect(base().copyWith(linkedCompositionId: null).linkedCompositionId, isNull);
  });

  test('copyWith(deletedAt: null)은 deletedAt을 실제로 지운다', () {
    final deleted = base().copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    final restored = deleted.copyWith(deletedAt: null, isDeleted: false);
    expect(restored.deletedAt, isNull);
  });
}
