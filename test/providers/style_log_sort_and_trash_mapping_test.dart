import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';

class _FixedStyleLogsNotifier extends StyleLogsNotifier {
  _FixedStyleLogsNotifier(List<StyleLog> initial) {
    state = initial;
  }
}

StyleLog log(String id, {DateTime? wornDate, DateTime? createdAt, bool isDeleted = false}) {
  return StyleLog(
    id: id,
    coverImagePath: '',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    wornDate: wornDate,
    isDeleted: isDeleted,
    deletedAt: isDeleted ? DateTime.now() : null,
  );
}

ProviderContainer containerWith(List<StyleLog> logs) {
  final container = ProviderContainer(
    overrides: [styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier(logs))],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('filteredStyleLogsProvider 정렬', () {
    test('착용일이 있는 항목은 최신 먼저 온다', () {
      final container = containerWith([
        log('old', wornDate: DateTime(2025, 1, 1)),
        log('new', wornDate: DateTime(2026, 6, 1)),
        log('mid', wornDate: DateTime(2026, 1, 1)),
      ]);

      final ids = container.read(filteredStyleLogsProvider).map((l) => l.id).toList();
      expect(ids, ['new', 'mid', 'old']);
    });

    test('착용일이 null인 항목은 최신/최고령 어느 쪽도 아니라 맨 뒤로 간다', () {
      final container = containerWith([
        log('nodate'),
        log('new', wornDate: DateTime(2026, 6, 1)),
        log('old', wornDate: DateTime(2020, 1, 1)),
      ]);

      final ids = container.read(filteredStyleLogsProvider).map((l) => l.id).toList();
      expect(ids, ['new', 'old', 'nodate']);
    });

    test('착용일이 null인 항목이 여럿이면 전부 뒤에 모인다', () {
      final container = containerWith([
        log('nodate1'),
        log('dated', wornDate: DateTime(2026, 6, 1)),
        log('nodate2'),
      ]);

      final ids = container.read(filteredStyleLogsProvider).map((l) => l.id).toList();
      expect(ids.first, 'dated');
      expect(ids.sublist(1), containsAll(['nodate1', 'nodate2']));
    });

    test('전부 착용일이 null이어도 터지지 않는다', () {
      final container = containerWith([log('a'), log('b')]);
      expect(container.read(filteredStyleLogsProvider).length, 2);
    });

    test('삭제된 항목은 애초에 목록에서 빠진다', () {
      final container = containerWith([
        log('kept', wornDate: DateTime(2026, 1, 1)),
        log('gone', wornDate: DateTime(2026, 2, 1), isDeleted: true),
      ]);

      final ids = container.read(filteredStyleLogsProvider).map((l) => l.id).toList();
      expect(ids, ['kept']);
    });
  });

  group('TrashEntry.createdAt 매핑', () {
    test('스타일일지의 제작일은 wornDate가 아니라 createdAt에서 온다', () {
      final container = containerWith([
        log('trashed',
            createdAt: DateTime(2026, 3, 9),
            wornDate: DateTime(2024, 8, 1),
            isDeleted: true),
      ]);

      final entry =
          container.read(trashEntriesProvider).firstWhere((e) => e.id == 'trashed');
      expect(entry.category, AppCategory.styleLog);
      expect(entry.createdAt, DateTime(2026, 3, 9));
    });

    test('착용일을 안 적은 스타일일지도 제작일이 비지 않는다', () {
      // wornDate를 매핑하던 시절엔 이 경우 "제작일"이 빈칸이 됐다.
      final container = containerWith([
        log('nodate', createdAt: DateTime(2026, 3, 9), isDeleted: true),
      ]);

      final entry =
          container.read(trashEntriesProvider).firstWhere((e) => e.id == 'nodate');
      expect(entry.createdAt, DateTime(2026, 3, 9));
    });
  });
}
