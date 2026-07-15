# Step⑦(기능 구현) 1라운드 — Detail 3화면 실데이터 바인딩 + 코디↔스타일일지 바인딩 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **이 프로젝트는 위 스킬 대신 CLAUDE.md의 자체 하네스(PM→Worker→Review→Tester)로 실행된다.** 각 Task는 Layer=UI/Screen 또는 Data/Architecture, Stage=Implementation(Frontend)로 태깅된다. Task 1은 화면 변경이 없어 Worker→Review만 돈다. Task 2~5는 실제 화면 렌더링/상호작용이 생기므로 Worker→Review→Tester를 매번 돈다(CLAUDE.md §4). 이 Plan 전체(5개 Task, 모델+provider+화면 5개+Main 2개에 걸친 교차 변경)는 L 사이즈로 취급 — Task 5의 Tester 통과 직후, 완료 처리 전에 Audit을 한 번 더 돌린다(CLAUDE.md §4).

**Goal:** BACKLOG.md "다음 세션 작업"이 지정한 Step⑦ 착수 작업을 완료한다 — (1) 선행 정리 2건(`Composition`/`StyleLog.isIncomplete` 필드, `AppDetailScaffold` 계약 확장), (2) Detail 3화면(옷 상세/코디 상세/스타일일지 열람)의 실제 mock 데이터 바인딩과 화면 간 크로스 레퍼런스 네비게이션, (3) 사용자가 이번 라운드에 포함하기로 확정한 코디↔스타일일지 "바인딩"(기존에 연결된 게 없으면 선택 모달로 새로 연결). 겹친 아이템 팝업, 아트보드 실제 렌더링, 추가사진 드래그 순서변경 등 "편집기"급 상호작용은 이번 라운드 스코프 밖 — 별도 후속 작업으로 BACKLOG에 등록한다(이 Plan은 그 등록까지 하지 않고, 완료 후 PM이 세션 인계 시 처리).

**Architecture:** Riverpod `Provider.family`로 "이 옷을 포함한 코디들", "이 코디에 연결된 스타일일지들", "이 옷이 (코디를 거쳐) 간접 연결된 스타일일지들"을 조회하는 순수 파생 provider 3종을 추가한다. 바인딩(코디↔스타일일지 연결)은 `StyleLogsNotifier.linkToComposition(logId, compositionId)` 단일 메서드로 처리 — `StyleLog.linkedCompositionId`만 갱신하고 `Composition`은 이 라운드에서 절대 변경하지 않는다(연결 참조는 항상 StyleLog → Composition 단방향). 화면에서 "코디/스타일일지 선택 모달을 열어 고르고 그 결과로 바인딩"하는 흐름은, 기존에 이미 만들어진 `CompositionMainScreen(selectionMode: true)`/`StyleLogMainScreen(selectionMode: true)`를 go_router의 `context.push<String>()` + `context.pop(id)` 결과 반환 패턴으로 재호출한다(기존 `onItemSelected` 콜백 prop은 이 패턴으로 대체하며 제거).

**Tech Stack:** Flutter 3.44.4 / Dart 3.12.2, 기존 `flutter_riverpod`(`Provider.family`, 기존 `StateNotifierProvider`) + `go_router`(`context.push<T>()`/`context.pop(T)`)만 사용 — 신규 패키지 없음.

## Global Constraints

- **스코프 경계**: 아래 항목은 이번 Plan에 포함하지 않는다 — 코디 상세의 아트보드 실제 렌더링(x/y/scale/rotation 반영)과 겹친 아이템 터치 팝업, 코디 상세/스타일일지 열람에서 "신규 레코드 생성하며 바인딩"(선택 모달에서 기존 레코드 고르기만 지원, 그 자리에서 새로 만들기는 지원 안 함), 스타일일지의 "착용 옷 목록" 자유 추가/삭제([+] 버튼), 추가사진 드래그 순서변경, Detail 헤더 "⋯더보기" 메뉴의 실제 항목(수정/삭제) 연결. 전부 "편집기"급 상호작용이거나 별도 모델 필드가 선행되어야 하는 항목이라 후속 작업으로 미룬다.
- **`isIncomplete` 필드는 값 로직 없이 필드만**: `Composition`/`StyleLog`에 `bool isIncomplete = false`를 추가하되, 이번 Plan의 어떤 화면도 이 필드를 읽거나 쓰지 않는다(토글 로직은 `docs/history/Decision.md` "Editor 저장 모델 전환"의 "Editor Draft 구현" 후속 작업 몫).
- **`Composition`은 이번 라운드에 절대 mutate하지 않는다** — 바인딩은 항상 `StyleLog.linkedCompositionId` 갱신으로만 이뤄진다. `Composition`에 `copyWith`를 추가하지 않는다(YAGNI — 이번 라운드에 쓸 데가 없음).
- **네비게이션은 `context.push`/`context.pop`만 사용**(`context.go()` 금지) — `.claude/skills/flutter-implementation-conventions/SKILL.md` 그대로 적용.
- **`ref.watch()`는 `build()`에서만, `ref.read()`는 콜백에서만** — 바인딩 액션(`_bindStyleLog`/`_bindComposition`류 함수)은 전부 콜백이므로 그 안에서는 `ref.read`만 쓴다.
- **위젯 단위 TDD 아님**(Task 2~5): 이 프로젝트 확립 관례대로 화면 코드는 `flutter analyze` + `flutter run`/Tester 통합테스트로 검증한다. **Task 1(순수 provider 로직)만 TDD**(테스트 먼저 작성 → 실패 확인 → 구현 → 통과 확인).
- **기존 통합테스트 갱신은 이 Plan의 일부다**: `integration_test/detail_screens_header_hud_test.dart`(placeholder 문자열/높이 계산에 의존하는 assertion들)와 `integration_test/selection_modal_test.dart`(코디/스타일일지 선택 모달이 이제 실제로 `context.pop(id)`하는 것에 의존하는 assertion 3개)는 각 Task에서 실제로 바뀐 동작에 맞게 다시 쓴다 — "테스트가 깨졌으니 원복" 방향이 아니라 "새 동작에 맞는 새 assertion"으로 교체하는 것이 맞다. `ClosetMainScreen`의 `onItemSelected`/선택 흐름은 이 Plan에서 손대지 않으므로 관련 기존 테스트(옷장 선택 모달 4개, `onItemSelected` 콜백 직접구동 테스트)는 그대로 통과해야 한다(회귀 발생 시 버그).
- 값(spacing/색상/코너반경)은 전부 `AppSpacing`/`AppRadius`/`Theme.of(context)` 참조 — 리터럴 hex/px 금지(`engineering-principles` 스킬).

