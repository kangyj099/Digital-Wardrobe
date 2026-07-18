# 옷장·코디 메인 헤더 — 분류 기준 드릴다운 캡슐 + 설정 진입점 이동 Design

**작성일**: 2026-07-19

**배경**: `docs/work/BACKLOG.md`가 지정한 "Step⑦ 나머지 스코프" 중 "그룹형 드릴다운 실배선(옷장/코디 메인 2곳)"과 "설정 진입점 연결"을 브레인스토밍한 결과. 사용자가 제공한 최종 확정 목업(`참고자료/목업/옷장 메인/옷장-메인.png` + 동명 `.html` 인터랙션 프로토타입)을 실제 소스로 삼아, 기존에 이 저장소에 있던 `2026-07-12-cross-screen-ui-shell-design.md`의 "그룹형 드릴다운" 설계(3단계 `GroupedMainViewMode` enum, 계절 전용, 별도 전체폭 밴드)를 **대체**한다 — 그 설계는 실제 목업과 맞지 않는 것으로 확인됨(별도 밴드 없음, 계절 외에도 여러 분류 기준 존재).

**승인된 `04_설정.md`(2026-07-09 Design Review)와의 관계**: §1 "진입점 — 프로필 아이콘" 조항을 이 문서가 대체한다. 최종 목업엔 프로필 아이콘이 없고(grep 확인: "프로필"/"설정"/"Settings"/톱니 아이콘 0건), 사용자가 설정 진입점을 카테고리 드롭다운 내부로 재배치하기로 확정(2026-07-19). `04_설정.md` §1엔 이 사실을 반영하는 정정 각주를 추가하고, `docs/history/Decision.md`에도 override로 기록한다(이 스펙 승인 후, Task 8~15 폐기 때와 동일한 패턴 — 원본 문서는 보존, 상단에 대체 각주만 추가).

---

## 1. 스코프

- **대상 화면**: 옷장 메인(`closet_main_screen.dart`), 코디 메인(`composition_main_screen.dart`) — 둘 다 "Main-그룹형" 페이지 타입.
- **스타일일지 메인은 범위 밖**: "Main-플랫+필터형" 페이지 타입이라 이 캡슐 UI 자체가 붙지 않음(`00_페이지 타입 정의.md`). 스타일일지의 날짜/계절/날씨 필터는 별도 필터 칩(C3 FlatFilterGallery) 몫 — 이번 스펙에 포함하지 않음.
- **색상 분류 기준은 이번 라운드 제외**: `_공통 규칙.md` "분류 기준별 정렬 기준표"가 "색상환 기준(세부 색상 순서는 5단계 컬러 팔레트 확정 시 정의)"라고 스펙 자체에 미확정으로 남겨둠 — 팔레트 확정 전까지 착수 불가. 옷장 중분류 목록에 이번엔 넣지 않는다(향후 팔레트 확정 시 추가만 하면 되는 구조로 설계).
- 헤더 좌측 카테고리 드롭다운(`CategoryToggleDropdown`)에 "설정" 진입 항목 추가.

---

## 2. 설정 진입점 이동

### 결정

프로필 아이콘 진입점(`04_설정.md` §1)을 폐기하고, `CategoryToggleDropdown`(옷장/코디/스타일일지 헤더 좌측 드롭다운)의 메뉴 최하단에 구분선 + 작은 폰트로 "설정" 항목을 추가한다 — 3개 Main 화면이 이 위젯을 공유하므로 자동으로 전 화면에 동일 적용된다.

### 동작

- 메뉴 구성: `옷장 / 코디 / 스타일일지` (기존 3개, `AppCategory` 그대로) — 구분선(`PopupMenuDivider` 또는 동등물) — `설정`(작은 폰트, 예: `labelSmall` 또는 `bodySmall` — 카테고리 항목보다 한 단계 작게).
- "설정" 탭 시 `context.push(AppRoute.settingsMain)` — 카테고리 전환(`context.go()`)과 달리 **push**를 쓴다. 이유: `SettingsScreen`이 이미 `showBackButton` 기본값(true)으로 만들어져 있어 뒤로가기로 원래 화면에 복귀하는 걸 전제하고, Settings는 카테고리와 동렬의 "전환 대상"이 아니라 위로 진입하는 유틸리티 화면이기 때문(기존 Detail/Editor 화면들과 동일한 네비게이션 성격).
- "설정" 항목은 `current`(현재 카테고리) 상태에 영향을 주지 않는다 — 탭해도 드롭다운에 표시되는 현재 카테고리 라벨은 그대로 유지.

