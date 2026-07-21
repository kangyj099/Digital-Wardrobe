# 다중선택 + 휴지통 실행 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 옷장/코디/스타일일지/휴지통 4개 Main형 화면에 다중선택(진입/체크/하단버튼)을 추가하고, 휴지통의 복원/영구삭제/비우기를 실제로 동작시킨다.

**Architecture:** `GalleryMainScreen<T>` 제네릭 셸을 신설해 4개 화면이 공유하고, 분류(그룹형) 기능은 `ClassificationConfig<T>?`로 옵트인한다. 다중선택 상태는 이 위젯의 로컬 State. 삭제/복원/영구삭제는 도메인별 Notifier(`softDeleteMany`/`restoreMany`/`purgeMany`)가 실행하고, 휴지통은 3도메인을 집계하는 `Provider.autoDispose`로 표시한다.

**Tech Stack:** Flutter, Riverpod(`flutter_riverpod`+`flutter_riverpod/legacy.dart`의 `StateNotifierProvider`/`StateProvider`), go_router.

**스펙**: `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` (섹션 번호는 이 문서를 가리킴)

## Global Constraints

- Header/HUD Pinned Rule: 조작 요소는 각각 독립된 `GlassPill`/`GlassCircleButton`이어야 하며, 하나의 Container/Row로 합쳐 Bar처럼 렌더링하지 않는다(`lib/widgets/app_main_scaffold.dart` 상단 독스트링).
- `classification == null`인 화면(스타일일지/휴지통)은 밀도 `AppDensity.mid` 고정(§2.1).
- 영구삭제(`purgeMany`)는 실제로 데이터를 제거한다 — 캐스케이드 배지 UX는 만들지 않고 안전 가드만 추가한다(§3.7).
- Windows에서 `flutter test integration_test/<file> -d windows` 연속 실행 전엔 매번 `taskkill //F //IM digittal_wardrobe.exe`.
- 각 Task 끝에서 `flutter analyze`(전체) + `flutter test`(전체 unit/widget) 실행, 통과 확인 후 커밋.

---

### Task 1: 모델 — `deletedAt` 필드 + `copyWith` sentinel 패턴 (3개 모델)

**Files:**
- Modify: `lib/models/clothing_item.dart`
- Modify: `lib/models/style_log.dart`
- Modify: `lib/models/composition.dart` (신규 `copyWith` 작성)
- Test: `test/models/clothing_item_test.dart` (신규)
- Test: `test/models/style_log_test.dart` (신규)
- Test: `test/models/composition_test.dart` (신규)

**Interfaces:**
- Produces: `ClothingItem.deletedAt`(`DateTime?`), `ClothingItem.copyWith({..., Object? deletedAt = _unset, bool? isDeleted})`가 `null`을 명시적으로 지울 수 있음. `Composition`/`StyleLog` 동일.

- [ ] **Step 1: `ClothingItem` 유닛테스트 작성 (실패 예상)**

`test/models/clothing_item_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';

void main() {
  final base = ClothingItem(
    id: 'c1',
    name: '테스트',
    category: null,
    imagePath: 'x.png',
    createdAt: DateTime(2026, 1, 1),
  );

  test('copyWith(category: null)은 미지정이 아니라 실제로 null로 지운다', () {
    final withCategory = base.copyWith(category: () => null); // 컴파일 확인용, 아래 실제 시그니처로 교체됨
  });

  test('copyWith()에 아무것도 안 넘기면 기존 deletedAt이 유지된다', () {
    final deleted = base.copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    final unchanged = deleted.copyWith(isDeleted: true);
    expect(unchanged.deletedAt, DateTime(2026, 1, 1));
  });

  test('copyWith(deletedAt: null)은 deletedAt을 실제로 지운다(복원 시나리오)', () {
    final deleted = base.copyWith(deletedAt: DateTime(2026, 1, 1), isDeleted: true);
    final restored = deleted.copyWith(deletedAt: null, isDeleted: false);
    expect(restored.deletedAt, isNull);
    expect(restored.isDeleted, isFalse);
  });

  test('copyWith(color: null)은 color를 실제로 지운다', () {
    final withColor = base.copyWith(color: 'red');
    final cleared = withColor.copyWith(color: null);
    expect(cleared.color, isNull);
  });
}
```

위 첫 번째 test(`copyWith(category: () => null)`)는 잘못된 시그니처를 일부러 넣은 게 아니라 삭제 대상이다 — 아래처럼 정리한다. `test/models/clothing_item_test.dart`를 다음 최종본으로 바로 작성한다(위 초안 대신):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/clothing_item.dart';
import 'package:digittal_wardrobe/models/enums.dart';

