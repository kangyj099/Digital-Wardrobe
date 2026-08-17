import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/enums.dart';

void main() {
  ClothingItem base() => ClothingItem(
        id: 'c1',
        name: '테스트',
        category: ClothingCategory.top,
        color: ClothingColor.red,
        season: Season.summer,
        material: ClothingMaterial.cotton,
        imagePath: 'x.png',
        createdAt: DateTime(2026, 1, 1),
      );

  test('copyWith()에 아무것도 안 넘기면 기존 값이 전부 유지된다', () {
    final copy = base().copyWith();
    expect(copy.category, ClothingCategory.top);
    expect(copy.deletedAt, isNull);
  });

  test('copyWith(deletedAt: DateTime, isDeleted: true)는 소프트삭제를 표현한다', () {
    final deleted = base().copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    expect(deleted.deletedAt, DateTime(2026, 1, 1));
    expect(deleted.isDeleted, isTrue);
  });

  test('copyWith(deletedAt: null)은 deletedAt을 실제로 지운다(복원 시나리오)', () {
    final deleted = base().copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    final restored = deleted.copyWith(deletedAt: null, isDeleted: false);
    expect(restored.deletedAt, isNull);
    expect(restored.isDeleted, isFalse);
  });

  test('copyWith(category: null)은 category를 실제로 지운다', () {
    final cleared = base().copyWith(category: null);
    expect(cleared.category, isNull);
    expect(cleared.color, ClothingColor.red); // 다른 필드는 안 건드림
  });

  test('copyWith(season: null)/copyWith(color: null)/copyWith(material: null)도 동일하게 지운다', () {
    expect(base().copyWith(season: null).season, isNull);
    expect(base().copyWith(color: null).color, isNull);
    expect(base().copyWith(material: null).material, isNull);
  });

  test('hasGraphic/hasPattern/acquiredAt은 기본값이 null이다(미태깅 상태)', () {
    final item = base();
    expect(item.hasGraphic, isNull);
    expect(item.hasPattern, isNull);
    expect(item.acquiredAt, isNull);
  });

  test('hasGraphic false와 null은 다른 상태다', () {
    // false = "그래픽 없음"으로 판정됨, null = "아직 판정 안 됨".
    final tagged = base().copyWith(hasGraphic: false);
    expect(tagged.hasGraphic, isFalse);
    expect(tagged.copyWith(hasGraphic: null).hasGraphic, isNull);
  });

  test('hasGraphic과 hasPattern은 서로 독립이다(둘 다 true 가능)', () {
    final both = base().copyWith(hasGraphic: true, hasPattern: true);
    expect(both.hasGraphic, isTrue);
    expect(both.hasPattern, isTrue);
  });

  test('copyWith()는 안 넘긴 bool? 필드를 조용히 지우지 않는다', () {
    final tagged = base().copyWith(hasGraphic: true, hasPattern: false);
    final renamed = tagged.copyWith(name: '새 이름');
    expect(renamed.hasGraphic, isTrue);
    expect(renamed.hasPattern, isFalse);
  });

  test('acquiredAt은 createdAt과 독립이다', () {
    final item = base().copyWith(acquiredAt: DateTime(2020, 5, 1));
    expect(item.createdAt, DateTime(2026, 1, 1));
    expect(item.acquiredAt, DateTime(2020, 5, 1));
    expect(item.copyWith(acquiredAt: null).acquiredAt, isNull);
  });
}