### 구현 메모 (Worker 재량, 스펙은 계약만 명시)

`DropdownButton<AppCategory>`는 `value`와 동일 타입의 항목만 담을 수 있어 "설정"(비-카테고리 액션)을 자연스럽게 못 담는다. `PopupMenuButton` 또는 커스텀 오버레이 메뉴로 교체가 필요할 가능성이 높음 — 정확한 위젯 선택은 Worker가 기존 글래스모피즘 톤(`GlassPill`)과의 시각적 일관성을 유지하는 선에서 결정.

### 04_설정.md 개정

§1 전체(진입점을 프로필 아이콘으로 규정한 부분)에 이 문서를 가리키는 정정 각주 추가. §4 "Trash 통합 — 스코프 아웃"은 이번 스펙에서 다루지 않음(별도 Group, 휴지통 실행 작업 때 재검토).

---

## 3. 분류 기준 드릴다운 캡슐 (옷장/코디 메인)

### 3.1 UI 구조

Row 2의 기존 계절 필터 pill 자리를, **`[중분류 ▾][소분류 ▾]`** 2세그먼트 캡슐로 확장한다. 별도 전체폭 밴드가 아니다 — `AppMainScaffold`의 `groupingBar` 슬롯(현재 skeleton)은 **사용하지 않고 삭제**한다(`closet_main_screen.dart`/`composition_main_screen.dart`의 `groupingBar: skeletonRegion(...)` 호출 제거, `contentSpacerHeight`의 `groupingBarHeight` 인자도 제거).

- **중분류**(분류 기준 선택): 항상 노출.
- **소분류**(그 기준 내 세부 값 선택): 중분류가 "세부 값을 갖는" 기준일 때만 노출. 세부 값이 없는 기준(아래 "전체보기"/"착용빈도")을 고르면 캡슐이 첫 세그먼트 크기로 줄어들고 소분류 세그먼트는 사라진다.

**메인 그리드는 3가지 상태를 가진다** (소분류가 있는 중분류를 고른 경우, 소분류 세그먼트의 선택 여부로 갈림 — 별도로 추적하는 상태값이 아니라 `(중분류, 소분류값)` 조합에서 그대로 파생됨):

1. **플랫**(`flat`): 중분류가 "전체보기" 또는 "착용빈도"(소분류 없는 기준)일 때. 기존과 동일하게 아이템 타일이 그대로 나열됨.
2. **그룹 개요**(`groupOverview`): 소분류가 있는 중분류를 골랐지만 아직 소분류 값은 안 고른 상태. 소분류 세그먼트엔 아직 특정 값이 아니라 **플레이스홀더 텍스트 "소분류"** 가 표시된다(계절 필터의 기존 `hint: '계절'` 패턴과 동일). 이때 메인 그리드는 아이템 타일이 아니라, 폰 갤러리 앱의 폴더 카드처럼 **소분류 값별로 묶은 그룹 카드**를 보여준다(카드 하나 = 그 소분류 값에 속한 아이템들의 썸네일 콜라주 + 그룹 라벨 + 개수). 아이템이 0개인 소분류 값은 카드 자체를 만들지 않는다(빈 폴더를 보여주지 않음 — 갤러리 앱 관례).
3. **드릴인**(`drilledIn`): 그룹 카드를 탭했거나, 소분류 세그먼트에서 직접 값을 골랐을 때. 메인 그리드가 그 교집합(중분류=X ∩ 소분류=Y)의 아이템 타일 플랫 목록으로 전환된다(폰 갤러리에서 폴더를 펼친 것과 동일한 느낌 — 전환 애니메이션은 Worker 재량, 필수 아님).

**두 진입 경로가 같은 상태로 수렴한다**: 그룹 카드를 탭하는 것과 소분류 드롭다운에서 값을 직접 고르는 것 둘 다 동일한 소분류 provider를 갱신한다 — 그래서 그룹 카드로 드릴인해도 소분류 세그먼트 텍스트가 자동으로 그 값으로 바뀐다(별도 동기화 로직 불필요, 같은 상태를 읽고 쓰는 것뿐). 반대로 소분류 세그먼트를 다시 "미선택"으로 되돌리는 UI(예: 그룹 개요로 복귀하는 뒤로가기/칩의 X)도 필요 — 이 캡슐 자체나 그리드 상단에 작은 "전체 그룹 보기로" 버튼/칩으로 제공한다(정확한 배치는 Worker 재량).

### 3.2 화면별 중분류 목록

**옷장** (`ClosetSortCriterion`):