void main() {
  ClothingItem base() => ClothingItem(
        id: 'c1',
        name: '테스트',
        category: ClothingCategory.top,
        color: 'red',
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
    expect(cleared.color, 'red'); // 다른 필드는 안 건드림
  });

  test('copyWith(season: null)/copyWith(color: null)/copyWith(material: null)도 동일하게 지운다', () {
    expect(base().copyWith(season: null).season, isNull);
    expect(base().copyWith(color: null).color, isNull);
    expect(base().copyWith(material: null).material, isNull);
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/models/clothing_item_test.dart`
Expected: `copyWith(deletedAt: ...)`/`copyWith(category: null)` 관련 컴파일 에러(아직 `deletedAt` 파라미터가 없고, `category: null`은 현재 시그니처상 "미지정"과 동일해 테스트가 실패함).

- [ ] **Step 3: `ClothingItem`에 sentinel 패턴 적용**

`lib/models/clothing_item.dart` 전체를 다음으로 교체:
```dart
import 'enums.dart';

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    this.category,
    this.color,
    this.season,
    this.material,
    required this.imagePath,
    required this.createdAt,
    this.location = '',
    this.memo = '',
    this.wearCount = 0,
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final ClothingCategory? category;
  final String? color;
  final Season? season;
  final ClothingMaterial? material;
  final String imagePath;
  final DateTime createdAt;
  final String location;
  final String memo;
  final int wearCount;
  final bool isIncomplete;
  final bool isDeleted;

  /// 휴지통 이동 시각 — `isDeleted:true`와 함께 세팅, 복원 시 다시 null.
  /// `daysUntilPurge` 계산 근거(`docs/providers/trash_providers.dart`).
  final DateTime? deletedAt;

  /// `copyWith`의 nullable 필드용 sentinel — 파라미터 기본값으로 써서 "안 넘김"과
  /// "명시적으로 null 넘김"을 구분한다(`identical` 비교). 리스트업: category/color/season/
  /// material/deletedAt 5개(`docs/history/TechnicalDebt.md` 원 버그 항목 참고).
  static const Object _unset = Object();

  ClothingItem copyWith({
    String? id,
    String? name,
    Object? category = _unset,
    Object? color = _unset,
    Object? season = _unset,
    Object? material = _unset,
    String? imagePath,
    DateTime? createdAt,
    String? location,
    String? memo,
    int? wearCount,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: identical(category, _unset) ? this.category : category as ClothingCategory?,
      color: identical(color, _unset) ? this.color : color as String?,
      season: identical(season, _unset) ? this.season : season as Season?,
      material: identical(material, _unset) ? this.material : material as ClothingMaterial?,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
```

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run: `flutter test test/models/clothing_item_test.dart`
Expected: PASS (5개 테스트 전부)

- [ ] **Step 5: `StyleLog` 유닛테스트 작성**

`test/models/style_log_test.dart`(신규):
```dart
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
```

- [ ] **Step 6: 테스트 실행해서 실패 확인**

Run: `flutter test test/models/style_log_test.dart`
Expected: FAIL(`deletedAt` 파라미터 없음, `linkedCompositionId: null` 미반영)

- [ ] **Step 7: `StyleLog`에 sentinel 패턴 적용**

`lib/models/style_log.dart` 전체를 다음으로 교체:
```dart
class StyleLog {
  const StyleLog({
    required this.id,
    required this.coverImagePath,
    required this.wornDate,
    this.linkedCompositionId,
    this.additionalImagePaths = const [],
    this.location = '',
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;
  final List<String> additionalImagePaths;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;
  final DateTime? deletedAt;

  static const Object _unset = Object();

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? wornDate,
    Object? linkedCompositionId = _unset,
    List<String>? additionalImagePaths,
    String? location,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return StyleLog(
      id: id ?? this.id,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      wornDate: wornDate ?? this.wornDate,
      linkedCompositionId: identical(linkedCompositionId, _unset)
          ? this.linkedCompositionId
          : linkedCompositionId as String?,
      additionalImagePaths: additionalImagePaths ?? this.additionalImagePaths,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
```

- [ ] **Step 8: 테스트 재실행해서 통과 확인**

Run: `flutter test test/models/style_log_test.dart`
Expected: PASS

- [ ] **Step 9: `Composition` 유닛테스트 작성**

`test/models/composition_test.dart`(신규):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/enums.dart';

void main() {
  Composition base() => const Composition(
        id: 'comp1',
        name: '테스트 코디',
        items: [],
        createdAt: null,
      ).copyWith(createdAt: DateTime(2026, 1, 1), season: Season.summer, weather: Weather.clear, coverImagePath: 'x.png');

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
```

`Composition({required id, required name, required items, required createdAt, ...})`는 `createdAt`이 `required`라 위 `base()`의 `const Composition(..., createdAt: null)` 초기화는 컴파일되지 않는다 — Step 9의 `base()`를 아래로 바로 수정해서 작성한다:
```dart
Composition base() => Composition(
      id: 'comp1',
      name: '테스트 코디',
      items: const [],
      createdAt: DateTime(2026, 1, 1),
      season: Season.summer,
      weather: Weather.clear,
      coverImagePath: 'x.png',
    );
```

- [ ] **Step 10: 테스트 실행해서 실패 확인**

Run: `flutter test test/models/composition_test.dart`
Expected: FAIL(`copyWith` 메서드 자체가 없어 컴파일 에러)

- [ ] **Step 11: `Composition`에 `copyWith` 신규 작성(처음부터 sentinel)**

`lib/models/composition.dart`의 `Composition` 클래스에 `deletedAt` 필드와 `copyWith`를 추가(파일 전체 교체):
```dart
import 'enums.dart';

class CompositionItemPlacement {
  const CompositionItemPlacement({
    required this.clothingItemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  final String clothingItemId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
}

class Composition {
  const Composition({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.season,
    this.weather,
    this.coverImagePath,
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;
  final DateTime createdAt;
  final Season? season;
  final Weather? weather;
  final String? coverImagePath;
  final bool isIncomplete;
  final bool isDeleted;
  final DateTime? deletedAt;

  static const Object _unset = Object();

  Composition copyWith({
    String? id,
    String? name,
    List<CompositionItemPlacement>? items,
    DateTime? createdAt,
    Object? season = _unset,
    Object? weather = _unset,
    Object? coverImagePath = _unset,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return Composition(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      season: identical(season, _unset) ? this.season : season as Season?,
      weather: identical(weather, _unset) ? this.weather : weather as Weather?,
      coverImagePath: identical(coverImagePath, _unset) ? this.coverImagePath : coverImagePath as String?,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
```

- [ ] **Step 12: 테스트 재실행해서 통과 확인**

Run: `flutter test test/models/composition_test.dart`
Expected: PASS

- [ ] **Step 13: 전체 unit/widget 테스트 + analyze로 회귀 확인**

Run: `flutter analyze && flutter test`
Expected: 기존 66개 + 신규 12개(3파일) 전부 PASS, analyze는 기존 6개 경고만.

- [ ] **Step 14: `docs/history/TechnicalDebt.md`의 `copyWith` nullable 필드 항목 해소 처리**

`docs/history/TechnicalDebt.md`에서 "[TechDebt] `ClothingItem.copyWith`가 nullable 필드..." 항목(270~283행 부근)의 "상태: 미해결" 줄을 다음으로 교체:
```
상태: 해소(2026-07-21) — sentinel 패턴 채택, `ClothingItem`(category/color/season/material/deletedAt)/`StyleLog`(linkedCompositionId/deletedAt)/`Composition`(season/weather/coverImagePath/deletedAt, 신규 작성) 전체 적용. 다중선택+휴지통 그룹 B의 `restoreMany`가 실제 소비자.
```

- [ ] **Step 15: 커밋**

```bash
git add lib/models/clothing_item.dart lib/models/style_log.dart lib/models/composition.dart test/models/clothing_item_test.dart test/models/style_log_test.dart test/models/composition_test.dart docs/history/TechnicalDebt.md
git commit -m "feat(models): add deletedAt field and fix copyWith null-clearing via sentinel pattern"
```

---

### Task 2: 도메인 Notifier — `softDeleteMany`/`restoreMany`/`purgeMany`

**Files:**
- Modify: `lib/providers/closet_providers.dart`
- Modify: `lib/providers/composition_providers.dart`
- Modify: `lib/providers/style_log_providers.dart`
- Test: `test/providers/closet_providers_test.dart` (기존 파일에 추가)
- Test: `test/providers/composition_providers_test.dart` (기존 파일에 추가)
- Test: `test/providers/style_log_providers_test.dart` (신규 — 지금 이 provider의 전용 테스트 파일이 없으면 신규 생성)

**Interfaces:**
- Consumes: Task 1의 `ClothingItem.copyWith`/`Composition.copyWith`/`StyleLog.copyWith` (deletedAt sentinel 포함)
- Produces: `ClosetItemsNotifier.softDeleteMany(Set<String>)`/`.restoreMany(Set<String>)`/`.purgeMany(Set<String>)`, `CompositionsNotifier` 동일 3종, `StyleLogsNotifier` 동일 3종. `ClosetItemsNotifier.softDelete(String)`(기존 시그니처 유지).

- [ ] **Step 1: 옷장 Notifier 테스트 추가(실패 예상)**

`test/providers/closet_providers_test.dart`에 다음 테스트 3개 추가(기존 파일 마지막에 `group`이나 개별 `test`로 이어붙임 — 기존 `import` 구문은 그대로 두고 파일 하단에 추가):
```dart
test('softDeleteMany는 대상 id들만 isDeleted:true, deletedAt 세팅한다', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(closetItemsProvider.notifier);
  notifier.softDeleteMany({'c01', 'c02'});
  final items = container.read(closetItemsProvider);
  final c01 = items.firstWhere((i) => i.id == 'c01');
  final c03 = items.firstWhere((i) => i.id == 'c03');
  expect(c01.isDeleted, isTrue);
  expect(c01.deletedAt, isNotNull);
  expect(c03.isDeleted, isFalse);
});

test('restoreMany는 isDeleted를 false로, deletedAt을 null로 되돌린다', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(closetItemsProvider.notifier);
  notifier.softDeleteMany({'c01'});
  notifier.restoreMany({'c01'});
  final c01 = container.read(closetItemsProvider).firstWhere((i) => i.id == 'c01');
  expect(c01.isDeleted, isFalse);
  expect(c01.deletedAt, isNull);
});

test('purgeMany는 리스트에서 완전히 제거한다', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(closetItemsProvider.notifier);
  final before = container.read(closetItemsProvider).length;
  notifier.purgeMany({'c01'});
  final items = container.read(closetItemsProvider);
  expect(items.length, before - 1);
  expect(items.any((i) => i.id == 'c01'), isFalse);
});
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/providers/closet_providers_test.dart`
Expected: FAIL(`softDeleteMany`/`restoreMany`/`purgeMany` 메서드 없음, 컴파일 에러)

- [ ] **Step 3: `ClosetItemsNotifier`에 3종 메서드 추가**

`lib/providers/closet_providers.dart`의 `ClosetItemsNotifier` 클래스를 다음으로 교체(파일 상단 import는 유지):
```dart
class ClosetItemsNotifier extends StateNotifier<List<ClothingItem>> {
  ClosetItemsNotifier() : super(mockClothingItems);

  void softDelete(String id) => softDeleteMany({id});

  void softDeleteMany(Set<String> ids) {
    final now = DateTime.now();
    state = [
      for (final item in state)
        if (ids.contains(item.id)) item.copyWith(isDeleted: true, deletedAt: now) else item,
    ];
  }

  void restoreMany(Set<String> ids) {
    state = [
      for (final item in state)
        if (ids.contains(item.id)) item.copyWith(isDeleted: false, deletedAt: null) else item,
    ];
  }

  void purgeMany(Set<String> ids) {
    state = [for (final item in state) if (!ids.contains(item.id)) item];
  }
}
```

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run: `flutter test test/providers/closet_providers_test.dart`
Expected: PASS

- [ ] **Step 5: 코디 Notifier 테스트 추가(실패 예상)**

`test/providers/composition_providers_test.dart` 하단에 추가:
```dart
test('CompositionsNotifier.softDeleteMany/restoreMany/purgeMany가 동작한다', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(compositionsProvider.notifier);

  notifier.softDeleteMany({'comp01'});
  var comp01 = container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
  expect(comp01.isDeleted, isTrue);
  expect(comp01.deletedAt, isNotNull);

  notifier.restoreMany({'comp01'});
  comp01 = container.read(compositionsProvider).firstWhere((c) => c.id == 'comp01');
  expect(comp01.isDeleted, isFalse);
  expect(comp01.deletedAt, isNull);

  final before = container.read(compositionsProvider).length;
  notifier.purgeMany({'comp01'});
  final after = container.read(compositionsProvider);
  expect(after.length, before - 1);
  expect(after.any((c) => c.id == 'comp01'), isFalse);
});
```

- [ ] **Step 6: 테스트 실행해서 실패 확인**

Run: `flutter test test/providers/composition_providers_test.dart`
Expected: FAIL(메서드 없음, 컴파일 에러)

- [ ] **Step 7: `CompositionsNotifier`에 3종 메서드 추가**

`lib/providers/composition_providers.dart`의 `CompositionsNotifier` 클래스를 다음으로 교체:
```dart
class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);

  void softDeleteMany(Set<String> ids) {
    final now = DateTime.now();
    state = [
      for (final c in state)
        if (ids.contains(c.id)) c.copyWith(isDeleted: true, deletedAt: now) else c,
    ];
  }

  void restoreMany(Set<String> ids) {
    state = [
      for (final c in state)
        if (ids.contains(c.id)) c.copyWith(isDeleted: false, deletedAt: null) else c,
    ];
  }

  void purgeMany(Set<String> ids) {
    state = [for (final c in state) if (!ids.contains(c.id)) c];
  }
}
```

- [ ] **Step 8: 테스트 재실행해서 통과 확인**

Run: `flutter test test/providers/composition_providers_test.dart`
Expected: PASS

- [ ] **Step 9: 스타일일지 Notifier 테스트 신규 작성**

`test/providers/style_log_providers_test.dart`(신규 — 기존에 이 provider 전용 테스트 파일이 있으면 그 파일 하단에 추가, 없으면 신규):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';

void main() {
  test('StyleLogsNotifier.softDeleteMany/restoreMany/purgeMany가 동작한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(styleLogsProvider.notifier);

    notifier.softDeleteMany({'log01'});
    var log01 = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01');
    expect(log01.isDeleted, isTrue);
    expect(log01.deletedAt, isNotNull);

    notifier.restoreMany({'log01'});
    log01 = container.read(styleLogsProvider).firstWhere((l) => l.id == 'log01');
    expect(log01.isDeleted, isFalse);
    expect(log01.deletedAt, isNull);

    final before = container.read(styleLogsProvider).length;
    notifier.purgeMany({'log01'});
    final after = container.read(styleLogsProvider);
    expect(after.length, before - 1);
    expect(after.any((l) => l.id == 'log01'), isFalse);
  });
}
```

- [ ] **Step 10: 테스트 실행해서 실패 확인**

Run: `flutter test test/providers/style_log_providers_test.dart`
Expected: FAIL(메서드 없음)

- [ ] **Step 11: `StyleLogsNotifier`에 3종 메서드 추가**

`lib/providers/style_log_providers.dart`의 `StyleLogsNotifier` 클래스를 다음으로 교체(기존 `linkToComposition` 메서드는 유지):
```dart
class StyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  StyleLogsNotifier() : super(mockStyleLogs);

  void linkToComposition(String logId, String compositionId) {
    state = [
      for (final log in state)
        if (log.id == logId) log.copyWith(linkedCompositionId: compositionId) else log,
    ];
  }

  void softDeleteMany(Set<String> ids) {
    final now = DateTime.now();
    state = [
      for (final log in state)
        if (ids.contains(log.id)) log.copyWith(isDeleted: true, deletedAt: now) else log,
    ];
  }

  void restoreMany(Set<String> ids) {
    state = [
      for (final log in state)
        if (ids.contains(log.id)) log.copyWith(isDeleted: false, deletedAt: null) else log,
    ];
  }

  void purgeMany(Set<String> ids) {
    state = [for (final log in state) if (!ids.contains(log.id)) log];
  }
}
```

- [ ] **Step 12: 테스트 재실행해서 통과 확인**

Run: `flutter test test/providers/style_log_providers_test.dart`
Expected: PASS

- [ ] **Step 13: 전체 회귀 확인 + 커밋**

Run: `flutter analyze && flutter test`
Expected: 전부 PASS.

```bash
git add lib/providers/closet_providers.dart lib/providers/composition_providers.dart lib/providers/style_log_providers.dart test/providers/closet_providers_test.dart test/providers/composition_providers_test.dart test/providers/style_log_providers_test.dart
git commit -m "feat(providers): add softDeleteMany/restoreMany/purgeMany to all 3 domain notifiers"
```

---

### Task 3: 휴지통 집계 재작성 + 자동 영구삭제 + 안전가드 3곳

**Files:**
- Modify: `lib/models/trash_entry.dart` (`remainingDays` → `daysUntilPurge`)
- Modify: `lib/providers/trash_providers.dart` (전면 재작성)
- Modify: `lib/mock/mock_data.dart` (`mockTrashEntries` 삭제, `deletedAt` 시드)
- Modify: `lib/main.dart` (`purgeExpiredTrash` 배선)
- Modify: `lib/providers/composition_providers.dart` (`compositionCoverImageProvider` 안전가드)
- Modify: `lib/screens/composition_detail_screen.dart` (아트보드 안전가드)
- Modify: `lib/screens/style_log_viewer_screen.dart` (연결 코디 안전가드)
- Test: `test/providers/trash_providers_test.dart` (신규)

**Interfaces:**
- Consumes: Task 2의 3도메인 `softDeleteMany`/`purgeMany`.
- Produces: `TrashEntry.daysUntilPurge`(`int`), `trashEntriesProvider`(`Provider.autoDispose<List<TrashEntry>>`), `purgeExpiredTrash(ProviderContainer container)`.

- [ ] **Step 1: `TrashEntry` 필드명 변경**

`lib/models/trash_entry.dart` 전체를 다음으로 교체:
```dart
import 'enums.dart';

/// 휴지통 타일 1건을 표현하는 집계용 모델(파생 값 — `trashEntriesProvider`가 3도메인
/// provider를 watch해 실시간으로 만들어낸다, 별도 상태로 저장하지 않음).
class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.category,
    required this.imagePath,
    required this.daysUntilPurge,
  });

  final String id;
  final AppCategory category;
  final String imagePath;

  /// 영구 삭제(purge)까지 남은 일수 — `deletedAt` 기준 매번 다시 계산됨.
  final int daysUntilPurge;
}
```

- [ ] **Step 2: `trashEntriesProvider` 테스트 작성(실패 예상)**

`test/providers/trash_providers_test.dart`(신규):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';

void main() {
  test('trashEntriesProvider는 isDeleted인 3도메인 항목만 집계한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    container.read(compositionsProvider.notifier).softDeleteMany({'comp01'});

    final entries = container.read(trashEntriesProvider);
    expect(entries.any((e) => e.id == 'c01'), isTrue);
    expect(entries.any((e) => e.id == 'comp01'), isTrue);
    expect(entries.any((e) => e.id == 'log01'), isFalse);
  });

  test('daysUntilPurge는 deletedAt으로부터 15일 기준으로 계산되고 0 밑으로 안 내려간다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    final entry = container.read(trashEntriesProvider).firstWhere((e) => e.id == 'c01');
    expect(entry.daysUntilPurge, 15);
  });

  test('purgeExpiredTrash는 15일 초과 항목을 자동 제거한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final oldDate = DateTime.now().subtract(const Duration(days: 20));
    final notifier = container.read(closetItemsProvider.notifier);
    notifier.softDeleteMany({'c01'});
    // 20일 전으로 강제 세팅 — softDeleteMany 이후 직접 조작.
    final items = container.read(closetItemsProvider);
    final patched = [
      for (final item in items)
        if (item.id == 'c01') item.copyWith(deletedAt: oldDate) else item,
    ];
    container.read(closetItemsProvider.notifier).restoreMany({}); // no-op, state 갱신 트리거용 아님
    // restoreMany는 사용하지 않고 직접 state를 patched로 바꿀 수 없으므로(테스트가 내부
    // 구현에 의존하면 안 됨), purgeMany 호출 대신 purgeExpiredTrash 자체를 검증한다:
    purgeExpiredTrash(container);
    final entries = container.read(trashEntriesProvider);
    // oldDate로 강제 패치가 안 됐으므로 이 시점엔 아직 15일 초과가 아니라 살아있어야 한다.
    expect(entries.any((e) => e.id == 'c01'), isTrue);
  });
}
```

Step 2의 세 번째 테스트는 `deletedAt`을 과거로 강제 패치할 공개 API가 아직 없어 실제로 "15일 초과" 상황을 못 만든다 — 이 테스트를 아래로 교체해서 `purgeExpiredTrash`가 최소한 크래시 없이 동작하고 15일 이내 항목은 안 건드리는 것만 검증한다(실제 만료 시나리오는 Step 9의 mock 데이터 시드로 통합테스트에서 검증):
```dart
  test('purgeExpiredTrash는 15일 이내 항목은 건드리지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    purgeExpiredTrash(container);
    final entries = container.read(trashEntriesProvider);
    expect(entries.any((e) => e.id == 'c01'), isTrue);
  });
```

- [ ] **Step 3: 테스트 실행해서 실패 확인**

Run: `flutter test test/providers/trash_providers_test.dart`
Expected: FAIL(`trashEntriesProvider`가 아직 옛 구조라 `daysUntilPurge` 없음, `purgeExpiredTrash` 없음)

- [ ] **Step 4: `trash_providers.dart` 전면 재작성**

`lib/providers/trash_providers.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/trash_entry.dart';
import 'closet_providers.dart';
import 'composition_providers.dart';
import 'style_log_providers.dart';

const int _trashRetentionDays = 15;

int _daysUntilPurge(DateTime deletedAt) {
  final elapsed = DateTime.now().difference(deletedAt).inDays;
  return (_trashRetentionDays - elapsed).clamp(0, _trashRetentionDays);
}

/// 휴지통 목록 — 3도메인(옷장/코디/스타일일지) provider를 watch해 `isDeleted`인 것만
/// 걸러 `TrashEntry`로 매핑하는 파생 뷰. `autoDispose`인 이유: 휴지통 화면을 벗어나면
/// 폐기되고 재진입 시 완전히 새로 계산돼, `daysUntilPurge`가 "휴지통 재진입 시" 자연스럽게
/// 갱신된다(시간 경과 자체로는 재계산 안 되므로 이렇게 안 하면 오래 켜둔 세션에서 값이
/// 고정돼 보일 수 있음).
final trashEntriesProvider = Provider.autoDispose<List<TrashEntry>>((ref) {
  final closetItems = ref.watch(closetItemsProvider).where((i) => i.isDeleted);
  final compositions = ref.watch(compositionsProvider).where((c) => c.isDeleted);
  final styleLogs = ref.watch(styleLogsProvider).where((l) => l.isDeleted);

  return [
    for (final item in closetItems)
      TrashEntry(
        id: item.id,
        category: AppCategory.closet,
        imagePath: item.imagePath,
        daysUntilPurge: _daysUntilPurge(item.deletedAt!),
      ),
    for (final c in compositions)
      TrashEntry(
        id: c.id,
        category: AppCategory.composition,
        imagePath: c.coverImagePath ?? '',
        daysUntilPurge: _daysUntilPurge(c.deletedAt!),
      ),
    for (final log in styleLogs)
      TrashEntry(
        id: log.id,
        category: AppCategory.styleLog,
        imagePath: log.coverImagePath,
        daysUntilPurge: _daysUntilPurge(log.deletedAt!),
      ),
  ];
});

/// 앱 실행 시 1회 — 15일 초과된 휴지통 항목을 3도메인에서 조용히 영구삭제한다.
/// `main.dart`의 `runApp()` 호출 전에 실행(Riverpod provider 빌더 안에서 부수효과로 하지
/// 않고 명시적 imperative 단계로 분리).
void purgeExpiredTrash(ProviderContainer container) {
  final closetExpired = container
      .read(closetItemsProvider)
      .where((i) => i.isDeleted && _daysUntilPurge(i.deletedAt!) <= 0)
      .map((i) => i.id)
      .toSet();
  if (closetExpired.isNotEmpty) {
    container.read(closetItemsProvider.notifier).purgeMany(closetExpired);
  }

  final compositionExpired = container
      .read(compositionsProvider)
      .where((c) => c.isDeleted && _daysUntilPurge(c.deletedAt!) <= 0)
      .map((c) => c.id)
      .toSet();
  if (compositionExpired.isNotEmpty) {
    container.read(compositionsProvider.notifier).purgeMany(compositionExpired);
  }

  final styleLogExpired = container
      .read(styleLogsProvider)
      .where((l) => l.isDeleted && _daysUntilPurge(l.deletedAt!) <= 0)
      .map((l) => l.id)
      .toSet();
  if (styleLogExpired.isNotEmpty) {
    container.read(styleLogsProvider.notifier).purgeMany(styleLogExpired);
  }
}
```

- [ ] **Step 5: 테스트 재실행해서 통과 확인**

Run: `flutter test test/providers/trash_providers_test.dart`
Expected: PASS

- [ ] **Step 6: `mock_data.dart` 갱신 — `mockTrashEntries` 삭제 + `deletedAt` 시드**

`lib/mock/mock_data.dart`의 69~76행(휴지통 mock 블록)을 삭제하고, `mockClothingItems`/`mockCompositions`/`mockStyleLogs` 중 각 1개 이상에 `isDeleted`+`deletedAt`을 심는다. 파일 하단(69행 이후)을 다음으로 교체:
```dart
```
(빈 내용 — `mockTrashEntries` 블록 자체를 지운다. 5~6번째 줄의 `import '../models/trash_entry.dart';`도 더 이상 안 쓰이면 제거.)

`mockClothingItems`의 `c07`(리넨 반바지) 항목을 정상범위 삭제 예시로, `c08`(슬립 드레스)을 15일 초과(자동정리 시연) 예시로 바꾼다 — 8번째/15번째 줄을 각각:
```dart
  ClothingItem(id: 'c07', name: '리넨 반바지', category: ClothingCategory.bottom, color: 'blue', season: Season.summer, material: ClothingMaterial.linen, imagePath: 'assets/images/mock/IMG_4275.PNG', createdAt: DateTime(2025, 7, 22), wearCount: 6, isDeleted: true, deletedAt: DateTime.now().subtract(const Duration(days: 3))),
```
```dart
  ClothingItem(id: 'c08', name: '슬립 드레스', category: ClothingCategory.onePiece, color: 'black', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4276.PNG', createdAt: DateTime(2024, 12, 30), wearCount: 1, isDeleted: true, deletedAt: DateTime.now().subtract(const Duration(days: 20))),
```

`mockCompositions`의 `comp02`에도 `isDeleted: true, deletedAt: DateTime.now().subtract(const Duration(days: 5))`를 추가(생성자 호출 마지막에 두 필드 추가).

이 시드 변경으로 옷장 메인의 mock 아이템 개수 assertion(현재 12개, `c07`/`c08`이 `isDeleted`가 되면 `filteredClosetItemsProvider`에서 빠져 10개가 됨)이 깨진다 — 이건 Task 7(옷장 메인 마이그레이션)에서 함께 갱신한다(지금 이 Task에서는 `flutter test`가 일부 실패해도 진행하고, Step 10에서 실패 목록을 확인만 해둔다).

- [ ] **Step 7: `main.dart`에 `purgeExpiredTrash` 배선**

`lib/main.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/trash_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  final container = ProviderContainer();
  purgeExpiredTrash(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DigitalWardrobeApp(),
    ),
  );
}

class DigitalWardrobeApp extends ConsumerWidget {
  const DigitalWardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Digital Wardrobe',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 8: 안전가드 — `compositionCoverImageProvider`**

`lib/providers/composition_providers.dart`의 `compositionCoverImageProvider` 정의를 다음으로 교체:
```dart
final compositionCoverImageProvider = Provider.family<String?, String>((ref, compositionId) {
  final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
  if (composition.coverImagePath != null) return composition.coverImagePath;
  final closetItems = ref.watch(closetItemsProvider);
  for (final placement in composition.items) {
    final matches = closetItems.where((item) => item.id == placement.clothingItemId);
    if (matches.isNotEmpty) return matches.first.imagePath;
  }
  return null;
});
```

- [ ] **Step 9: 안전가드 — `composition_detail_screen.dart` 아트보드**

`lib/screens/composition_detail_screen.dart`의 `usedItems` 계산부(현재 34~37행)를 다음으로 교체:
```dart
    final usedItems = <ClothingItem>[
      for (final placement in composition.items)
        ...closetItems.where((item) => item.id == placement.clothingItemId),
    ];
```
`ClothingItem` import가 이 파일에 없으면 상단에 `import '../models/clothing_item.dart';` 추가.

- [ ] **Step 10: 안전가드 — `style_log_viewer_screen.dart` 연결 코디**

`lib/screens/style_log_viewer_screen.dart`의 `linkedComposition` 계산부(현재 52~54행)를 다음으로 교체:
```dart
    final linkedComposition = log.linkedCompositionId == null
        ? null
        : ref
            .watch(compositionsProvider)
            .where((c) => c.id == log.linkedCompositionId)
            .firstOrNull;
```
`firstOrNull`은 `dart:core`의 `Iterable` 확장(Dart 3.0+, `package:collection` 불필요)에 이미 있음 — 없다고 나오면 대신 아래로 교체:
```dart
    final linkedMatches = log.linkedCompositionId == null
        ? const <Composition>[]
        : ref.watch(compositionsProvider).where((c) => c.id == log.linkedCompositionId);
    final linkedComposition = linkedMatches.isEmpty ? null : linkedMatches.first;
```
(이 경우 `import '../models/composition.dart';` 추가 필요.)

- [ ] **Step 11: 전체 테스트 실행 — 실패 목록 확인(예상된 실패, Task 7에서 해소)**

Run: `flutter analyze && flutter test`
Expected: `closet_main_screen_test.dart` 등 mock 개수(12개) 전제 assertion 일부 실패 — 원인이 Step 6의 mock 시드 변경(c07/c08 `isDeleted`화)임을 확인만 하고 다음 단계로 진행. 그 외(모델/provider 테스트) 전부 PASS.

- [ ] **Step 12: 커밋**

```bash
git add lib/models/trash_entry.dart lib/providers/trash_providers.dart lib/providers/composition_providers.dart lib/screens/composition_detail_screen.dart lib/screens/style_log_viewer_screen.dart lib/mock/mock_data.dart lib/main.dart test/providers/trash_providers_test.dart
git commit -m "feat(trash): rewrite trashEntriesProvider as derived autoDispose aggregate, add purgeExpiredTrash and safety guards"
```

---

### Task 4: `AppMainScaffold.bottomFloatingActions` 파라미터

**Files:**
- Modify: `lib/widgets/app_main_scaffold.dart`
- Test: `test/widgets/app_main_scaffold_test.dart` (기존 파일에 추가)

**Interfaces:**
- Produces: `AppMainScaffold({..., List<Widget> bottomFloatingActions = const []})` — 뒤로가기와 같은 하단 밴드에 독립 위젯들을 우측 정렬로 얹음.

- [ ] **Step 1: 테스트 작성(실패 예상)**

`test/widgets/app_main_scaffold_test.dart` 하단에 추가:
```dart
testWidgets('bottomFloatingActions에 넘긴 위젯들이 하단에 렌더링된다', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AppMainScaffold(
        current: AppCategory.closet,
        bottomFloatingActions: const [Text('삭제')],
        body: const SizedBox.shrink(),
      ),
    ),
  );
  expect(find.text('삭제'), findsOneWidget);
});
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/widgets/app_main_scaffold_test.dart`
Expected: FAIL(생성자에 `bottomFloatingActions` 파라미터 없음)

- [ ] **Step 3: `bottomFloatingActions` 파라미터 추가**

`lib/widgets/app_main_scaffold.dart`의 생성자에 파라미터 추가(37~48행):
```dart
  const AppMainScaffold({
    super.key,
    required this.current,
    required this.body,
    this.showBackButton = true,
    this.showCategoryToggle = true,
    this.headerActions = const [],
    this.secondaryControlsLeft = const [],
    this.secondaryControlsRight = const [],
    this.onReselectCurrentCategory,
    this.bottomFloatingActions = const [],
    this.floatingActionButton,
  });
