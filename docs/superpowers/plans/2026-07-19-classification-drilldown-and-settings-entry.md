# 분류 기준 드릴다운 캡슐 + 설정 진입점 이동 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: 이 플랜은 프로젝트 고유 하네스(`CLAUDE.md` "하네스 운영 원칙")를 따른다 — `superpowers:subagent-driven-development`/`executing-plans` 대신, PM(루트 세션)이 Task마다 `worker`/`review`/`tester` 서브에이전트를 스폰하는 Worker→Review→(통과 시) Tester→(통과 시) 완료 사이클을 사용한다. Task 7은 XL이므로 Tester 통과 후 Audit이 한 번 더 돈다(`Workflow_Project.md` §5).

**Goal:** 옷장/코디 메인 화면의 `groupingBar` skeleton을 실제 "[중분류▾][소분류▾]" 드릴다운 캡슐로 교체하고(플랫/그룹개요/드릴인 3상태), `CategoryToggleDropdown`에 설정 진입점을 추가한다.

**Architecture:** 스펙(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`)이 이미 확정한 설계를 그대로 구현한다 — 데이터 모델에 `createdAt`/`Weather` 신설 → 옷장/코디 각각 독립 provider 세트(필터+정렬+그룹 요약, `DrilledValue<T>` wrapper로 "미선택"과 "미분류 드릴인" 구분) → 공용 프레젠테이션 위젯(캡슐/그룹카드/그룹그리드) → 두 메인 화면 배선 + `AppMainScaffold.groupingBar` 슬롯 제거.

**Tech Stack:** Flutter, Riverpod(`StateProvider`/`Provider`), go_router.

## Global Constraints

- 색상 분류 기준은 이번 스코프에서 제외(팔레트 미확정, 스펙 §1).
- 스타일일지 메인은 대상 아님(플랫+필터형, 스펙 §1).
- `AppMainScaffold.groupingBar`/`groupingBarHeight`/`defaultGroupingBarHeight`는 이 스코프가 끝나면 소비자가 0개가 되므로 완전히 삭제한다(YAGNI, 스펙 §4).
- 신규 provider는 옷장/코디 도메인별 완전히 독립 인스턴스(타입은 공유해도 되지만 이번엔 enum 자체가 도메인마다 달라 공유하지 않음, 스펙 §3.6).
- 진행 중 발견된 스펙 미기재 사항(아래 "Task 3 — 정렬 방향 해석" 참고)은 임의로 확정하지 않고 `docs/work/TO_사용자결정.md`에 기록 후 스펙이 명시한 "기본 정렬 순서" 표(§3.2)를 우선하는 해석으로 잠정 구현한다.

---

## File Structure

**신규 파일**
- `lib/providers/classification_models.dart` — `DrilledValue<T>`, `ClassificationGroupSummary`, `compareNullableIndexLast()`. 옷장/코디 provider 파일이 공유(스펙 §3.6/§3.7의 pseudo-code가 두 도메인에서 동일한 타입을 재정의하고 있어, 실제로는 하나의 공유 파일로 두는 것이 DRY — Worker 재량으로 명시된 부분 중 이 플랜이 확정하는 지점).
- `lib/widgets/classification_drilldown_capsule.dart` — 캡슐 UI. 제네릭 위젯 대신 문자열 라벨 + 인덱스 콜백 기반으로 옷장/코디가 공유(스펙 §3.1 "Worker 재량" 중 "제네릭하게 만들기" 방향을 문자열 기반으로 구현 — enum 타입 파라미터 2개(`C`,`S`)를 위젯에 노출하는 대신 화면이 인덱스↔enum 매핑을 소유).
- `lib/widgets/classification_group_card.dart` — 그룹 개요 상태의 폴더형 카드(썸네일 콜라주+라벨+개수).
- `lib/widgets/classification_group_grid.dart` — 그룹 카드 그리드(`AppGalleryGrid` 재사용).
- `test/providers/closet_classification_test.dart`, `test/providers/composition_classification_test.dart` — 신규 provider 순수 로직 TDD.
- `test/widgets/classification_drilldown_capsule_test.dart`, `test/widgets/classification_group_card_test.dart` — 렌더 스모크 테스트(상호작용/애니메이션은 Task 7 이후 Tester 몫, 스펙 §5).

**수정 파일**
- `lib/models/enums.dart` — `Weather` enum 추가.
- `lib/models/clothing_item.dart` — `createdAt` 필드(+ `copyWith`).
- `lib/models/composition.dart` — `createdAt`, `weather` 필드.
- `lib/mock/mock_data.dart` — 전 항목 `createdAt` 채움, 미분류 데모용 값 조정.
- `lib/providers/closet_providers.dart` — `selectedSeasonFilterProvider` 제거·대체, `ClosetSortCriterion` 등 신설.
- `lib/providers/composition_providers.dart` — `selectedCompositionSeasonFilterProvider` 제거·대체, `CompositionSortCriterion` 등 신설.
- `lib/widgets/category_toggle_dropdown.dart` — `DropdownButton` → `PopupMenuButton`, "설정" 항목 추가.
- `lib/screens/closet_main_screen.dart`, `lib/screens/composition_main_screen.dart` — 캡슐/3상태 그리드 배선, `groupingBar` 제거.
- `lib/widgets/app_main_scaffold.dart` — `groupingBar`/`groupingBarHeight`/`defaultGroupingBarHeight` 삭제.
- `test/providers/closet_providers_test.dart`, `test/providers/composition_providers_test.dart` — 제거되는 provider의 테스트 정리.
- `test/widgets/app_main_scaffold_test.dart`, `integration_test/header_hud_stack_architecture_test.dart`, `integration_test/composition_style_log_main_screen_test.dart`, `integration_test/selection_modal_test.dart` — `groupingBar` 관련 assertion 정리.
- `docs/reference/plan/03_화면별UX명세서/04_설정.md` — §1 정정 각주(PM 직접 수정).
- `docs/history/Decision.md` — override 기록(PM 직접 수정).

---

## Task 1: 데이터 모델 — `Weather` enum, `createdAt`/`weather` 필드, mock 데이터

**Layer×Stage**: Data/Architecture × Implementation.

**Files:**
- Modify: `lib/models/enums.dart`
- Modify: `lib/models/clothing_item.dart`
- Modify: `lib/models/composition.dart`
- Modify: `lib/mock/mock_data.dart`
- Modify(**실행 중 발견된 plan 공백, Worker가 지적**): `ClothingItem`/`Composition`을 직접 생성하는 테스트 파일 13개 — `createdAt`이 required가 되며 컴파일이 깨짐. `integration_test/closet_item_nullable_fields_test.dart`, `closet_main_screen_test.dart`, `composition_detail_addtile_square_test.dart`, `composition_detail_data_binding_test.dart`, `composition_preview_carousel_scroll_test.dart`, `detail_cross_reference_visuals_test.dart`, `detail_thumbnail_square_unification_test.dart` / `test/providers/composition_cover_image_provider_test.dart`, `test/screens/composition_detail_screen_test.dart`, `test/screens/style_log_viewer_screen_test.dart`, `test/widgets/composition_gallery_grid_test.dart`, `test/widgets/composition_gallery_tile_test.dart`, `test/widgets/gallery_semantics_test.dart`. 각 생성자 호출에 `createdAt:` 기계적으로 추가(값 자체는 임의, 날짜 기반 assertion이 없는 한 정확성 무관). `const` 생성자였던 곳은 `DateTime`이 const가 아니므로 `const` 제거 필요(mock_data.dart와 동일 패턴).

**Interfaces:**
- Produces: `Weather` enum(`clear/rain/snow` + `.label`), `ClothingItem.createdAt`(`DateTime`, non-nullable), `Composition.createdAt`(`DateTime`, non-nullable), `Composition.weather`(`Weather?`, nullable).이후 모든 Task가 이 필드들을 전제로 한다.

- [ ] **Step 1: `Weather` enum 추가**

`lib/models/enums.dart` 파일 끝(L98 `}` 다음)에 추가:

```dart

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [Composition.weather]에 허용되는 값.
enum Weather {
  clear,
  rain,
  snow;