| 값 | 소분류(세부 값) | 데이터 소스 |
|---|---|---|
| 전체보기 | 없음(캡슐 축소) | — |
| 날짜·시간 | 연도 | `ClothingItem.createdAt`(신설) |
| 옷 종류 | `ClothingCategory` 8종 | 기존 필드, 이미 착용순서로 선언돼 있어 추가 매핑 불필요 |
| 계절 | `Season` 3종 | 기존 필드 |
| 착용빈도 | 없음(캡슐 축소, 정렬 전용) | 기존 `wearCount` |

**코디** (`CompositionSortCriterion`):

| 값 | 소분류(세부 값) | 데이터 소스 |
|---|---|---|
| 전체보기 | 없음(캡슐 축소) | — |
| 날짜·시간 | 연도 | `Composition.createdAt`(신설) |
| 계절 | `Season` 3종 | 기존 필드 |
| 날씨 | `Weather` 3종 + 미지정 | `Composition.weather`(신설, nullable) |

기본 정렬 순서(`_공통 규칙.md` "분류 기준별 정렬 기준표" 그대로): 날짜=최신순 내림차순, 옷종류=머리→발, 계절=봄가을→여름→겨울, 착용빈도=많이 입은 순 내림차순, 날씨=맑음→비→눈. 모든 기준에 오름차순/내림차순 토글 제공.

### 3.3 캡슐 축소 규칙 (일반화)

"전체보기를 고르면 축소"가 아니라, **소분류가 없는 중분류를 고르면 축소** — 옷장의 "착용빈도"도 동일하게 적용된다(전체보기와 마찬가지로 소분류 세그먼트 없이 캡슐이 줄어듦). 코디는 3개 기준 모두 소분류가 있어 "전체보기"만 축소 대상.

```dart
extension on ClosetSortCriterion {
  bool get hasSubClassification => switch (this) {
        ClosetSortCriterion.all => false,
        ClosetSortCriterion.wearFrequency => false,
        _ => true,
      };
}
```

### 3.4 정렬 방향 & nullable 값 처리

- 오름차순/내림차순은 기존 `secondaryControlsRight`에 이미 자리만 잡아둔 스텁 버튼을 재사용한다 — 옷장의 `GlassCircleButton(icon: Icons.adjust, tooltip: '(미정)')`, 코디의 `GlassCircleButton(icon: Icons.sort, tooltip: '정렬 기준', onTap: () {})`. 둘 다 지금은 `onPressed: () {}`인 스텁으로, 이 캡슐 작업의 오름차순/내림차순 토글로 배선하면 자연스럽게 의미가 채워짐(아이콘/툴팁은 Worker가 방향 표시에 맞게 조정).
- **nullable 소분류 값(현재는 코디의 `weather`만 해당) 정렬 규칙**: 오름차순이면 미지정(`null`)이 맨 아래로, 내림차순이면 미지정이 맨 위로 온다. 즉 `null`을 항상 "가장 큰 값"으로 취급해 `compareTo`에 넣으면 두 방향 모두 별도 분기 없이 일관되게 처리된다:

```dart
int _compareNullableLast<T extends Comparable>(T? a, T? b, {required bool ascending}) {
  if (a == null && b == null) return 0;
  if (a == null) return ascending ? 1 : -1;
  if (b == null) return ascending ? -1 : 1;
  return ascending ? a.compareTo(b) : b.compareTo(a);
}
```

### 3.5 데이터 모델 변경

```dart
// lib/models/enums.dart — 신설
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

```dart
// lib/models/clothing_item.dart — 필드 추가
final DateTime createdAt; // required, 신설
```

```dart
// lib/models/composition.dart — 필드 추가
final DateTime createdAt; // required, 신설
final Weather? weather;   // nullable, season과 동일한 성격의 "의도된" 선택 태그
                           // (실제 착용일 관측 날씨가 아니라 코디 자체에 붙는 선택적 속성)
```

`copyWith`/`mock_data.dart`의 기존 인스턴스 전부 `createdAt` 채워야 함(Worker 작업, 임의의 그럴듯한 날짜로 채우되 연도별 분산은 되게).

### 3.6 Provider 아키텍처

기존 `selectedSeasonFilterProvider`/`selectedCompositionSeasonFilterProvider`(계절 필터)는 유지하고 "중분류=계절"일 때의 소분류 값 저장소로 재사용한다. 나머지 기준은 새 provider를 추가한다 — 도메인별 독립(옷장 드릴다운이 코디 상태에 영향 없음), `2026-07-12` 스펙의 "타입은 공유, 인스턴스는 도메인별 분리" 원칙은 유지하되 enum 자체는 옷장/코디가 각자 다른 기준 목록을 가지므로 공유하지 않는다(공유 시도는 과설계 — 옷장 5종/코디 4종이 겹치는 게 "전체보기/날짜/계절"뿐이라 억지로 합치면 코디에 없는 "옷종류"/"착용빈도"까지 끌고 들어옴).

```dart
// lib/providers/closet_providers.dart 추가
enum ClosetSortCriterion { all, dateTime, clothingType, season, wearFrequency }