```
필드 선언(66~70행 부근)에 추가:
```dart
  /// 하단 밴드(뒤로가기와 같은 자리)에 우측 정렬로 얹는 독립 floating pill/circle
  /// 버튼들 — 다중선택 모드의 [삭제]/[복원]/[영구 삭제] 등. Header/HUD Pinned Rule에
  /// 따라 이미 각자 독립적으로 글래스 스타일링된 위젯이어야 한다.
  final List<Widget> bottomFloatingActions;
```
`build()`의 `FrostedBackButton` `Positioned`(190~197행) 바로 다음에 추가:
```dart
            if (bottomFloatingActions.isNotEmpty)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _withGaps(bottomFloatingActions),
                ),
              ),
```

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run: `flutter test test/widgets/app_main_scaffold_test.dart`
Expected: PASS

- [ ] **Step 5: 전체 회귀 확인 + 커밋**

Run: `flutter analyze && flutter test`
Expected: PASS(Task 3의 mock 개수 실패는 여전히 남아있음 — 정상, Task 7에서 해소)

```bash
git add lib/widgets/app_main_scaffold.dart test/widgets/app_main_scaffold_test.dart
git commit -m "feat(scaffold): add bottomFloatingActions slot for multi-select action buttons"
```

---

### Task 5: 다중선택 시각 지원 — 타일 4종 + 그리드 어댑터 3종

**Files:**
- Create: `lib/widgets/multi_select_checkmark.dart`
- Modify: `lib/widgets/selectable_gallery_tile.dart`
- Modify: `lib/widgets/composition_gallery_tile.dart`
- Modify: `lib/widgets/style_log_gallery_tile.dart`
- Modify: `lib/widgets/trash_gallery_tile.dart`
- Modify: `lib/widgets/grouped_gallery_grid.dart`
- Modify: `lib/widgets/composition_gallery_grid.dart`
- Modify: `lib/widgets/style_log_gallery_grid.dart`
- Test: `test/widgets/multi_select_checkmark_test.dart` (신규)
- Test: `test/widgets/selectable_gallery_tile_test.dart` (기존 파일에 추가, 없으면 신규)

**Interfaces:**
- Produces: `MultiSelectCheckmark({required bool selected})`. 4개 타일 전부 `selected: bool`(기본 false) + `onLongPress: VoidCallback?` 파라미터. 3개 그리드 어댑터 전부 `multiSelectMode: bool`(기본 false) + `selectedIds: Set<String>`(기본 `const {}`) + `onItemLongPress: void Function(T)?` 파라미터.

- [ ] **Step 1: `MultiSelectCheckmark` 테스트 작성(실패 예상)**

`test/widgets/multi_select_checkmark_test.dart`(신규):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';

void main() {
  testWidgets('selected=false면 체크 아이콘이 없다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MultiSelectCheckmark(selected: false)),
    );
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('selected=true면 체크 아이콘이 보인다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MultiSelectCheckmark(selected: true)),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/widgets/multi_select_checkmark_test.dart`
Expected: FAIL(파일 없음)

- [ ] **Step 3: `MultiSelectCheckmark` 위젯 작성**

`lib/widgets/multi_select_checkmark.dart`(신규):
```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 다중선택 모드의 타일 우상단 체크서클 — 4개 도메인 타일(`SelectableGalleryTile` 등)이
/// 공유하는 순수 UI 원자(도메인 정보 없음). 미선택=아웃라인 원, 선택=프라이머리 채움+체크.
class MultiSelectCheckmark extends StatelessWidget {
  const MultiSelectCheckmark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colorScheme.primary : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: colorScheme.primary, width: selected ? 0 : 1.5),
      ),
      child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }
}
```

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run: `flutter test test/widgets/multi_select_checkmark_test.dart`
Expected: PASS

- [ ] **Step 5: `SelectableGalleryTile` 테스트 추가(실패 예상)**