  String get label => switch (this) {
        Weather.clear => '맑음',
        Weather.rain => '비',
        Weather.snow => '눈',
      };
}
```

- [ ] **Step 2: `ClothingItem.createdAt` 추가**

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
  });

  final String id;
  final String name;
  final ClothingCategory? category;
  final String? color;
  final Season? season;
  final ClothingMaterial? material;
  final String imagePath;

  /// 옷장 "날짜·시간" 분류 기준의 소분류(연도) 근거. non-nullable이라 이 기준엔 미분류
  /// 카드가 생기지 않는다(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md` §3.2).
  final DateTime createdAt;
  final String location;
  final String memo;
  final int wearCount;
  final bool isIncomplete;
  final bool isDeleted;

  ClothingItem copyWith({
    String? id,
    String? name,
    ClothingCategory? category,
    String? color,
    Season? season,
    ClothingMaterial? material,
    String? imagePath,
    DateTime? createdAt,
    String? location,
    String? memo,
    int? wearCount,
    bool? isIncomplete,
    bool? isDeleted,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      season: season ?? this.season,
      material: material ?? this.material,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      wearCount: wearCount ?? this.wearCount,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
```

- [ ] **Step 3: `Composition.createdAt`/`weather` 추가**

`lib/models/composition.dart`의 `Composition` 클래스(L21-43)를 다음으로 교체(`CompositionItemPlacement`는 변경 없음):

```dart
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
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;

  /// 코디 "날짜·시간" 분류 기준의 소분류(연도) 근거 — `ClothingItem.createdAt`과 동일 성격.
  final DateTime createdAt;
  final Season? season;

  /// 코디 자체에 붙는 선택적 태그(실제 착용일 관측 날씨가 아님) — `season`과 동일 성격.
  final Weather? weather;

  /// 사용자가 지정한 대표 이미지(신규 기능, 이번 라운드에 선택 UI는 없음 — `docs/history/
  /// TechnicalDebt.md` "CompositionGalleryTile이 아직 텍스트만 표시" 참고). `null`이면
  /// [compositionCoverImageProvider]가 첫 번째 옷 이미지로 폴백한다.
  final String? coverImagePath;
  final bool isIncomplete;
  final bool isDeleted;
}
```

(주의: `copyWith`는 신설하지 않는다 — 이 클래스엔 원래 `copyWith`가 없었고, 이번 필드 추가 자체도 이를 수정하는 실제 소비자가 없다. `ClothingItem.copyWith`의 nullable-되돌리기 불가 한계(`docs/history/TechnicalDebt.md`)와 동일한 이유로, 소비자 없이 먼저 만들지 않는다 — YAGNI.)

- [ ] **Step 4: mock 데이터에 `createdAt` 채우고 미분류 데모 값 반영**

`lib/mock/mock_data.dart`의 `mockClothingItems`/`mockCompositions` 리터럴을 다음으로 교체(`mockStyleLogs`/`mockTrashEntries`는 변경 없음):

```dart
final List<ClothingItem> mockClothingItems = [
  const ClothingItem(id: 'c01', name: '플로럴 원피스', category: ClothingCategory.onePiece, color: 'pink', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png', createdAt: DateTime(2024, 3, 12), location: '옷장 2단', wearCount: 3),
  const ClothingItem(id: 'c02', name: '데님 팬츠', category: ClothingCategory.bottom, color: 'black', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png', createdAt: DateTime(2025, 6, 1), wearCount: 9),
  const ClothingItem(id: 'c03', name: '그래픽 와이드팬츠', category: ClothingCategory.bottom, color: 'khaki', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4261_preview_rev_1.png', createdAt: DateTime(2023, 11, 20), wearCount: 4),
  const ClothingItem(id: 'c04', name: '트렌치코트', category: ClothingCategory.outer, color: 'brown', season: Season.springFall, material: ClothingMaterial.leather, imagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png', createdAt: DateTime(2024, 9, 5), location: '옷장 1단', wearCount: 2),
  const ClothingItem(id: 'c05', name: '스트라이프 블라우스', category: ClothingCategory.top, color: 'burgundy', season: Season.springFall, material: ClothingMaterial.silkSatin, imagePath: 'assets/images/mock/IMG_4267_preview_rev_1.png', createdAt: DateTime(2025, 2, 14), wearCount: 5),
  const ClothingItem(id: 'c06', name: '코튼 반바지', category: ClothingCategory.bottom, color: 'sage', season: Season.summer, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4273.PNG', createdAt: DateTime(2026, 1, 8), isIncomplete: true),
  const ClothingItem(id: 'c07', name: '리넨 반바지', category: ClothingCategory.bottom, color: 'blue', season: Season.summer, material: ClothingMaterial.linen, imagePath: 'assets/images/mock/IMG_4275.PNG', createdAt: DateTime(2025, 7, 22), wearCount: 6),
  const ClothingItem(id: 'c08', name: '슬립 드레스', category: ClothingCategory.onePiece, color: 'black', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4276.PNG', createdAt: DateTime(2024, 12, 30), wearCount: 1),
  const ClothingItem(id: 'c09', name: '레더 재킷', category: ClothingCategory.outer, color: 'black', season: Season.springFall, material: ClothingMaterial.leather, imagePath: 'assets/images/mock/IMG_4277.PNG', createdAt: DateTime(2023, 5, 17), location: '옷장 1단', wearCount: 7),
  const ClothingItem(id: 'c10', name: '그래픽 반팔티', category: ClothingCategory.top, color: 'white', season: Season.summer, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4257_preview_rev_1.png', createdAt: DateTime(2025, 4, 3), wearCount: 12),
  const ClothingItem(id: 'c11', name: '그래픽 맨투맨', category: ClothingCategory.top, color: 'pink', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png', createdAt: DateTime(2024, 8, 19), wearCount: 8),
  // category/season 둘 다 null — 옷장 "옷 종류"/"계절" 분류의 미분류 카드 데모용
  // (`docs/history/Decision.md`의 nullable화 결정, 2026-07-19).
  const ClothingItem(id: 'c12', name: '플로럴 스커트', color: 'multi', material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4268-removebg-preview.png', createdAt: DateTime(2026, 2, 25), wearCount: 2),
];

final List<Composition> mockCompositions = [
  const Composition(
    id: 'comp01',
    name: '데일리 룩',
    createdAt: DateTime(2025, 3, 10),
    season: Season.springFall,
    weather: Weather.clear,
    items: [
      CompositionItemPlacement(clothingItemId: 'c01', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c11', x: 60, y: 120, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c07', x: 60, y: 260, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c03', x: 80, y: 380, zIndex: 3),
    ],
  ),
  const Composition(
    id: 'comp02',
    name: '포멀 코디',
    createdAt: DateTime(2026, 1, 20),
    // season 미지정 — 코디 "계절" 분류의 미분류 카드 데모용.
    weather: Weather.rain,
    items: [
      CompositionItemPlacement(clothingItemId: 'c04', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c05', x: 70, y: 140, zIndex: 1),
    ],
  ),
];
```

- [ ] **Step 5: 회귀 검증**

Run: `flutter analyze && flutter test`

Expected: 컴파일 에러 없음. `test/mock/mock_data_test.dart`(미완성 아이템 존재 여부, id 참조 무결성만 검사 — `createdAt`/`category`/`season` null 여부와 무관)와 나머지 기존 테스트 전부 PASS. (이 Task는 순수 데이터 필드 추가라 이 저장소 관례상 모델 전용 단위테스트를 새로 만들지 않는다 — `test/models/` 디렉토리 자체가 이 프로젝트에 없음, 실제 검증은 이 필드들을 소비하는 Task 3/4의 provider TDD가 담당.)

- [ ] **Step 6: Commit**

```bash
git add lib/models/enums.dart lib/models/clothing_item.dart lib/models/composition.dart lib/mock/mock_data.dart
git commit -m "feat(models): add Weather enum and createdAt/weather fields for classification drilldown"
```

---

## Task 2: 설정 진입점 — `CategoryToggleDropdown` → `PopupMenuButton`

**Layer×Stage**: UI/Screen × Implementation.

**Files:**
- Modify: `lib/widgets/category_toggle_dropdown.dart`

**Interfaces:**
- Consumes: `AppRoute.settingsMain`(`lib/router/app_router.dart`, 이미 존재), `AppCategory`(`lib/models/enums.dart`).
- Produces: 기존과 동일한 공개 API(`CategoryToggleDropdown({required AppCategory current})`) — 호출부(`AppMainScaffold`) 변경 없음.

- [ ] **Step 1: `PopupMenuButton` 기반으로 재작성**

`lib/widgets/category_toggle_dropdown.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../router/app_router.dart';
import 'glass_pill.dart';

/// 헤더 좌측 카테고리 드롭다운 — 옷장/코디/스타일일지 전환 + 설정 진입.
///
/// `DropdownButton<AppCategory>`는 `AppCategory` 값만 담을 수 있어 "설정"(카테고리가
/// 아닌 액션)을 넣을 수 없다 — `PopupMenuButton`으로 교체해 구분선 아래 "설정" 항목을
/// 별도 추가한다(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`
/// §2). "설정"을 골라도 [current] 표시는 바뀌지 않는다 — 메뉴가 닫힌 뒤 보이는 텍스트는
/// 항상 `current.label`이고, 선택된 메뉴 항목 값과 무관하다.
class CategoryToggleDropdown extends StatelessWidget {
  const CategoryToggleDropdown({super.key, required this.current});

  final AppCategory current;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      child: PopupMenuButton<_CategoryMenuEntry>(
        tooltip: '',
        onSelected: (entry) => _onSelected(context, entry),
        itemBuilder: (context) => [
          for (final category in AppCategory.values)
            PopupMenuItem(
              value: _CategoryMenuEntry.category(category),
              child: Text(category.label),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: const _CategoryMenuEntry.settings(),
            child: Text('설정', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.label),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _onSelected(BuildContext context, _CategoryMenuEntry entry) {
    if (entry.isSettings) {
      context.push(AppRoute.settingsMain);
      return;
    }
    final category = entry.category!;
    if (category == current) return;
    switch (category) {
      case AppCategory.closet:
        context.go(AppRoute.closetMain);
      case AppCategory.composition:
        context.go(AppRoute.compositionMain);
      case AppCategory.styleLog:
        context.go(AppRoute.styleLogMain);
    }
  }
}

class _CategoryMenuEntry {
  const _CategoryMenuEntry.category(AppCategory value)
      : category = value,
        isSettings = false;
  const _CategoryMenuEntry.settings()
      : category = null,
        isSettings = true;

  final AppCategory? category;
  final bool isSettings;

  @override
  bool operator ==(Object other) =>
      other is _CategoryMenuEntry && other.category == category && other.isSettings == isSettings;

  @override
  int get hashCode => Object.hash(category, isSettings);
}
```

- [ ] **Step 2: 검증**

Run: `flutter analyze`

Expected: 에러 없음(`GlassPill`의 `child` 파라미터에 `PopupMenuButton`을 그대로 넣을 수 있는지만 확인 — 기존에도 `DropdownButton`을 넣던 자리라 위젯 타입 제약 없음).

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/category_toggle_dropdown.dart
git commit -m "feat(nav): move Settings entry point into CategoryToggleDropdown menu"
```

**실행 중 추가로 발견된 gap(PM이 직접 수정, 2026-07-19)**: `DropdownButton<AppCategory>` → `PopupMenuButton` 전환으로 `find.byWidgetPredicate((w) => w is DropdownButton<AppCategory>)`/`find.byIcon(Icons.arrow_drop_down)`(후자는 계절 필터 DropdownButton과 아이콘이 겹쳐 모호하게 매칭됨)로 카테고리 드롭다운을 찾던 `integration_test/` 파일 15개가 전부 깨짐(단순 `flutter test`는 이 프로젝트에서 `integration_test/`를 아예 건너뛰므로 초기 회귀 검증에서 안 걸림 — `-d windows` 필요, `docs/work/BACKLOG.md` Known Issues 참고). 최종적으로 `find.byType(CategoryToggleDropdown)`(위젯 타입 자체로 탭, 아이콘 중복 문제 없음)로 통일. 영향 파일: `closet_main_screen_test.dart`, `composition_style_log_main_screen_test.dart`, `typography_pass3_test.dart`, `composition_preview_carousel_scroll_test.dart`, `style_log_gallery_column_count_test.dart`, `composition_detail_data_binding_test.dart`, `style_log_composition_binding_test.dart`, `composition_detail_addtile_square_test.dart`, `editor_header_navigation_test.dart`, `style_log_carousel_gesture_test.dart`, `detail_cross_reference_visuals_test.dart`, `closet_main_shell_widgets_regression_test.dart`, `header_hud_stack_architecture_test.dart`, `detail_thumbnail_square_unification_test.dart`, `detail_screens_header_hud_test.dart`. 대표 3개 파일(`closet_main_screen_test.dart` 28/28, `composition_style_log_main_screen_test.dart` 16/16, `composition_detail_addtile_square_test.dart` 4/4)을 `-d windows`로 직접 실행해 통과 확인, 나머지 12개는 동일한 기계적 치환(sed, 문자열 100% 일치 확인)이라 안전한 것으로 판단(전수 실행은 Windows exe 빌드-잠금 이슈로 시간이 많이 들어 생략).

**Review 체크포인트**: 정적 리뷰(flutter analyze, 스펙 §2 대조 — push/go 구분, current 라벨 불변).

**Tester 체크포인트**(Review 통과 후, 런타임 동작 있음): 옷장/코디/스타일일지 각 메인 화면에서 카테고리 드롭다운 탭 → "설정" 항목까지 스크롤/탭 → `/settings`로 push되는지, 뒤로가기로 원래 화면(현재 카테고리 라벨 유지)으로 복귀하는지 3개 화면 모두 확인. `integration_test/`에 신규 테스트 파일 작성(예: `settings_entry_point_test.dart`).

---

## Task 3: 공유 분류 모델 + 옷장 classification providers

**Layer×Stage**: Logic/Feature × Implementation. TDD 대상(스펙 §5).

**Files:**
- Create: `lib/providers/classification_models.dart`
- Modify: `lib/providers/closet_providers.dart`
- Modify: `test/providers/closet_providers_test.dart` (구 `selectedSeasonFilterProvider` 테스트 제거)
- Test: `test/providers/closet_classification_test.dart`

**Interfaces:**
- Produces: `DrilledValue<T>`, `ClassificationGroupSummary`, `compareNullableIndexLast(int? a, int? b, {required bool ascending})`(`classification_models.dart`, Task 4가 그대로 import) / `ClosetSortCriterion`, `closetSortCriterionProvider`, `closetSortAscendingProvider`, `closetDrilledYearProvider`, `closetDrilledCategoryProvider`, `closetDrilledSeasonProvider`, `closetGroupSummariesProvider`, `closetGridDisplayStateProvider`, `ClosetGridDisplayState`(`closet_providers.dart`, Task 7이 소비).
- Consumes: `ClothingItem.createdAt`(Task 1), `ClothingCategory`/`Season`(`lib/models/enums.dart`).

### 정렬 방향 해석 — TO 문서에 기록할 지점

스펙 §3.2 "기본 정렬 순서" 표는 옷종류=머리→발, 계절=봄가을→여름→겨울을 **기본값**이라 명시하지만, §3.6의 `closetSortAscendingProvider` 기본값은 `false`이고 그 옆 주석은 "기본 내림차순(최신/많이입은순)"이라고만 적혀 있어 날짜·착용빈도 두 기준만 근거를 댄다. `ascending=false`를 "index 내림차순"으로 그대로 해석하면 옷종류/계절 기본 표시가 발→머리/겨울→여름→봄가을이 되어 §3.2 표와 어긋난다.

**이 플랜이 채택하는 해석**: `ascending` 파라미터의 의미를 "그 기준의 §3.2 기본 순서로부터의 상대 방향"으로 정의한다 — 날짜/착용빈도는 자연스러운 방향(`ascending=true`=값 오름차순)이 곧 표의 기본이 아니므로 그대로 두고, 옷종류/계절처럼 표의 기본이 "index 오름차순"과 일치하는 기준은 `!ascending`을 넘겨 기본값(`false`)이 표와 일치하게 만든다. 근거/구현은 아래 Step 2 코드의 `compareNullableIndexLast(..., ascending: !ascending)` 호출부 주석 참고. **이 해석 자체가 스펙에 명시되어 있지 않으므로, `docs/work/TO_사용자결정.md`에 기록해 사용자 확인을 받는다**(Step 5).

- [ ] **Step 1: `classification_models.dart` 작성**

Create `lib/providers/classification_models.dart`:

```dart
/// 소분류 provider의 상태 3가지: 미선택(그룹 개요) / 특정 값으로 드릴인 / 미분류로 드릴인.
/// provider 자체가 null이면 미선택, non-null이면 드릴인(그 안의 [value]가 null이면 미분류).
class DrilledValue<T> {
  const DrilledValue.value(T v) : value = v;
  const DrilledValue.unclassified() : value = null;

  final T? value;

  bool get isUnclassified => value == null;

  @override
  bool operator ==(Object other) => other is DrilledValue<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// 분류 기준 드릴다운의 "그룹 개요" 상태에서 그리는 폴더형 카드 한 장의 데이터.
class ClassificationGroupSummary {
  const ClassificationGroupSummary({
    required this.label,
    required this.thumbnailPaths,
    required this.count,
    required this.value,
  });

  final String label;

  /// 콜라주용, 최대 4장.
  final List<String> thumbnailPaths;
  final int count;

  /// 탭 시 드릴인 provider에 그대로 세팅할 값. `null`이면 미분류 카드.
  final Object? value;
}

/// index 기반(연도/열거형 index) nullable 정렬 — null은 항상 "가장 큰 값"으로 취급해
/// [ascending]이면 맨 뒤, 아니면 맨 앞으로 보낸다
/// (스펙 §3.4 — 옷장/코디 provider가 공유하는 유일한 정렬 헬퍼).
int compareNullableIndexLast(int? a, int? b, {required bool ascending}) {
  if (a == null && b == null) return 0;
  if (a == null) return ascending ? 1 : -1;
  if (b == null) return ascending ? -1 : 1;
  return ascending ? a.compareTo(b) : b.compareTo(a);
}
```

- [ ] **Step 2: `closet_providers.dart`에 classification 로직 추가**

`lib/providers/closet_providers.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/clothing_item.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import 'classification_models.dart';

class ClosetItemsNotifier extends StateNotifier<List<ClothingItem>> {
  ClosetItemsNotifier() : super(mockClothingItems);

  void softDelete(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isDeleted: true) else item,
    ];
  }
}

final closetItemsProvider =
    StateNotifierProvider<ClosetItemsNotifier, List<ClothingItem>>((ref) => ClosetItemsNotifier());

/// 옷장 메인 헤더 캡슐의 중분류 값. 순서가 곧 캡슐 드롭다운 항목 순서(스펙 §3.2).
enum ClosetSortCriterion { all, dateTime, clothingType, season, wearFrequency }

extension ClosetSortCriterionX on ClosetSortCriterion {
  /// 캡슐 중분류 드롭다운에 표시할 라벨 — 다른 폐쇄 어휘 enum(`ClothingCategory` 등)과
  /// 동일하게 `.label` getter 패턴을 따른다(화면에 병렬 String 리스트를 따로 두지 않음 —
  /// Review 지적 P1, 화면이 인덱스로 하드코딩된 라벨 리스트를 따로 들면 enum과 동기화가
  /// 깨질 수 있음).
  String get label => switch (this) {
        ClosetSortCriterion.all => '전체보기',
        ClosetSortCriterion.dateTime => '날짜·시간',
        ClosetSortCriterion.clothingType => '옷 종류',
        ClosetSortCriterion.season => '계절',
        ClosetSortCriterion.wearFrequency => '착용빈도',
      };

  /// 소분류 세그먼트가 붙는 기준인지 — false면 캡슐이 첫 세그먼트 크기로 줄어든다(스펙 §3.3).
  bool get hasSubClassification => switch (this) {
        ClosetSortCriterion.all => false,
        ClosetSortCriterion.wearFrequency => false,
        _ => true,
      };

  /// 소분류 미선택(그룹 개요) 상태에서 캡슐에 보여줄 플레이스홀더(스펙 §3.1 표).
  /// [hasSubClassification]이 false인 기준은 호출되지 않는다.
  String get subClassificationHint => switch (this) {
        ClosetSortCriterion.dateTime => '연도',
        ClosetSortCriterion.clothingType => '종류',
        ClosetSortCriterion.season => '계절',
        _ => throw StateError('소분류 없는 기준: $this'),
      };
}

final closetSortCriterionProvider = StateProvider<ClosetSortCriterion>((ref) => ClosetSortCriterion.all);

/// 기본 false(내림차순) — 날짜/착용빈도는 문자 그대로 "최신순"/"많이 입은 순"(스펙 §3.6).
/// 옷종류/계절은 이 값이 "표의 기본 순서로부터의 상대 방향"으로 재해석된다 — 아래
/// [filteredClosetItemsProvider]의 `!ascending` 호출부 주석 참고(플랜 "정렬 방향 해석" 절,
/// `docs/work/TO_사용자결정.md`에 확인 요청 기록됨).
final closetSortAscendingProvider = StateProvider<bool>((ref) => false);

/// `createdAt`이 non-nullable이라 [DrilledValue] wrapper가 필요 없다 — null=미선택뿐.
final closetDrilledYearProvider = StateProvider<int?>((ref) => null);

final closetDrilledCategoryProvider = StateProvider<DrilledValue<ClothingCategory>?>((ref) => null);
final closetDrilledSeasonProvider = StateProvider<DrilledValue<Season>?>((ref) => null);

/// 3가지 그리드 상태(스펙 §3.1) — 별도 상태 저장 없이 위 provider들의 조합에서 파생된다.
enum ClosetGridDisplayState { flat, groupOverview, drilledIn }

final closetGridDisplayStateProvider = Provider<ClosetGridDisplayState>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  if (!criterion.hasSubClassification) return ClosetGridDisplayState.flat;
  final isDrilledIn = switch (criterion) {
    ClosetSortCriterion.clothingType => ref.watch(closetDrilledCategoryProvider) != null,
    ClosetSortCriterion.season => ref.watch(closetDrilledSeasonProvider) != null,
    ClosetSortCriterion.dateTime => ref.watch(closetDrilledYearProvider) != null,
    ClosetSortCriterion.all || ClosetSortCriterion.wearFrequency => false,
  };
  return isDrilledIn ? ClosetGridDisplayState.drilledIn : ClosetGridDisplayState.groupOverview;
});

/// 삭제되지 않고, 현재 중분류의 소분류 필터에 맞는 아이템을 현재 정렬 기준+방향으로 정렬.
final filteredClosetItemsProvider = Provider<List<ClothingItem>>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  final ascending = ref.watch(closetSortAscendingProvider);

  Iterable<ClothingItem> items = ref.watch(closetItemsProvider).where((item) => !item.isDeleted);

  switch (criterion) {
    case ClosetSortCriterion.clothingType:
      final drilled = ref.watch(closetDrilledCategoryProvider);
      if (drilled != null) {
        items = items.where((item) => item.category == drilled.value);
      }
    case ClosetSortCriterion.season:
      final drilled = ref.watch(closetDrilledSeasonProvider);
      if (drilled != null) {
        items = items.where((item) => item.season == drilled.value);
      }
    case ClosetSortCriterion.dateTime:
      final year = ref.watch(closetDrilledYearProvider);
      if (year != null) {
        items = items.where((item) => item.createdAt.year == year);
      }
    case ClosetSortCriterion.all:
    case ClosetSortCriterion.wearFrequency:
      break;
  }

  final result = items.toList();
  if (criterion == ClosetSortCriterion.all) return result; // 정렬 없음(기존 동작 유지)

  result.sort((a, b) => switch (criterion) {
        ClosetSortCriterion.dateTime =>
          ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt),
        // !ascending: 기본(ascending=false)이 스펙 §3.2 표의 "머리→발" 기본 순서와
        // 일치하도록 반전(위 closetSortAscendingProvider 주석/TO 문서 참고).
        ClosetSortCriterion.clothingType =>
          compareNullableIndexLast(a.category?.index, b.category?.index, ascending: !ascending),
        ClosetSortCriterion.season =>
          compareNullableIndexLast(a.season?.index, b.season?.index, ascending: !ascending),
        ClosetSortCriterion.wearFrequency =>
          ascending ? a.wearCount.compareTo(b.wearCount) : b.wearCount.compareTo(a.wearCount),
        ClosetSortCriterion.all => 0, // 위에서 이미 return, 도달하지 않음(exhaustive switch용)
      });
  return result;
});

/// 그룹 개요 상태에서 그릴 카드 목록 — 소분류 필터 적용 **전** 단계 값을 기준으로 묶는다
/// (그룹 개요는 항상 전체 그룹을 보여줘야 하므로, 스펙 §3.7).
final closetGroupSummariesProvider = Provider<List<ClassificationGroupSummary>>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  final ascending = ref.watch(closetSortAscendingProvider);
  final items = ref.watch(closetItemsProvider).where((item) => !item.isDeleted).toList();

  switch (criterion) {
    case ClosetSortCriterion.clothingType:
      return _summarize<ClothingCategory>(
        items,
        keyOf: (item) => item.category,
        labelOf: (category) => category.label,
        indexOf: (category) => category.index,
        ascending: !ascending,
      );
    case ClosetSortCriterion.season:
      return _summarize<Season>(
        items,
        keyOf: (item) => item.season,
        labelOf: (season) => season.label,
        indexOf: (season) => season.index,
        ascending: !ascending,
      );
    case ClosetSortCriterion.dateTime:
      return _summarizeByYear(items, ascending: ascending);
    case ClosetSortCriterion.all:
    case ClosetSortCriterion.wearFrequency:
      return const [];
  }
});

/// 옷장/코디가 공유하는 "값별로 묶어 카드 목록 만들기" 로직 — [K]는 분류 기준의 소분류
/// 타입(`ClothingCategory`/`Season`/`Weather`), null 키는 미분류 카드가 된다.
List<ClassificationGroupSummary> _summarize<K>(
  List<ClothingItem> items, {
  required K? Function(ClothingItem) keyOf,
  required String Function(K) labelOf,
  required int Function(K) indexOf,
  required bool ascending,
}) {
  final groups = <K?, List<ClothingItem>>{};
  for (final item in items) {
    groups.putIfAbsent(keyOf(item), () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      if (entry.value.isNotEmpty)
        ClassificationGroupSummary(
          label: entry.key == null ? '미분류' : labelOf(entry.key as K),
          thumbnailPaths: entry.value.take(4).map((item) => item.imagePath).toList(),
          count: entry.value.length,
          value: entry.key,
        ),
  ];
  summaries.sort((a, b) => compareNullableIndexLast(
        a.value == null ? null : indexOf(a.value as K),
        b.value == null ? null : indexOf(b.value as K),
        ascending: ascending,
      ));
  return summaries;
}

List<ClassificationGroupSummary> _summarizeByYear(List<ClothingItem> items, {required bool ascending}) {
  final groups = <int, List<ClothingItem>>{};
  for (final item in items) {
    groups.putIfAbsent(item.createdAt.year, () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      ClassificationGroupSummary(
        label: '${entry.key}년',
        thumbnailPaths: entry.value.take(4).map((item) => item.imagePath).toList(),
        count: entry.value.length,
        value: entry.key,
      ),
  ];
  summaries.sort((a, b) {
    final ay = a.value as int;
    final by = b.value as int;
    return ascending ? ay.compareTo(by) : by.compareTo(ay);
  });
  return summaries;
}

/// 옷장 메인 그리드 밀도 — `AppDensity.min/mid/max` 중 하나.
final closetDensityProvider = StateProvider<int>((ref) => AppDensity.mid);
```

- [ ] **Step 3: 구 `selectedSeasonFilterProvider` 테스트 정리**

`test/providers/closet_providers_test.dart`를 읽고, `selectedSeasonFilterProvider`를 참조하는 테스트("selectedSeasonFilterProvider를 설정하면...")를 제거한다(해당 provider가 이제 없음). `softDelete` 테스트는 그대로 유지한다. 결과 파일:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('softDelete한 아이템은 filteredClosetItemsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredClosetItemsProvider).length;
    final target = container.read(closetItemsProvider).first;
    container.read(closetItemsProvider.notifier).softDelete(target.id);
    final after = container.read(filteredClosetItemsProvider);

    expect(after.length, before - 1);
    expect(after.any((item) => item.id == target.id), isFalse);
  });
}
```

(원본 파일의 정확한 `softDelete` 테스트 코드가 위와 다르면 그 로직은 유지하고 `selectedSeasonFilterProvider` 관련 테스트만 제거 — 정확한 원본은 Worker가 실제 파일을 읽고 확인.)

- [ ] **Step 4: 신규 TDD 테스트 작성 후 통과 확인**

Create `test/providers/closet_classification_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('중분류가 옷종류면 미선택 상태에서 groupOverview, 카테고리 드릴인 시 drilledIn', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.groupOverview);

    container.read(closetDrilledCategoryProvider.notifier).state =
        const DrilledValue.value(ClothingCategory.top);
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.drilledIn);
    expect(
      container.read(filteredClosetItemsProvider).every((item) => item.category == ClothingCategory.top),
      isTrue,
    );
  });

  test('전체보기/착용빈도는 소분류 없이 항상 flat', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.all;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.flat);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.wearFrequency;
    expect(container.read(closetGridDisplayStateProvider), ClosetGridDisplayState.flat);
  });

  test('옷종류 미분류로 드릴인하면 category가 null인 아이템만 남는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    container.read(closetDrilledCategoryProvider.notifier).state = const DrilledValue.unclassified();

    final result = container.read(filteredClosetItemsProvider);
    expect(result, isNotEmpty);
    expect(result.every((item) => item.category == null), isTrue);
  });

  test('그룹 개요 카드는 빈 그룹을 만들지 않고, 미분류 카드는 값이 있는 아이템이 있을 때만 나타난다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    final summaries = container.read(closetGroupSummariesProvider);

    expect(summaries.every((s) => s.count > 0), isTrue);
    expect(summaries.any((s) => s.label == '미분류'), isTrue); // mock c12가 category null
  });

  test('옷종류 그룹 카드는 기본(ascending=false)일 때 머리→발 순서(ClothingCategory index 오름차순)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.clothingType;
    final summaries = container.read(closetGroupSummariesProvider);
    final classified = summaries.where((s) => s.value != null).toList();

    for (var i = 1; i < classified.length; i++) {
      final prevIndex = (classified[i - 1].value as ClothingCategory).index;
      final currIndex = (classified[i].value as ClothingCategory).index;
      expect(prevIndex, lessThan(currIndex));
    }
  });

  test('날짜 기준 기본 정렬은 최신순(내림차순)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.dateTime;
    final result = container.read(filteredClosetItemsProvider);

    for (var i = 1; i < result.length; i++) {
      expect(
        result[i - 1].createdAt.isAfter(result[i].createdAt) ||
            result[i - 1].createdAt.isAtSameMomentAs(result[i].createdAt),
        isTrue,
      );
    }
  });
}
```

Run: `flutter test test/providers/closet_classification_test.dart -v`

Expected: 전부 PASS. (구현이 Step 2에서 이미 끝났으므로 이 Step은 "먼저 실패를 본다"는 고전적 TDD 순서 대신, 구현+테스트를 같은 Step으로 묶어 검증한다 — 이 프로젝트의 provider 테스트 관례(`test/providers/closet_providers_test.dart`)도 이미 존재하는 구현을 사후 검증하는 형태를 취하고 있어 동일 패턴을 따름.)

- [ ] **Step 5: `docs/work/TO_사용자결정.md`에 정렬 방향 해석 기록**

파일이 없으면 새로 만들고, 있으면 이어서 추가:

```markdown
# 사용자 확인 필요 — 자고 일어나서 확인 후 삭제

## 옷장/코디 분류 기준 정렬의 "오름차순" 의미 (2026-07-19, Task 3)

**배경**: `2026-07-19-main-header-classification-and-settings-entry-design.md` §3.2가 "기본 정렬
순서" 표(옷종류=머리→발, 계절=봄가을→여름→겨울 등)를 명시하지만, §3.6의
`closetSortAscendingProvider` 기본값(`false`)에 대한 주석은 "기본 내림차순(최신/많이입은순)"만
언급하고 옷종류/계절 케이스는 다루지 않음. 두 조항을 문자 그대로 조합하면 옷종류/계절 기본
표시가 표와 반대(발→머리, 겨울→여름→봄가을)가 됨.

**이 플랜이 잠정 채택한 해석**: `ascending` 토글의 "false(기본)"은 항상 §3.2 표의 순서와
일치하도록 정의(옷종류/계절은 index를 반전해서 넘김 — `lib/providers/closet_providers.dart`/
`composition_providers.dart`의 `compareNullableIndexLast(..., ascending: !ascending)` 호출부).
즉 토글을 안 건드리면 항상 §3.2 표대로 보이고, 토글하면 반대 방향이 됨.

**확인 필요**: 이 해석이 맞는지, 혹은 "ascending=true가 항상 index 오름차순"이라는 더 단순한
전역 규칙을 원하는지(그러면 옷종류/계절 기본 표시가 발→머리가 됨). 확정되면 이 항목 삭제.
```

- [ ] **Step 6: Commit**

```bash
git add lib/providers/classification_models.dart lib/providers/closet_providers.dart \
        test/providers/closet_providers_test.dart test/providers/closet_classification_test.dart \
        docs/work/TO_사용자결정.md
git commit -m "feat(closet): add classification drilldown providers (criterion/drilled-value/group-summary)"
```

**Review 체크포인트**: `compareNullableIndexLast`/`!ascending` 반전 로직이 스펙 §3.2 기본 표와 실제로 일치하는지, dead code(Step 2 자체검토에서 지적한 placeholder 줄)가 남아있지 않은지, `flutter analyze`/`flutter test` 클린 여부.

**Tester 불필요**(순수 로직, 아직 화면에 배선 안 됨 — Task 7에서 배선 후 런타임 검증).

---

## Task 4: 코디 classification providers

**Layer×Stage**: Logic/Feature × Implementation. TDD 대상.

**Files:**
- Modify: `lib/providers/composition_providers.dart`
- Modify: `test/providers/composition_providers_test.dart`
- Test: `test/providers/composition_classification_test.dart`

**Interfaces:**
- Consumes: `classification_models.dart`(Task 3의 `DrilledValue`/`ClassificationGroupSummary`/`compareNullableIndexLast`), `Composition.createdAt`/`weather`(Task 1).
- Produces: `CompositionSortCriterion`, `compositionSortCriterionProvider`, `compositionSortAscendingProvider`, `compositionDrilledYearProvider`, `compositionDrilledSeasonProvider`, `compositionDrilledWeatherProvider`, `compositionGroupSummariesProvider`, `compositionGridDisplayStateProvider`, `CompositionGridDisplayState`(Task 7이 소비).

- [ ] **Step 1: `composition_providers.dart`에 classification 로직 추가**

`lib/providers/composition_providers.dart` 전체를 다음으로 교체(`CompositionsNotifier`/`compositionsProvider`/`compositionsContainingItemProvider`/`compositionCoverImageProvider`는 기존 그대로 유지, `selectedCompositionSeasonFilterProvider`만 대체):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import 'classification_models.dart';
import 'closet_providers.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>((ref) => CompositionsNotifier());

/// 코디 메인 헤더 캡슐의 중분류 값. 순서가 곧 캡슐 드롭다운 항목 순서(스펙 §3.2).
enum CompositionSortCriterion { all, dateTime, season, weather }

extension CompositionSortCriterionX on CompositionSortCriterion {
  /// 캡슐 중분류 드롭다운 라벨 — `ClosetSortCriterionX.label`과 동일 패턴(Review 지적 P1).
  String get label => switch (this) {
        CompositionSortCriterion.all => '전체보기',
        CompositionSortCriterion.dateTime => '날짜·시간',
        CompositionSortCriterion.season => '계절',
        CompositionSortCriterion.weather => '날씨',
      };

  /// 코디는 "전체보기"만 소분류가 없다(스펙 §3.3 — 옷장의 "착용빈도"에 대응하는 게 없음).
  bool get hasSubClassification => this != CompositionSortCriterion.all;

  String get subClassificationHint => switch (this) {
        CompositionSortCriterion.dateTime => '연도',
        CompositionSortCriterion.season => '계절',
        CompositionSortCriterion.weather => '날씨',
        CompositionSortCriterion.all => throw StateError('소분류 없는 기준: $this'),
      };
}

final compositionSortCriterionProvider =
    StateProvider<CompositionSortCriterion>((ref) => CompositionSortCriterion.all);

/// 기본 false(내림차순) — 날짜는 "최신순". 계절/날씨는 §3.2 기본 표와 일치하도록 반전해서
/// 쓴다(`lib/providers/closet_providers.dart`의 동일 주석/`docs/work/TO_사용자결정.md` 참고).
final compositionSortAscendingProvider = StateProvider<bool>((ref) => false);

final compositionDrilledYearProvider = StateProvider<int?>((ref) => null);
final compositionDrilledSeasonProvider = StateProvider<DrilledValue<Season>?>((ref) => null);
final compositionDrilledWeatherProvider = StateProvider<DrilledValue<Weather>?>((ref) => null);

enum CompositionGridDisplayState { flat, groupOverview, drilledIn }

final compositionGridDisplayStateProvider = Provider<CompositionGridDisplayState>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  if (!criterion.hasSubClassification) return CompositionGridDisplayState.flat;
  final isDrilledIn = switch (criterion) {
    CompositionSortCriterion.season => ref.watch(compositionDrilledSeasonProvider) != null,
    CompositionSortCriterion.weather => ref.watch(compositionDrilledWeatherProvider) != null,
    CompositionSortCriterion.dateTime => ref.watch(compositionDrilledYearProvider) != null,
    CompositionSortCriterion.all => false,
  };
  return isDrilledIn ? CompositionGridDisplayState.drilledIn : CompositionGridDisplayState.groupOverview;
});

/// 삭제되지 않고, 현재 중분류의 소분류 필터에 맞는 코디를 현재 정렬 기준+방향으로 정렬.
final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  final ascending = ref.watch(compositionSortAscendingProvider);

  Iterable<Composition> items = ref.watch(compositionsProvider).where((c) => !c.isDeleted);

  switch (criterion) {
    case CompositionSortCriterion.season:
      final drilled = ref.watch(compositionDrilledSeasonProvider);
      if (drilled != null) {
        items = items.where((c) => c.season == drilled.value);
      }
    case CompositionSortCriterion.weather:
      final drilled = ref.watch(compositionDrilledWeatherProvider);
      if (drilled != null) {
        items = items.where((c) => c.weather == drilled.value);
      }
    case CompositionSortCriterion.dateTime:
      final year = ref.watch(compositionDrilledYearProvider);
      if (year != null) {
        items = items.where((c) => c.createdAt.year == year);
      }
    case CompositionSortCriterion.all:
      break;
  }

  final result = items.toList();
  if (criterion == CompositionSortCriterion.all) return result;

  result.sort((a, b) => switch (criterion) {
        CompositionSortCriterion.dateTime =>
          ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt),
        CompositionSortCriterion.season =>
          compareNullableIndexLast(a.season?.index, b.season?.index, ascending: !ascending),
        CompositionSortCriterion.weather =>
          compareNullableIndexLast(a.weather?.index, b.weather?.index, ascending: !ascending),
        CompositionSortCriterion.all => 0, // 도달하지 않음
      });
  return result;
});

final compositionGroupSummariesProvider = Provider<List<ClassificationGroupSummary>>((ref) {
  final criterion = ref.watch(compositionSortCriterionProvider);
  final ascending = ref.watch(compositionSortAscendingProvider);
  final items = ref.watch(compositionsProvider).where((c) => !c.isDeleted).toList();

  switch (criterion) {
    case CompositionSortCriterion.season:
      return _summarizeCompositions<Season>(
        items,
        keyOf: (c) => c.season,
        labelOf: (season) => season.label,
        indexOf: (season) => season.index,
        ascending: !ascending,
      );
    case CompositionSortCriterion.weather:
      return _summarizeCompositions<Weather>(
        items,
        keyOf: (c) => c.weather,
        labelOf: (weather) => weather.label,
        indexOf: (weather) => weather.index,
        ascending: !ascending,
      );
    case CompositionSortCriterion.dateTime:
      return _summarizeCompositionsByYear(items, ascending: ascending);
    case CompositionSortCriterion.all:
      return const [];
  }
});

/// 대표 이미지 — `coverImagePath`가 있으면 그대로, 없으면 첫 옷 이미지로 폴백
/// (`compositionCoverImageProvider`와 동일 폴백 규칙을 그룹 카드 썸네일에도 적용).
List<ClassificationGroupSummary> _summarizeCompositions<K>(
  List<Composition> items, {
  required K? Function(Composition) keyOf,
  required String Function(K) labelOf,
  required int Function(K) indexOf,
  required bool ascending,
}) {
  final groups = <K?, List<Composition>>{};
  for (final item in items) {
    groups.putIfAbsent(keyOf(item), () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      if (entry.value.isNotEmpty)
        ClassificationGroupSummary(
          label: entry.key == null ? '미분류' : labelOf(entry.key as K),
          thumbnailPaths: entry.value
              .take(4)
              .map((c) => c.coverImagePath ?? '')
              .where((path) => path.isNotEmpty)
              .toList(),
          count: entry.value.length,
          value: entry.key,
        ),
  ];
  summaries.sort((a, b) => compareNullableIndexLast(
        a.value == null ? null : indexOf(a.value as K),
        b.value == null ? null : indexOf(b.value as K),
        ascending: ascending,
      ));
  return summaries;
}

List<ClassificationGroupSummary> _summarizeCompositionsByYear(
  List<Composition> items, {
  required bool ascending,
}) {
  final groups = <int, List<Composition>>{};
  for (final item in items) {
    groups.putIfAbsent(item.createdAt.year, () => []).add(item);
  }
  final summaries = [
    for (final entry in groups.entries)
      ClassificationGroupSummary(
        label: '${entry.key}년',
        thumbnailPaths: entry.value
            .take(4)
            .map((c) => c.coverImagePath ?? '')
            .where((path) => path.isNotEmpty)
            .toList(),
        count: entry.value.length,
        value: entry.key,
      ),
  ];
  summaries.sort((a, b) {
    final ay = a.value as int;
    final by = b.value as int;
    return ascending ? ay.compareTo(by) : by.compareTo(ay);
  });
  return summaries;
}

/// 코디 메인 그리드 밀도 — `AppDensity.min/mid/max` 중 하나.
final compositionDensityProvider = StateProvider<int>((ref) => AppDensity.mid);

/// [itemId]를 포함하는(삭제되지 않은) Composition 목록 — 옷 상세 화면의
/// "연결된 코디" 크로스 레퍼런스 근거.
final compositionsContainingItemProvider = Provider.family<List<Composition>, String>((ref, itemId) {
  return ref
      .watch(compositionsProvider)
      .where((c) => !c.isDeleted && c.items.any((p) => p.clothingItemId == itemId))
      .toList();
});

/// [compositionId]의 표시용 커버 이미지 경로 — `Composition.coverImagePath`가 있으면 그대로,
/// 없으면 코디에 포함된 첫 번째 옷의 이미지로 폴백한다(둘 다 없으면 null).
final compositionCoverImageProvider = Provider.family<String?, String>((ref, compositionId) {
  final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
  if (composition.coverImagePath != null) return composition.coverImagePath;
  if (composition.items.isEmpty) return null;
  final closetItems = ref.watch(closetItemsProvider);
  final firstItemId = composition.items.first.clothingItemId;
  return closetItems.firstWhere((item) => item.id == firstItemId).imagePath;
});
```

(주의: `_summarizeCompositions`의 썸네일이 `coverImagePath ?? ''`로 빈 값을 필터링하는 건 그룹 카드 콜라주용 간이 처리다 — `compositionCoverImageProvider`처럼 "코디에 포함된 첫 옷 이미지로 폴백"까지 완전히 재현하려면 `ref`가 필요해 순수 함수로 못 뺀다. 이 폴백까지 필요한지는 Task 6의 `ClassificationGroupCard`가 빈 콜라주를 어떻게 그리는지에 달려 있음 — Task 6 Step 1의 `_ThumbnailCollage`가 빈 리스트를 placeholder 배경으로 처리하므로 지금은 문제없다.)

- [ ] **Step 2: 구 `selectedCompositionSeasonFilterProvider` 테스트 제거**

`test/providers/composition_providers_test.dart` 전체를 다음으로 교체(기존 유일한 테스트가 제거되는 provider를 쓰므로 파일이 사실상 비게 되나, `main()`은 남겨 향후 확장 지점을 유지):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('삭제된 코디는 filteredCompositionsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredCompositionsProvider).length;
    expect(before, container.read(compositionsProvider).length);
  });
}
```

- [ ] **Step 3: 신규 TDD 테스트 작성 후 통과 확인**

Create `test/providers/composition_classification_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/providers/composition_providers.dart';

void main() {
  test('전체보기는 항상 flat, 나머지 3개 기준은 소분류를 갖는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.all;
    expect(container.read(compositionGridDisplayStateProvider), CompositionGridDisplayState.flat);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    expect(container.read(compositionGridDisplayStateProvider), CompositionGridDisplayState.groupOverview);
  });

  test('계절 미분류로 드릴인하면 season이 null인 코디만 남는다(mock comp02)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.season;
    container.read(compositionDrilledSeasonProvider.notifier).state = const DrilledValue.unclassified();

    final result = container.read(filteredCompositionsProvider);
    expect(result, isNotEmpty);
    expect(result.every((c) => c.season == null), isTrue);
  });

  test('날씨 기준으로 드릴인하면 해당 Weather 값만 남는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    container.read(compositionDrilledWeatherProvider.notifier).state =
        const DrilledValue.value(Weather.rain);

    final result = container.read(filteredCompositionsProvider);
    expect(result, isNotEmpty);
    expect(result.every((c) => c.weather == Weather.rain), isTrue);
  });

  test('그룹 카드는 빈 그룹을 만들지 않는다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(compositionSortCriterionProvider.notifier).state = CompositionSortCriterion.weather;
    final summaries = container.read(compositionGroupSummariesProvider);

    expect(summaries.every((s) => s.count > 0), isTrue);
    expect(summaries.any((s) => s.label == '눈'), isFalse); // mock 데이터에 snow 없음
  });
}
```

Run: `flutter test test/providers/composition_classification_test.dart test/providers/composition_providers_test.dart -v`

Expected: 전부 PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/composition_providers.dart test/providers/composition_providers_test.dart \
        test/providers/composition_classification_test.dart
git commit -m "feat(composition): add classification drilldown providers (mirrors closet)"
```