final closetSortCriterionProvider = StateProvider<ClosetSortCriterion>((ref) => ClosetSortCriterion.all);
final closetSortAscendingProvider = StateProvider<bool>((ref) => false); // 기본 내림차순(최신/많이입은순)
final closetDrilledCategoryProvider = StateProvider<ClothingCategory?>((ref) => null);
final closetDrilledYearProvider = StateProvider<int?>((ref) => null);
// 계절 소분류는 기존 selectedSeasonFilterProvider 재사용
```

```dart
// lib/providers/composition_providers.dart 추가
enum CompositionSortCriterion { all, dateTime, season, weather }

final compositionSortCriterionProvider = StateProvider<CompositionSortCriterion>((ref) => CompositionSortCriterion.all);
final compositionSortAscendingProvider = StateProvider<bool>((ref) => false);
final compositionDrilledYearProvider = StateProvider<int?>((ref) => null);
final compositionDrilledWeatherProvider = StateProvider<Weather?>((ref) => null);
// 계절 소분류는 기존 selectedCompositionSeasonFilterProvider 재사용
```

`filteredClosetItemsProvider`/`filteredCompositionsProvider`는 위 provider들을 모두 `watch`해서 (a) 현재 중분류의 소분류 필터 적용 (b) 정렬 기준+방향 적용하도록 확장한다. 기존 시그니처(반환 타입 `List<ClothingItem>`/`List<Composition>`) 그대로 유지 — 소비하는 화면 쪽 변경 없음.

**3가지 그리드 상태(§3.1)는 별도 provider 없이 파생값이다** — `closetDrilledCategoryProvider`(옷종류 소분류) 등은 이미 nullable로 설계돼 있어, `null` = 아직 소분류 안 고름(그룹 개요), non-null = 드릴인 상태를 그대로 나타낸다. 화면은 `(criterion, subValue)` 조합만 보고 `flat`/`groupOverview`/`drilledIn` 중 뭘 그릴지 순수 함수로 계산하면 된다 — 3번째 provider(예: `ClosetGalleryViewState`)를 별도로 만들면 소분류 provider와 상태가 어긋날 수 있는 이중 소스가 생기므로 만들지 않는다.

### 3.7 그룹 카드 데이터

`groupOverview` 상태에서 그릴 카드 목록(그룹 라벨/썸네일/개수)도 파생 provider로 계산한다 — 원본 아이템 목록을 현재 중분류 기준으로 묶어서 만들며, 빈 그룹은 목록에서 제외한다.

```dart
class ClassificationGroupSummary {
  const ClassificationGroupSummary({
    required this.label,
    required this.thumbnailPaths, // 콜라주용, 최대 4장 정도로 자름
    required this.count,
    required this.value, // 탭 시 드릴인 provider에 그대로 세팅할 값
  });

  final String label;
  final List<String> thumbnailPaths;
  final int count;
  final Object value;
}