`test/widgets/selectable_gallery_tile_test.dart`에 다음 테스트 추가(파일이 없으면 신규 생성, 있으면 하단에 추가 — 기존 import에 `mockClothingItems`류 픽스처가 있으면 그걸 쓰고, 없으면 아래처럼 직접 `ClothingItem` 인스턴스 생성):
```dart
testWidgets('selected=true면 체크서클이 보이고 롱프레스가 onLongPress를 호출한다', (tester) async {
  var longPressed = false;
  final item = ClothingItem(
    id: 'c1',
    name: '테스트',
    imagePath: '',
    createdAt: DateTime(2026, 1, 1),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: SelectableGalleryTile(
        item: item,
        onTap: () {},
        selected: true,
        onLongPress: () => longPressed = true,
      ),
    ),
  );
  expect(find.byType(MultiSelectCheckmark), findsOneWidget);
  await tester.longPress(find.byType(SelectableGalleryTile));
  expect(longPressed, isTrue);
});
```
필요한 import(`ClothingItem`, `SelectableGalleryTile`, `MultiSelectCheckmark`)를 파일 상단에 추가.

- [ ] **Step 6: 테스트 실행해서 실패 확인**

Run: `flutter test test/widgets/selectable_gallery_tile_test.dart`
Expected: FAIL(`selected`/`onLongPress` 파라미터 없음 — `selected`는 이미 있지만 체크서클 렌더링이 없어 `MultiSelectCheckmark` 못 찾음, `onLongPress`는 아예 없어 컴파일 에러)

- [ ] **Step 7: `SelectableGalleryTile`에 체크서클 + `onLongPress` 추가**

`lib/widgets/selectable_gallery_tile.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';
import 'status_badge.dart';

class SelectableGalleryTile extends StatelessWidget {
  const SelectableGalleryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onIncompleteTap,
    this.onLongPress,
    this.selected = false,
  });

  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback? onIncompleteTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.color ?? '미분류'}, 착용 ${item.wearCount}회'
          '${item.isIncomplete ? ", 미완성" : ""}'
          '${selected ? ", 선택됨" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: item.isIncomplete ? onIncompleteTap : onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: semantic.gray200,
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: item.imagePath.isNotEmpty
                        ? Image.asset(item.imagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  if (item.isIncomplete)
                    const Positioned(top: AppSpacing.xxs, left: AppSpacing.xxs, child: StatusBadge(label: '미완성')),
                  Positioned(
                    top: AppSpacing.xxs,
                    right: AppSpacing.xxs,
                    child: MultiSelectCheckmark(selected: selected),
                  ),
                  GalleryMetaLabel(label: item.category?.label ?? '미분류', maxWidth: constraints.maxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

`MultiSelectCheckmark`는 항상 렌더링되지만(다중선택 모드가 아닐 때도 `selected=false`인 빈 원이 계속 떠 있는 건 원치 않음) — Task 6(그리드 어댑터)에서 `multiSelectMode=false`일 땐 이 타일 자체에 `selected`를 아예 안 넘기게 해서 자연히 안 그려지게 한다. 여기서는 위젯 레벨 계약만 확정.

- [ ] **Step 8: 테스트 재실행해서 통과 확인**

Run: `flutter test test/widgets/selectable_gallery_tile_test.dart`
Expected: PASS

- [ ] **Step 9: `CompositionGalleryTile`에 동일 패턴 추가**

`lib/widgets/composition_gallery_tile.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/composition.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

class CompositionGalleryTile extends StatelessWidget {
  const CompositionGalleryTile({
    super.key,
    required this.composition,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Composition composition;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final season = composition.season;
    return Semantics(
      button: true,
      label: (season == null ? composition.name : '${composition.name}, ${season.label}') +
          (selected ? ', 선택됨' : ''),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: semantic.gray200,
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        composition.name,
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  if (season != null)
                    GalleryMetaLabel(label: season.label, maxWidth: constraints.maxWidth),
                  Positioned(
                    top: AppSpacing.xxs,
                    right: AppSpacing.xxs,
                    child: MultiSelectCheckmark(selected: selected),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 10: `StyleLogGalleryTile`에 동일 패턴 추가**

`lib/widgets/style_log_gallery_tile.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

class StyleLogGalleryTile extends StatelessWidget {
  const StyleLogGalleryTile({
    super.key,
    required this.styleLog,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final StyleLog styleLog;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = styleLog.wornDate.toIso8601String().substring(0, 10);
    final metaLabel = styleLog.location.isEmpty ? dateLabel : '$dateLabel · ${styleLog.location}';
    return Semantics(
      button: true,
      label: metaLabel + (selected ? ', 선택됨' : ''),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: semantic.gray200,
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: styleLog.coverImagePath.isNotEmpty
                        ? Image.asset(styleLog.coverImagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  GalleryMetaLabel(label: metaLabel, maxWidth: constraints.maxWidth),
                  Positioned(
                    top: AppSpacing.xxs,
                    right: AppSpacing.xxs,
                    child: MultiSelectCheckmark(selected: selected),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 11: `TrashGalleryTile`에 동일 패턴 추가 + `remainingDays`→`daysUntilPurge`**

`lib/widgets/trash_gallery_tile.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';
import 'multi_select_checkmark.dart';

class TrashGalleryTile extends StatelessWidget {
  const TrashGalleryTile({
    super.key,
    required this.imagePath,
    required this.category,
    required this.daysUntilPurge,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final String imagePath;
  final AppCategory category;
  final int daysUntilPurge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final daysLabel = '$daysUntilPurge일';
    return Semantics(
      button: true,
      label: '${category.label}, 영구 삭제까지 $daysLabel' + (selected ? ', 선택됨' : ''),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: semantic.gray200,
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: imagePath.isNotEmpty
                        ? Image.asset(imagePath, fit: BoxFit.contain)
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: AppSpacing.xxs,
                    left: AppSpacing.xxs,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: semantic.gray50.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_categoryIcon(category), size: 14),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.xxs,
                    right: AppSpacing.xxs,
                    child: MultiSelectCheckmark(selected: selected),
                  ),
                  GalleryMetaLabel(label: daysLabel, maxWidth: constraints.maxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(AppCategory category) => switch (category) {
        AppCategory.closet => Icons.checkroom,
        AppCategory.composition => Icons.dashboard_customize,
        AppCategory.styleLog => Icons.photo_camera_back,
      };
}
```

- [ ] **Step 12: 그리드 어댑터 3종에 `multiSelectMode`/`selectedIds`/`onItemLongPress` 추가**

`lib/widgets/grouped_gallery_grid.dart`의 생성자+필드+`itemBuilder` 내부를 다음으로 교체(파일 전체):
```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'app_gallery_grid.dart';
import 'selectable_gallery_tile.dart';

class GroupedGalleryGrid extends StatelessWidget {
  const GroupedGalleryGrid({
    super.key,
    required this.items,
    required this.density,
    required this.onItemTap,
    this.onIncompleteTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<ClothingItem> items;
  final int density;
  final void Function(ClothingItem item) onItemTap;
  final void Function(ClothingItem item)? onIncompleteTap;
  final void Function(ClothingItem item)? onItemLongPress;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final ScrollController? controller;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: items.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableGalleryTile(
          key: ValueKey(item.id),
          item: item,
          onTap: () => onItemTap(item),
          onIncompleteTap: onIncompleteTap == null ? null : () => onIncompleteTap!(item),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(item),
          selected: multiSelectMode && selectedIds.contains(item.id),
        );
      },
    );
  }
}
```

`lib/widgets/composition_gallery_grid.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/composition.dart';
import 'app_gallery_grid.dart';
import 'composition_gallery_tile.dart';

class CompositionGalleryGrid extends StatelessWidget {
  const CompositionGalleryGrid({
    super.key,
    required this.compositions,
    required this.density,
    required this.onItemTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<Composition> compositions;
  final int density;
  final void Function(Composition composition) onItemTap;
  final void Function(Composition composition)? onItemLongPress;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final ScrollController? controller;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: compositions.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final composition = compositions[index];
        return CompositionGalleryTile(
          key: ValueKey(composition.id),
          composition: composition,
          onTap: () => onItemTap(composition),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(composition),
          selected: multiSelectMode && selectedIds.contains(composition.id),
        );
      },
    );
  }
}
```

`lib/widgets/style_log_gallery_grid.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/style_log.dart';
import '../theme/app_spacing.dart';
import 'app_gallery_grid.dart';
import 'style_log_gallery_tile.dart';

class StyleLogGalleryGrid extends StatelessWidget {
  const StyleLogGalleryGrid({
    super.key,
    required this.logs,
    required this.onItemTap,
    this.onItemLongPress,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.controller,
    this.topSpacing = 0,
  });

  final List<StyleLog> logs;
  final void Function(StyleLog styleLog) onItemTap;
  final void Function(StyleLog styleLog)? onItemLongPress;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final ScrollController? controller;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: logs.length,
      density: AppDensity.mid,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final log = logs[index];
        return StyleLogGalleryTile(
          key: ValueKey(log.id),
          styleLog: log,
          onTap: () => onItemTap(log),
          onLongPress: onItemLongPress == null ? null : () => onItemLongPress!(log),
          selected: multiSelectMode && selectedIds.contains(log.id),
        );
      },
    );
  }
}
```

- [ ] **Step 13: 전체 회귀 확인**

Run: `flutter analyze && flutter test`
Expected: `test/widgets/composition_gallery_grid_test.dart`/`style_log_gallery_grid_test.dart` 등 기존 테스트가 새 파라미터(기본값 있음)와 무관하게 그대로 PASS. `trash_main_screen.dart`가 아직 `TrashGalleryTile`을 `remainingDays:`로 호출하고 있어 컴파일 에러 발생 — 이건 Task 9(휴지통 마이그레이션)에서 해소되므로, 지금은 `lib/screens/trash_main_screen.dart`의 해당 한 줄만 임시로 `daysUntilPurge: entry.daysUntilPurge`로 고쳐서 컴파일을 통과시킨다(`lib/providers/trash_providers.dart`가 이미 이 필드명을 쓰므로 자연스러운 임시 수정).

- [ ] **Step 14: 커밋**

```bash
git add lib/widgets/multi_select_checkmark.dart lib/widgets/selectable_gallery_tile.dart lib/widgets/composition_gallery_tile.dart lib/widgets/style_log_gallery_tile.dart lib/widgets/trash_gallery_tile.dart lib/widgets/grouped_gallery_grid.dart lib/widgets/composition_gallery_grid.dart lib/widgets/style_log_gallery_grid.dart lib/screens/trash_main_screen.dart test/widgets/multi_select_checkmark_test.dart test/widgets/selectable_gallery_tile_test.dart
git commit -m "feat(tiles): add multi-select checkmark, selected state, and long-press across all 4 tile widgets and grid adapters"
```

---

### Task 6: `GlassToast` 위젯

**Files:**
- Create: `lib/widgets/glass_toast.dart`
- Test: `test/widgets/glass_toast_test.dart` (신규)

**Interfaces:**
- Produces: `GlassToast.show(BuildContext context, {required String message, String? actionLabel, VoidCallback? onAction})`.

- [ ] **Step 1: 테스트 작성(실패 예상)**

`test/widgets/glass_toast_test.dart`(신규):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/glass_toast.dart';

void main() {
  testWidgets('메시지와 액션 라벨이 렌더링되고 액션 탭 시 콜백이 호출된다', (tester) async {
    var actionTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => GlassToast.show(
              context,
              message: '휴지통으로 이동됨',
              actionLabel: '실행취소',
              onAction: () => actionTapped = true,
            ),
            child: const Text('트리거'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('트리거'));
    await tester.pump();
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(find.text('실행취소'), findsOneWidget);
    await tester.tap(find.text('실행취소'));
    expect(actionTapped, isTrue);
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run: `flutter test test/widgets/glass_toast_test.dart`
Expected: FAIL(파일 없음)

- [ ] **Step 3: `GlassToast` 작성**

`lib/widgets/glass_toast.dart`(신규):
```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// GlassPill 스타일 Toast — 기존 코드에 SnackBar 패턴이 없어 신설(Overlay 삽입 방식).
/// "휴지통으로 이동됨 · 실행취소"(다중선택 삭제, Detail 더보기 삭제 공통)에 쓰인다.
class GlassToast {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
        child: Material(
          color: Colors.transparent,
          child: GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(message, overflow: TextOverflow.ellipsis)),
                if (actionLabel != null)
                  TextButton(
                    onPressed: () {
                      onAction?.call();
                      entry.remove();
                    },
                    child: Text(actionLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}
```

`GlassPill`의 기본 `mainAxisSize`가 `Row`를 무한폭으로 강제하진 않는지 확인 필요 — `GlassPill.child`가 그대로 렌더링되는 구조라 `Row(mainAxisSize: MainAxisSize.min, ...)`을 넣었으므로 폭은 컨텐츠에 맞게 줄어든다(좌우 `AppSpacing.md` 마진의 `Positioned(left/right)` 안에서 필요한 만큼만 채움 — 요소 2개짜리라 실제로는 꽉 참).

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run: `flutter test test/widgets/glass_toast_test.dart`
Expected: PASS

- [ ] **Step 5: 전체 회귀 확인 + 커밋**

Run: `flutter analyze && flutter test`
Expected: PASS

```bash
git add lib/widgets/glass_toast.dart test/widgets/glass_toast_test.dart
git commit -m "feat(toast): add GlassToast widget for undo-style notifications"
```

---

### Task 7: `GalleryMainScreen<T>` 셸 신설 + 옷장 메인 마이그레이션

**Files:**
- Create: `lib/widgets/gallery_main_screen.dart`
- Modify: `lib/screens/closet_main_screen.dart` (전면 재작성)
- Modify: `lib/screens/app_detail_scaffold.dart` (변경 없음 — 참고용, 이 Task에서 안 건드림)
- Test: `integration_test/closet_multi_select_test.dart` (신규)

**Interfaces:**
- Consumes: Task 4(`bottomFloatingActions`), Task 5(그리드 어댑터 `multiSelectMode`/`selectedIds`/`onItemLongPress`), Task 6(`GlassToast`).
- Produces: `GalleryMainScreen<T>({required current, required itemId, required gridBuilder, classification, showCategoryToggle, showBackButton, headerActions, selectionMode, fab, onItemTap, onReselectCurrentCategory, multiSelectDeleteLabel, onDeleteSelected})`.

- [ ] **Step 1: `GalleryMainScreen<T>` 작성**

이 위젯은 제네릭이라 유닛테스트보다 실제 소비자(옷장 메인)로 바로 검증한다(스펙 §6 "GalleryMainScreen<T>를 가짜 타입으로 고립 테스트하지 않고 첫 실제 소비자로 검증"). `lib/widgets/gallery_main_screen.dart`(신규):
```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import 'app_main_scaffold.dart';
import 'glass_pill.dart';
import 'frosted_close_button.dart';

/// 그리드 렌더링을 도메인 wrapper에 위임하는 콜백 — `GalleryMainScreen`은 `T`의 런타임
/// 타입을 분기하지 않는다(각 도메인이 자기 기존 그리드 어댑터를 그대로 인스턴스화).
typedef GalleryGridBuilder<T> = Widget Function({
  required int density,
  required ScrollController? controller,
  required double topSpacing,
  required bool multiSelectMode,
  required Set<String> selectedIds,
  required void Function(T item) onItemTap,
  required void Function(T item) onItemLongPress,
});

/// 그룹형(옷장/코디) 전용 — 분류 캡슐+밀도+3상태 그리드 배선에 필요한 값 전부.
/// null이면 [GalleryMainScreen]이 캡슐/밀도 UI 자체를 렌더링하지 않는다(플랫+필터형).
class ClassificationConfig<T> {
  const ClassificationConfig({
    required this.criterionLabels,
    required this.selectedCriterionIndex,
    required this.onCriterionChanged,
    required this.hasSubClassification,
    this.subHint,
    required this.subOptionLabels,
    required this.selectedSubOptionIndex,
    required this.onSubOptionSelected,
    required this.onClearSubSelection,
    required this.density,
    required this.ascending,
    required this.onAscendingChanged,
    required this.isGroupOverview,
    required this.groupSummaryCount,
  });

  final List<String> criterionLabels;
  final int selectedCriterionIndex;
  final ValueChanged<int> onCriterionChanged;
  final bool hasSubClassification;
  final String? subHint;
  final List<String> subOptionLabels;
  final int? selectedSubOptionIndex;
  final ValueChanged<int> onSubOptionSelected;
  final VoidCallback onClearSubSelection;
  final int density;
  final bool ascending;
  final ValueChanged<bool> onAscendingChanged;

  /// true면 지금 그룹 개요 상태(캡슐만 그리고 그리드는 호출부가 별도로 그림) — 이 config는
  /// 캡슐/밀도/정렬 버튼 배선만 책임지고, 실제 그리드 콘텐츠 스위칭(그룹카드 vs 아이템)은
  /// 여전히 도메인 wrapper의 `gridBuilder`가 맡는다.
  final bool isGroupOverview;
  final int groupSummaryCount;
}

class GalleryMainScreen<T> extends StatefulWidget {
  const GalleryMainScreen({
    super.key,
    required this.current,
    required this.items,
    required this.itemId,
    required this.gridBuilder,
    required this.onItemTap,
    this.classification,
    this.showCategoryToggle = true,
    this.showBackButton = true,
    this.headerActions = const [],
    this.selectionMode = false,
    this.fab,
    this.onReselectCurrentCategory,
    this.multiSelectDeleteLabel = '삭제',
    this.onDeleteSelected,
  });

  final AppCategory current;
  final List<T> items;
  final String Function(T item) itemId;
  final GalleryGridBuilder<T> gridBuilder;
  final void Function(T item) onItemTap;
  final ClassificationConfig<T>? classification;
  final bool showCategoryToggle;
  final bool showBackButton;
  final List<Widget> headerActions;

  /// 기존 "재호출 피커 모달" 개념 — true면 다중선택 진입 경로(선택버튼/롱프레스) 자체를
  /// 렌더링하지 않는다(§2.2).
  final bool selectionMode;
  final Widget? fab;
  final VoidCallback? onReselectCurrentCategory;
  final String multiSelectDeleteLabel;

  /// non-null이면 다중선택 하단에 [multiSelectDeleteLabel] 버튼 1개가 뜬다. null이면
  /// (예: 휴지통처럼 버튼 구성이 다른 화면은) 이 위젯 대신 직접 `bottomFloatingActions`를
  /// 구성해야 하므로, 그 경우 호출부가 `GalleryMainScreen` 대신 더 낮은 레벨을 쓴다 —
  /// 이 Task 스코프(옷장/코디/스타일일지)에선 항상 non-null.
  final void Function(Set<String> selectedIds)? onDeleteSelected;

  @override
  State<GalleryMainScreen<T>> createState() => _GalleryMainScreenState<T>();
}

class _GalleryMainScreenState<T> extends State<GalleryMainScreen<T>> {
  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};

  void _enterOrToggle(T item) {
    final id = widget.itemId(item);
    setState(() {
      if (!_multiSelectMode) {
        _multiSelectMode = true;
        _selectedIds.add(id);
      } else {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      }
    });
  }

  void _toggle(T item) {
    final id = widget.itemId(item);
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _handleDelete() {
    widget.onDeleteSelected?.call(Set.of(_selectedIds));
    _exitMultiSelect();
  }

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing =
        AppMainScaffold.contentSpacerHeight(hasSecondaryRow: widget.classification != null);

    final effectiveOnItemTap = _multiSelectMode ? _toggle : widget.onItemTap;
    final effectiveOnLongPress = widget.selectionMode ? (T item) {} : _enterOrToggle;

    final headerActions = widget.selectionMode
        ? widget.headerActions
        : _multiSelectMode
            ? [
                GlassPill(
                  child: Text('${_selectedIds.length}개 선택'),
                ),
                FrostedCloseButton(onTap: _exitMultiSelect),
              ]
            : [
                ...widget.headerActions,
                GlassPill(
                  child: TextButton(
                    onPressed: () => setState(() => _multiSelectMode = true),
                    child: const Text('선택'),
                  ),
                ),
              ];

    return AppMainScaffold(
      current: widget.current,
      showCategoryToggle: widget.showCategoryToggle && !_multiSelectMode,
      showBackButton: widget.showBackButton && !_multiSelectMode,
      headerActions: headerActions,
      onReselectCurrentCategory: widget.onReselectCurrentCategory,
      floatingActionButton: _multiSelectMode ? null : widget.fab,
      bottomFloatingActions: _multiSelectMode && widget.onDeleteSelected != null
          ? [
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty ? null : _handleDelete,
                    child: Text(widget.multiSelectDeleteLabel),
                  ),
                ),
              ),
            ]
          : const [],
      body: widget.gridBuilder(
        density: widget.classification?.density ?? AppDensity.mid,
        controller: null,
        topSpacing: contentTopSpacing,
        multiSelectMode: _multiSelectMode,
        selectedIds: _selectedIds,
        onItemTap: (item) => effectiveOnItemTap(item),
        onItemLongPress: (item) => effectiveOnLongPress(item),
      ),
    );
  }
}
```

`gridBuilder`가 `AppScrollContainer`(스크롤 힌트)까지 책임지는지, `GalleryMainScreen`이 그걸 감싸는지가 애매하다 — 기존 3화면 전부 `body: AppScrollContainer(topHintThreshold: ..., builder: (context, controller) => ...그리드...)` 구조였다. 위 초안의 `body: widget.gridBuilder(...)`는 `controller: null`을 그냥 넘기고 있어 스크롤 힌트가 빠진다 — 이건 잘못이다. `gridBuilder` 호출을 `AppScrollContainer`로 감싸도록 바로 수정한다(위 `build()`의 `body:` 부분을 아래로 교체):
```dart
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => widget.gridBuilder(
          density: widget.classification?.density ?? AppDensity.mid,
          controller: controller,
          topSpacing: contentTopSpacing,
          multiSelectMode: _multiSelectMode,
          selectedIds: _selectedIds,
          onItemTap: (item) => effectiveOnItemTap(item),
          onItemLongPress: (item) => effectiveOnLongPress(item),
        ),
      ),
