# InteractiveArtboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Project-specific note:** This repo layers its own PM/Worker/Review/Tester harness on top of the generic flow (`CLAUDE.md`, `.claude/agents/worker.md` / `review.md` / `tester.md`). When executed inside this repo, route each task through that harness instead of a generic subagent loop: Worker implements a task → Review checks it → (once ALL tasks pass Review) Tester writes and runs `integration_test/interactive_artboard_test.dart` per the checklist in spec §7 (Tester is intentionally **not** part of this plan's tasks — Worker never writes `integration_test/`, per project convention that a separate agent verifies runtime behavior independently). Task 1 is the only task with its own automated test (a plain Dart unit test, not gesture/UI behavior) because it's pure data-transformation logic outside that convention's scope.

**Goal:** Build the `InteractiveArtboard` Flutter widget — a standalone, domain-agnostic artboard for placing/moving/resizing/rotating/reordering/deleting items — fully isolated from the `Composition`/`ClothingItem` app models, per the approved spec.

**Architecture:** A `StatefulWidget` (`InteractiveArtboard`) renders a `LayoutBuilder`-sized canvas of `ArtboardItemView`s stacked by `zIndex`, with a top-level `GestureDetector.onTapUp` classifying taps against a per-item Hit Area (smaller than the render box) for selection/overlap, per-item `GestureDetector.onPan*` handlers for move/resize/rotate (Tap and Pan recognizers coexist in the same gesture arena without manual mediation), an `Overlay`-based delete-zone for drag-out-to-delete, and a fully controlled `selectedItemId`/`onSelectionChanged` pair so a future Thumbnail list can share selection state.

**Tech Stack:** Flutter/Dart only (`GestureDetector`, `Transform`, `Overlay`, `ReorderableListView`) — no Riverpod, no external packages, matching `00_MVP.md` §6's "no suitable off-the-shelf package" rationale.

## Global Constraints

- Zero dependency on `Composition`, `ClothingItem`, or any Riverpod provider anywhere in `lib/widgets/interactive_artboard/` (spec §1, §2).
- All new code lives under `lib/widgets/interactive_artboard/` (4 files) — no existing file is modified (spec §6).
- The widget assumes its parent wraps it in `AspectRatio(aspectRatio: 1)` — it does not enforce this itself (spec §3).
- Every literal tuning value (Hit Area inset ratio, scale bounds, handle offset floor, handle visual size, rotate stem length) must be a named `const` with a one-line rationale comment — no bare magic numbers (`engineering-principles` skill, spec §4.3/§4.4).
- Selection is a fully controlled pair: the widget never mutates `selectedItemId` itself, only calls `onSelectionChanged` and waits for the parent to pass the new value back down (spec §5).
- `onItemsChanged` fires only when a gesture **commits** (pan end / reorder), never on every frame during a drag (spec §4.3, §5).
- Verification convention for this plan: each task (except Task 1) ends with `flutter analyze` — clean gesture/UI behavior verification is Tester's job (post-Review, separate from this plan) per this project's established Worker/Review/Tester split and per spec §7, which already enumerates the full behavioral test checklist Tester will implement.

---

## Task 1: `ArtboardItem` data model

**Files:**
- Create: `lib/widgets/interactive_artboard/artboard_item.dart`
- Test: `test/widgets/interactive_artboard/artboard_item_test.dart`

**Interfaces:**
- Produces: `class ArtboardItem` with fields `id (String)`, `imagePath (String)`, `x (double)`, `y (double)`, `scale (double, default 1.0)`, `rotation (double, default 0.0, radians)`, `zIndex (int, default 0)`, and method `ArtboardItem copyWith({double? x, double? y, double? scale, double? rotation, int? zIndex})`. Every later task in this plan constructs, reads, and calls `.copyWith(...)` on this exact type.

- [ ] **Step 1: Write the failing test**

```dart
// test/widgets/interactive_artboard/artboard_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/interactive_artboard/artboard_item.dart';

void main() {
  group('ArtboardItem.copyWith', () {
    test('overrides only the specified fields', () {
      const original = ArtboardItem(
        id: 'item-1',
        imagePath: 'assets/mock/item1.png',
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        zIndex: 0,
      );

      final updated = original.copyWith(x: 0.7, scale: 1.5);

      expect(updated.id, 'item-1');
      expect(updated.imagePath, 'assets/mock/item1.png');
      expect(updated.x, 0.7);
      expect(updated.y, 0.5);
      expect(updated.scale, 1.5);
      expect(updated.rotation, 0.0);
      expect(updated.zIndex, 0);
    });

    test('keeps all fields unchanged when called with no arguments', () {
      const original = ArtboardItem(
        id: 'item-2',
        imagePath: 'assets/mock/item2.png',
        x: 0.2,
        y: 0.3,
        scale: 0.8,
        rotation: 1.2,
        zIndex: 3,
      );

      final updated = original.copyWith();

      expect(updated.x, original.x);
      expect(updated.y, original.y);
      expect(updated.scale, original.scale);
      expect(updated.rotation, original.rotation);
      expect(updated.zIndex, original.zIndex);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/interactive_artboard/artboard_item_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/widgets/interactive_artboard/artboard_item.dart': No such file or directory.` (or equivalent "package not found" compile error)

- [ ] **Step 3: Write the implementation**

