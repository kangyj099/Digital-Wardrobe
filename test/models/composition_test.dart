import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';

void main() {
  Composition base() => Composition(
        id: 'comp1',
        name: '테스트 코디',
        items: const [],
        createdAt: DateTime(2026, 1, 1),
        season: Season.summer,
        weather: Weather.clear,
        coverImagePath: 'x.png',
      );

  test('copyWith()에 아무것도 안 넘기면 기존 값 유지', () {
    expect(base().copyWith().season, Season.summer);
  });

  test('copyWith(season: null)/copyWith(weather: null)/copyWith(coverImagePath: null)은 실제로 지운다', () {
    expect(base().copyWith(season: null).season, isNull);
    expect(base().copyWith(weather: null).weather, isNull);
    expect(base().copyWith(coverImagePath: null).coverImagePath, isNull);
  });

  test('copyWith(deletedAt: null)은 deletedAt을 실제로 지운다', () {
    final deleted = base().copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    final restored = deleted.copyWith(deletedAt: null, isDeleted: false);
    expect(restored.deletedAt, isNull);
  });
}