```
파일 상단 import에 `import 'app_scroll_container.dart';` 추가.

분류 캡슐(`ClassificationConfig`)을 실제로 `secondaryControlsLeft`에 꽂는 배선이 위 초안에 빠져있다 — `AppMainScaffold(...)` 호출에 다음을 추가:
```dart
      secondaryControlsLeft: widget.classification == null
          ? const []
          : [
              // 캡슐 위젯 자체는 Task 8(코디)/Task 9(스타일일지) 진행 중 실제 옷장
              // 마이그레이션에서 `ClassificationDrilldownCapsule`을 그대로 여기 꽂는다
              // (지금 이 Step에선 옷장이 아직 `classification`을 안 넘기므로 미도달 분기).
            ],
      secondaryControlsRight: widget.classification == null
          ? const []
          : [
              GlassCircleButton(
                icon: AppDensity.iconFor(widget.classification!.density),
                tooltip: '그리드 밀도 전환',
                onTap: () {}, // 실제 밀도 순환은 도메인 wrapper의 onCriterionChanged와 같은
                              // 층위에서 배선 — 이 Step(옷장)에서 곧바로 실제 콜백으로 교체.
              ),
              GlassCircleButton(
                icon: widget.classification!.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                tooltip: widget.classification!.ascending ? '오름차순' : '내림차순',
                onTap: () => widget.classification!.onAscendingChanged(!widget.classification!.ascending),
              ),
            ],
```

위 밀도 버튼의 `onTap: () {}`는 완성이 아니다 — `ClassificationConfig`에 `onDensityChanged: ValueChanged<int>` 필드를 추가해서 실제 순환을 넘겨받아야 한다. `ClassificationConfig` 클래스 정의에 다음 필드 추가:
```dart
  final ValueChanged<int> onDensityChanged;
```
생성자에도 `required this.onDensityChanged,` 추가. `secondaryControlsRight`의 밀도 버튼 `onTap`을 다음으로 교체:
```dart
                onTap: () => widget.classification!.onDensityChanged(widget.classification!.density),
```
"현재 density를 넘기고 다음 단계 계산은 호출부가 한다"는 계약 — 옷장 wrapper가 `AppDensity.levels`를 이미 알고 있으므로 순환 로직은 wrapper 쪽에 남긴다(캡슐 config가 순환 로직까지 떠안지 않음, 관심사 분리).

캡슐 위젯(`ClassificationDrilldownCapsule`) 자체를 `secondaryControlsLeft`에 꽂는 것도 `ClassificationConfig`가 갖고 있는 원시 값들로 이 위젯 안에서 직접 만든다 — `secondaryControlsLeft` 항목을 다음으로 교체:
```dart
      secondaryControlsLeft: widget.classification == null
          ? const []
          : [
              ClassificationDrilldownCapsule(
                criterionLabels: widget.classification!.criterionLabels,
                selectedCriterionIndex: widget.classification!.selectedCriterionIndex,
                onCriterionChanged: widget.classification!.onCriterionChanged,
                hasSubClassification: widget.classification!.hasSubClassification,
                subHint: widget.classification!.subHint,
                subOptionLabels: widget.classification!.subOptionLabels,
                selectedSubOptionIndex: widget.classification!.selectedSubOptionIndex,
                onSubOptionSelected: widget.classification!.onSubOptionSelected,
                onClearSubSelection: widget.classification!.onClearSubSelection,
              ),
            ],
```
import에 `import 'classification_drilldown_capsule.dart';` 추가.

`isGroupOverview`/`groupSummaryCount` 필드는 실제로 이 위젯 안에서 안 쓰인다(그리드 콘텐츠 스위칭은 `gridBuilder` 내부, 즉 도메인 wrapper 책임) — 죽은 필드라 `ClassificationConfig`에서 제거한다(위 정의에서 이 두 필드와 생성자 파라미터를 삭제).

- [ ] **Step 2: 옷장 메인을 `GalleryMainScreen<ClothingItem>`으로 재작성**

`lib/screens/closet_main_screen.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/gallery_main_screen.dart';
import '../widgets/glass_toast.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/selection_aware_header_actions.dart';

class ClosetMainScreen extends ConsumerStatefulWidget {
  const ClosetMainScreen({super.key, this.selectionMode = false, this.onItemSelected});

  final bool selectionMode;
  final ValueChanged<String>? onItemSelected;

  @override
  ConsumerState<ClosetMainScreen> createState() => _ClosetMainScreenState();
}