```dart
// lib/widgets/interactive_artboard/artboard_item.dart

/// 코디 편집기 아트보드에 배치되는 아이템 1개.
///
/// `Composition`/`ClothingItem` 도메인 모델과 독립적이다 — `clothingItemId` 같은
/// FK를 포함하지 않아, 이 위젯이 Composition 도메인에 결합되지 않는다.
class ArtboardItem {
  const ArtboardItem({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  /// 아이템 고유 ID. 선택 상태(`selectedItemId`)와 삭제(`onItemDeleted`) 콜백이
  /// 이 값을 기준으로 아이템을 식별한다.
  final String id;

  /// 렌더링할 이미지 asset 경로.
  final String imagePath;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 중심 앵커 기준.
  final double x;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 중심 앵커 기준.
  final double y;

  /// 렌더 박스 배율. 1.0이 기본 크기(`baseItemSize`).
  final double scale;

  /// 회전각(라디안).
  final double rotation;

  /// 렌더 순서 — 값이 클수록 위에 그려진다.
  final int zIndex;

  ArtboardItem copyWith({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
  }) {
    return ArtboardItem(
      id: id,
      imagePath: imagePath,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/interactive_artboard/artboard_item_test.dart`
Expected: `00:0X +2: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/interactive_artboard/artboard_item.dart test/widgets/interactive_artboard/artboard_item_test.dart
git commit -m "feat(artboard): add ArtboardItem data model"
```

---

## Task 2: Static rendering (positioning + zIndex paint order)

**Files:**
- Create: `lib/widgets/interactive_artboard/artboard_item_view.dart`
- Create: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `ArtboardItem` (Task 1) — all fields.
- Produces:
  - `class ArtboardItemView extends StatelessWidget` with constructor `ArtboardItemView({required ArtboardItem item, required double renderBoxSize})` — pure image rendering, no gesture, no rotation (rotation is applied by the parent, spec §4.3 — Selection Box/handles must share the same rotation transform later).
  - `class InteractiveArtboard extends StatefulWidget` with constructor params `items (List<ArtboardItem>, required)`, `onItemsChanged (ValueChanged<List<ArtboardItem>>, required)`, `onItemDeleted (ValueChanged<String>, required)`, `selectedItemId (String?, required)`, `onSelectionChanged (ValueChanged<String?>, required)`, `baseItemSizeFraction (double, default 0.28)`. Later tasks only *add* to `_InteractiveArtboardState` — this task's constructor signature is final and unchanged by every later task.

- [ ] **Step 1: Write `ArtboardItemView`**

```dart
// lib/widgets/interactive_artboard/artboard_item_view.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';

/// 아이템 1개의 이미지 렌더링만 담당한다 — 위치/회전은 부모([InteractiveArtboard])가
/// 감싸는 Transform이 처리한다(스펙 §4.3, Selection Box·핸들과 동일 Transform 공유).
class ArtboardItemView extends StatelessWidget {
  const ArtboardItemView({
    super.key,
    required this.item,
    required this.renderBoxSize,
  });

  final ArtboardItem item;

  /// §2.1의 렌더 박스 한 변 길이(`baseItemSize * item.scale`), 이미 계산된 값을 받는다.
  final double renderBoxSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: renderBoxSize,
      height: renderBoxSize,
      child: Image.asset(item.imagePath, fit: BoxFit.contain),
    );
  }
}
```

- [ ] **Step 2: Write `InteractiveArtboard` (static rendering only)**

```dart
// lib/widgets/interactive_artboard/interactive_artboard.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';

/// 코디 편집기 아트보드 — 배치/이동/회전/크기조절/겹침처리/삭제의 코어 상호작용을
/// 제공하는 완전 독립 위젯. `Composition`/`ClothingItem` 모델에 의존하지 않는다.
///
/// 선택 상태는 완전 외부 제어(controlled)다 — 위젯이 내부에 선택을 소유하지 않고
/// [selectedItemId]를 그대로 반영만 한다(스펙 §5).
class InteractiveArtboard extends StatefulWidget {
  const InteractiveArtboard({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.onItemDeleted,
    required this.selectedItemId,
    required this.onSelectionChanged,
    this.baseItemSizeFraction = 0.28,
  });

  final List<ArtboardItem> items;
  final ValueChanged<List<ArtboardItem>> onItemsChanged;
  final ValueChanged<String> onItemDeleted;
  final String? selectedItemId;
  final ValueChanged<String?> onSelectionChanged;

  /// 캔버스 짧은 변 대비 baseItemSize 비율(스펙 §2.1, 권장 범위 25~30%의 중간값).
  final double baseItemSizeFraction;

  @override
  State<InteractiveArtboard> createState() => _InteractiveArtboardState();
}

class _InteractiveArtboardState extends State<InteractiveArtboard> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return Stack(
          key: _canvasKey,
          clipBehavior: Clip.none,
          children: [
            for (final item in sortedItems)
              _positioned(item, canvasSize, baseItemSize),
          ],
        );
      },
    );
  }

  Widget _positioned(ArtboardItem item, Size canvasSize, double baseItemSize) {
    final renderBoxSize = baseItemSize * item.scale;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;
    return Positioned(
      key: ValueKey(item.id),
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
      ),
    );
  }
}
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/interactive_artboard/artboard_item_view.dart lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): render items positioned/scaled/rotated by zIndex order"
```

---

## Task 3: Hit Area, tap classification (0/1 cases), controlled selection, Selection Outline

**Files:**
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `_InteractiveArtboardState._positioned` (Task 2, full method replaced below).
- Produces: `_InteractiveArtboardState._hitAreaContains(ArtboardItem, Offset, Size, double)` and `_InteractiveArtboardState._handleTapUp(TapUpDetails, Size, double)` — Task 4 extends `_handleTapUp`'s 2-or-more branch; Task 5/6 reuse the same Hit Area sizing constant `_hitAreaInsetFactor`.