---

### Task 1: 모델 필드 확장 + 크로스 레퍼런스 조회 provider + 바인딩 메서드 (Data/Architecture, Implementation)

**Files:**
- Modify: `lib/models/composition.dart`
- Modify: `lib/models/style_log.dart`
- Modify: `lib/providers/composition_providers.dart`
- Modify: `lib/providers/style_log_providers.dart`
- Test: `test/providers/cross_reference_providers_test.dart` (신규)

**Interfaces:**
- Consumes: 없음(기존 `Composition`/`StyleLog`/`mockCompositions`/`mockStyleLogs`만 사용)
- Produces: `Composition.isIncomplete`(`bool`, 기본 `false`), `StyleLog.isIncomplete`(`bool`, 기본 `false`), `StyleLog.copyWith({...})`, `compositionsContainingItemProvider`(`Provider.family<List<Composition>, String>`), `styleLogsLinkedToCompositionProvider`(`Provider.family<List<StyleLog>, String>`), `styleLogsLinkedToItemProvider`(`Provider.family<List<StyleLog>, String>`), `StyleLogsNotifier.linkToComposition(String logId, String compositionId)` — Task 3/4/5가 전부 소비.

- [ ] **Step 1: `lib/models/composition.dart`에 `isIncomplete` 필드 추가**

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
    this.season,
    this.isIncomplete = false,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;
  final Season? season;
  final bool isIncomplete;
  final bool isDeleted;
}
```

- [ ] **Step 2: `lib/models/style_log.dart`에 `isIncomplete` 필드 + `copyWith` 추가**

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
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;
  final List<String> additionalImagePaths;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? wornDate,
    String? linkedCompositionId,
    List<String>? additionalImagePaths,
    String? location,
    bool? isIncomplete,
    bool? isDeleted,
  }) {
    return StyleLog(
      id: id ?? this.id,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      wornDate: wornDate ?? this.wornDate,
      linkedCompositionId: linkedCompositionId ?? this.linkedCompositionId,
      additionalImagePaths: additionalImagePaths ?? this.additionalImagePaths,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
```

- [ ] **Step 3: 실패하는 테스트 먼저 작성 — `test/providers/cross_reference_providers_test.dart`**

이 시점엔 `compositionsContainingItemProvider` 등이 아직 없어 컴파일 자체가 실패해야 정상이다.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';

void main() {
  test('compositionsContainingItemProvider는 해당 옷을 포함한 코디만 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: c01은 comp01에만 포함됨.
    final result = container.read(compositionsContainingItemProvider('c01'));

    expect(result.map((c) => c.id), contains('comp01'));
    expect(result.map((c) => c.id), isNot(contains('comp02')));
  });

  test('styleLogsLinkedToCompositionProvider는 해당 코디에 연결된 스타일일지만 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // mock_data.dart 기준: log01.linkedCompositionId == 'comp01'.
    final result = container.read(styleLogsLinkedToCompositionProvider('comp01'));

    expect(result.map((l) => l.id), contains('log01'));
    expect(result.map((l) => l.id), isNot(contains('log02')));
  });

  test('styleLogsLinkedToItemProvider는 코디를 거쳐 간접 연결된 스타일일지를 반환한다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // c01 → comp01 → log01 경로.
    final result = container.read(styleLogsLinkedToItemProvider('c01'));

    expect(result.map((l) => l.id), contains('log01'));
  });

  test('linkToComposition은 대상 로그의 linkedCompositionId만 바꾸고 다른 로그는 그대로 둔다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(styleLogsProvider.notifier).linkToComposition('log02', 'comp01');
    final logs = container.read(styleLogsProvider);

    expect(logs.firstWhere((l) => l.id == 'log02').linkedCompositionId, 'comp01');
    expect(logs.firstWhere((l) => l.id == 'log01').linkedCompositionId, 'comp01');
  });
}
```

- [ ] **Step 4: 테스트 실행 — 컴파일 실패로 fail 확인**

```bash
flutter test test/providers/cross_reference_providers_test.dart
```

Expected: `compositionsContainingItemProvider`(그 외 신규 심볼) 관련 에러로 컴파일 실패.

- [ ] **Step 5: `lib/providers/composition_providers.dart`에 `compositionsContainingItemProvider` 추가**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>(
        (ref) => CompositionsNotifier());

/// null = 전체 시즌.
final selectedCompositionSeasonFilterProvider = StateProvider<Season?>((ref) => null);

/// 삭제되지 않았고, 선택된 시즌 필터에 맞는 코디만.
final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  final compositions = ref.watch(compositionsProvider);
  final season = ref.watch(selectedCompositionSeasonFilterProvider);
  return compositions
      .where((c) => !c.isDeleted)
      .where((c) => season == null || c.season == season)
      .toList();
});

/// 코디 메인 그리드 밀도 — AppDensity.min/mid/max 중 하나.
final compositionDensityProvider = StateProvider<int>((ref) => AppDensity.mid);

/// [itemId]를 포함하는(삭제되지 않은) Composition 목록 — 옷 상세 화면의
/// "연결된 코디" 크로스 레퍼런스 근거.
final compositionsContainingItemProvider =
    Provider.family<List<Composition>, String>((ref, itemId) {
  return ref
      .watch(compositionsProvider)
      .where((c) => !c.isDeleted && c.items.any((p) => p.clothingItemId == itemId))
      .toList();
});
```

- [ ] **Step 6: `lib/providers/style_log_providers.dart`에 `linkToComposition` + 조회 provider 2종 추가**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/style_log.dart';
import '../mock/mock_data.dart';
import 'composition_providers.dart';

class StyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  StyleLogsNotifier() : super(mockStyleLogs);

  /// [logId]인 StyleLog의 [linkedCompositionId]를 [compositionId]로 갱신한다.
  /// `Composition`은 변경하지 않는다 — 연결 참조는 항상 StyleLog → Composition 단방향.
  void linkToComposition(String logId, String compositionId) {
    state = [
      for (final log in state)
        if (log.id == logId) log.copyWith(linkedCompositionId: compositionId) else log,
    ];
  }
}

final styleLogsProvider =
    StateNotifierProvider<StyleLogsNotifier, List<StyleLog>>(
        (ref) => StyleLogsNotifier());

final filteredStyleLogsProvider = Provider<List<StyleLog>>((ref) {
  final logs = ref.watch(styleLogsProvider).where((l) => !l.isDeleted).toList();
  logs.sort((a, b) => b.wornDate.compareTo(a.wornDate));
  return logs;
});