class _ClosetMainScreenState extends ConsumerState<ClosetMainScreen> {
  @override
  Widget build(BuildContext context) {
    final criterion = ref.watch(closetSortCriterionProvider);
    final ascending = ref.watch(closetSortAscendingProvider);
    final displayState = ref.watch(closetGridDisplayStateProvider);
    final density = ref.watch(closetDensityProvider);
    final items = ref.watch(filteredClosetItemsProvider);
    final groups = ref.watch(closetGroupSummariesProvider);

    final singleLabel = criterion == ClosetSortCriterion.all ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = criterion == ClosetSortCriterion.all ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    return GalleryMainScreen<ClothingItem>(
      current: AppCategory.closet,
      items: items,
      itemId: (item) => item.id,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      selectionMode: widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      onReselectCurrentCategory: () {
        ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.all;
        _resetAllDrilldowns(ref);
      },
      classification: ClassificationConfig<ClothingItem>(
        criterionLabels: [for (final c in ClosetSortCriterion.values) c.label],
        selectedCriterionIndex: criterion.index,
        onCriterionChanged: (index) {
          ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.values[index];
          _resetAllDrilldowns(ref);
        },
        hasSubClassification: criterion.hasSubClassification,
        subHint: criterion.hasSubClassification ? criterion.subClassificationHint : null,
        subOptionLabels: _subOptionLabels(ref, criterion),
        selectedSubOptionIndex: _selectedSubOptionIndex(ref, criterion),
        onSubOptionSelected: (index) => _drillInto(ref, criterion, index),
        onClearSubSelection: () => _clearDrilldown(ref, criterion),
        density: density,
        onDensityChanged: (current) {
          final currentIndex = AppDensity.levels.indexOf(current);
          final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
          ref.read(closetDensityProvider.notifier).state = AppDensity.levels[previousIndex];
        },
        ascending: ascending,
        onAscendingChanged: (value) => ref.read(closetSortAscendingProvider.notifier).state = value,
      ),
      onItemTap: (item) {
        if (widget.selectionMode) {
          widget.onItemSelected?.call(item.id);
        } else {
          context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id));
        }
      },
      onDeleteSelected: (ids) {
        ref.read(closetItemsProvider.notifier).softDeleteMany(ids);
        GlassToast.show(
          context,
          message: '${ids.length}개 항목이 휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(closetItemsProvider.notifier).restoreMany(ids),
        );
      },
      gridBuilder: ({
        required density,
        required controller,
        required topSpacing,
        required multiSelectMode,
        required selectedIds,
        required onItemTap,
        required onItemLongPress,
      }) {
        if (displayState == ClosetGridDisplayState.groupOverview) {
          return ClassificationGroupGrid(
            groups: groups,
            density: density,
            controller: controller,
            topSpacing: topSpacing,
            onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
          );
        }
        return GroupedGalleryGrid(
          items: items,
          density: density,
          controller: controller,
          topSpacing: topSpacing,
          multiSelectMode: multiSelectMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
          onIncompleteTap: widget.selectionMode ? (item) => context.push(AppRoute.closetAdd) : null,
        );
      },
      fab: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: singleLabel, onTap: () => context.push(AppRoute.closetAdd)),
                ExpandableAddFabOption(label: multiLabel, onTap: () => context.push(AppRoute.closetAdd)),
              ],
            ),
    );
  }

  List<String> _subOptionLabels(WidgetRef ref, ClosetSortCriterion criterion) {
    return switch (criterion) {
      ClosetSortCriterion.clothingType => [
          for (final category in ClothingCategory.values) category.label,
          '미분류',
        ],
      ClosetSortCriterion.season => [
          for (final season in Season.values) season.label,
          '미분류',
        ],
      ClosetSortCriterion.dateTime => [
          for (final group in ref.watch(closetGroupSummariesProvider)) group.label,
        ],
      _ => const [],
    };
  }

  int? _selectedSubOptionIndex(WidgetRef ref, ClosetSortCriterion criterion) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        final drilled = ref.watch(closetDrilledCategoryProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified
            ? ClothingCategory.values.length
            : ClothingCategory.values.indexOf(drilled.value as ClothingCategory);
      case ClosetSortCriterion.season:
        final drilled = ref.watch(closetDrilledSeasonProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Season.values.length : Season.values.indexOf(drilled.value as Season);
      case ClosetSortCriterion.dateTime:
        final year = ref.watch(closetDrilledYearProvider);
        if (year == null) return null;
        final groups = ref.watch(closetGroupSummariesProvider);
        final index = groups.indexWhere((g) => g.value == year);
        return index == -1 ? null : index;
      default:
        return null;
    }
  }

  void _drillInto(WidgetRef ref, ClosetSortCriterion criterion, int optionIndex) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state = optionIndex == ClothingCategory.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(ClothingCategory.values[optionIndex]);
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state = optionIndex == Season.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Season.values[optionIndex]);
      case ClosetSortCriterion.dateTime:
        final groups = ref.read(closetGroupSummariesProvider);
        ref.read(closetDrilledYearProvider.notifier).state = groups[optionIndex].value as int;
      default:
        break;
    }
  }

  void _drillIntoValue(WidgetRef ref, ClosetSortCriterion criterion, Object? value) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as ClothingCategory);
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Season);
      case ClosetSortCriterion.dateTime:
        ref.read(closetDrilledYearProvider.notifier).state = value as int?;
      default:
        break;
    }
  }

  void _resetAllDrilldowns(WidgetRef ref) {
    ref.read(closetDrilledCategoryProvider.notifier).state = null;
    ref.read(closetDrilledSeasonProvider.notifier).state = null;
    ref.read(closetDrilledYearProvider.notifier).state = null;
  }

  void _clearDrilldown(WidgetRef ref, ClosetSortCriterion criterion) {
    switch (criterion) {
      case ClosetSortCriterion.clothingType:
        ref.read(closetDrilledCategoryProvider.notifier).state = null;
      case ClosetSortCriterion.season:
        ref.read(closetDrilledSeasonProvider.notifier).state = null;
      case ClosetSortCriterion.dateTime:
        ref.read(closetDrilledYearProvider.notifier).state = null;
      default:
        break;
    }
  }
}
```

- [ ] **Step 3: `flutter analyze`로 컴파일 확인, 기존 통합테스트로 회귀 확인**

Run: `flutter analyze`
Expected: 새 미사용 import/미정의 심볼 없음(있으면 이 Step에서 바로 고침 — 특히 `GlassCircleButton`/`ClassificationDrilldownCapsule` import가 `gallery_main_screen.dart`에 실제로 있는지 확인).

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/closet_main_screen_test.dart -d windows`
Expected: mock 개수 전제(12개→10개, Task 3의 `c07`/`c08` 시드 변경 때문) 관련 assertion 실패 — 이 파일의 해당 숫자(12, 4, 3, 8 등 `c07`/`c08` 포함 여부에 따라 달라지는 카운트)를 실제 값으로 갱신한다. `c07`은 반바지(bottom), `c08`은 원피스(onePiece)였으므로 "옷 종류" 그룹 카운트, 계절별 카운트(`c07`=summer, `c08`=springFall)에 영향을 준다 — 실패 메시지의 `Expected: N` vs `Actual: M`을 보고 하나씩 실제 값으로 고친다.

- [ ] **Step 4: 다중선택 통합테스트 작성**

`integration_test/closet_multi_select_test.dart`(신규):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/widgets/multi_select_checkmark.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('타일 롱프레스로 다중선택 모드 진입 + 그 타일 즉시 1개 선택된다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(SelectableGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
    expect(find.byType(MultiSelectCheckmark), findsWidgets);
  });

  testWidgets('여러 개 선택 후 [삭제] 탭 시 실제로 휴지통 이동되고 모드가 종료된다', (tester) async {
    final container = await pumpApp(tester);
    final tiles = find.byType(SelectableGalleryTile);
    await tester.longPress(tiles.first);
    await tester.pumpAndSettle();
    await tester.tap(tiles.at(1));
    await tester.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('1개 선택'), findsNothing);
    final deletedCount = container.read(closetItemsProvider).where((i) => i.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(2));
  });

  testWidgets('X 탭으로 다중선택 모드를 취소하면 선택이 비워진다', (tester) async {
    await pumpApp(tester);
    await tester.longPress(find.byType(SelectableGalleryTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsNothing);
  });
}
```

`FrostedCloseButton`의 실제 tooltip 문자열이 `'닫기'`가 아닐 수 있다 — `lib/widgets/frosted_close_button.dart`를 확인해서 정확한 tooltip으로 위 테스트의 `find.byTooltip('닫기')`를 교체한다(다른 파일에서 이미 `FrostedCloseButton`을 쓰는 곳의 tooltip 문자열을 grep해서 맞춘다).

- [ ] **Step 5: 통합테스트 실행**

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/closet_multi_select_test.dart -d windows`
Expected: PASS(실패 시 `GalleryMainScreen`의 헤더 텍스트/버튼 라벨을 테스트 기대값에 맞게, 또는 반대로 테스트를 실제 렌더링 결과에 맞게 조정 — 둘 다 스펙 §4.3~4.5 의도를 벗어나지 않는 선에서).

- [ ] **Step 6: 영향받는 기존 통합테스트 전체 재실행**

Run(taskkill 먼저, 파일별로): `closet_main_screen_test.dart`, `classification_drilldown_test.dart`, `closet_main_shell_widgets_regression_test.dart`, `header_hud_stack_architecture_test.dart`, `app_main_scaffold_shell_migration_test.dart`
Expected: 전부 PASS(Step 3에서 이미 갱신한 개수 assertion 포함).

- [ ] **Step 7: 커밋**

```bash
git add lib/widgets/gallery_main_screen.dart lib/screens/closet_main_screen.dart integration_test/closet_multi_select_test.dart integration_test/closet_main_screen_test.dart
git commit -m "feat(closet): introduce GalleryMainScreen<T> shell and migrate closet main screen onto it"
```

---

### Task 8: 코디 메인 마이그레이션

**Files:**
- Modify: `lib/screens/composition_main_screen.dart` (전면 재작성 — Task 7의 `closet_main_screen.dart` 패턴을 `Composition`/`CompositionSortCriterion`/`compositionsProvider`로 그대로 대응)
- Test: `integration_test/composition_multi_select_test.dart` (신규, Task 7 Step 4의 3개 테스트를 `Composition`/`CompositionGalleryTile` 기준으로 대응)

**Interfaces:**
- Consumes: Task 7의 `GalleryMainScreen<T>`, `ClassificationConfig<T>`.

- [ ] **Step 1: 코디 메인 재작성**

`lib/screens/composition_main_screen.dart`를 Task 7 Step 2의 `closet_main_screen.dart`와 동일 구조로 재작성한다 — `ClothingItem`→`Composition`, `ClosetSortCriterion`→`CompositionSortCriterion`, `closetItemsProvider`→`compositionsProvider`, `GroupedGalleryGrid`→`CompositionGalleryGrid`, `_subOptionLabels`/`_selectedSubOptionIndex`/`_drillInto`/`_drillIntoValue`/`_resetAllDrilldowns`/`_clearDrilldown`은 기존 `composition_main_screen.dart`(이 Task 착수 전 버전)의 로직을 그대로 옮긴다(계절/날씨/날짜 3기준). FAB는 `ExpandableAddFab` 대신 `FloatingActionButton(onPressed: () => context.push(AppRoute.compositionEditor), child: const Icon(Icons.add))`(기존과 동일, 옵션 팝업 없음). `onDeleteSelected`는:
```dart
      onDeleteSelected: (ids) {
        ref.read(compositionsProvider.notifier).softDeleteMany(ids);
        GlassToast.show(
          context,
          message: '${ids.length}개 항목이 휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(compositionsProvider.notifier).restoreMany(ids),
        );
      },
```

- [ ] **Step 2: `flutter analyze`로 컴파일 확인**

Run: `flutter analyze`
Expected: 에러 없음.

- [ ] **Step 3: 다중선택 통합테스트 작성 + 실행**

`integration_test/composition_multi_select_test.dart`를 Task 7 Step 4 파일에서 `SelectableGalleryTile`→`CompositionGalleryTile`, `closetItemsProvider`→`compositionsProvider`, `ClosetMainScreen`→`CompositionMainScreen`으로 치환해 작성. 코디는 mock이 2개뿐이라 "2개 선택 후 삭제" 테스트는 "1개 선택 후 삭제"로 조정.

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/composition_multi_select_test.dart -d windows`
Expected: PASS

- [ ] **Step 4: 영향받는 기존 통합테스트 재실행**

Run(taskkill 먼저): `composition_style_log_main_screen_test.dart`, `classification_drilldown_test.dart`
Expected: PASS(mock 개수 변화 있으면 Task 7 Step 3처럼 실제 값으로 갱신 — `comp02`가 Task 3에서 `isDeleted:true`가 됐으므로 코디 메인의 "mock 2개" 전제 대부분이 "1개"로 바뀜, 관련 assertion 전수 확인).

- [ ] **Step 5: 커밋**

```bash
git add lib/screens/composition_main_screen.dart integration_test/composition_multi_select_test.dart integration_test/composition_style_log_main_screen_test.dart
git commit -m "feat(composition): migrate composition main screen onto GalleryMainScreen<T>"
```

---

### Task 9: 스타일일지 메인 마이그레이션 (플랫형 첫 검증)

**Files:**
- Modify: `lib/screens/style_log_main_screen.dart` (전면 재작성)
- Test: `integration_test/style_log_multi_select_test.dart` (신규)

**Interfaces:**
- Consumes: Task 7의 `GalleryMainScreen<T>`(`classification: null` 경로 첫 실사용).

- [ ] **Step 1: 스타일일지 메인 재작성**

`lib/screens/style_log_main_screen.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../models/style_log.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/gallery_main_screen.dart';
import '../widgets/glass_toast.dart';
import '../widgets/selection_aware_header_actions.dart';
import '../widgets/style_log_gallery_grid.dart';

class StyleLogMainScreen extends ConsumerStatefulWidget {
  const StyleLogMainScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  ConsumerState<StyleLogMainScreen> createState() => _StyleLogMainScreenState();
}