- [ ] **Step 1: Add Hit Area math, tap classification, and Selection Outline**

Replace the full file content of `lib/widgets/interactive_artboard/interactive_artboard.dart` with:

```dart
// lib/widgets/interactive_artboard/interactive_artboard.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';

/// 렌더 박스 대비 Hit Area 축소 비율 — 배경제거 옷 이미지의 투명 여백을 터치판정에서
/// 제외하기 위함(스펙 §2.2). 85%로 좁혀 실제 불투명 영역을 넉넉히 감싸되 여백은 배제.
/// 잠정값 — 스펙 §2.2가 요구하는 대로, Worker는 실제 배경제거 이미지로 시각 확인 후
/// 필요하면 이 값을 조정한다.
const double _hitAreaInsetFactor = 0.85;

/// 코디 편집기 아트보드 — 배치/이동/회전/크기조절/겹침처리/삭제의 코어 상호작용을
/// 제공하는 완전 독립 위젯. `Composition`/`ClothingItem` 모델에 의존하지 않는다.
///
/// 선택 상태는 완전 외부 제어(controlled)다 — 위젯이 내부에 선택을 소유하지 않고
/// [selectedItemId]를 그대로 반영만 한다(스펙 §5).
class InteractiveArtboard extends StatefulWidget {
  const InteractiveArtboard({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.onItemDeleted,
    required this.selectedItemId,
    required this.onSelectionChanged,
    this.baseItemSizeFraction = 0.28,
  });

  final List<ArtboardItem> items;
  final ValueChanged<List<ArtboardItem>> onItemsChanged;
  final ValueChanged<String> onItemDeleted;
  final String? selectedItemId;
  final ValueChanged<String?> onSelectionChanged;

  /// 캔버스 짧은 변 대비 baseItemSize 비율(스펙 §2.1, 권장 범위 25~30%의 중간값).
  final double baseItemSizeFraction;

  @override
  State<InteractiveArtboard> createState() => _InteractiveArtboardState();
}

class _InteractiveArtboardState extends State<InteractiveArtboard> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _handleTapUp(details, canvasSize, baseItemSize),
          child: Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: [
              for (final item in sortedItems)
                _positioned(item, canvasSize, baseItemSize),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(ArtboardItem item, Size canvasSize, double baseItemSize) {
    final renderBoxSize = baseItemSize * item.scale;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;
    final isSelected = item.id == widget.selectedItemId;
    return Positioned(
      key: ValueKey(item.id),
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 아이템의 Hit Area(렌더 박스를 [_hitAreaInsetFactor]만큼 축소한, 회전 반영 사각형)
  /// 안에 [point]가 들어가는지 판정한다(스펙 §2.2/§4.1).
  bool _hitAreaContains(
    ArtboardItem item,
    Offset point,
    Size canvasSize,
    double baseItemSize,
  ) {
    final renderBoxSize = baseItemSize * item.scale;
    final hitHalf = renderBoxSize * _hitAreaInsetFactor / 2;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;
    final dx = point.dx - centerX;
    final dy = point.dy - centerY;
    final cosT = math.cos(item.rotation);
    final sinT = math.sin(item.rotation);
    final localX = dx * cosT + dy * sinT;
    final localY = -dx * sinT + dy * cosT;
    return localX.abs() <= hitHalf && localY.abs() <= hitHalf;
  }

  void _handleTapUp(TapUpDetails details, Size canvasSize, double baseItemSize) {
    final matches = widget.items
        .where((item) =>
            _hitAreaContains(item, details.localPosition, canvasSize, baseItemSize))
        .toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    if (matches.isEmpty) {
      widget.onSelectionChanged(null);
    } else if (matches.length == 1) {
      widget.onSelectionChanged(matches.first.id);
    }
    // 2개 이상(겹침) 처리는 Task 4(겹침 팝업)에서 추가.
  }
}
```

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): add Hit Area tap classification, controlled selection, Selection Outline"
```

---

## Task 4: Overlap popup (2-or-more tap branch)

**Files:**
- Create: `lib/widgets/interactive_artboard/artboard_overlap_popup.dart`
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `ArtboardItem` (Task 1), `_handleTapUp`'s matches list (Task 3).
- Produces: `class ArtboardOverlapPopup extends StatefulWidget` with constructor `ArtboardOverlapPopup({required List<ArtboardItem> items, required ValueChanged<String> onSelect, required ValueChanged<List<String>> onReorder})`.

- [ ] **Step 1: Write `ArtboardOverlapPopup`**

```dart
// lib/widgets/interactive_artboard/artboard_overlap_popup.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';

/// 겹친 아이템 목록을 z-순서(위→아래)로 보여주는 팝업(스펙 §4.5).
/// - 행의 썸네일/라벨 탭 → [onSelect]
/// - 행 끝 드래그핸들로 재배열 → [onReorder](재배열된 새 순서의 id 리스트, 위→아래)
///
/// 탭(선택)과 드래그(재배열)의 히트영역을 분리한다 — `ReorderableListView`의
/// `buildDefaultDragHandles: false` + `ReorderableDragStartListener`로 드래그 트리거를
/// trailing 아이콘에만 한정하고, `ListTile.onTap`은 그대로 탭 선택에 쓴다.
class ArtboardOverlapPopup extends StatefulWidget {
  const ArtboardOverlapPopup({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onReorder,
  });

  /// z-순서 내림차순(위→아래)으로 이미 정렬되어 들어온다.
  final List<ArtboardItem> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<List<String>> onReorder;

