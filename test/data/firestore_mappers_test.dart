import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/data/clothing_item_mapper.dart';
import 'package:digittal_wardrobe/data/composition_mapper.dart';
import 'package:digittal_wardrobe/data/firestore_codec.dart';
import 'package:digittal_wardrobe/data/style_log_mapper.dart';
import 'package:digittal_wardrobe/data/user_mapper.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/models/user.dart';

/// 쓰기 경로는 `DateTime`을 그대로 넘기지만 Firestore는 읽을 때 `Timestamp`로 돌려준다.
/// 실제 읽기 경로를 흉내내려면 날짜를 `Timestamp`로 바꿔줘야 한다.
Map<String, Object?> asServerRead(Map<String, Object?> written) {
  return {
    for (final entry in written.entries)
      entry.key: entry.value is DateTime
          ? Timestamp.fromDate(entry.value as DateTime)
          : entry.value,
  };
}

void main() {
  group('firestore_codec', () {
    test('모르는 enum 이름은 던지지 않고 null이 된다', () {
      // 폐기됐거나 앱보다 새로운 버전이 쓴 값 하나로 문서 전체를 못 읽으면 안 된다.
      expect(enumFromName(ClothingColor.values, 'burgundy'), isNull);
      expect(enumFromName(ClothingColor.values, null), isNull);
      expect(enumFromName(ClothingColor.values, 42), isNull);
    });

    test('enum은 라벨이 아니라 이름으로 저장된다', () {
      expect(enumToName(ClothingColor.navy), 'navy');
      expect(enumToName(ClothingColor.multi), 'multi');
      expect(enumToName(null), isNull);
    });

    test('정수로 저장된 값도 double 필드로 읽힌다', () {
      // Firestore는 1.0을 int 1로 돌려줄 수 있어 `as double`이 터진다.
      expect(doubleOr(1, 0.0), 1.0);
      expect(doubleOr(0.5, 0.0), 0.5);
      expect(doubleOr(null, 9.0), 9.0);
    });

    test('필수 날짜가 없으면 어느 문서의 어느 필드인지 밝히며 던진다', () {
      expect(
        () => requiredDateTime(null, field: 'createdAt', documentId: 'doc-1'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', allOf(contains('doc-1'), contains('createdAt')))),
      );
    });

    test('문자열 배열에서 문자열 아닌 원소는 버린다', () {
      expect(stringListFrom(['a', 1, null, 'b']), ['a', 'b']);
      expect(stringListFrom(null), isEmpty);
    });
  });

  group('ClothingItemMapper', () {
    ClothingItem full() => ClothingItem(
          id: 'c01',
          name: '플로럴 원피스',
          category: ClothingCategory.onePiece,
          color: ClothingColor.pink,
          season: Season.springFall,
          material: ClothingMaterial.cotton,
          hasGraphic: true,
          hasPattern: false,
          imagePath: 'assets/x.png',
          createdAt: DateTime(2024, 3, 12),
          acquiredAt: DateTime(2024, 3, 2),
          location: '옷장 2단',
          memo: '메모',
          wearCount: 3,
          isIncomplete: true,
          isDeleted: true,
          deletedAt: DateTime(2026, 1, 1),
        );

    void expectSame(ClothingItem actual, ClothingItem expected) {
      expect(actual.id, expected.id);
      expect(actual.name, expected.name);
      expect(actual.category, expected.category);
      expect(actual.color, expected.color);
      expect(actual.season, expected.season);
      expect(actual.material, expected.material);
      expect(actual.hasGraphic, expected.hasGraphic);
      expect(actual.hasPattern, expected.hasPattern);
      expect(actual.imagePath, expected.imagePath);
      expect(actual.createdAt, expected.createdAt);
      expect(actual.acquiredAt, expected.acquiredAt);
      expect(actual.location, expected.location);
      expect(actual.memo, expected.memo);
      expect(actual.wearCount, expected.wearCount);
      expect(actual.isIncomplete, expected.isIncomplete);
      expect(actual.isDeleted, expected.isDeleted);
      expect(actual.deletedAt, expected.deletedAt);
    }

    test('모든 필드가 채워진 상태로 왕복한다', () {
      final item = full();
      expectSame(
        ClothingItemMapper.fromFirestore('c01', ClothingItemMapper.toFirestore(item)),
        item,
      );
    });

    test('Timestamp로 돌아온 서버 응답으로도 왕복한다', () {
      final item = full();
      final read = asServerRead(ClothingItemMapper.toFirestore(item));
      expectSame(ClothingItemMapper.fromFirestore('c01', read), item);
    });

    test('nullable 필드가 전부 null이어도 왕복한다', () {
      final minimal = ClothingItem(
        id: 'c99',
        name: '이름만',
        imagePath: '',
        createdAt: DateTime(2026, 5, 5),
      );
      final restored = ClothingItemMapper.fromFirestore(
          'c99', asServerRead(ClothingItemMapper.toFirestore(minimal)));
      expectSame(restored, minimal);
      expect(restored.color, isNull);
      expect(restored.hasGraphic, isNull);
      expect(restored.acquiredAt, isNull);
    });

    test('nullable 필드는 키를 생략하지 않고 명시적 null로 쓴다', () {
      final data = ClothingItemMapper.toFirestore(
        ClothingItem(id: 'c99', name: 'x', imagePath: '', createdAt: DateTime(2026, 1, 1)),
      );
      expect(data.containsKey('color'), isTrue);
      expect(data['color'], isNull);
      expect(data.containsKey('acquiredAt'), isTrue);
    });

    test('색상은 한글 라벨이 아니라 enum 이름으로 저장된다', () {
      final data = ClothingItemMapper.toFirestore(full());
      expect(data['color'], 'pink');
    });
  });

  group('StyleLogMapper', () {
    StyleLog full() => StyleLog(
          id: 'log01',
          coverImagePath: 'assets/cover.png',
          createdAt: DateTime(2026, 1, 6),
          wornDate: DateTime(2026, 1, 5),
          linkedCompositionId: 'comp01',
          wornItemIds: const ['c11', 'c07'],
          additionalImagePaths: const ['a.png', 'b.png'],
          season: Season.springFall,
          weather: Weather.clear,
          location: '집',
        );

    void expectSame(StyleLog actual, StyleLog expected) {
      expect(actual.id, expected.id);
      expect(actual.coverImagePath, expected.coverImagePath);
      expect(actual.createdAt, expected.createdAt);
      expect(actual.wornDate, expected.wornDate);
      expect(actual.linkedCompositionId, expected.linkedCompositionId);
      expect(actual.wornItemIds, expected.wornItemIds);
      expect(actual.additionalImagePaths, expected.additionalImagePaths);
      expect(actual.season, expected.season);
      expect(actual.weather, expected.weather);
      expect(actual.location, expected.location);
      expect(actual.isDeleted, expected.isDeleted);
    }

    test('모든 필드가 채워진 상태로 왕복한다', () {
      final log = full();
      expectSame(
        StyleLogMapper.fromFirestore('log01', asServerRead(StyleLogMapper.toFirestore(log))),
        log,
      );
    });

    test('착용일이 null이어도 등록일은 살아서 왕복한다', () {
      final log = StyleLog(
        id: 'log02',
        coverImagePath: '',
        createdAt: DateTime(2026, 3, 9),
      );
      final restored =
          StyleLogMapper.fromFirestore('log02', asServerRead(StyleLogMapper.toFirestore(log)));
      expect(restored.wornDate, isNull);
      expect(restored.createdAt, DateTime(2026, 3, 9));
    });

    test('createdAt과 wornDate가 서로 뒤바뀌지 않는다', () {
      final data = StyleLogMapper.toFirestore(full());
      expect(data['createdAt'], DateTime(2026, 1, 6));
      expect(data['wornDate'], DateTime(2026, 1, 5));
    });

    test('wornItemIds와 additionalImagePaths는 별개 필드로 저장된다', () {
      final data = StyleLogMapper.toFirestore(full());
      expect(data['wornItemIds'], ['c11', 'c07']);
      expect(data['additionalImagePaths'], ['a.png', 'b.png']);
    });
  });

  group('UserMapper', () {
    test('연동된 계정이 왕복한다', () {
      final user = User(
        id: 'uid-1',
        email: 'someone@example.com',
        authProvider: AuthProvider.google,
        createdAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 2),
        lastSyncedAt: DateTime(2026, 1, 2),
      );
      final restored =
          UserMapper.fromFirestore('uid-1', asServerRead(UserMapper.toFirestore(user)));
      expect(restored.id, 'uid-1');
      expect(restored.email, user.email);
      expect(restored.authProvider, AuthProvider.google);
      expect(restored.createdAt, user.createdAt);
      expect(restored.lastActiveAt, user.lastActiveAt);
      expect(restored.lastSyncedAt, user.lastSyncedAt);
    });

    test('아직 동기화 안 된 계정은 lastSyncedAt이 null인 채로 왕복한다', () {
      final user = User(
        id: 'uid-2',
        createdAt: DateTime(2026, 1, 1),
        lastActiveAt: DateTime(2026, 1, 1),
      );
      final restored =
          UserMapper.fromFirestore('uid-2', asServerRead(UserMapper.toFirestore(user)));
      expect(restored.lastSyncedAt, isNull);
      expect(restored.email, isNull);
      expect(restored.authProvider, isNull);
    });
  });

  group('CompositionMapper', () {
    Composition full() => Composition(
          id: 'comp01',
          name: '데일리 룩',
          createdAt: DateTime(2025, 3, 10),
          season: Season.springFall,
          weather: Weather.clear,
          coverImagePath: 'assets/cover.png',
          backgroundColor: ArtboardBackgroundColor.lightGray,
          items: const [
            CompositionItemPlacement(clothingItemId: 'c01', x: 0.3, y: 0.25, zIndex: 0),
            CompositionItemPlacement(
                clothingItemId: 'c11', x: 0.7, y: 0.65, scale: 1.5, rotation: 0.4, zIndex: 3),
          ],
        );

    test('아이템 배치까지 값이 보존된 채 왕복한다', () {
      final composition = full();
      final restored = CompositionMapper.fromFirestore(
          'comp01', asServerRead(CompositionMapper.toFirestore(composition)));

      expect(restored.name, composition.name);
      expect(restored.createdAt, composition.createdAt);
      expect(restored.backgroundColor, ArtboardBackgroundColor.lightGray);
      expect(restored.coverImagePath, 'assets/cover.png');
      expect(restored.items.length, 2);
      expect(restored.items[1].clothingItemId, 'c11');
      expect(restored.items[1].x, 0.7);
      expect(restored.items[1].scale, 1.5);
      expect(restored.items[1].rotation, 0.4);
      expect(restored.items[1].zIndex, 3);
    });

    test('아이템 순서가 유지된다', () {
      final restored = CompositionMapper.fromFirestore(
          'comp01', asServerRead(CompositionMapper.toFirestore(full())));
      expect(restored.items.map((p) => p.clothingItemId).toList(), ['c01', 'c11']);
    });

    test('clothingItemId가 없는 배치는 버린다', () {
      final restored = CompositionMapper.fromFirestore('comp01', {
        'name': 'x',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'items': [
          {'x': 0.1, 'y': 0.1},
          {'clothingItemId': 'c01', 'x': 0.2, 'y': 0.2},
        ],
      });
      expect(restored.items.length, 1);
      expect(restored.items.single.clothingItemId, 'c01');
    });

    test('아이템 좌표가 정수로 저장돼 있어도 읽힌다', () {
      final restored = CompositionMapper.fromFirestore('comp01', {
        'name': 'x',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'items': [
          {'clothingItemId': 'c01', 'x': 0, 'y': 1, 'scale': 1, 'rotation': 0},
        ],
      });
      expect(restored.items.single.x, 0.0);
      expect(restored.items.single.scale, 1.0);
    });

    test('빈 코디도 왕복한다', () {
      final empty = Composition(
        id: 'comp99',
        name: '빈 코디',
        items: const [],
        createdAt: DateTime(2026, 2, 2),
        isIncomplete: true,
      );
      final restored = CompositionMapper.fromFirestore(
          'comp99', asServerRead(CompositionMapper.toFirestore(empty)));
      expect(restored.items, isEmpty);
      expect(restored.isIncomplete, isTrue);
      expect(restored.backgroundColor, isNull);
    });
  });
}