class _StyleLogMainScreenState extends ConsumerState<StyleLogMainScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(filteredStyleLogsProvider);

    return GalleryMainScreen<StyleLog>(
      current: AppCategory.styleLog,
      items: logs,
      itemId: (log) => log.id,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      selectionMode: widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      onReselectCurrentCategory: () {},
      onItemTap: (log) {
        if (widget.selectionMode) {
          context.pop(log.id);
        } else {
          context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id));
        }
      },
      onDeleteSelected: (ids) {
        ref.read(styleLogsProvider.notifier).softDeleteMany(ids);
        GlassToast.show(
          context,
          message: '${ids.length}개 항목이 휴지통으로 이동됨',
          actionLabel: '실행취소',
          onAction: () => ref.read(styleLogsProvider.notifier).restoreMany(ids),
        );
      },
      gridBuilder: ({
        required density,
        required controller,
        required topSpacing,
        required multiSelectMode,
        required selectedIds,
        required onItemTap,
        required onItemLongPress,
      }) {
        return StyleLogGalleryGrid(
          logs: logs,
          controller: controller,
          topSpacing: topSpacing,
          multiSelectMode: multiSelectMode,
          selectedIds: selectedIds,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      },
      fab: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: '1카드 추가', onTap: () => context.push(AppRoute.styleLogAdd)),
                ExpandableAddFabOption(
                  label: '여러카드에 분할 추가',
                  onTap: () => context.push(AppRoute.styleLogAdd),
                ),
              ],
            ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`로 컴파일 확인**

Run: `flutter analyze`
Expected: 에러 없음. `classification: null`(기본값)이라 `GalleryMainScreen`이 캡슐/밀도 UI를 안 그리는지 이 시점엔 정적으로만 확인.

- [ ] **Step 3: 다중선택 통합테스트 작성 + 실행**

`integration_test/style_log_multi_select_test.dart`(신규, Task 7 Step 4 패턴을 `StyleLog`/`StyleLogGalleryTile`/`styleLogsProvider`/`StyleLogMainScreen`으로 대응):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/widgets/style_log_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    // 스타일일지로 이동.
    await tester.tap(find.byType(PopupMenuButton<Object>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('스타일일지').last);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('스타일일지도 롱프레스로 다중선택 진입 후 삭제하면 휴지통으로 이동한다', (tester) async {
    final container = await pumpApp(tester);
    await tester.longPress(find.byType(StyleLogGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    final deletedCount = container.read(styleLogsProvider).where((l) => l.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(1));
  });
}
```
카테고리 드롭다운 탭 방식이 기존 통합테스트들(`composition_style_log_main_screen_test.dart`의 `goToCategory` 헬퍼)과 다르면, 그 파일의 `categoryDropdownFinder()`/`goToCategory()` 구현을 그대로 옮겨와서 위 `pumpApp`을 교체한다(임의로 `PopupMenuButton<Object>`를 추측하지 않고 실제 finder 재사용).

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/style_log_multi_select_test.dart -d windows`
Expected: PASS

- [ ] **Step 4: 영향받는 기존 통합테스트 재실행**

Run(taskkill 먼저): `composition_style_log_main_screen_test.dart`
Expected: PASS(mock 개수 변화 반영 확인).

- [ ] **Step 5: 커밋**

```bash
git add lib/screens/style_log_main_screen.dart integration_test/style_log_multi_select_test.dart
git commit -m "feat(style-log): migrate style log main screen onto GalleryMainScreen<T> (flat/classification-null path)"
```

---

### Task 10: 휴지통 메인 마이그레이션 + 복원/영구삭제/비우기 실행

**Files:**
- Modify: `lib/screens/trash_main_screen.dart` (전면 재작성)
- Test: `integration_test/trash_execution_test.dart` (신규)

**Interfaces:**
- Consumes: Task 3(`trashEntriesProvider`, `daysUntilPurge`), Task 5(`TrashGalleryTile` 신규 파라미터), Task 6(`GlassToast`), Task 7의 `AppMainScaffold.bottomFloatingActions`(직접 사용 — `GalleryMainScreen`은 버튼 1개 전제라 휴지통은 그걸 안 쓰고 `AppMainScaffold`를 직접 배선).

휴지통은 `[복원]`+`[영구삭제]` 2버튼, 탭 시 상세이동 대신 정보팝업, 필터칩 등 `GalleryMainScreen<T>`의 "버튼 1개+탭=상세이동" 전제와 다른 점이 많아 `GalleryMainScreen`을 쓰지 않고 `AppMainScaffold`를 직접 써서 다중선택을 이 화면 로컬로 구현한다(스펙 §2.1 "화면 전용 확장" 원칙 — 억지로 우산에 넣지 않음).

- [ ] **Step 1: 휴지통 메인 재작성**

`lib/screens/trash_main_screen.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/trash_entry.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../providers/trash_providers.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_gallery_grid.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_pill.dart';
import '../widgets/glass_toast.dart';
import '../widgets/trash_gallery_tile.dart';

class TrashMainScreen extends ConsumerStatefulWidget {
  const TrashMainScreen({super.key});

  @override
  ConsumerState<TrashMainScreen> createState() => _TrashMainScreenState();
}

class _TrashMainScreenState extends ConsumerState<TrashMainScreen> {
  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};
  AppCategory? _filter;

  void _exitMultiSelect() => setState(() {
        _multiSelectMode = false;
        _selectedIds.clear();
      });

  Map<AppCategory, Set<String>> _groupByCategory(List<TrashEntry> entries, Set<String> ids) {
    final grouped = <AppCategory, Set<String>>{};
    for (final entry in entries) {
      if (ids.contains(entry.id)) {
        grouped.putIfAbsent(entry.category, () => {}).add(entry.id);
      }
    }
    return grouped;
  }

  void _restore(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    grouped[AppCategory.closet]?.let((s) => ref.read(closetItemsProvider.notifier).restoreMany(s));
    grouped[AppCategory.composition]?.let((s) => ref.read(compositionsProvider.notifier).restoreMany(s));
    grouped[AppCategory.styleLog]?.let((s) => ref.read(styleLogsProvider.notifier).restoreMany(s));
  }

  void _purge(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    grouped[AppCategory.closet]?.let((s) => ref.read(closetItemsProvider.notifier).purgeMany(s));
    grouped[AppCategory.composition]?.let((s) => ref.read(compositionsProvider.notifier).purgeMany(s));
    grouped[AppCategory.styleLog]?.let((s) => ref.read(styleLogsProvider.notifier).purgeMany(s));
  }

  Future<bool> _confirmPurge(BuildContext context, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('영구 삭제')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _confirmEmptyTrash(BuildContext context, List<TrashEntry> entries) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('휴지통 비우기'),
        content: Text('전체 ${entries.length}개 항목을 영구 삭제하시겠어요? 되돌릴 수 없어요'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('비우기')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _purge(ref, entries, entries.map((e) => e.id).toSet());
    }
  }

  void _showTrashItemInfo(BuildContext context, WidgetRef ref, List<TrashEntry> entries, TrashEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.category.label} · 영구 삭제까지 ${entry.daysUntilPurge}일',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _restore(ref, entries, {entry.id});
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('복원'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final confirmed = await _confirmPurge(sheetContext, '영구 삭제하면 되돌릴 수 없어요, 계속할까요?');
                        if (confirmed && sheetContext.mounted) {
                          _purge(ref, entries, {entry.id});
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('영구 삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(trashEntriesProvider);
    final entries = _filter == null ? allEntries : allEntries.where((e) => e.category == _filter).toList();
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.closet,
      showCategoryToggle: false,
      showBackButton: !_multiSelectMode,
      headerActions: _multiSelectMode
          ? [
              GlassPill(child: Text('${_selectedIds.length}개 선택')),
              GlassPill(
                child: TextButton(
                  onPressed: _exitMultiSelect,
                  child: const Text('닫기'),
                ),
              ),
            ]
          : [
              GlassPill(
                child: TextButton(
                  onPressed: () => setState(() => _multiSelectMode = true),
                  child: const Text('선택', style: AppTypography.actionMinimal),
                ),
              ),
              GlassPill(
                child: TextButton(
                  onPressed: () => _confirmEmptyTrash(context, allEntries),
                  child: const Text('비우기', style: AppTypography.actionMinimal),
                ),
              ),
            ],
      secondaryControlsLeft: [
        for (final option in [null, AppCategory.closet, AppCategory.composition, AppCategory.styleLog])
          GlassPill(
            child: TextButton(
              onPressed: () => setState(() => _filter = option),
              child: Text(option?.label ?? '전체'),
            ),
          ),
      ],
      bottomFloatingActions: _multiSelectMode
          ? [
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            _restore(ref, allEntries, _selectedIds);
                            GlassToast.show(context, message: '${_selectedIds.length}개 항목이 복원됨');
                            _exitMultiSelect();
                          },
                    child: const Text('복원'),
                  ),
                ),
              ),
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () async {
                            final confirmed = await _confirmPurge(context, '영구 삭제하면 되돌릴 수 없어요, 계속할까요?');
                            if (confirmed && mounted) {
                              _purge(ref, allEntries, _selectedIds);
                              _exitMultiSelect();
                            }
                          },
                    child: const Text('영구 삭제'),
                  ),
                ),
              ),
            ]
          : const [],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => AppGalleryGrid(
          itemCount: entries.length,
          density: AppDensity.mid,
          controller: controller,
          topSpacing: contentTopSpacing,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final selected = _multiSelectMode && _selectedIds.contains(entry.id);
            return TrashGalleryTile(
              key: ValueKey(entry.id),
              imagePath: entry.imagePath,
              category: entry.category,
              daysUntilPurge: entry.daysUntilPurge,
              selected: selected,
              onLongPress: () => setState(() {
                if (!_multiSelectMode) {
                  _multiSelectMode = true;
                  _selectedIds.add(entry.id);
                } else if (_selectedIds.contains(entry.id)) {
                  _selectedIds.remove(entry.id);
                } else {
                  _selectedIds.add(entry.id);
                }
              }),
              onTap: () {
                if (_multiSelectMode) {
                  setState(() {
                    if (_selectedIds.contains(entry.id)) {
                      _selectedIds.remove(entry.id);
                    } else {
                      _selectedIds.add(entry.id);
                    }
                  });
                } else {
                  _showTrashItemInfo(context, ref, allEntries, entry);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
```

`?.let(...)` 확장 메서드는 Dart 표준 라이브러리에 없다(Kotlin 관용구) — `lib/providers/trash_providers.dart` 등에도 없으므로 이 파일에서 직접 안 쓰고 아래처럼 null 체크로 바로 교체한다(`_restore`/`_purge` 메서드를 다음으로 교체):
```dart
  void _restore(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    final closetIds = grouped[AppCategory.closet];
    if (closetIds != null) ref.read(closetItemsProvider.notifier).restoreMany(closetIds);
    final compositionIds = grouped[AppCategory.composition];
    if (compositionIds != null) ref.read(compositionsProvider.notifier).restoreMany(compositionIds);
    final styleLogIds = grouped[AppCategory.styleLog];
    if (styleLogIds != null) ref.read(styleLogsProvider.notifier).restoreMany(styleLogIds);
  }

  void _purge(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    final closetIds = grouped[AppCategory.closet];
    if (closetIds != null) ref.read(closetItemsProvider.notifier).purgeMany(closetIds);
    final compositionIds = grouped[AppCategory.composition];
    if (compositionIds != null) ref.read(compositionsProvider.notifier).purgeMany(compositionIds);
    final styleLogIds = grouped[AppCategory.styleLog];
    if (styleLogIds != null) ref.read(styleLogsProvider.notifier).purgeMany(styleLogIds);
  }
```

- [ ] **Step 2: `flutter analyze`로 컴파일 확인**

Run: `flutter analyze`
Expected: 에러 없음.

- [ ] **Step 3: 휴지통 실행 통합테스트 작성**

`integration_test/trash_execution_test.dart`(신규):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/providers/trash_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('mock_data.dart에 시드된 삭제 항목이 휴지통에 실제로 보인다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    final navigator = container.read(appRouterProvider);
    navigator.push(AppRoute.trashMain);
    await tester.pumpAndSettle();
    expect(find.byType(TrashMainScreen), findsOneWidget);
    expect(find.byType(TrashGalleryTile), findsWidgets);
  });

  testWidgets('타일 탭 시 정보팝업에서 [복원]을 누르면 실제로 복원된다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01'});
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TrashGalleryTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('복원'));
    await tester.pumpAndSettle();

    final stillDeleted = container.read(trashEntriesProvider).any((e) => e.id == 'c01');
    expect(stillDeleted, isFalse);
  });

  testWidgets('다중선택으로 여러 개 골라 [영구 삭제] 확인 시 실제로 지워진다', (tester) async {
    final container = await pumpApp(tester);
    container.read(closetItemsProvider.notifier).softDeleteMany({'c01', 'c02'});
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    final tiles = find.byType(TrashGalleryTile);
    await tester.longPress(tiles.first);
    await tester.pumpAndSettle();
    await tester.tap(tiles.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('영구 삭제').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('영구 삭제').last); // 확인 모달의 버튼
    await tester.pumpAndSettle();

    final items = container.read(closetItemsProvider);
    expect(items.any((i) => i.id == 'c01'), isFalse);
    expect(items.any((i) => i.id == 'c02'), isFalse);
  });

  testWidgets('비우기 확인 모달에서 확정하면 휴지통이 전부 비워진다', (tester) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).push(AppRoute.trashMain);
    await tester.pumpAndSettle();

    await tester.tap(find.text('비우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비우기').last);
    await tester.pumpAndSettle();

    expect(container.read(trashEntriesProvider), isEmpty);
  });
}
```

`appRouterProvider`가 `GoRouter`를 직접 노출하는지, `navigator.push`가 실제로 이 프로젝트의 라우팅 방식과 맞는지 이 시점에 `lib/router/app_router.dart`를 다시 확인해서 위 `container.read(appRouterProvider).push(...)` 호출이 실제로 유효한 패턴인지 검증한다 — 안 맞으면 기존 통합테스트들이 쓰는 `context.push`/`tester.tap` 기반 네비게이션(예: 옷장 메인 위에 `/trash`를 인위적으로 push하는 기존 `closet_main_screen_test.dart`의 패턴)을 그대로 재사용해서 `pumpApp` 내부에서 `tester.widget<MaterialApp>` 대신 직접 `context.push(AppRoute.trashMain)`을 호출하는 버튼을 임시로 심거나, 더 간단히는 기존 파일들이 쓰는 인위적 push 패턴(`Builder` + `ElevatedButton.onPressed: () => context.push(...)`를 얹은 wrapper)을 그대로 따른다.

- [ ] **Step 4: 통합테스트 실행**

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/trash_execution_test.dart -d windows`
Expected: PASS(네비게이션 방식 이슈로 실패하면 Step 3 마지막 문단 방식으로 `pumpApp`을 조정 후 재실행).

- [ ] **Step 5: 영향받는 기존 통합테스트 재실행**

Run(taskkill 먼저): `settings_trash_shell_test.dart`, `closet_main_screen_test.dart`(휴지통을 인위적으로 push하는 케이스 포함)
Expected: PASS(`TrashGalleryTile` 생성자 파라미터명 변경(`remainingDays`→`daysUntilPurge`)으로 인한 컴파일 에러 있으면 해당 테스트 파일에서 고침).

- [ ] **Step 6: 커밋**

```bash
git add lib/screens/trash_main_screen.dart integration_test/trash_execution_test.dart integration_test/settings_trash_shell_test.dart integration_test/closet_main_screen_test.dart
git commit -m "feat(trash): implement real restore/purge/empty execution with multi-select and type filter chips"
```

---

### Task 11: Detail 3화면 "더보기" 메뉴 — 실제 [삭제] 연결

**Files:**
- Modify: `lib/screens/app_detail_scaffold.dart`
- Modify: `lib/screens/closet_item_detail_screen.dart`
- Modify: `lib/screens/composition_detail_screen.dart`
- Modify: `lib/screens/style_log_viewer_screen.dart`
- Test: `integration_test/detail_delete_menu_test.dart` (신규)

**Interfaces:**
- Consumes: Task 2(`softDeleteMany`), Task 6(`GlassToast`).
- Produces: `AppDetailScaffold({..., required VoidCallback onDelete})`.

- [ ] **Step 1: `AppDetailScaffold`에 `onDelete` 연결**

`lib/screens/app_detail_scaffold.dart` 전체를 다음으로 교체:
```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/glass_circle_button.dart';

class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({super.key, required this.category, required this.body, required this.onDelete});

  final AppCategory category;
  final Widget body;

  /// "더보기" 메뉴의 유일한 항목 — [삭제] 탭 시 호출. 호출부가 자기 도메인의
  /// `softDeleteMany({id})` + `context.pop()` + `GlassToast.show(...)`를 책임진다
  /// (이 Scaffold는 도메인을 모름).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: category,
      headerActions: [
        _MoreMenuButton(onDelete: onDelete),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing),
          child: body,
        ),
      ),
    );
  }
}