  @override
  State<ArtboardOverlapPopup> createState() => _ArtboardOverlapPopupState();
}

class _ArtboardOverlapPopupState extends State<ArtboardOverlapPopup> {
  // `late` 필요 이유: State 필드 초기화는 위젯이 attach되기 전에 실행되므로
  // widget.items를 즉시 참조하는 non-late 초기화는 실패한다.
  late final List<ArtboardItem> _order = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ReorderableListView(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        // `onReorder`는 이 프로젝트가 쓰는 Flutter SDK(3.44.4)에서 deprecated —
        // `onReorderItem`이 newIndex를 이미 보정해서 넘겨주므로 수동 보정이 필요 없다
        // (Worker가 flutter analyze 중 발견, SDK 공식 마이그레이션 예시와 일치).
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final moved = _order.removeAt(oldIndex);
            _order.insert(newIndex, moved);
          });
          widget.onReorder(_order.map((item) => item.id).toList());
        },
        children: [
          for (var i = 0; i < _order.length; i++)
            ListTile(
              key: ValueKey(_order[i].id),
              leading: Image.asset(
                _order[i].imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
              title: Text(_order[i].id),
              onTap: () => widget.onSelect(_order[i].id),
              trailing: ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the popup into the 2-or-more tap branch**

In `lib/widgets/interactive_artboard/interactive_artboard.dart`:

Add the import:

```dart
import 'artboard_overlap_popup.dart';
```

Replace the `_handleTapUp` method with:

```dart
  void _handleTapUp(TapUpDetails details, Size canvasSize, double baseItemSize) {
    final matches = widget.items
        .where((item) =>
            _hitAreaContains(item, details.localPosition, canvasSize, baseItemSize))
        .toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    if (matches.isEmpty) {
      widget.onSelectionChanged(null);
    } else if (matches.length == 1) {
      widget.onSelectionChanged(matches.first.id);
    } else {
      _openOverlapPopup(matches);
    }
  }

  Future<void> _openOverlapPopup(List<ArtboardItem> matches) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ArtboardOverlapPopup(
        items: matches,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          widget.onSelectionChanged(id);
        },
        onReorder: (orderedIds) {
          // 겹친 아이템들이 원래 갖고 있던 zIndex 값 집합을 그대로 재사용하고
          // (0..N-1 같은 새 범위로 압축하지 않음), 순서만 새로 배정한다 — 캔버스에
          // 이 팝업에 없는 다른 아이템들이 이미 그 zIndex 값 사이사이를 차지하고
          // 있을 수 있어서, 새 범위로 압축하면 그 아이템들과 충돌해 전체 페인트
          // 순서가 조용히 어긋난다(리뷰 P1 반영).
          final originalZIndexesDescending = matches.map((item) => item.zIndex).toList()
            ..sort((a, b) => b.compareTo(a));
          final newZIndexById = <String, int>{
            for (var i = 0; i < orderedIds.length; i++)
              orderedIds[i]: originalZIndexesDescending[i],
          };
          final updated = widget.items.map((item) {
            final newZ = newZIndexById[item.id];
            return newZ == null ? item : item.copyWith(zIndex: newZ);
          }).toList();
          widget.onItemsChanged(updated);
        },
      ),
    );
  }
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/interactive_artboard/artboard_overlap_popup.dart lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): add overlap popup with separated tap-to-select/drag-to-reorder"
```

---

## Task 5: Move — body drag with local-pixel tracking and normalize-on-commit

**Files:**
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `_hitAreaContains`'s sizing logic (Task 3, reused for the per-item drag `GestureDetector`'s size); `_positioned` (Task 3, renamed and restructured below).
- Produces: `_InteractiveArtboardState._bodyDragStart/_bodyDragUpdate/_bodyDragEnd(ArtboardItem, ...)` — Task 6 reuses these three verbatim for the 이동 handle; Task 7 extends `_bodyDragUpdate`/`_bodyDragEnd` with boundary/delete logic. Also produces `_itemLayer(...)` (renamed from `_positioned`, now with `includeVisual`/`includeInteraction` params) and the hoisted-selection addition to `build()` — Task 6 extends `_itemLayer` further (resize/rotate + handles), Task 8 extends it again (RepaintBoundary).

- [ ] **Step 1: Add drag state fields, hoist the selected item's interaction layer, and split `_positioned` into `_itemLayer`**

**Why this split is needed:** spec §4.1 requires that "the selected item's interaction layer (body hit-test area + 3 handles) always paints on top, decoupled from zIndex paint order" — otherwise an item selected via the overlap popup (Task 4) while visually covered by a higher-`zIndex` item would have its drag hit-area buried underneath and become permanently undraggable. `_positioned` (from Task 3) draws each item once, in `zIndex` order, with no way to separately re-prioritize one item's interactive layer — so this task renames it to `_itemLayer` and gives it `includeVisual`/`includeInteraction` flags: `build()` now renders every item's `_itemLayer` in normal `zIndex` order for their **visual** (image + outline), and additionally renders the **selected** item's `_itemLayer` one more time, last in the `Stack`, with only its **interaction** layer (hit-area) turned on — so it's always on top for touch, while its image only paints once (not duplicated).

In `lib/widgets/interactive_artboard/interactive_artboard.dart`, add these fields to `_InteractiveArtboardState` (right after `final GlobalKey _canvasKey = GlobalKey();`):

```dart
  String? _draggingItemId;
  Offset _dragDelta = Offset.zero;
```

Replace the `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        final selectedIndex =
            widget.items.indexWhere((item) => item.id == widget.selectedItemId);
        final selectedItem = selectedIndex == -1 ? null : widget.items[selectedIndex];

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _handleTapUp(details, canvasSize, baseItemSize),
          child: Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: [
              for (final item in sortedItems)
                _itemLayer(
                  item,
                  canvasSize,
                  baseItemSize,
                  isSelected: item.id == widget.selectedItemId,
                  includeInteraction: item.id != widget.selectedItemId,
                ),
              // 선택된 아이템의 몸체 히트테스트 영역은 paint 순서(zIndex)와 분리해
              // 항상 Stack 최상단에 별도로 그린다 — 팝업으로 선택한 아래쪽 아이템이
              // 위쪽 아이템에 가려져 있어도 계속 드래그로 조작할 수 있게 하기 위함
              // (스펙 §4.1). 이미지/아웃라인은 위 루프에서 이미 그렸으므로 여기선
              // 상호작용 레이어만 중복 없이 추가한다(includeVisual: false).
              if (selectedItem != null)
                _itemLayer(
                  selectedItem,
                  canvasSize,
                  baseItemSize,
                  isSelected: true,
                  includeInteraction: true,
                  includeVisual: false,
                ),
            ],
          ),
        );
      },
    );
  }
```

Replace the `_positioned` method (renaming it to `_itemLayer`) with:

```dart
  Widget _itemLayer(
    ArtboardItem item,
    Size canvasSize,
    double baseItemSize, {
    required bool isSelected,
    required bool includeInteraction,
    bool includeVisual = true,
  }) {
    final renderBoxSize = baseItemSize * item.scale;
    final hitAreaSize = renderBoxSize * _hitAreaInsetFactor;
    var centerX = canvasSize.width * item.x;
    var centerY = canvasSize.height * item.y;
    if (item.id == _draggingItemId) {
      centerX += _dragDelta.dx;
      centerY += _dragDelta.dy;
    }
    return Positioned(
      // 같은 아이템이 자연 위치(시각)와 최상단 고정(상호작용) 두 곳에 각각 렌더링될
      // 수 있어(선택된 아이템, 아래 build()의 마지막 추가 호출 참고) 단순
      // ValueKey(item.id)만 쓰면 Stack 안에서 키가 중복돼 런타임 에러가 난다 —
      // includeVisual로 역할을 구분해 키를 유일하게 만든다.
      key: ValueKey('${item.id}:${includeVisual ? 'visual' : 'interactive'}'),
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (includeVisual) ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
            if (includeVisual && isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (includeInteraction)
              SizedBox(
                width: hitAreaSize,
                height: hitAreaSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _bodyDragStart(item),
                  onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
                  onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _bodyDragStart(ArtboardItem item) {
    setState(() {
      _draggingItemId = item.id;
      _dragDelta = Offset.zero;
    });
  }

  void _bodyDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    setState(() {
      _dragDelta += details.delta;
    });
  }

  void _bodyDragEnd(ArtboardItem item, Size canvasSize) {
    final dxNormalized = _dragDelta.dx / canvasSize.width;
    final dyNormalized = _dragDelta.dy / canvasSize.height;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(x: current.x + dxNormalized, y: current.y + dyNormalized);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _draggingItemId = null;
      _dragDelta = Offset.zero;
    });
  }
```

**Note on z-order default:** the per-item `GestureDetector`s are built inside `for (final item in sortedItems)` (ascending `zIndex`), so later (higher-`zIndex`) items are later `Stack` children and paint on top — Flutter's default hit-testing gives pointer-down priority to the topmost child at that point, so a direct drag on an overlapping region always grabs the highest-`zIndex` item automatically, satisfying `02_코디.md`'s "겹친 이미지 이동 시 기본은 최상단 옷" with no extra branching.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): add body drag-to-move with normalize-on-commit"
```

---

## Task 6: Selection Box handles — 이동/크기조절/회전

**Files:**
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `_bodyDragStart/_bodyDragUpdate/_bodyDragEnd` (Task 5, reused verbatim for the 이동 핸들).
- Produces: `_resizeDragStart/_resizeDragUpdate/_resizeDragEnd`, `_rotateDragStart/_rotateDragUpdate/_rotateDragEnd` — Task 7 does not touch these (delete-drag-out only applies to move); Task 8 wraps the 3 handles with `Semantics`.

- [ ] **Step 1: Add scale/handle constants**

In `lib/widgets/interactive_artboard/interactive_artboard.dart`, add these consts next to `_hitAreaInsetFactor`:

```dart
/// scale 하한/상한 — 너무 작아지면 조작 불가, 너무 커지면 캔버스를 벗어나 보기
/// 어려워짐(스펙 §4.3).
const double _minScale = 0.3;
const double _maxScale = 3.0;

/// 핸들이 아이템 중심에서 최소 이만큼은 떨어지도록 하는 오프셋(논리픽셀) — 44px
/// 접근성 최소 터치영역 권장 기준의 절반(스펙 §4.4).
const double _minHandleOffset = 24.0;

/// 핸들 원형 시각/히트 크기(논리픽셀) — 44x44 접근성 최소 터치영역 기준을 그대로
/// 적용(`flutter-implementation-conventions` Review 체크리스트 "터치 타겟 44×44
/// 이상"). 32px로는 이 기준에 못 미쳤던 걸 리뷰에서 지적받아 수정.
const double _handleVisualDiameter = 44.0;

/// 회전 핸들이 상단 모서리에서 위로 뻗는 연결선 길이(논리픽셀).
const double _rotateStemLength = 20.0;

/// 아이템 렌더 박스를 감싸는 상호작용 레이어의 여유 마진(논리픽셀) — 핸들(특히
/// 회전 핸들의 줏대)이 렌더 박스 경계 밖으로 튀어나오는데, `Positioned`에 크기를
/// 명시하면 `RenderBox.hitTest`가 딱 그 크기 안에서만 자식으로 히트테스트를
/// 위임한다(`Clip.none`은 페인트 오버플로만 허용하고 히트테스트엔 영향 없음) —
/// 그래서 레이어 자체를 핸들 최대 도달 거리보다 넉넉히 키워서, 핸들이 항상 이
/// 레이어의 히트테스트 가능 영역 안에 들어오게 한다(리뷰 P0 반영).
const double _handleLayerMargin = _minHandleOffset + _rotateStemLength + _handleVisualDiameter;
```

- [ ] **Step 2: Add resize/rotate state, canvas-local pointer helper, and handle widgets**

Add these fields to `_InteractiveArtboardState` (after `Offset _dragDelta = Offset.zero;`):

```dart
  String? _resizingItemId;
  double _resizeStartDistance = 0;
  double _resizeStartScale = 1;
  double? _liveScale;

  String? _rotatingItemId;
  double _rotateStartAngleOffset = 0;
  double? _liveRotation;
```

Add this helper method (converts a global pointer position into the canvas `Stack`'s local coordinate space, using `_canvasKey`):

```dart
  Offset _toCanvasLocal(Offset globalPosition) {
    final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }
```

Replace the `_itemLayer` method with (adds live resize/rotate + handles; handles are gated by `includeInteraction` — same hoisting rule from Task 5 applies to them, since spec §4.1 explicitly includes "핸들 3개" in what must stay reachable/visible on top of a covering item):

**Why the outer `Positioned` is now sized to `layerSize` instead of `renderBoxSize`:** handles sit outside the render box (that's the point — they're corner/stem handles around the item). If the outer `Positioned` is exactly `renderBoxSize`-sized, Flutter's `RenderBox.hitTest()` rejects any touch outside that box *before* it ever reaches the child `Stack` — `Clip.none` only lets the overflow *paint*, it does not extend the hit-testable region. So the whole per-item layer (image, hit-area, and handles) is now built inside a bigger box (`layerSize = renderBoxSize + 2 * _handleLayerMargin`), and everything inside is positioned relative to that bigger box's own center (`layerCenter`) instead of the render box's corner.

```dart
  Widget _itemLayer(
    ArtboardItem item,
    Size canvasSize,
    double baseItemSize, {
    required bool isSelected,
    required bool includeInteraction,
    bool includeVisual = true,
  }) {
    final effectiveScale =
        (item.id == _resizingItemId && _liveScale != null) ? _liveScale! : item.scale;
    final effectiveRotation = (item.id == _rotatingItemId && _liveRotation != null)
        ? _liveRotation!
        : item.rotation;
    final renderBoxSize = baseItemSize * effectiveScale;
    final hitAreaSize = renderBoxSize * _hitAreaInsetFactor;
    final layerSize = renderBoxSize + 2 * _handleLayerMargin;
    final layerCenter = layerSize / 2;
    var centerX = canvasSize.width * item.x;
    var centerY = canvasSize.height * item.y;
    if (item.id == _draggingItemId) {
      centerX += _dragDelta.dx;
      centerY += _dragDelta.dy;
    }
    final handleOffset = math.max(renderBoxSize / 2, _minHandleOffset);

    return Positioned(
      key: ValueKey('${item.id}:${includeVisual ? 'visual' : 'interactive'}'),
      left: centerX - layerSize / 2,
      top: centerY - layerSize / 2,
      width: layerSize,
      height: layerSize,
      child: Transform.rotate(
        angle: effectiveRotation,
        alignment: Alignment.center,
        child: Stack(
          children: [
            if (includeVisual)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
                child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
              ),
            if (includeVisual && isSelected)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (includeInteraction)
              Positioned(
                left: layerCenter - hitAreaSize / 2,
                top: layerCenter - hitAreaSize / 2,
                width: hitAreaSize,
                height: hitAreaSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _bodyDragStart(item),
                  onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
                  onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
                ),
              ),
            if (includeInteraction && isSelected)
              ..._buildHandles(item, layerCenter, handleOffset, canvasSize),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHandles(
    ArtboardItem item,
    double center,
    double handleOffset,
    Size canvasSize,
  ) {
    return [
      // 이동 핸들 — 좌하단
      _handle(
        left: center - handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        onPanStart: (_) => _bodyDragStart(item),
        onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
      ),
      // 크기조절 핸들 — 우하단
      _handle(
        left: center + handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        onPanStart: (details) => _resizeDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _resizeDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _resizeDragEnd(item),
      ),
      // 회전 핸들 — 상단 중앙에서 위로 뻗은 연결선 끝
      _handle(
        left: center - _handleVisualDiameter / 2,
        top: center - handleOffset - _rotateStemLength - _handleVisualDiameter / 2,
        onPanStart: (details) => _rotateDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _rotateDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _rotateDragEnd(item),
      ),
    ];
  }

  Widget _handle({
    required double left,
    required double top,
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: _handleVisualDiameter,
          height: _handleVisualDiameter,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  void _resizeDragStart(ArtboardItem item, DragStartDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    _resizeStartDistance = (pointerLocal - canvasCenter).distance;
    _resizeStartScale = item.scale;
    setState(() {
      _resizingItemId = item.id;
      _liveScale = item.scale;
    });
  }

  void _resizeDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    if (_resizeStartDistance == 0) return;
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final currentDistance = (pointerLocal - canvasCenter).distance;
    final rawScale = _resizeStartScale * (currentDistance / _resizeStartDistance);
    setState(() {
      _liveScale = rawScale.clamp(_minScale, _maxScale);
    });
  }

  void _resizeDragEnd(ArtboardItem item) {
    final finalScale = _liveScale ?? item.scale;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(scale: finalScale);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _resizingItemId = null;
      _liveScale = null;
    });
  }

  void _rotateDragStart(ArtboardItem item, DragStartDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final pointerAngle = math.atan2(
      pointerLocal.dy - canvasCenter.dy,
      pointerLocal.dx - canvasCenter.dx,
    );
    _rotateStartAngleOffset = pointerAngle - item.rotation;
    setState(() {
      _rotatingItemId = item.id;
      _liveRotation = item.rotation;
    });
  }

  void _rotateDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final pointerAngle = math.atan2(
      pointerLocal.dy - canvasCenter.dy,
      pointerLocal.dx - canvasCenter.dx,
    );
    setState(() {
      _liveRotation = pointerAngle - _rotateStartAngleOffset;
    });
  }

  void _rotateDragEnd(ArtboardItem item) {
    final finalRotation = _liveRotation ?? item.rotation;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(rotation: finalRotation);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _rotatingItemId = null;
      _liveRotation = null;
    });
  }