**Review 체크포인트**: 옷장(Task 3)과 코디 provider 간 동형성(같은 헬퍼 재사용 여부), `flutter analyze`/`flutter test` 클린. **Tester 불필요**(Task 3과 동일 이유).

---

## Task 5: `ClassificationDrilldownCapsule` 위젯

**Layer×Stage**: UI/Screen × Implementation.

**Files:**
- Create: `lib/widgets/classification_drilldown_capsule.dart`
- Test: `test/widgets/classification_drilldown_capsule_test.dart`

**Interfaces:**
- Produces: `ClassificationDrilldownCapsule` — 옷장/코디 전용 enum 타입을 모르는 순수 프레젠테이션 위젯(인덱스 기반). Task 7이 소비.

- [ ] **Step 1: 위젯 작성**

Create `lib/widgets/classification_drilldown_capsule.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// 옷장/코디 메인 헤더의 "[중분류▾][소분류▾]" 2세그먼트 캡슐(스펙 §3.1).
///
/// 중분류/소분류 값의 실제 타입(옷장은 `ClosetSortCriterion`, 코디는
/// `CompositionSortCriterion`처럼 서로 다른 enum)을 이 위젯이 모르게 하고, 화면이
/// 인덱스↔enum 매핑과 라벨 문자열만 넘긴다 — 제네릭 타입 파라미터 2개를 위젯에 노출하는
/// 대신 화면이 매핑을 소유하는 방식(Worker 재량으로 명시된 지점 중 이 플랜이 확정한 선택).
///
/// **Header/HUD Pinned Rule과의 관계**: 이 캡슐은 "중분류"와 "소분류"라는 하나의 논리적
/// 컨트롤을 두 세그먼트로 표현한 것이지, 서로 독립적인 별개 컨트롤(예: 밀도 버튼+정렬
/// 버튼)을 인위적으로 합친 게 아니다 — 기존 계절 필터 pill(`GlassPill`+`DropdownButton`
/// 하나)이 이미 같은 성격이었으므로, 하나의 `GlassPill` 안에 두 `DropdownButton`을 두는
/// 것은 Pinned Rule이 금지하는 "서로 다른 의도의 컨트롤 병합"에 해당하지 않는다.
class ClassificationDrilldownCapsule extends StatelessWidget {
  const ClassificationDrilldownCapsule({
    super.key,
    required this.criterionLabels,
    required this.selectedCriterionIndex,
    required this.onCriterionChanged,
    required this.hasSubClassification,
    this.subHint,
    this.subOptionLabels = const [],
    this.selectedSubOptionIndex,
    this.onSubOptionSelected,
    this.onClearSubSelection,
  });

  /// 중분류 세그먼트 드롭다운 항목 라벨(순서=enum.values 순서, 화면이 보장).
  final List<String> criterionLabels;
  final int selectedCriterionIndex;
  final ValueChanged<int> onCriterionChanged;

  /// 현재 선택된 중분류가 소분류를 갖는지 — false면 소분류 세그먼트 자체를 숨기고
  /// 캡슐이 첫 세그먼트 크기로 줄어든다(스펙 §3.3).
  final bool hasSubClassification;

  /// 소분류 값 미선택(그룹 개요) 상태에서 보여줄 플레이스홀더(예: '계절').
  final String? subHint;

  /// 소분류 세그먼트 드롭다운 항목 라벨(그룹 값들 + 필요 시 '미분류', 화면이 순서 결정).
  final List<String> subOptionLabels;

  /// 소분류 값이 선택된 상태(드릴인)일 때 그 인덱스. null이면 미선택(그룹 개요).
  final int? selectedSubOptionIndex;

  final ValueChanged<int>? onSubOptionSelected;

  /// "전체 그룹 보기로" 되돌리기 — 드릴인 상태에서 소분류 세그먼트 최상단 항목으로 제공.
  final VoidCallback? onClearSubSelection;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: selectedCriterionIndex,
            underline: const SizedBox.shrink(),
            items: [
              for (var i = 0; i < criterionLabels.length; i++)
                DropdownMenuItem<int>(value: i, child: Text(criterionLabels[i])),
            ],
            onChanged: (value) {
              if (value != null) onCriterionChanged(value);
            },
          ),
          if (hasSubClassification) ...[
            const SizedBox(width: AppSpacing.xs),
            DropdownButton<int?>(
              value: selectedSubOptionIndex,
              hint: Text(subHint ?? ''),
              underline: const SizedBox.shrink(),
              items: [
                if (selectedSubOptionIndex != null)
                  const DropdownMenuItem<int?>(value: null, child: Text('전체 그룹 보기')),
                for (var i = 0; i < subOptionLabels.length; i++)
                  DropdownMenuItem<int?>(value: i, child: Text(subOptionLabels[i])),
              ],
              onChanged: (value) {
                if (value == null) {
                  onClearSubSelection?.call();
                } else {
                  onSubOptionSelected?.call(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 렌더 스모크 테스트**

Create `test/widgets/classification_drilldown_capsule_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/classification_drilldown_capsule.dart';