final closetGroupSummariesProvider = Provider<List<ClassificationGroupSummary>>((ref) {
  final criterion = ref.watch(closetSortCriterionProvider);
  final items = ref.watch(filteredClosetItemsProvider); // 소분류 필터 적용 전 단계 값 사용
  // criterion별로 groupBy 후 ClassificationGroupSummary로 매핑, count == 0인 그룹은 생성 자체를 안 함
  // (실제 groupBy 키/라벨 매핑은 Worker가 criterion에 따라 분기 구현)
});
```

코디도 동일한 모양의 `compositionGroupSummariesProvider`를 둔다. `value`의 런타임 타입은 criterion에 따라 다르므로(`ClothingCategory`/`Season`/`int`(연도)/`Weather`) `Object`로 받고, 그룹 카드 탭 핸들러가 대상 provider에 캐스팅해서 세팅한다 — criterion과 provider의 매핑이 이미 고정돼 있어 안전한 캐스팅(런타임 타입 불일치는 프로그래밍 오류로 취급, 방어적 캐스팅 불필요).

---

## 4. 영향 범위

**신규/수정 파일**:
- `lib/models/enums.dart` — `Weather` enum 추가
- `lib/models/clothing_item.dart`, `lib/models/composition.dart` — `createdAt` 필드(+ `Composition.weather`)
- `lib/providers/closet_providers.dart`, `lib/providers/composition_providers.dart` — 위 provider 세트
- `lib/mock/mock_data.dart` — 기존 인스턴스에 `createdAt` 채움
- `lib/widgets/category_toggle_dropdown.dart` — "설정" 항목 추가, 위젯 타입 변경 가능성
- `lib/screens/closet_main_screen.dart`, `lib/screens/composition_main_screen.dart` — `groupingBar` 제거, Row2 캡슐 위젯으로 교체, 정렬방향 스텁 버튼 배선
- `lib/widgets/app_main_scaffold.dart` — `groupingBar`/`groupingBarHeight` 파라미터와 `defaultGroupingBarHeight` 상수 삭제, `contentSpacerHeight` 시그니처에서 관련 인자 제거
- 신규 위젯(가칭) `lib/widgets/classification_drilldown_capsule.dart` — 캡슐 UI 자체(옷장/코디가 세그먼트 개수는 같지만 옵션 목록이 달라 제네릭하게 만들거나, 화면별로 얇게 감싸는 두 개의 얇은 wrapper를 둘지는 Worker 판단)
- 신규 위젯(가칭) `lib/widgets/classification_group_card.dart` — 그룹 개요 상태의 폴더형 카드(썸네일 콜라주+라벨+개수), `lib/widgets/classification_group_grid.dart` — 이 카드들을 배치하는 그리드(기존 `AppGalleryGrid`를 재사용할지, 카드가 아이템 타일보다 커서 별도로 둘지는 Worker 판단)
- `docs/reference/plan/03_화면별UX명세서/04_설정.md` — §1 정정 각주
- `docs/history/Decision.md` — 이 스펙이 `04_설정.md` §1과 `2026-07-12-cross-screen-ui-shell-design.md`의 그룹형 드릴다운 설계를 대체한다는 override 기록

**`AppMainScaffold.groupingBar`/`groupingBarHeight` 슬롯 자체를 제거한다** — 이 변경 후 옷장/코디 둘 다 더 이상 쓰지 않으면 소비자가 하나도 안 남는 파라미터라, "나중에 다른 화면이 쓸 수도 있으니" 남겨두는 건 YAGNI 위반이다. `defaultGroupingBarHeight` 상수, `skeletonRegion(...)` 호출부, 관련 테스트(`app_main_scaffold_shell_migration_test.dart` 등의 groupingBar assertion)까지 함께 정리한다. 향후 다른 화면에 정말 필요해지면 그때 다시 추가하는 비용이 낮다(단순 파라미터 추가라 재도입 비용이 크지 않음).

---

## 5. 테스트 전략

- Provider 로직(필터+정렬+캡슐 축소 판정, nullable 정렬, 그룹 카드 생성 — 빈 그룹 제외 포함)은 순수 로직이라 TDD 대상 — `test/providers/closet_classification_test.dart`, `test/providers/composition_classification_test.dart`(신규).
- 캡슐 UI 자체(펼침/축소 애니메이션, 드롭다운 상호작용)와 3가지 그리드 상태 전환(플랫/그룹개요/드릴인, 그룹 카드 탭 시 소분류 세그먼트 텍스트 동기화)은 이 프로젝트 관례대로 Tester 통합테스트로 검증(위젯 단위 TDD 아님).
- 기존 `closet_main_screen_test.dart`/`composition_style_log_main_screen_test.dart` 등은 `groupingBar` skeleton 관련 assertion이 있다면 제거된 동작에 맞게 갱신 필요 — Worker가 실제 변경 시 확인.
- "설정" 드롭다운 항목: 탭 시 실제로 `/settings`로 push되고 뒤로가기로 복귀하는지 Tester가 확인.

---

## 6. 스코프 경계 (이번 라운드에 포함하지 않음)

- 색상 분류 기준(팔레트 미확정 — 위 §1 참고)
- 스타일일지 메인의 날짜/계절/날씨 필터(플랫+필터형 별도 메커니즘, 이 스펙 대상 아님)
- `04_설정.md`의 다른 미해결 드리프트(로그아웃 로우 부재, 다크모드/프로필편집 로우 스펙外 잔존) — `docs/history/TechnicalDebt.md`에 이미 별도 기록됨, 사용자가 아직 설정 화면 자체를 검토하지 못해 이번 스펙에서 다루지 않음(다음 Group 논의 때 별도 처리)
- 다중선택/휴지통 실행("선택" 버튼 배선) — 별도 스펙(Group B)