```

**Why this math is rotation-independent (spec §4.3):** `DragUpdateDetails`/`DragStartDetails.globalPosition` are screen-space coordinates, unaffected by the ancestor `Transform.rotate` the handle sits inside — so distance-from-center (resize) and `atan2` angle (rotate), both computed from `_toCanvasLocal(details.globalPosition)` against the item's fixed canvas-space center, are correct regardless of the item's current rotation, with no manual un-rotation needed.

- [ ] **Step 3: Manual smoke check before running analysis**

This handle-layout restructuring (the `layerSize`/`layerCenter` change above) is exactly the kind of runtime-only geometry issue `flutter analyze` cannot catch — a previous version of this plan sized the outer `Positioned` to `renderBoxSize` instead of `layerSize`, which passed static analysis cleanly while leaving the rotate handle completely untappable (`RenderBox.hitTest` rejects any touch outside the `Positioned`'s own declared size before it ever reaches the child `Stack`, regardless of `Clip.none`). Before committing, sanity-check by hand: `flutter run` the app on a throwaway screen that mounts `InteractiveArtboard` with 1-2 mock items, select an item, and confirm by touch/click that all 3 handles respond (drag each one briefly and confirm the item visibly rotates/resizes/moves). This is a quick manual spot-check, not a permanent test file — the full automated behavioral suite is still Tester's job after Task 8 (see "After all 8 tasks pass Review").

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): add move/resize/rotate Selection Box handles"
```