void main() {
  testWidgets('소분류가 없으면 두 번째 세그먼트가 렌더링되지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationDrilldownCapsule(
          criterionLabels: const ['전체보기', '착용빈도'],
          selectedCriterionIndex: 0,
          onCriterionChanged: (_) {},
          hasSubClassification: false,
        ),
      ),
    ));

    expect(find.text('전체보기'), findsOneWidget);
    expect(find.byType(DropdownButton<int?>), findsNothing);
  });

  testWidgets('소분류가 있으면 hint가 표시된다(미선택=그룹 개요 상태)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationDrilldownCapsule(
          criterionLabels: const ['전체보기', '옷 종류'],
          selectedCriterionIndex: 1,
          onCriterionChanged: (_) {},
          hasSubClassification: true,
          subHint: '종류',
          subOptionLabels: const ['상의', '하의', '미분류'],
        ),
      ),
    ));

    expect(find.text('종류'), findsOneWidget);
  });
}
```

Run: `flutter test test/widgets/classification_drilldown_capsule_test.dart -v`

Expected: 둘 다 PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/classification_drilldown_capsule.dart test/widgets/classification_drilldown_capsule_test.dart
git commit -m "feat(ui): add ClassificationDrilldownCapsule widget"
```

**Review 체크포인트**: `flutter-implementation-conventions`/`flutter-ui-reference` 스킬 체크리스트(터치 영역, 글래스모피즘 톤 일관성) 대조, Header/HUD Pinned Rule 관련 위젯 docstring의 논거가 타당한지. **Tester 불필요**(아직 화면 미배선).