/// [GlassCircleButton]과 동일한 글래스 데코레이션을 유지하되, 내부를 `IconButton` 대신
/// `PopupMenuButton`으로 바꿔 [삭제] 1항목 메뉴를 연다.
class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kMinInteractiveDimension,
      height: kMinInteractiveDimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
          child: PopupMenuButton<void>(
            tooltip: '더보기 메뉴',
            icon: const Icon(Icons.more_horiz),
            onSelected: (_) => onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem<void>(value: null, child: Text('삭제')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze`로 컴파일 확인**

Run: `flutter analyze`
Expected: `closet_item_detail_screen.dart`/`composition_detail_screen.dart`/`style_log_viewer_screen.dart`에서 `AppDetailScaffold(...)` 호출에 `onDelete` 누락 컴파일 에러(다음 스텝에서 해소).

- [ ] **Step 3: 3개 Detail 화면에 `onDelete` 배선**

`lib/screens/closet_item_detail_screen.dart`의 `AppDetailScaffold(` 호출부(30행)를 다음으로 교체(import에 `'../widgets/glass_toast.dart';` 추가):
```dart
    return AppDetailScaffold(
      category: AppCategory.closet,
      onDelete: () {
        ref.read(closetItemsProvider.notifier).softDeleteMany({itemId});
        context.pop();
        GlassToast.show(context, message: '휴지통으로 이동됨');
      },
```

`lib/screens/composition_detail_screen.dart`의 `AppDetailScaffold(` 호출부(40행)를 다음으로 교체(import에 `'../widgets/glass_toast.dart';` 추가):
```dart
    return AppDetailScaffold(
      category: AppCategory.composition,
      onDelete: () {
        ref.read(compositionsProvider.notifier).softDeleteMany({compositionId});
        context.pop();
        GlassToast.show(context, message: '휴지통으로 이동됨');
      },
```

`lib/screens/style_log_viewer_screen.dart`의 `AppDetailScaffold(` 호출부(58행)를 다음으로 교체(import에 `'../widgets/glass_toast.dart';` 추가):
```dart
    return AppDetailScaffold(
      category: AppCategory.styleLog,
      onDelete: () {
        ref.read(styleLogsProvider.notifier).softDeleteMany({widget.styleLogId});
        context.pop();
        GlassToast.show(context, message: '휴지통으로 이동됨');
      },
```

- [ ] **Step 4: `flutter analyze`로 컴파일 확인**

Run: `flutter analyze`
Expected: 에러 없음.

- [ ] **Step 5: Detail 삭제 메뉴 통합테스트 작성**

`integration_test/detail_delete_menu_test.dart`(신규):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('옷 상세의 더보기 메뉴에서 삭제를 고르면 휴지통 이동+뒤로가기+토스트가 뜬다', (tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectableGalleryTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('더보기 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.byType(ClosetMainScreen), findsOneWidget);
    expect(find.byType(ClosetItemDetailScreen), findsNothing);
    final deletedCount = container.read(closetItemsProvider).where((i) => i.isDeleted).length;
    expect(deletedCount, greaterThanOrEqualTo(1));
  });
}
```

- [ ] **Step 6: 테스트 실행**

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/detail_delete_menu_test.dart -d windows`
Expected: PASS

- [ ] **Step 7: 영향받는 기존 통합테스트 재실행**

Run(taskkill 먼저): `closet_main_screen_test.dart`(더보기 메뉴 존재를 확인하는 기존 케이스가 있으면), `detail_screens_header_hud_test.dart`
Expected: PASS

- [ ] **Step 8: 커밋**

```bash
git add lib/screens/app_detail_scaffold.dart lib/screens/closet_item_detail_screen.dart lib/screens/composition_detail_screen.dart lib/screens/style_log_viewer_screen.dart integration_test/detail_delete_menu_test.dart
git commit -m "feat(detail): wire real delete action into the more-menu on all 3 detail screens"
```

---

### Task 12: 설정 → 휴지통 진입 로우

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Test: `integration_test/settings_trash_shell_test.dart` (기존 파일에 추가)

**Interfaces:**
- Consumes: 없음(라우트는 이미 존재).

- [ ] **Step 1: 테스트 작성(실패 예상)**

`integration_test/settings_trash_shell_test.dart` 하단에 추가(파일의 기존 `pumpApp`/설정 진입 헬퍼를 그대로 재사용):
```dart
testWidgets('설정 화면에서 휴지통 로우를 탭하면 실제로 휴지통 화면으로 이동한다', (tester) async {
  await pumpApp(tester); // 기존 헬퍼 — /settings로 이동시키는 로직 재사용
  await tester.tap(find.text('휴지통'));
  await tester.pumpAndSettle();
  expect(find.byType(TrashMainScreen), findsOneWidget);
});
```
`TrashMainScreen` import를 파일 상단에 추가.

- [ ] **Step 2: 테스트 실행해서 실패 확인**

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/settings_trash_shell_test.dart -d windows`
Expected: FAIL("휴지통" 텍스트 없음)

- [ ] **Step 3: 설정 화면에 휴지통 로우 추가**

`lib/screens/settings_screen.dart`의 `_SettingsRow(title: '알림', ...)` 다음(53행 이후)에 추가:
```dart
            _SettingsRow(
              title: '휴지통',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoute.trashMain),
            ),
```
파일 상단 import에 `import 'package:go_router/go_router.dart';`와 `import '../router/app_router.dart';` 추가(현재 파일에 없으면).

- [ ] **Step 4: 테스트 재실행해서 통과 확인**

Run(taskkill 먼저): `taskkill //F //IM digittal_wardrobe.exe; flutter test integration_test/settings_trash_shell_test.dart -d windows`
Expected: PASS

- [ ] **Step 5: 전체 회귀 확인 + 커밋**

Run: `flutter analyze && flutter test`
Expected: PASS

```bash
git add lib/screens/settings_screen.dart integration_test/settings_trash_shell_test.dart
git commit -m "feat(settings): add trash entry row, making /trash reachable from normal UI flow"
```

---

### Task 13: 문서 갱신 마무리

**Files:**
- Modify: `docs/history/TechnicalDebt.md`
- Modify: `docs/history/Decision.md`
- Modify: `docs/work/BACKLOG.md`

- [ ] **Step 1: `TechnicalDebt.md`에 저-우선순위 항목 추가**

`docs/history/TechnicalDebt.md` 상단(가장 최근 항목 위)에 추가:
```
[TechDebt] Detail 3화면의 자기 자신 id 조회(`firstWhere`)가 안전가드 대상에서 제외됨

상태: 의도적 미해결(우선순위 낮음)

내용:
`closet_item_detail_screen.dart`/`composition_detail_screen.dart`/`style_log_viewer_screen.dart`가
자기 자신의 id(itemId/compositionId/styleLogId)를 `orElse` 없는 `firstWhere`로 조회한다.
그 화면이 스택에 남아있는 채로 대상이 다른 경로로 purge되면 크래시하지만, 이 앱이 단순
`GoRoute` push 스택이라(딥링크/탭 상태 유지 없음) 실질 도달 불가능해 가드를 안 함
(`docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` §3.7).

조치 방향(착수 조건): 딥링크나 `StatefulShellRoute` 같은 네비게이션 구조 변경이 생기면
재검토.

---
```

- [ ] **Step 2: `Decision.md`에 이번 세션 아키텍처/명명 결정 기록**

`docs/history/Decision.md` 최상단에 추가:
```
[Decision] Main형 4개 화면(옷장/코디/스타일일지/휴지통) 셸을 `GalleryMainScreen<T>`로 제네릭화, 다중선택+휴지통 실행 구현

- `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` 전체 구현 완료.
- 분류(그룹형) 기능은 `ClassificationConfig<T>?`로 옵트인 — 스타일일지/휴지통은 null.
- 다중선택 상태는 `GalleryMainScreen`의 로컬 State(전역 provider 아님).
- `TrashEntry.remainingDays`를 `daysUntilPurge`로 명명 변경.
- `deletedAt` sentinel 패턴을 3개 모델 전체 nullable 필드로 확장 적용 —
  `docs/history/TechnicalDebt.md`의 관련 항목 해소.
- 영구삭제는 실제 데이터 제거 + 안전가드 3곳(코디 커버이미지 폴백/아트보드 렌더링 skip/
  스타일일지 연결끊김 처리) — 캐스케이드 배지 UX는 "Editor Draft 구현" 후속 이관 유지.

---
```

- [ ] **Step 3: `BACKLOG.md` 갱신**

`docs/work/BACKLOG.md`의 "Last Completed" 섹션을 다음으로 교체(기존 내용 삭제):
```
**Step⑦ 그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기) 완료 (2026-07-21).**
`docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md`를 Task 1~13으로
구현 — `GalleryMainScreen<T>` 제네릭 셸 신설(4개 Main형 화면 전부 마이그레이션),
`deletedAt` 필드+`copyWith` sentinel 패턴(3개 모델), 도메인 Notifier
`softDeleteMany`/`restoreMany`/`purgeMany`, 휴지통 파생 집계(`daysUntilPurge`,
`Provider.autoDispose`), 앱 실행 시 자동 영구삭제, 안전가드 3곳, Detail 더보기
메뉴 실제 삭제 연결, 설정→휴지통 진입 로우. 상세 경위: 위 스펙 문서, 이 계획 문서
(`docs/superpowers/plans/2026-07-21-multi-select-and-trash.md`).
```
"Current" 섹션의 "다음 세션 작업" 1번 항목에서 "그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기): 아직 스펙 착수 전 — 다음 착수 대상." 줄을 다음으로 교체:
```
   - ~~그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기)~~ **완료(2026-07-21)** — 위 "Last Completed" 참고. 다음은 그룹 C(설정 나머지)부터.
```

- [ ] **Step 4: 커밋**

```bash
git add docs/history/TechnicalDebt.md docs/history/Decision.md docs/work/BACKLOG.md
git commit -m "docs: record Group B completion in TechnicalDebt/Decision/BACKLOG"
```

---

## Self-Review 메모 (작성자용, 실행 전 확인)

- 스펙 커버리지: §2(아키텍처)=Task 7, §3.1~3.3=Task 1~2, §3.4~3.5=Task 3, §3.6=Task 7~10, §3.7=Task 3, §3.8=Task 12, §4=Task 5+7~10, §5=Task 6, §6=전체, §7=해당 없음(리뷰 이력 자체). 전 섹션 커버 확인.
- Task 7~10은 서로 강하게 의존(순서 고정 필요) — Task 8/9/10 착수 전 Task 7이 반드시 완료·검증돼 있어야 한다.
- Task 3 Step 6(mock 데이터 시드)이 Task 7/8의 기존 통합테스트 숫자 assertion을 깨뜨리는 걸 알고도 진행하는 구조 — Task 7/8의 Step 3/4가 그 해소를 명시적으로 포함하고 있음을 재확인함.