---

## Task 7: Delete drag-out (Overlay dim + trash icon + haptic)

**Files:**
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `_bodyDragUpdate`/`_bodyDragEnd` (Task 5, both replaced below with boundary-aware versions — the 이동 핸들 from Task 6 already calls these same two methods, so it gets delete-drag-out for free).
- Produces: nothing new consumed by later tasks (this is the last behavioral task; Task 8 is polish-only).

- [ ] **Step 1: Add the `dart:math`-independent import and delete-zone state**

Add this import at the top of `lib/widgets/interactive_artboard/interactive_artboard.dart`:

```dart
import 'package:flutter/services.dart';
```

Add these fields to `_InteractiveArtboardState` (after `double? _liveRotation;`):

```dart
  OverlayEntry? _deleteZoneOverlayEntry;
  bool _isOutOfBounds = false;
```

- [ ] **Step 2: Replace `_bodyDragUpdate`/`_bodyDragEnd` with boundary-aware versions, add overlay helpers and `dispose`**

Replace `_bodyDragUpdate` and `_bodyDragEnd` with:

```dart
  void _bodyDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    setState(() {
      _dragDelta += details.delta;
    });
    final centerX = canvasSize.width * item.x + _dragDelta.dx;
    final centerY = canvasSize.height * item.y + _dragDelta.dy;
    final outOfBounds = _isCenterOutOfBounds(centerX, centerY, canvasSize);
    if (outOfBounds && !_isOutOfBounds) {
      HapticFeedback.mediumImpact();
      _showDeleteZoneOverlay();
    } else if (!outOfBounds && _isOutOfBounds) {
      _hideDeleteZoneOverlay();
    }
    _isOutOfBounds = outOfBounds;
  }

  void _bodyDragEnd(ArtboardItem item, Size canvasSize) {
    _hideDeleteZoneOverlay();
    if (_isOutOfBounds) {
      widget.onItemDeleted(item.id);
      setState(() {
        _draggingItemId = null;
        _dragDelta = Offset.zero;
        _isOutOfBounds = false;
      });
      return;
    }
    final dxNormalized = _dragDelta.dx / canvasSize.width;
    final dyNormalized = _dragDelta.dy / canvasSize.height;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(x: current.x + dxNormalized, y: current.y + dyNormalized);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _draggingItemId = null;
      _dragDelta = Offset.zero;
      _isOutOfBounds = false;
    });
  }

  bool _isCenterOutOfBounds(double centerX, double centerY, Size canvasSize) {
    return centerX < 0 || centerX > canvasSize.width || centerY < 0 || centerY > canvasSize.height;
  }

  void _showDeleteZoneOverlay() {
    _deleteZoneOverlayEntry = OverlayEntry(
      builder: (context) => const Positioned.fill(
        child: IgnorePointer(
          child: _DeleteZoneVisual(),
        ),
      ),
    );
    Overlay.of(context).insert(_deleteZoneOverlayEntry!);
  }

  void _hideDeleteZoneOverlay() {
    // remove()만으로는 부족하다 — OverlayEntry는 remove()(Overlay에서 분리)와
    // dispose()(리소스 해제, 누수추적 훅 발동)가 분리된 2단계 생명주기다
    // (Flutter `OverlayEntry` 문서: "remove must be called before dispose").
    // 매번 새 OverlayEntry를 만들므로 이 호출을 빠뜨리면 누적 누수가 생긴다(리뷰 P1 반영).
    _deleteZoneOverlayEntry?..remove()..dispose();
    _deleteZoneOverlayEntry = null;
  }

  @override
  void dispose() {
    _deleteZoneOverlayEntry?..remove()..dispose();
    super.dispose();
  }
```