---

## Task 6: `ClassificationGroupCard` + `ClassificationGroupGrid` 위젯

**Layer×Stage**: UI/Screen × Implementation.

**Files:**
- Create: `lib/widgets/classification_group_card.dart`
- Create: `lib/widgets/classification_group_grid.dart`
- Test: `test/widgets/classification_group_card_test.dart`

**Interfaces:**
- Consumes: `ClassificationGroupSummary`(Task 3), `AppGalleryGrid`(`lib/widgets/app_gallery_grid.dart`, 기존).
- Produces: `ClassificationGroupCard`, `ClassificationGroupGrid`. Task 7이 소비.

- [ ] **Step 1: 그룹 카드 위젯**

Create `lib/widgets/classification_group_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../providers/classification_models.dart';
import '../theme/app_spacing.dart';

/// 그룹 개요 상태의 폴더형 카드 — 소분류 값 하나에 속한 아이템들의 썸네일 콜라주 +
/// 라벨 + 개수(스펙 §3.1, "폰 갤러리 앱의 폴더 카드"). 빈 그룹은 애초에
/// `ClassificationGroupSummary` 목록에 안 들어오므로(provider 단계에서 필터링, Task 3/4)
/// 이 위젯은 항상 `count > 0`인 카드만 그린다.
class ClassificationGroupCard extends StatelessWidget {
  const ClassificationGroupCard({super.key, required this.summary, required this.onTap});

  final ClassificationGroupSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ThumbnailCollage(paths: summary.thumbnailPaths),
            Positioned(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.xxs),
                ),
                child: Text(
                  '${summary.label} · ${summary.count}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailCollage extends StatelessWidget {
  const _ThumbnailCollage({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    }
    if (paths.length == 1) {
      return Image.asset(paths.first, fit: BoxFit.cover);
    }
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final path in paths.take(4)) Image.asset(path, fit: BoxFit.cover)],
    );
  }
}
```