/// [compositionId]에 연결된(삭제되지 않은) StyleLog 목록 — 코디 상세 화면의
/// "연결된 스타일일지" 크로스 레퍼런스 근거.
final styleLogsLinkedToCompositionProvider =
    Provider.family<List<StyleLog>, String>((ref, compositionId) {
  return ref
      .watch(styleLogsProvider)
      .where((l) => !l.isDeleted && l.linkedCompositionId == compositionId)
      .toList();
});

/// [itemId]를 포함하는 코디에 연결된(삭제되지 않은) StyleLog 목록 — 옷 상세 화면의
/// "간접 연결된 스타일일지"(코디를 거쳐 연결) 크로스 레퍼런스 근거.
final styleLogsLinkedToItemProvider =
    Provider.family<List<StyleLog>, String>((ref, itemId) {
  final compositionIds =
      ref.watch(compositionsContainingItemProvider(itemId)).map((c) => c.id).toSet();
  return ref
      .watch(styleLogsProvider)
      .where((l) => !l.isDeleted && compositionIds.contains(l.linkedCompositionId))
      .toList();
});
```

- [ ] **Step 7: 테스트 실행 — 통과 확인**

```bash
flutter test test/providers/cross_reference_providers_test.dart
```

Expected: `4 tests passed`

- [ ] **Step 8: 회귀 확인 — 기존 provider 테스트도 여전히 통과하는지**

```bash
flutter test test/providers/ test/mock/
```

Expected: 모든 테스트 통과(`Composition`/`StyleLog` 생성자에 새 필드가 기본값을 가지므로 기존 테스트의 생성자 호출은 변경 없이 통과해야 함).

- [ ] **Step 9: `flutter analyze` 확인**

```bash
flutter analyze lib/models/ lib/providers/
```

Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/models/composition.dart lib/models/style_log.dart lib/providers/composition_providers.dart lib/providers/style_log_providers.dart test/providers/cross_reference_providers_test.dart
git commit -m "feat(models): add isIncomplete fields, cross-reference lookup providers, style log binding"
```

---

### Task 2: `AppDetailScaffold` 계약 확장 (UI/Screen, Implementation/Frontend)

**Files:**
- Modify: `lib/screens/app_detail_scaffold.dart`
- Modify: `lib/screens/closet_item_detail_screen.dart`
- Modify: `lib/screens/composition_detail_screen.dart`
- Modify: `lib/screens/style_log_viewer_screen.dart`
- Modify: `integration_test/detail_screens_header_hud_test.dart`

**Interfaces:**
- Consumes: `CrossReferenceLinkEntry`(기존, `lib/widgets/cross_reference_link_bar.dart`)
- Produces: `AppDetailScaffold({required AppCategory category, required Widget body, List<CrossReferenceLinkEntry> crossReferenceEntries = const []})` — `placeholderLabel`/`crossReferenceLabel`(String) 파라미터는 제거된다. Task 3/4/5가 이 새 계약으로 실제 콘텐츠를 채운다.

- [ ] **Step 1: `lib/screens/app_detail_scaffold.dart` 계약 교체**

```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/cross_reference_link_bar.dart';
import '../widgets/glass_circle_button.dart';

/// Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 공용 셸 — `AppMainScaffold` 위에
/// Detail 전용 스크롤 콘텐츠 구조(본문 + 하단 크로스 레퍼런스 바)를 얹는다
/// (`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목).
///
/// Step⑦ 1라운드(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`)에서
/// `placeholderLabel`/`crossReferenceLabel`(단일 문자열) 계약을 `body`(임의 위젯)와
/// `crossReferenceEntries`(리스트)로 넓혔다 — Audit(2026-07-15)이 호출부가 3곳뿐인
/// 지금 넓히는 게 가장 저렴하다고 지적한 항목.
class AppDetailScaffold extends StatelessWidget {
  const AppDetailScaffold({
    super.key,
    required this.category,
    required this.body,
    this.crossReferenceEntries = const [],
  });

  /// 헤더 카테고리 토글에 넘길 현재 카테고리([AppMainScaffold.current]로 그대로 전달).
  final AppCategory category;

  /// 본문 콘텐츠 — 화면마다 실제 상세 정보를 자유롭게 채운다.
  final Widget body;

