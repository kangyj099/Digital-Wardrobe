import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/style_log.dart';

void main() {
  StyleLog base() => StyleLog(
        id: 'l1',
        coverImagePath: 'x.png',
        createdAt: DateTime(2026, 1, 1),
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

  test('copyWith(wornDate: null)은 착용일을 실제로 지운다', () {
    expect(base().copyWith(wornDate: null).wornDate, isNull);
  });

  test('copyWith()는 wornDate를 안 넘겼을 때 기존 착용일을 유지한다', () {
    // sentinel이 없으면 "안 넘김"이 null로 뭉개져 착용일이 조용히 지워진다.
    expect(base().copyWith(location: '집').wornDate, DateTime(2026, 1, 1));
  });

  test('createdAt과 wornDate는 서로 독립이다', () {
    final copy = base().copyWith(wornDate: DateTime(2025, 12, 24));
    expect(copy.createdAt, DateTime(2026, 1, 1));
    expect(copy.wornDate, DateTime(2025, 12, 24));
  });

  test('additionalImagePaths는 기본값이 빈 리스트다', () {
    expect(base().additionalImagePaths, isEmpty);
  });

  test('additionalImagePaths는 wornItemIds와 별개로 보존된다', () {
    final copy = base().copyWith(
      additionalImagePaths: const ['a.png', 'b.png'],
      wornItemIds: const ['c01'],
    );
    expect(copy.additionalImagePaths, ['a.png', 'b.png']);
    expect(copy.wornItemIds, ['c01']);
  });
}