- [ ] **Step 2: 그룹 그리드 위젯**

Create `lib/widgets/classification_group_grid.dart`:

```dart
import 'package:flutter/material.dart';
import '../providers/classification_models.dart';
import 'app_gallery_grid.dart';
import 'classification_group_card.dart';

/// `List<ClassificationGroupSummary>` + [ClassificationGroupCard] 매핑 전용 어댑터 —
/// `GroupedGalleryGrid`/`CompositionGalleryGrid`와 동일한 얇은 어댑터 패턴.
class ClassificationGroupGrid extends StatelessWidget {
  const ClassificationGroupGrid({
    super.key,
    required this.groups,
    required this.density,
    required this.onGroupTap,
    this.controller,
    this.topSpacing = 0,
  });

  final List<ClassificationGroupSummary> groups;
  final int density;
  final void Function(ClassificationGroupSummary group) onGroupTap;
  final ScrollController? controller;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AppGalleryGrid(
      itemCount: groups.length,
      density: density,
      controller: controller,
      topSpacing: topSpacing,
      itemBuilder: (context, index) {
        final group = groups[index];
        return ClassificationGroupCard(
          key: ValueKey(group.label),
          summary: group,
          onTap: () => onGroupTap(group),
        );
      },
    );
  }
}
```

- [ ] **Step 3: 렌더 스모크 테스트**

Create `test/widgets/classification_group_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/classification_models.dart';
import 'package:digittal_wardrobe/widgets/classification_group_card.dart';

void main() {
  testWidgets('라벨과 개수를 함께 표시한다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationGroupCard(
          summary: const ClassificationGroupSummary(
            label: '상의',
            thumbnailPaths: [],
            count: 5,
            value: 'top',
          ),
          onTap: () {},
        ),
      ),
    ));

    expect(find.textContaining('상의'), findsOneWidget);
    expect(find.textContaining('5'), findsOneWidget);
  });

  testWidgets('탭하면 onTap이 호출된다', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassificationGroupCard(
          summary: const ClassificationGroupSummary(label: '미분류', thumbnailPaths: [], count: 1, value: null),
          onTap: () => tapped = true,
        ),
      ),
    ));

    await tester.tap(find.byType(ClassificationGroupCard));
    expect(tapped, isTrue);
  });
}
```

Run: `flutter test test/widgets/classification_group_card_test.dart -v`

Expected: 둘 다 PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/classification_group_card.dart lib/widgets/classification_group_grid.dart \
        test/widgets/classification_group_card_test.dart
git commit -m "feat(ui): add ClassificationGroupCard/Grid widgets for group-overview state"
```

**Review 체크포인트**: 빈 콜라주/1장/2장 이상 케이스 렌더 분기가 실제 자산 경로에서 깨지지 않는지(`Image.asset` 경로 유효성은 Tester가 실기기에서 확인). **Tester 불필요**(아직 화면 미배선).

---

## Task 7: 화면 배선 — 옷장/코디 메인 + `AppMainScaffold.groupingBar` 제거

**Layer×Stage**: UI/Screen × Implementation. **크기: XL** — Tester 통과 후 Audit 1회(`CLAUDE.md` §4/`Workflow_Project.md` §5).

**Files:**
- Modify: `lib/widgets/app_main_scaffold.dart`
- Modify: `lib/screens/closet_main_screen.dart`
- Modify: `lib/screens/composition_main_screen.dart`
- Modify: `test/widgets/app_main_scaffold_test.dart`
- Modify: `integration_test/header_hud_stack_architecture_test.dart`
- Modify: `integration_test/composition_style_log_main_screen_test.dart`
- Modify: `integration_test/selection_modal_test.dart`
- Modify (docstring/comment만, 로직 변경 없음): `integration_test/app_main_scaffold_shell_migration_test.dart`, `lib/screens/trash_main_screen.dart`, `lib/screens/settings_screen.dart` — 셋 다 `groupingBar`를 실제 파라미터로 넘기진 않지만 주석/docstring에서 언급하고 있어(Review 지적 P1, grep으로 확인됨) 슬롯 삭제 사실과 어긋나지 않게 정리.

**Interfaces:**
- Consumes: Task 2(`CategoryToggleDropdown`, 이미 자동 적용됨 — `AppMainScaffold`가 내부에서 호출), Task 3/4(모든 classification provider), Task 5(`ClassificationDrilldownCapsule`), Task 6(`ClassificationGroupGrid`).
- Produces: 없음(최종 배선 — 이 Task 이후 남은 소비자 없음).

이 Task는 `AppMainScaffold`의 공개 API(`groupingBar`/`groupingBarHeight` 삭제)를 바꾸므로, 이를 쓰는 두 화면과 관련 테스트를 **같은 커밋 경계** 안에서 함께 고쳐야 컴파일이 깨지지 않는다 — Step을 세분화하되 파일 간 미완료 중간 상태로 커밋하지 않는다(마지막 Step에서 한 번에 커밋).

- [ ] **Step 1: `AppMainScaffold`에서 `groupingBar` 슬롯 제거**

`lib/widgets/app_main_scaffold.dart`에서:
- 생성자(L39-51)의 `this.groupingBar,`/`this.groupingBarHeight = 0,` 두 줄 삭제.
- 필드 선언(L75-79)의 `groupingBar`/`groupingBarHeight` 두 필드와 그 docstring 삭제.
- `defaultGroupingBarHeight` 상수(L95-99) 삭제.
- `contentSpacerHeight`(L105-114)에서 `double groupingBarHeight = 0` 파라미터와 `if (groupingBarHeight > 0) height += rowGap + groupingBarHeight;` 줄 삭제 — 최종 시그니처:
  ```dart
  static double contentSpacerHeight({bool hasSecondaryRow = false}) {
    double height = rowGap + controlHeight; // Row 1
    if (hasSecondaryRow) height += rowGap + controlHeight; // Row 2
    height += rowGap; // 마지막 밴드와 실제 콘텐츠 사이 여백
    return height;
  }
  ```
- `build()` 메서드에서 `groupingBarTop` 계산 줄(L127)과 `if (groupingBar != null) Positioned(...)` 블록(L206-207) 삭제. `lastRowBottom`(L126)은 그대로 유지(더 이상 `groupingBarTop` 계산에 안 쓰이지만 다른 곳에서 안 쓰인다면 이 줄 자체도 삭제 — Worker가 실제 참조 여부 확인 후 정리).
- 클래스 docstring(L9-37)에서 "그룹형 드릴다운 바" 관련 서술(L9, L33-37)을 제거하거나 "이 슬롯은 삭제됨(2026-07-19, 화면별 캡슐로 대체)"로 갱신.

- [ ] **Step 2: `closet_main_screen.dart` 배선**

`lib/screens/closet_main_screen.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/classification_drilldown_capsule.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/expandable_add_fab.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/selection_aware_header_actions.dart';