  /// 하단 [CrossReferenceLinkBar]에 넘길 항목들. 비어 있으면 빈 바(높이만 차지)를 그린다.
  final List<CrossReferenceLinkEntry> crossReferenceEntries;

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: false);

    return AppMainScaffold(
      current: category,
      headerActions: [
        GlassCircleButton(
          icon: Icons.more_horiz,
          tooltip: '더보기 메뉴',
          onTap: () {}, // 실제 메뉴(수정/삭제 등) 연결은 이번 라운드 스코프 밖(Global Constraints 참고)
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.only(top: contentTopSpacing),
          child: Column(
            children: [
              body,
              CrossReferenceLinkBar(entries: crossReferenceEntries),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 3개 Detail 화면 호출부를 새 계약으로 임시 갱신(콘텐츠는 아직 skeleton — Task 3/4/5가 교체)**

`lib/screens/closet_item_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 3에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.closet,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('옷 상세 정보 (id: $itemId) — Task 3에서 실제 바인딩 예정'),
      ),
    );
  }
}
```

`lib/screens/composition_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 4에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.composition,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('코디 상세 (id: $compositionId) — Task 4에서 실제 바인딩 예정'),
      ),
    );
  }
}
```

`lib/screens/style_log_viewer_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 5에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.styleLog,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('스타일일지 카드 (id: $styleLogId) — Task 5에서 실제 바인딩 예정'),
      ),
    );
  }
}
```

- [ ] **Step 3: `integration_test/detail_screens_header_hud_test.dart`의 placeholder 의존 assertion 갱신**

이 파일의 그룹 1("Detail 3화면 실제 진입")과 그룹 4("CrossReferenceLinkBar placeholder 렌더링")는 옛 문자열(`'연결된 코디/스타일일지'` 등)과 `CrossReferenceLinkBar.height`(고정 64) 전제로 짠 것이라, 새 skeleton 문구·새 콘텐츠 높이에 맞게 다시 쓴다. 그룹 2/3/6(Pinned Rule, 뒤로가기, 카테고리 이동)은 문구에 의존하지 않으므로 그대로 둔다.

그룹 4를 다음으로 교체(문자열만 새 skeleton 문구로 갱신, `CrossReferenceLinkBar.height` assertion은 제거 — 이제 이 바는 항상 렌더링되지만 내용은 비어있을 수 있어 고정 높이 전제가 더 이상 유효하지 않음):

```dart
  // ── 4) Detail 화면 skeleton body 렌더링 ──────────────────────────────────

  group('Detail 화면 skeleton body 렌더링(Task 3~5 전까지)', () {
    testWidgets('옷 상세 화면 본문에 skeleton 안내 문구가 보인다(빈 화면처럼 보이지 않음)',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SelectableGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Task 3에서 실제 바인딩 예정'), findsOneWidget);
    });

    testWidgets('코디 상세 화면 본문에도 skeleton 안내 문구가 보인다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(CompositionGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Task 4에서 실제 바인딩 예정'), findsOneWidget);
    });

    testWidgets('스타일일지 상세 화면 본문에도 skeleton 안내 문구가 보인다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Task 5에서 실제 바인딩 예정'), findsOneWidget);
    });
  });
```

그룹 5("스크롤 동작")는 정확한 높이(528) 전제로 짜여 있었는데, skeleton body가 `Text` 한 줄로 바뀌면서 그 전제가 깨진다. 이 그룹 전체를 삭제한다 — Task 3(옷 상세 실제 콘텐츠, 이미지 포함이라 다시 스크롤 가능한 높이가 됨)에서 동일한 성격의 스크롤 검증을 새 콘텐츠 기준으로 다시 추가한다.

- [ ] **Step 4: 컴파일 + 기존 위젯 테스트 확인**

```bash
flutter analyze lib/screens/ integration_test/
flutter test test/
```

Expected: `flutter analyze`는 `No issues found!`, `flutter test`는 전부 통과(스크린 콘텐츠 String만 바뀐 것이라 위젯 유닛테스트 영향 없음).

- [ ] **Step 5: Tester 통합테스트 실행**

```bash
taskkill //F //IM digittal_wardrobe.exe
flutter test integration_test/detail_screens_header_hud_test.dart -d windows
```

Expected: 전부 Pass. (BACKLOG "Known Issues" — Windows 파일 잠금 예방 위해 매 통합테스트 실행 전 `taskkill` 습관화.)

- [ ] **Step 6: Commit**

```bash
git add lib/screens/app_detail_scaffold.dart lib/screens/closet_item_detail_screen.dart lib/screens/composition_detail_screen.dart lib/screens/style_log_viewer_screen.dart integration_test/detail_screens_header_hud_test.dart
git commit -m "refactor(screens): widen AppDetailScaffold contract to body+crossReferenceEntries"
```

---

### Task 3: 옷 상세 실데이터 바인딩 (UI/Screen, Implementation/Frontend)

**Files:**
- Modify: `lib/screens/closet_item_detail_screen.dart`
- Modify: `integration_test/detail_screens_header_hud_test.dart`

**Interfaces:**
- Consumes: `AppDetailScaffold`(Task 2), `closetItemsProvider`(`lib/providers/closet_providers.dart`), `compositionsContainingItemProvider`/`styleLogsLinkedToItemProvider`(Task 1), `CrossReferenceLinkEntry`(`lib/widgets/cross_reference_link_bar.dart`), `AppRoute`(`lib/router/app_router.dart`)

- [ ] **Step 1: `lib/screens/closet_item_detail_screen.dart` 실제 데이터 바인딩으로 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/cross_reference_link_bar.dart';
import 'app_detail_scaffold.dart';

/// 옷 상세 — 이미지/메타데이터/착용 이력을 실제 mock 데이터로 표시하고, 이 옷을 포함한
/// 코디들과 (코디를 거쳐) 간접 연결된 스타일일지들을 하단 크로스 레퍼런스로 보여준다.
/// 옷↔코디/스타일일지는 읽기 전용 탐색만 지원 — 이 화면에서 바인딩 액션은 없다(코디
/// 상세/스타일일지 열람에서만 코디↔스타일일지 바인딩을 지원, `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class ClosetItemDetailScreen extends ConsumerWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(closetItemsProvider).firstWhere((i) => i.id == itemId);
    final linkedCompositions = ref.watch(compositionsContainingItemProvider(itemId));
    final linkedStyleLogs = ref.watch(styleLogsLinkedToItemProvider(itemId));

    return AppDetailScaffold(
      category: AppCategory.closet,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(item.imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${item.category.label} · ${item.season.label} · ${item.material.label} · ${item.color}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (item.location.isNotEmpty) Text('보관 위치: ${item.location}'),
            if (item.memo.isNotEmpty) Text('메모: ${item.memo}'),
            const SizedBox(height: AppSpacing.xs),
            Text('착용 ${item.wearCount}회', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      crossReferenceEntries: [
        for (final composition in linkedCompositions)
          CrossReferenceLinkEntry(
            label: composition.name,
            icon: Icons.checkroom,
            onTap: () =>
                context.push(AppRoute.compositionDetail.replaceFirst(':id', composition.id)),
          ),
        for (final log in linkedStyleLogs)
          CrossReferenceLinkEntry(
            label: '${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}',
            icon: Icons.menu_book,
            onTap: () => context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: `integration_test/detail_screens_header_hud_test.dart`의 옷 상세 관련 그룹 갱신**

그룹 1의 옷 상세 테스트 assertion(`find.textContaining(item.id)`)을 실제 이름 기준으로 교체하고, Task 2에서 지운 "스크롤 동작" 그룹을 옷 상세 실제 콘텐츠 기준으로 복원한다:

```dart
    testWidgets('옷장 메인에서 아이템 탭 → ClosetItemDetailScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      final tile = find.byType(SelectableGalleryTile).first;
      final item = tester.widget<SelectableGalleryTile>(tile).item;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
      expect(find.text(item.name), findsOneWidget);
    });
```

그룹 4(Task 2에서 "Detail 화면 skeleton body 렌더링"으로 바꿔둔 것)의 옷 상세 케이스를 실제 크로스 레퍼런스 렌더링 확인으로 교체:

```dart
    testWidgets('옷 상세 화면 하단에 연결된 코디/스타일일지 크로스 레퍼런스가 실제로 보인다(빈 화면처럼 보이지 않음)',
        (tester) async {
      await pumpApp(tester);
      final tile = find.byType(SelectableGalleryTile).first;
      final item = tester.widget<SelectableGalleryTile>(tile).item;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(item.id, 'c01'); // mock_data.dart 첫 항목은 comp01에 포함되어 크로스 레퍼런스가 비지 않음을 전제.
      expect(find.textContaining('데일리 룩'), findsOneWidget); // comp01.name
    });
```

그룹 5("스크롤 동작")를 실제 콘텐츠 기준으로 복원:

```dart
  group('스크롤 동작', () {
    testWidgets(
      '옷 상세 화면 콘텐츠(이미지+메타데이터+크로스 레퍼런스)가 짧은 뷰포트에서 스크롤 가능하고, '
      'TopGradientOverlay/BottomGradientOverlay가 스크롤 위치에 따라 크래시 없이 전환된다',
      (tester) async {
        await pumpApp(tester, size: scrollableDetailSize);
        await tester.tap(find.byType(SelectableGalleryTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);
        expect(find.byType(AppScrollContainer), findsOneWidget);

        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          scrollable.position.maxScrollExtent,
          greaterThan(0),
          reason: '이 시나리오는 실제로 스크롤 가능해야 의미가 있다',
        );

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, greaterThan(0));

        await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -2000), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
        expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 1));
      },
    );
  });
```

- [ ] **Step 3: `flutter analyze` 확인**

```bash
flutter analyze lib/screens/closet_item_detail_screen.dart integration_test/detail_screens_header_hud_test.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Tester 통합테스트 실행**

```bash
taskkill //F //IM digittal_wardrobe.exe
flutter test integration_test/detail_screens_header_hud_test.dart -d windows
```

Expected: 전부 Pass.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/closet_item_detail_screen.dart integration_test/detail_screens_header_hud_test.dart
git commit -m "feat(screen): bind real data to 옷 상세 (closet item detail)"
```

---

### Task 4: 코디 상세 실데이터 바인딩 + 스타일일지 바인딩 (UI/Screen, Implementation/Frontend)

**Files:**
- Modify: `lib/screens/composition_detail_screen.dart`
- Modify: `lib/screens/style_log_main_screen.dart`
- Modify: `integration_test/detail_screens_header_hud_test.dart`
- Modify: `integration_test/selection_modal_test.dart`

**Interfaces:**
- Consumes: `AppDetailScaffold`(Task 2), `compositionsProvider`/`closetItemsProvider`, `styleLogsLinkedToCompositionProvider`/`styleLogsProvider`(Task 1), `AppRoute.styleLogSelect`(기존)
- Produces: `StyleLogMainScreen`의 `onItemSelected` prop 제거 — `selectionMode`일 때 타일 탭이 `context.pop(l.id)`를 직접 호출(다른 화면이 `context.push<String>(AppRoute.styleLogSelect)`로 결과를 받을 수 있게 됨).

- [ ] **Step 1: `lib/screens/style_log_main_screen.dart`의 `onItemSelected` 콜백을 `context.pop` 결과 반환으로 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/selection_aware_header_actions.dart';
import '../widgets/style_log_gallery_grid.dart';

/// Main-플랫+필터형 — 그룹 드릴다운 없음(기존 스펙대로 날짜 기준 최신순 고정). FAB는
/// `closet_main_screen.dart`의 2-옵션 팝업 패턴을 그대로 이식.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 참고.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(스타일일지 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(log.id)`로 결과를 반환한다. 호출부는 `context.push<String>(AppRoute.styleLogSelect)`로
/// 열고 반환값을 기다리면 된다(`lib/screens/composition_detail_screen.dart` 사용례 참고).
class StyleLogMainScreen extends ConsumerStatefulWidget {
  const StyleLogMainScreen({super.key, this.selectionMode = false});

  /// true면 선택 모달로 동작 — 타일 탭 시 상세 화면 대신 `context.pop(id)`로 결과 반환.
  final bool selectionMode;

  @override
  ConsumerState<StyleLogMainScreen> createState() => _StyleLogMainScreenState();
}

class _StyleLogMainScreenState extends ConsumerState<StyleLogMainScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(filteredStyleLogsProvider);

    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.styleLog,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      secondaryControlsRight: [
        GlassCircleButton(icon: Icons.sort, tooltip: '정렬 기준', onTap: () {}),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => StyleLogGalleryGrid(
          logs: logs,
          controller: controller,
          topSpacing: contentTopSpacing,
          onItemTap: (l) {
            if (widget.selectionMode) {
              context.pop(l.id);
            } else {
              context.push(AppRoute.styleLogViewer.replaceFirst(':id', l.id));
            }
          },
        ),
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(
                  label: '1카드 추가',
                  onTap: () => context.push(AppRoute.styleLogAdd),
                ),
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

- [ ] **Step 2: `lib/screens/composition_detail_screen.dart` 실제 데이터 바인딩 + 스타일일지 바인딩으로 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/cross_reference_link_bar.dart';
import 'app_detail_scaffold.dart';

/// 코디 상세 — 사용된 옷 목록과 연결된 스타일일지를 실제 mock 데이터로 표시한다.
/// 연결된 스타일일지가 없으면 크로스 레퍼런스 바에 "+" 바인딩 항목이 뜨고, 탭하면
/// 스타일일지 선택 모달(`AppRoute.styleLogSelect`)을 열어 기존 스타일일지를 골라
/// 연결한다(신규 생성 바인딩/아트보드 실제 렌더링은 스코프 밖 — `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class CompositionDetailScreen extends ConsumerWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  Future<void> _bindStyleLog(BuildContext context, WidgetRef ref) async {
    final selectedLogId = await context.push<String>(AppRoute.styleLogSelect);
    if (selectedLogId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(selectedLogId, compositionId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
    final closetItems = ref.watch(closetItemsProvider);
    final usedItems = [
      for (final placement in composition.items)
        closetItems.firstWhere((item) => item.id == placement.clothingItemId),
    ];
    final linkedStyleLogs = ref.watch(styleLogsLinkedToCompositionProvider(compositionId));

    return AppDetailScaffold(
      category: AppCategory.composition,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(composition.name, style: Theme.of(context).textTheme.headlineSmall),
            if (composition.season != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(composition.season!.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('사용된 옷', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: usedItems.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = usedItems[index];
                  return GestureDetector(
                    key: ValueKey(item.id),
                    onTap: () =>
                        context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.asset(item.imagePath, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      crossReferenceEntries: linkedStyleLogs.isEmpty
          ? [
              CrossReferenceLinkEntry(
                label: '스타일일지 연결하기',
                icon: Icons.add,
                onTap: () => _bindStyleLog(context, ref),
              ),
            ]
          : [
              for (final log in linkedStyleLogs)
                CrossReferenceLinkEntry(
                  label: '${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}',
                  icon: Icons.menu_book,
                  onTap: () => context.push(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
                ),
            ],
    );
  }
}
```

- [ ] **Step 3: `integration_test/detail_screens_header_hud_test.dart`의 코디 상세 관련 그룹 갱신**

그룹 1(진입)과 그룹 4(크로스 레퍼런스)의 코디 상세 케이스를 실제 콘텐츠 기준으로 교체:

```dart
    testWidgets('코디 메인에서 코디 탭 → CompositionDetailScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);

      final tile = find.byType(CompositionGalleryTile).first;
      final composition = tester.widget<CompositionGalleryTile>(tile).composition;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionDetailScreen), findsOneWidget);
      expect(find.text(composition.name), findsOneWidget);
    });
```

```dart
    testWidgets('코디 상세 화면 하단에 연결된 스타일일지 크로스 레퍼런스가 보인다(mock 기준 comp01은 log01에 연결됨)',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');
      await tester.tap(find.byType(CompositionGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(find.textContaining('2026.1.5'), findsOneWidget); // log01.wornDate
    });
```

- [ ] **Step 4: `integration_test/selection_modal_test.dart`의 스타일일지 선택 모달 assertion을 실제 pop-result 동작에 맞게 교체**

> **정정(2026-07-15, Task 4 실행 중 Worker가 발견)**: 이 자리에 원래 적혀 있던 코드 블록은 "코디 선택 모달" 테스트였으나, 이 Task(Task 4)가 실제로 `context.pop` 전환을 적용하는 파일은 `composition_main_screen.dart`가 아니라 `style_log_main_screen.dart`다(코디 쪽 전환은 Task 5 Step 1 몫). 두 Task의 Step 4 코드 블록이 서로 뒤바뀌어 있던 저작 오류 — 아래가 Task 4에 맞는(실제로 적용된) 스타일일지 선택 모달 블록이고, 코디 선택 모달 블록은 Task 5 Step 4로 옮겼다.

```dart
  testWidgets(
    '스타일일지 선택 모달(/style-log/select)도 닫기 버튼으로 교체되고, 카테고리 토글/FAB는 '
    '없으며, 원래도 그룹형이 아니라 groupingBar는 (변화 없이) 여전히 없다. 타일 탭 시 '
    'context.pop(id)로 결과를 반환한다',
    (tester) async {
      await pumpApp(tester);

      String? poppedResult;
      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push<String>(AppRoute.styleLogSelect).then((value) {
        poppedResult = value;
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(closeButtonFinder(), findsOneWidget);
      expect(backButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('분류 선택 바'), findsNothing);
      expect(find.byType(StyleLogGalleryTile), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(poppedResult, 'log01');
    },
  );
```

이 교체에 맞춰 이제 쓰이지 않는 import 2개(`composition_detail_screen.dart`, `style_log_viewer_screen.dart`)도 함께 제거한다(코디 선택 모달 테스트의 `findsNothing` assertion에서만 쓰였는데, 그 테스트는 이번 Task에서 변경되지 않으므로 실제로는 `expect(find.byType(CompositionDetailScreen), findsNothing)`처럼 다른 import에 의존하던 라인이 있다면 그 라인만 제거하고 나머지 코디 선택 모달 테스트는 그대로 둔다).

- [ ] **Step 5: `flutter analyze` 확인**

```bash
flutter analyze lib/screens/composition_detail_screen.dart lib/screens/style_log_main_screen.dart integration_test/
```

Expected: `No issues found!`

- [ ] **Step 6: Tester 통합테스트 실행**

```bash
taskkill //F //IM digittal_wardrobe.exe
flutter test integration_test/detail_screens_header_hud_test.dart integration_test/selection_modal_test.dart -d windows
```

Expected: 전부 Pass.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/composition_detail_screen.dart lib/screens/style_log_main_screen.dart integration_test/detail_screens_header_hud_test.dart integration_test/selection_modal_test.dart
git commit -m "feat(screen): bind real data to 코디 상세 + wire style-log binding via selection modal"
```

---

### Task 5: 스타일일지 열람 실데이터 바인딩 + 코디 바인딩 (UI/Screen, Implementation/Frontend)

**Files:**
- Modify: `lib/screens/style_log_viewer_screen.dart`
- Modify: `lib/screens/composition_main_screen.dart`
- Modify: `integration_test/detail_screens_header_hud_test.dart`
- Modify: `integration_test/selection_modal_test.dart`
- Test: `test/screens/composition_detail_screen_test.dart` (신규)
- Test: `test/screens/style_log_viewer_screen_test.dart` (신규)

**Interfaces:**
- Consumes: `AppDetailScaffold`(Task 2), `styleLogsProvider`/`compositionsProvider`(Task 1), `AppRoute.compositionSelect`(기존)
- Produces: `CompositionMainScreen`의 `onItemSelected` prop 제거 — `selectionMode`일 때 타일 탭이 `context.pop(c.id)`를 직접 호출.

**주의(중요)**: 현재 mock 데이터(`lib/mock/mock_data.dart`)는 `comp01↔log01`, `comp02↔log02`가 이미 서로 연결되어 있어 — **"연결 안 된" 코디/스타일일지 조합이 mock 데이터에 존재하지 않는다.** "+" 바인딩 항목(미연결 상태)의 렌더링·탭 동작은 실제 mock 데이터로 검증할 수 없으므로, 아래 Step 5는 `mock_data.dart`를 건드리는 대신(다른 통합테스트 다수가 "코디 2개/스타일일지 2개"라는 고정 개수를 전제하고 있어 건드리면 이 Plan 밖의 파일까지 광범위하게 깨짐) `ProviderScope` override로 그 화면만 격리해 검증하는 위젯 테스트로 만든다.

- [ ] **Step 1: `lib/screens/composition_main_screen.dart`의 `onItemSelected` 콜백을 `context.pop` 결과 반환으로 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/glass_pill.dart';
import '../widgets/selection_aware_header_actions.dart';
import 'skeleton_region.dart';

/// Main-그룹형(옷장 메인과 동일 페이지 타입) — `closet_main_screen.dart` 패턴을 그대로 이식.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(코디 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(composition.id)`로 결과를 반환한다. 호출부는
/// `context.push<String>(AppRoute.compositionSelect)`로 열고 반환값을 기다리면 된다
/// (`lib/screens/style_log_viewer_screen.dart` 사용례 참고).
class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key, this.selectionMode = false});

  /// true면 선택 모달로 동작 — 타일 탭 시 상세 화면 대신 `context.pop(id)`로 결과 반환.
  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositions = ref.watch(filteredCompositionsProvider);
    final season = ref.watch(selectedCompositionSeasonFilterProvider);
    final density = ref.watch(compositionDensityProvider);

    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(
      hasSecondaryRow: true,
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
    );

    return AppMainScaffold(
      current: AppCategory.composition,
      showBackButton: !selectionMode,
      showCategoryToggle: !selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: selectionMode,
        onClose: () => context.pop(),
      ),
      secondaryControlsLeft: [
        GlassPill(
          child: DropdownButton<Season?>(
            value: season,
            hint: const Text('계절'),
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem<Season?>(value: null, child: Text('전체')),
              ...Season.values.map(
                (s) => DropdownMenuItem<Season?>(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (value) =>
                ref.read(selectedCompositionSeasonFilterProvider.notifier).state = value,
          ),
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(compositionDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0
                ? AppDensity.levels.length - 1
                : currentIndex - 1;
            final next = AppDensity.levels[previousIndex];
            ref.read(compositionDensityProvider.notifier).state = next;
          },
        ),
        GlassCircleButton(icon: Icons.sort, tooltip: '정렬 기준', onTap: () {}),
      ],
      groupingBar: skeletonRegion(
        context,
        '분류 선택 바 (그룹형 드릴다운) — Step⑦(기능 구현)에서 실제 드릴다운으로 대체 예정',
        height: AppMainScaffold.defaultGroupingBarHeight,
      ),
      groupingBarHeight: AppMainScaffold.defaultGroupingBarHeight,
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => CompositionGalleryGrid(
          compositions: compositions,
          density: density,
          controller: controller,
          topSpacing: contentTopSpacing,
          onItemTap: (c) {
            if (selectionMode) {
              context.pop(c.id);
            } else {
              context.push(AppRoute.compositionDetail.replaceFirst(':id', c.id));
            }
          },
        ),
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoute.compositionEditor),
              child: const Icon(Icons.add),
            ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/style_log_viewer_screen.dart` 실제 데이터 바인딩 + 코디 바인딩으로 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/cross_reference_link_bar.dart';
import 'app_detail_scaffold.dart';

/// 스타일일지 열람 — 대표이미지/추가사진/날짜/장소를 실제 mock 데이터로 표시한다.
/// 연결된 코디가 없으면 크로스 레퍼런스 바에 "+" 바인딩 항목이 뜨고, 탭하면 코디 선택
/// 모달(`AppRoute.compositionSelect`)을 열어 기존 코디를 골라 연결한다(신규 생성
/// 바인딩/착용 옷 목록 자유 편집은 스코프 밖 — `docs/superpowers/plans/
/// 2026-07-15-step7-detail-binding.md` Global Constraints 참고).
class StyleLogViewerScreen extends ConsumerWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  Future<void> _bindComposition(BuildContext context, WidgetRef ref) async {
    final selectedCompositionId = await context.push<String>(AppRoute.compositionSelect);
    // Task 4의 `_bindStyleLog`에 없던 mounted 가드를 여기서는 추가한다 — async 갭 이후
    // ref를 쓰기 전에 위젯이 여전히 살아있는지 확인(Review가 Task 4에서 지적한 TechDebt,
    // `docs/history/TechnicalDebt.md` 참고. `_bindStyleLog` 쪽은 별도로 정리 예정이라
    // 이 Task에서 함께 고치지 않는다 — 이 함수만 새로 작성하므로 처음부터 바르게 작성).
    if (!context.mounted) return;
    if (selectedCompositionId != null) {
      ref.read(styleLogsProvider.notifier).linkToComposition(styleLogId, selectedCompositionId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(styleLogsProvider).firstWhere((l) => l.id == styleLogId);
    final linkedComposition = log.linkedCompositionId == null
        ? null
        : ref.watch(compositionsProvider).firstWhere((c) => c.id == log.linkedCompositionId);

    return AppDetailScaffold(
      category: AppCategory.styleLog,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(log.coverImagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'
              '${log.location.isEmpty ? '' : '  ${log.location}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (log.additionalImagePaths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('추가 사진', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: log.additionalImagePaths.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      log.additionalImagePaths[index],
                      width: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      crossReferenceEntries: [
        if (linkedComposition != null)
          CrossReferenceLinkEntry(
            label: linkedComposition.name,
            icon: Icons.checkroom,
            onTap: () =>
                context.push(AppRoute.compositionDetail.replaceFirst(':id', linkedComposition.id)),
          )
        else
          CrossReferenceLinkEntry(
            label: '코디 연결하기',
            icon: Icons.add,
            onTap: () => _bindComposition(context, ref),
          ),
      ],
    );
  }
}
```

- [ ] **Step 3: `integration_test/detail_screens_header_hud_test.dart`의 스타일일지 열람 관련 그룹 갱신**

```dart
    testWidgets('스타일일지 메인에서 카드 탭 → StyleLogViewerScreen이 크래시 없이 렌더링된다', (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      expect(find.byType(StyleLogMainScreen), findsOneWidget);

      final tile = find.byType(StyleLogGalleryTile).first;
      final log = tester.widget<StyleLogGalleryTile>(tile).styleLog;
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);
      expect(find.textContaining('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'),
          findsOneWidget);
    });
```

```dart
    testWidgets('스타일일지 상세 화면 하단에 연결된 코디 크로스 레퍼런스가 보인다(mock 기준 log01은 comp01에 연결됨)',
        (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');
      await tester.tap(find.byType(StyleLogGalleryTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
      expect(find.textContaining('데일리 룩'), findsOneWidget); // comp01.name
    });
```

- [ ] **Step 4: `integration_test/selection_modal_test.dart`의 코디 선택 모달 assertion을 실제 pop-result 동작에 맞게 교체**

> **정정(2026-07-15)**: Task 4 실행 시 이 블록이 Task 4/5 사이에서 뒤바뀌어 있던 저작 오류가 발견됐다 — Task 4는 이미 스타일일지 선택 모달 쪽을 처리했으므로(위 Task 4 Step 4 정정 내용 참고), 여기(Task 5)에서 실제로 `context.pop` 전환이 적용되는 것은 `composition_main_screen.dart`이고 아래 코디 선택 모달 블록이 이 Task에 맞는 블록이다.

```dart
  testWidgets(
    '코디 선택 모달(/composition/select)도 닫기 버튼으로 교체되고, 카테고리 토글/FAB는 '
    '없으며 groupingBar는 그대로 노출된다. 타일 탭 시 context.pop(id)로 결과를 반환한다',
    (tester) async {
      await pumpApp(tester);

      String? poppedResult;
      final context = tester.element(find.byType(SelectableGalleryTile).first);
      GoRouter.of(context).push<String>(AppRoute.compositionSelect).then((value) {
        poppedResult = value;
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(closeButtonFinder(), findsOneWidget);
      expect(backButtonFinder(), findsNothing);
      expect(find.byType(CategoryToggleDropdown), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('분류 선택 바'), findsOneWidget);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(poppedResult, 'comp01');
    },
  );
```

이 블록은 Task 4에서 이미 `expect(find.byType(CompositionDetailScreen), findsNothing)` 라인(그때 함께 지워진 미사용 import 대상)을 제거해둔 상태이므로, 이 Step에서는 그 라인을 다시 넣지 않고 위 코드 그대로 반영한다.

- [ ] **Step 5: `ProviderScope` override로 "미연결 → + 바인딩 항목" 케이스를 격리 검증하는 위젯 테스트 2개 추가**

새 파일 `test/screens/composition_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';

class _FixedCompositionsNotifier extends StateNotifier<List<Composition>> {
  _FixedCompositionsNotifier(super.state);
}

class _FixedStyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  _FixedStyleLogsNotifier(super.state);
}

void main() {
  const composition = Composition(id: 'test-comp', name: '테스트 코디', items: []);

  testWidgets('연결된 스타일일지가 없으면 "스타일일지 연결하기" 바인딩 항목이 보이고, 탭하면 선택 화면으로 이동한다',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/composition/test-comp',
      routes: [
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) =>
              CompositionDetailScreen(compositionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoute.styleLogSelect,
          builder: (context, state) => const Scaffold(body: Text('스타일일지 선택 화면')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier([composition])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier(const [])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
    expect(find.text('스타일일지 연결하기'), findsOneWidget);

    await tester.tap(find.text('스타일일지 연결하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('스타일일지 선택 화면'), findsOneWidget);
  });

  testWidgets('연결된 스타일일지가 있으면 바인딩 항목 대신 실제 연결 목록이 보인다', (tester) async {
    final linkedLog = StyleLog(
      id: 'test-log',
      coverImagePath: '',
      wornDate: DateTime(2026, 3, 1),
      linkedCompositionId: 'test-comp',
    );
    final router = GoRouter(
      initialLocation: '/composition/test-comp',
      routes: [
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) =>
              CompositionDetailScreen(compositionId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) => const Scaffold(body: Text('스타일일지 열람')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier([composition])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([linkedLog])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스타일일지 연결하기'), findsNothing);
    expect(find.textContaining('2026.3.1'), findsOneWidget);
  });
}
```

새 파일 `test/screens/style_log_viewer_screen_test.dart` (대칭 케이스 — 코디 바인딩):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:digittal_wardrobe/models/composition.dart';
import 'package:digittal_wardrobe/models/style_log.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';
import 'package:digittal_wardrobe/providers/style_log_providers.dart';
import 'package:digittal_wardrobe/router/app_router.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/cross_reference_link_bar.dart';

class _FixedCompositionsNotifier extends StateNotifier<List<Composition>> {
  _FixedCompositionsNotifier(super.state);
}

class _FixedStyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  _FixedStyleLogsNotifier(super.state);
}

void main() {
  final unlinkedLog = StyleLog(id: 'test-log', coverImagePath: '', wornDate: DateTime(2026, 3, 1));

  testWidgets('연결된 코디가 없으면 "코디 연결하기" 바인딩 항목이 보이고, 탭하면 선택 화면으로 이동한다',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/style-log/test-log',
      routes: [
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) =>
              StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoute.compositionSelect,
          builder: (context, state) => const Scaffold(body: Text('코디 선택 화면')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith((ref) => _FixedCompositionsNotifier(const [])),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([unlinkedLog])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CrossReferenceLinkBar), findsOneWidget);
    expect(find.text('코디 연결하기'), findsOneWidget);

    await tester.tap(find.text('코디 연결하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('코디 선택 화면'), findsOneWidget);
  });

  testWidgets('연결된 코디가 있으면 바인딩 항목 대신 실제 연결 목록이 보인다', (tester) async {
    const linkedComposition = Composition(id: 'test-comp', name: '연결된 코디', items: []);
    final log = StyleLog(
      id: 'test-log',
      coverImagePath: '',
      wornDate: DateTime(2026, 3, 1),
      linkedCompositionId: 'test-comp',
    );
    final router = GoRouter(
      initialLocation: '/style-log/test-log',
      routes: [
        GoRoute(
          path: '/style-log/:id',
          builder: (context, state) =>
              StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/composition/:id',
          builder: (context, state) => const Scaffold(body: Text('코디 상세')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionsProvider.overrideWith(
            (ref) => _FixedCompositionsNotifier([linkedComposition]),
          ),
          styleLogsProvider.overrideWith((ref) => _FixedStyleLogsNotifier([log])),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('코디 연결하기'), findsNothing);
    expect(find.text('연결된 코디'), findsOneWidget);
  });
}
```

- [ ] **Step 6: 신규 위젯 테스트 실행 — 통과 확인**

```bash
flutter test test/screens/
```

Expected: `4 tests passed`

- [ ] **Step 7: `flutter analyze` 확인**

```bash
flutter analyze lib/ integration_test/ test/
```

Expected: `No issues found!`

- [ ] **Step 8: 전체 통합테스트 + 유닛테스트 실행**

```bash
taskkill //F //IM digittal_wardrobe.exe
flutter test integration_test/ -d windows
flutter test test/
```

Expected: 전부 Pass. (여러 통합테스트 파일을 순차 실행하므로 파일 하나 끝날 때마다 필요시 `taskkill` 재실행 — BACKLOG Known Issues 참고.)

- [ ] **Step 9: Commit**

```bash
git add lib/screens/style_log_viewer_screen.dart lib/screens/composition_main_screen.dart integration_test/detail_screens_header_hud_test.dart integration_test/selection_modal_test.dart test/screens/composition_detail_screen_test.dart test/screens/style_log_viewer_screen_test.dart
git commit -m "feat(screen): bind real data to 스타일일지 열람 + wire composition binding via selection modal"
```

---

## 완료 후 PM 처리 사항 (이 Plan의 실행 대상 아님 — 세션 인계 메모)

- Task 5 Tester 통과 직후 Audit 1회 실행(이 Plan 전체 = L 사이즈, CLAUDE.md §4).
- BACKLOG.md Current 갱신: 이 Plan 완료를 "Step⑦ 1라운드(선행 정리 2건 + Detail 3화면 바인딩 + 코디↔스타일일지 바인딩) 완료"로 압축 기록.
- 이번 Plan에서 스코프 밖으로 미룬 항목(겹친 아이템 팝업/아트보드 실제 렌더링/추가사진 드래그 순서변경/신규 생성 바인딩/Detail "⋯더보기" 메뉴)을 BACKLOG "Next" 또는 Current 하위 항목으로 신규 등록.
- 남은 Step⑦ 스코프(그룹형 드릴다운 실배선 2곳, 선택 버튼 진입/다중선택 자체, 휴지통 복원·영구삭제·비우기 실행, 설정 알림/다크모드/프로필 진입)는 별도 Plan으로 이어서 진행.