Add this private widget at the bottom of the file (outside `_InteractiveArtboardState`, top-level):

```dart
/// 딤드 오버레이의 반투명도 — 아이템이 삭제 가능 상태임을 알아볼 수 있을 만큼
/// 어둡히되 밑에 있던 캔버스 형태가 여전히 비치는 정도(스펙 §4.6, 정확한 수치는
/// Worker 재량).
const double _deleteZoneDimAlpha = 0.4;

/// 휴지통 아이콘을 화면 하단에서 띄우는 여백(논리픽셀) — 하단 안전영역에 아이콘이
/// 바짝 붙지 않도록 하는 시각적 여유.
const double _deleteZoneIconBottomPadding = 32.0;

/// 휴지통 아이콘 크기(논리픽셀) — 화면 전체를 덮는 딤드 오버레이 위에서 눈에 띄게
/// 하려고 핸들(44px)보다 큰 크기로 잡음.
const double _deleteZoneIconSize = 48.0;

/// 아이템을 캔버스 밖으로 드래그할 때 [Overlay]에 그리는 딤드+휴지통 아이콘 시각
/// 피드백(스펙 §4.6) — `interactive_artboard.dart`의 `RenderBox` 경계에 갇히지 않도록
/// `Overlay`를 통해 화면 전체 위에 그린다.
class _DeleteZoneVisual extends StatelessWidget {
  const _DeleteZoneVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: _deleteZoneDimAlpha)),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: _deleteZoneIconBottomPadding),
            child: Icon(Icons.delete, color: Colors.white, size: _deleteZoneIconSize),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "feat(artboard): add drag-out-to-delete with Overlay dim/trash feedback"
```