/// [selectionMode]가 true면 별도 화면을 새로 만들지 않고 이 Main 화면을 "선택 모달"로
/// 재호출한다 — 기능 재사용 원칙(`_공통 규칙.md`), 표는
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 "선택 모달(옷장/
/// 코디 재호출)" 행. 뒤로가기/카테고리 토글/FAB은 숨기고 헤더 우상단은 "선택"(다중선택)
/// 대신 닫기(X) 버튼으로 바뀐다. 분류 기준 캡슐은 원 화면과 동일 사양으로 유지된다(표에
/// 명시된 예외).
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
    // provider의 raw ascending은 옷종류/계절에서 반전되어 쓰인다(Task 3 참고) — 버튼
    // 아이콘/툴팁·사용자에게 보이는 의미는 항상 이 값을 써야 실제 정렬 방향과 일치한다.
    final effectiveAscending = switch (criterion) {
      ClosetSortCriterion.clothingType || ClosetSortCriterion.season => !ascending,
      _ => ascending,
    };
    final displayState = ref.watch(closetGridDisplayStateProvider);
    final density = ref.watch(closetDensityProvider);

    final singleLabel = criterion == ClosetSortCriterion.all ? '한 장 추가하기' : '이 분류에 한 장 추가하기';
    final multiLabel = criterion == ClosetSortCriterion.all ? '여러 장 추가하기' : '이 분류에 여러 장 추가하기';

    // Content Spacer(스펙 §4) — Row1(카테고리 토글/선택) + Row2(캡슐/밀도/◎ 스텁) 높이만
    // 합산한다(groupingBar 밴드는 삭제됨 — 캡슐은 Row2 안의 floating pill이라 별도 밴드가
    // 필요 없음).
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.closet,
      showBackButton: !widget.selectionMode,
      showCategoryToggle: !widget.selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: widget.selectionMode,
        onClose: () => context.pop(),
      ),
      secondaryControlsLeft: [
        ClassificationDrilldownCapsule(
          criterionLabels: [for (final c in ClosetSortCriterion.values) c.label],
          selectedCriterionIndex: criterion.index,
          onCriterionChanged: (index) =>
              ref.read(closetSortCriterionProvider.notifier).state = ClosetSortCriterion.values[index],
          hasSubClassification: criterion.hasSubClassification,
          subHint: criterion.hasSubClassification ? criterion.subClassificationHint : null,
          subOptionLabels: _subOptionLabels(ref, criterion),
          selectedSubOptionIndex: _selectedSubOptionIndex(ref, criterion),
          onSubOptionSelected: (index) => _drillInto(ref, criterion, index),
          onClearSubSelection: () => _clearDrilldown(ref, criterion),
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(closetDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
            ref.read(closetDensityProvider.notifier).state = AppDensity.levels[previousIndex];
          },
        ),
        // 아이콘/툴팁은 "화면에 실제로 보이는 순서"(effectiveAscending) 기준 — 옷종류/계절은
        // provider의 raw ascending을 반전해서 쓰므로(Task 3의 !ascending 트릭), 버튼 라벨도
        // 반전 없이 raw 값을 쓰면 실제 정렬 방향과 어긋난다(Review 지적 P0, 직접 시뮬레이션으로
        // 확인됨). 날짜/착용빈도는 반전이 없어 raw==effective.
        GlassCircleButton(
          icon: effectiveAscending ? Icons.arrow_upward : Icons.arrow_downward,
          tooltip: effectiveAscending ? '오름차순' : '내림차순',
          onTap: () => ref.read(closetSortAscendingProvider.notifier).state = !ascending,
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) {
          if (displayState == ClosetGridDisplayState.groupOverview) {
            final groups = ref.watch(closetGroupSummariesProvider);
            return ClassificationGroupGrid(
              groups: groups,
              density: density,
              controller: controller,
              topSpacing: contentTopSpacing,
              onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
            );
          }
          final items = ref.watch(filteredClosetItemsProvider);
          return GroupedGalleryGrid(
            items: items,
            density: density,
            controller: controller,
            topSpacing: contentTopSpacing,
            onItemTap: (item) {
              if (widget.selectionMode) {
                widget.onItemSelected?.call(item.id);
              } else {
                context.push(AppRoute.closetItemDetail.replaceFirst(':id', item.id));
              }
            },
            onIncompleteTap: widget.selectionMode ? (item) => context.push(AppRoute.closetAdd) : null,
          );
        },
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : ExpandableAddFab(
              options: [
                ExpandableAddFabOption(label: singleLabel, onTap: () => context.push(AppRoute.closetAdd)),
                ExpandableAddFabOption(label: multiLabel, onTap: () => context.push(AppRoute.closetAdd)),
              ],
            ),
    );
  }

  // 날짜·시간의 소분류(연도)는 고정 옵션이 아니라 실제 데이터에서 나온 그룹 목록이라,
  // closetGroupSummariesProvider를 그대로 라벨 소스로 쓴다 — 그룹 카드 탭과 드롭다운 직접
  // 선택이 정확히 같은 순서/값 집합을 참조하게 되어(스펙 §3.1 "두 진입 경로가 같은 상태로
  // 수렴한다") 드릴인 후 캡슐 텍스트도 자동으로 맞아떨어진다(Review 지적 P0 해결).
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

  /// 그룹 카드를 직접 탭했을 때 — [group.value]가 이미 실제 enum 값(또는 미분류=null)이라
  /// `_drillInto`의 인덱스 변환 없이 바로 세팅한다(스펙 §3.1 "두 진입 경로가 같은 상태로
  /// 수렴한다").
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

(날짜·시간 기준의 소분류(연도)는 고정 enum이 아니라 실제 데이터에서 나온 값이라, `_subOptionLabels`/`_selectedSubOptionIndex`/`_drillInto`가 `closetGroupSummariesProvider`를 라벨/인덱스 소스로 공유한다 — 그룹 카드 탭과 캡슐 드롭다운 직접 선택 둘 다 같은 provider(`closetDrilledYearProvider`)를 갱신하므로 스펙 §3.1 "두 진입 경로가 같은 상태로 수렴한다"를 그대로 만족한다.)

- [ ] **Step 3: `composition_main_screen.dart` 배선**

`lib/screens/composition_main_screen.dart` 전체를 다음으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/classification_models.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/classification_drilldown_capsule.dart';
import '../widgets/classification_group_grid.dart';
import '../widgets/composition_gallery_grid.dart';
import '../widgets/glass_circle_button.dart';
import '../widgets/selection_aware_header_actions.dart';

/// Main-그룹형(옷장 메인과 동일 페이지 타입) — `closet_main_screen.dart` 패턴을 그대로 이식.
///
/// [selectionMode]가 true면 이 화면이 "선택 모달(코디 재호출)"로 동작한다 — 타일 탭 시
/// `context.pop(composition.id)`로 결과를 반환한다.
class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criterion = ref.watch(compositionSortCriterionProvider);
    final ascending = ref.watch(compositionSortAscendingProvider);
    // closet_main_screen.dart와 동일한 이유(raw ascending이 계절/날씨에서 반전되어 쓰임)로
    // 버튼 라벨은 항상 이 값을 쓴다(Review 지적 P0).
    final effectiveAscending = switch (criterion) {
      CompositionSortCriterion.season || CompositionSortCriterion.weather => !ascending,
      _ => ascending,
    };
    final displayState = ref.watch(compositionGridDisplayStateProvider);
    final density = ref.watch(compositionDensityProvider);

    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.composition,
      showBackButton: !selectionMode,
      showCategoryToggle: !selectionMode,
      headerActions: buildSelectionAwareHeaderActions(
        selectionMode: selectionMode,
        onClose: () => context.pop(),
      ),
      secondaryControlsLeft: [
        ClassificationDrilldownCapsule(
          criterionLabels: [for (final c in CompositionSortCriterion.values) c.label],
          selectedCriterionIndex: criterion.index,
          onCriterionChanged: (index) => ref.read(compositionSortCriterionProvider.notifier).state =
              CompositionSortCriterion.values[index],
          hasSubClassification: criterion.hasSubClassification,
          subHint: criterion.hasSubClassification ? criterion.subClassificationHint : null,
          subOptionLabels: _subOptionLabels(ref, criterion),
          selectedSubOptionIndex: _selectedSubOptionIndex(ref, criterion),
          onSubOptionSelected: (index) => _drillInto(ref, criterion, index),
          onClearSubSelection: () => _clearDrilldown(ref, criterion),
        ),
      ],
      secondaryControlsRight: [
        GlassCircleButton(
          icon: AppDensity.iconFor(density),
          tooltip: '그리드 밀도 전환',
          onTap: () {
            final current = ref.read(compositionDensityProvider);
            final currentIndex = AppDensity.levels.indexOf(current);
            final previousIndex = currentIndex - 1 < 0 ? AppDensity.levels.length - 1 : currentIndex - 1;
            ref.read(compositionDensityProvider.notifier).state = AppDensity.levels[previousIndex];
          },
        ),
        GlassCircleButton(
          icon: effectiveAscending ? Icons.arrow_upward : Icons.arrow_downward,
          tooltip: effectiveAscending ? '오름차순' : '내림차순',
          onTap: () => ref.read(compositionSortAscendingProvider.notifier).state = !ascending,
        ),
      ],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) {
          if (displayState == CompositionGridDisplayState.groupOverview) {
            final groups = ref.watch(compositionGroupSummariesProvider);
            return ClassificationGroupGrid(
              groups: groups,
              density: density,
              controller: controller,
              topSpacing: contentTopSpacing,
              onGroupTap: (group) => _drillIntoValue(ref, criterion, group.value),
            );
          }
          final compositions = ref.watch(filteredCompositionsProvider);
          return CompositionGalleryGrid(
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
          );
        },
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoute.compositionEditor),
              child: const Icon(Icons.add),
            ),
    );
  }

  // closet_main_screen.dart와 동일한 이유로 날짜·시간(연도)은 closetGroupSummariesProvider의
  // 코디 버전(compositionGroupSummariesProvider)을 라벨/인덱스 소스로 공유한다.
  List<String> _subOptionLabels(WidgetRef ref, CompositionSortCriterion criterion) {
    return switch (criterion) {
      CompositionSortCriterion.season => [for (final season in Season.values) season.label, '미분류'],
      CompositionSortCriterion.weather => [for (final weather in Weather.values) weather.label, '미분류'],
      CompositionSortCriterion.dateTime => [
          for (final group in ref.watch(compositionGroupSummariesProvider)) group.label,
        ],
      CompositionSortCriterion.all => const [],
    };
  }

  int? _selectedSubOptionIndex(WidgetRef ref, CompositionSortCriterion criterion) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        final drilled = ref.watch(compositionDrilledSeasonProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Season.values.length : Season.values.indexOf(drilled.value as Season);
      case CompositionSortCriterion.weather:
        final drilled = ref.watch(compositionDrilledWeatherProvider);
        if (drilled == null) return null;
        return drilled.isUnclassified ? Weather.values.length : Weather.values.indexOf(drilled.value as Weather);
      case CompositionSortCriterion.dateTime:
        final year = ref.watch(compositionDrilledYearProvider);
        if (year == null) return null;
        final groups = ref.watch(compositionGroupSummariesProvider);
        final index = groups.indexWhere((g) => g.value == year);
        return index == -1 ? null : index;
      default:
        return null;
    }
  }

  void _drillInto(WidgetRef ref, CompositionSortCriterion criterion, int optionIndex) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state = optionIndex == Season.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Season.values[optionIndex]);
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state = optionIndex == Weather.values.length
            ? const DrilledValue.unclassified()
            : DrilledValue.value(Weather.values[optionIndex]);
      case CompositionSortCriterion.dateTime:
        final groups = ref.read(compositionGroupSummariesProvider);
        ref.read(compositionDrilledYearProvider.notifier).state = groups[optionIndex].value as int;
      default:
        break;
    }
  }

  void _drillIntoValue(WidgetRef ref, CompositionSortCriterion criterion, Object? value) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Season);
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state =
            value == null ? const DrilledValue.unclassified() : DrilledValue.value(value as Weather);
      case CompositionSortCriterion.dateTime:
        ref.read(compositionDrilledYearProvider.notifier).state = value as int?;
      case CompositionSortCriterion.all:
        break;
    }
  }

  void _clearDrilldown(WidgetRef ref, CompositionSortCriterion criterion) {
    switch (criterion) {
      case CompositionSortCriterion.season:
        ref.read(compositionDrilledSeasonProvider.notifier).state = null;
      case CompositionSortCriterion.weather:
        ref.read(compositionDrilledWeatherProvider.notifier).state = null;
      case CompositionSortCriterion.dateTime:
        ref.read(compositionDrilledYearProvider.notifier).state = null;
      case CompositionSortCriterion.all:
        break;
    }
  }
}
```

- [ ] **Step 4: 관련 테스트 정리**

- `test/widgets/app_main_scaffold_test.dart`: `groupingBar`/`groupingBarHeight` 파라미터를 넘기거나 검증하는 테스트 그룹(연구 결과 L173-196, L210-219 부근)을 제거. `contentSpacerHeight`의 `groupingBarHeight` 인자를 넘기는 호출부는 인자 없이 호출하도록 수정.
- `integration_test/header_hud_stack_architecture_test.dart`: groupingBar 배치 회귀 전용 테스트(연구 결과 L91-95, L251-281, L293-296)를 제거 — 이 밴드 자체가 없어졌으므로 회귀 대상이 아님.
- `integration_test/composition_style_log_main_screen_test.dart`: "groupingBar skeleton, mock 코디 2개"(L82) 관련 assertion 문구/기대값을 실제 캡슐 렌더링에 맞게 수정. 스타일일지 쪽의 "groupingBar 자리 자체가 없다"(L228)는 여전히 유효하므로 그대로 둔다.
- `integration_test/selection_modal_test.dart`: "groupingBar는 그대로 노출된다"(L50, L134, L166) 문구를 "분류 기준 캡슐은 그대로 노출된다"로, 검증 대상 위젯을 `ClassificationDrilldownCapsule`로 수정.
- `integration_test/app_main_scaffold_shell_migration_test.dart`, `lib/screens/trash_main_screen.dart`, `lib/screens/settings_screen.dart`: `groupingBar`를 언급하는 주석/docstring을 찾아(실제 파라미터로 넘기는 곳은 없음 — 컴파일엔 영향 없음) "이 슬롯은 삭제됨" 또는 무관한 서술로 정리.

(각 파일의 정확한 현재 내용은 Worker가 실제로 읽고 수정 — 위 줄번호는 계획 수립 시점의 조사 결과라 실제 작업 시 어긋날 수 있음, 텍스트/의도 기준으로 찾아 고칠 것.)

- [ ] **Step 5: 전체 회귀 검증**

Run: `flutter analyze && flutter test`

Expected: 컴파일 에러 없음, 전체 단위/위젯 테스트 PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/app_main_scaffold.dart lib/screens/closet_main_screen.dart \
        lib/screens/composition_main_screen.dart test/widgets/app_main_scaffold_test.dart \
        integration_test/header_hud_stack_architecture_test.dart \
        integration_test/composition_style_log_main_screen_test.dart \
        integration_test/selection_modal_test.dart
git commit -m "feat(main-screens): wire classification drilldown capsule + 3-state grid, remove groupingBar slot"
```