---

## Task 8: Accessibility labels + RepaintBoundary

**Files:**
- Modify: `lib/widgets/interactive_artboard/interactive_artboard.dart`

**Interfaces:**
- Consumes: `_handle` (Task 6), `ArtboardItemView` usage in `_itemLayer` (Task 2/5/6).
- Produces: nothing new — this is the final polish task in this plan.

- [ ] **Step 1: Add `Semantics` labels to the 3 handles**

Replace the `_handle` method with:

```dart
  Widget _handle({
    required double left,
    required double top,
    required String label,
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Semantics(
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Container(
            width: _handleVisualDiameter,
            height: _handleVisualDiameter,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: Colors.blue, width: 1.5)),
            ),
          ),
        ),
      ),
    );
  }
```

Update the three `_handle(...)` call sites inside `_buildHandles` to pass `label:`:

```dart
      // 이동 핸들 — 좌하단
      _handle(
        left: center - handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        label: '이동 핸들',
        onPanStart: (_) => _bodyDragStart(item),
        onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
      ),
      // 크기조절 핸들 — 우하단
      _handle(
        left: center + handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        label: '크기조절 핸들',
        onPanStart: (details) => _resizeDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _resizeDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _resizeDragEnd(item),
      ),
      // 회전 핸들 — 상단 중앙에서 위로 뻗은 연결선 끝
      _handle(
        left: center - _handleVisualDiameter / 2,
        top: center - handleOffset - _rotateStemLength - _handleVisualDiameter / 2,
        label: '회전 핸들',
        onPanStart: (details) => _rotateDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _rotateDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _rotateDragEnd(item),
      ),
```

- [ ] **Step 2: Wrap the per-item image render in `RepaintBoundary`**

In `_itemLayer`, replace this block:

```dart
            if (includeVisual)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
                child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
              ),
```

with:

```dart
            if (includeVisual)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
                child: RepaintBoundary(
                  child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
                ),
              ),
```

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze lib/widgets/interactive_artboard/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/interactive_artboard/interactive_artboard.dart
git commit -m "chore(artboard): add handle Semantics labels and per-item RepaintBoundary"
```

---

## After all 8 tasks pass Review

Per this project's harness (not a task in this plan): once every task above has passed Review, PM spawns Tester to write `integration_test/interactive_artboard_test.dart`, implementing the full checklist already enumerated in spec §7 (18 checks — static Selection Box display, move/resize/rotate isolation, overlap popup reorder/select, drag-out delete with the boundary case, controlled-`selectedItemId` verification, and the Hit Area-vs-render-box edge tap). Tester mounts `InteractiveArtboard` directly inside a bare `MaterialApp`/`Scaffold` with a small local `StatefulWidget` test wrapper playing the "parent" role for `selectedItemId`/`onSelectionChanged`, using local mock `ArtboardItem` fixtures — no `lib/mock/mock_data.dart`, no `Composition` model, per the spec's isolation requirement (§1, §7).