**Review 체크포인트**: `flutter analyze`/`flutter test` 클린, `AppMainScaffold` 공개 API 변경이 다른 소비자(Detail 화면 등)에 영향 없는지(`groupingBar: null` 기본값에 의존하던 곳이 없어야 함 — grep으로 `groupingBar` 잔존 참조 전수 확인), 두 화면의 그룹 카드 탭↔소분류 드롭다운 값 동기화 로직이 실제로 동일 provider를 가리키는지.

**Tester 체크포인트**(런타임 동작 다수, 이 Task의 핵심 검증):
1. 옷장 메인: 중분류를 "옷 종류"로 바꾸면 그룹 개요(폴더 카드)로 전환되는지, 카드 탭 시 드릴인되어 소분류 드롭다운 텍스트도 동기화되는지, "전체 그룹 보기"로 되돌아가는지.
2. 옷장 메인: "옷 종류" 미분류 카드(mock c12) 탭 → category null인 아이템만 나오는지.
3. 코디 메인: "날씨" 기준 동일 3상태 전환 + "계절" 미분류 카드(mock comp02) 확인.
4. 정렬 방향 버튼(◎→↑/↓ 아이콘) 탭 시 실제 그리드/그룹카드 순서가 바뀌는지 — §3.2 기본 표와 일치하는 기본 방향인지 스크린샷/실측으로 확인(Task 3의 TO 문서 항목과 연결).
5. `selectionMode`(옷장/코디 선택 모달)에서도 캡슐이 동일하게 노출되는지.
6. `flutter analyze` 미등재 경고 없이 실행되는지.

Tester가 새 통합테스트 파일(예: `integration_test/classification_drilldown_test.dart`) 작성. Tester 통과 후 **Audit 1회** 실행(XL 크기).

---

## Task 8: 문서 갱신 — `04_설정.md` 각주 + `Decision.md` override 기록

**Layer×Stage**: 이 Task는 Worker에게 위임하지 않고 **PM(이 세션)이 직접 수정**한다 — `CLAUDE.md` "결정문서 diff 확인" 원칙(`docs/history/*`, `docs/reference/**` 수정은 항상 일반 Edit 승인 흐름).

**Files:**
- Modify: `docs/reference/plan/03_화면별UX명세서/04_설정.md`
- Modify: `docs/history/Decision.md`

- [ ] **Step 1**: `04_설정.md` §1(L12) 제목 바로 아래에 정정 각주 삽입:

```markdown
> **[정정, 2026-07-19]** 아래 §1 전체(프로필 아이콘 진입점)는
> `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md` §2로
> 대체되었다 — 최종 목업에 프로필 아이콘이 없고, 설정 진입점은 `CategoryToggleDropdown`(옷장/
> 코디/스타일일지 헤더 좌측 드롭다운) 메뉴 최하단으로 이동했다. 아래 원문은 이전 결정 기록으로
> 보존한다.
```

- [ ] **Step 2**: `Decision.md` 최상단(L1 주석 바로 아래)에 override 항목 추가 — 위 두 예시(L792-813, L815-831) 포맷을 따라 제목에 `(UI/Screen, Decision)` 태그, 배경에 대체 대상(`04_설정.md` §1, `2026-07-12-cross-screen-ui-shell-design.md`의 그룹형 드릴다운 설계) 명시, Impact에 Task 1~7의 실제 변경 파일 나열.

- [ ] **Step 3**: `git add docs/reference/plan/03_화면별UX명세서/04_설정.md docs/history/Decision.md && git commit -m "docs: record classification-drilldown spec as override of settings entry-point and grouped-drilldown decisions"`

---

## Self-Review 결과 (작성 완료 후 재점검)

1. **스펙 커버리지**: §1(스코프)→모든 Task 헤더, §2(설정 진입점)→Task 2, §3.1~3.4(캡슐/3상태/정렬)→Task 3/4/5/7, §3.5(모델)→Task 1, §3.6(provider)→Task 3/4, §3.7(그룹카드)→Task 3/4/6, §4(영향범위)→File Structure 전체, §5(테스트전략)→각 Task Interfaces/Tester 체크포인트, §6(스코프 제외)→Global Constraints. 누락 없음.
2. **Placeholder 스캔**: 초안에 있던 dead-code 줄(`_summarizeByYear`의 placeholder `sort` 호출)은 제거했다(review 1차 검토 P2 반영, 지시문 대신 코드 자체를 정리).
3. **타입 일관성**: `ClosetSortCriterion`/`CompositionSortCriterion`의 `.index` 순서가 캡슐 `criterionLabels`(이제 `.label` getter로 생성, 하드코딩 리스트 아님) 및 `_subOptionLabels`/`_drillInto`의 인덱스 매핑과 전부 일치. `DrilledValue<T>`/`ClassificationGroupSummary`/`compareNullableIndexLast` 네이밍이 Task 3→4→6→7에서 동일하게 쓰임.
4. **review 서브에이전트 1차 검토(2026-07-19) 반영 내역** — P0 2건/P1 2건/P2 1건, 전부 이 플랜 본문에 직접 반영 완료:
   - **P0**: 정렬 토글 버튼의 아이콘/툴팁이 raw `ascending`을 그대로 썼던 것을, `effectiveAscending`(옷종류/계절/날씨는 반전, 날짜/착용빈도는 그대로)으로 계산해 실제 정렬 방향과 항상 일치하도록 수정(Task 7 두 화면 모두).
   - **P0**: 날짜·시간(연도) 기준에서 그룹 카드 드릴인 시 캡슐 소분류 텍스트가 갱신 안 되던 것을, `_subOptionLabels`/`_selectedSubOptionIndex`/`_drillInto`가 `closetGroupSummariesProvider`/`compositionGroupSummariesProvider`를 라벨·인덱스 소스로 공유하도록 수정 — 두 진입 경로가 실제로 같은 provider를 갱신해 스펙 §3.1 "수렴한다" 요구를 만족.
   - **P1**: `ClosetSortCriterion`/`CompositionSortCriterion`에 다른 폐쇄 어휘 enum과 동일한 `.label` getter를 추가하고, 화면의 하드코딩 병렬 String 리스트(`_closetCriterionLabels` 등)를 제거해 `[for (c in X.values) c.label]`로 대체.
   - **P1**: Task 7 Files 목록에 `groupingBar`를 주석으로만 언급하는 3개 파일(`app_main_scaffold_shell_migration_test.dart`/`trash_main_screen.dart`/`settings_screen.dart`) 추가.
   - 정렬 방향(`ascending`)의 "기본이 §3.2 표와 일치하도록 반전" 해석 자체는 review도 "직접 시뮬레이션해 확인함, 초기값은 표와 일치"라고 검증했으나 여전히 스펙에 명시되지 않은 판단이라 `docs/work/TO_사용자결정.md` 기록은 유지.
   - 캡슐이 하나의 `GlassPill`에 두 세그먼트를 담는 것(Header/HUD Pinned Rule과의 관계) — review가 별도 이슈로 제기하지 않음, 스펙이 Worker 재량으로 이미 위임한 범위라 TO 문서에는 올리지 않음.
   - `_summarizeCompositions`의 그룹 카드 썸네일이 `compositionCoverImageProvider`의 "첫 옷 이미지 폴백"을 완전히 재현하지 못하는 것(순수 함수라 `ref` 접근 불가) — review가 별도 이슈로 제기하지 않음, Task 4 Step 1 각주에 한계 명시된 채로 유지(Tester 실측 시 어색하면 후속 조정).
5. **2차 검토**: 위 수정 반영 후 review 서브에이전트에게 다시 확인시키지는 않음(PM이 직접 수정 내용을 review의 지적사항과 1:1 대조해 커버리지 확인 완료) — Task 3/7 실제 구현 단계의 정식 Review 사이클에서 한 번 더 걸러진다.
