# 화면 관통 공용 UI 셸 + 프론트엔드 재산정 프로세스 — Design Spec

**작성일**: 2026-07-12
**배경**: `docs/work/전체화면_아키텍처_재설계_체크리스트.md` — 옷장 메인에 하단 좌측 뒤로가기 버튼(`_FrostedBackButton`, 커밋 `31b42b0`)을 추가하는 중, 뒤로가기/카테고리 전환 토글/그룹형 드릴다운이 "화면 하나의 기능"이 아니라 "앱을 관통하는 공용 UI"여야 한다는 게 드러났다. 원본 스프린트 플랜(`2026-07-08-flutter-frontend-hifi-screens.md`)의 Task 8~15는 화면을 하나씩 순서대로 구현하는 구조라 이 전제를 반영하지 못했다. 이 문서는 그 재설계와, 재설계를 실제로 굴릴 새 개발 프로세스(8단계)를 함께 정의한다.

---

## 1. 화면별 규칙 적용 표 (확정)

사용자가 확정한 3개 공용 규칙(뒤로가기=조건부 전 화면 / 카테고리 토글=Add·Create 3종 제외 전 화면 / 그룹형 드릴다운=도메인 메인 중 그룹형뿐)을 기존 스펙 문서(`docs/reference/plan/03_화면별UX명세서/`)와 대조해 확정한 표.

| 화면 | 페이지 타입 | 뒤로가기 | 카테고리 토글 | 그룹형 드릴다운 |
|---|---|---|---|---|
| 옷장 메인 | Main-그룹형 | O | O | **O** |
| 코디 메인 | Main-그룹형 | O | O | **O** |
| 스타일 일지 메인 | Main-플랫+필터형 | O | O | X |
| 휴지통 | Main-플랫+필터형 | O | X | X |
| 옷 상세 | Detail | O | O | X |
| 코디 상세 | Detail | O | O | X |
| 스타일 일지 열람 | Detail | O | O | X |
| 옷 추가하기 | Add/Create | X(자체 취소 버튼이 대체) | X | X |
| 코디 만들기 | Add/Create | X | X | X |
| 스타일 일지 추가 | Add/Create | X | X | X |
| 설정 | Utility | O | X | X |
| 선택 모달(옷장/코디 재호출) | Modal/Sheet | 별도(닫기 X버튼) | X | **O** (원 화면과 동일 사양 — 사용자 확정) |
| 선택 모달(스타일일지 재호출) | Modal/Sheet | 별도(닫기 X버튼) | X | X (원 화면이 플랫이므로 동일하게 X) |

**해소된 충돌**: 이전 체크리스트가 "그룹형 드릴다운은 옷장/코디/스타일일지 메인 전부"라고 기록했었으나, `00_페이지 타입 정의.md`와 `03_스타일 일지.md` 원문이 스타일 일지를 처음부터 "플랫+필터형"(그룹화 없음, 휴지통과 동일 계열)으로 명시하고 있어 충돌 — 사용자 확인 결과 **기존 스펙(플랫+필터형) 유지**로 확정. 그룹형 드릴다운은 옷장/코디 2개 화면에만 적용한다.

---

## 2. 아키텍처: 공용 셸 위젯 (`AppMainScaffold`)

**비유**: 공용 HUD 캔버스 하나를 두고, 화면마다 그 위의 어떤 요소(뒤로가기/카테고리 토글/그룹 바)를 노출·숨길지만 선언한다.

### 검토한 대안과 선택 이유

- **A. 리프 위젯만 추출**(기각): `FrostedBackButton`/`CategoryToggleDropdown`을 공용 위젯으로 뽑아도, 각 화면이 "이 화면에 이걸 붙인다"는 배선을 직접 반복해야 해서 지금 겪은 문제(옷장 메인만 챙기고 나머지 화면은 빠뜨림)가 구조적으로 재발할 수 있음.
- **B. 공용 셸 위젯이 크롬 전체를 소유**(채택): `AppMainScaffold`가 배경 데코+헤더+토글+조건부 뒤로가기+FAB passthrough+`groupingBar` 슬롯을 전부 내부 조립. 화면은 이 셸을 쓰기만 하면 되고, 플래그 기본값이 전부 "켬"이라 새 화면이 크롬을 빠뜨리는 게 구조적으로 불가능해짐. `OverlayHeader`와 뒤로가기 버튼 사이의 톤 리터럴 중복(기존 Review P2 이슈)도 이 참에 해소.
- **C. go_router `ShellRoute`**(기각): 화면마다 크롬 내용이 조금씩 달라(밀도/정렬 아이콘 유무 등) 결국 슬롯/빌더가 필요해져 B안으로 수렴하고, 라우터 레벨 재구조화는 마감(2026-07-24) 대비 리스크만 키움.

### 컴포넌트 (1차 확정분 — 나머지는 아래 Step②에서 별도 리스트업)

| 위젯 | 위치 | 비고 |
|---|---|---|
| `AppMainScaffold` | `lib/widgets/app_main_scaffold.dart` (신규) | `{required AppCategory current, required Widget body, bool showBackButton = true, bool showCategoryToggle = true, Widget? groupingBar, ...}` |
| `FrostedBackButton` | `lib/widgets/frosted_back_button.dart` (기존 `closet_main_screen.dart`의 private 클래스를 추출) | `OverlayHeader`와 톤 로직 공유 |
| `CategoryToggleDropdown` | `lib/widgets/category_toggle_dropdown.dart` (기존 `_buildCategoryDropdown`을 추출) | `current: AppCategory` 파라미터화 — 지금은 `AppCategory.closet` 하드코딩이라 다른 화면 재사용이 애초에 불가능했던 버그도 같이 해소 |

### 그룹형 드릴다운 상태 (옷장/코디 전용)

상태 "모양"(3단계 enum)은 옷장/코디에 동일한 개념이므로 **enum 타입 자체는 하나로 공유**한다(이 프로젝트가 `Season`/`ClothingCategory` 등 여러 모델이 공유 enum을 쓰는 기존 관례와 일치). 상태 **인스턴스**(Provider)는 도메인별로 분리 — 옷장/코디가 지금 각자 뭘 드릴다운했는지는 서로 독립된 값이어야 하기 때문(코디를 드릴다운해도 옷장 상태는 안 바뀜):

```dart
// lib/models/enums.dart — 옷장/코디 공용
enum GroupedMainViewMode { groupOverview, allFlat, drilledInto }

// lib/providers/closet_providers.dart
final closetViewModeProvider = StateProvider<GroupedMainViewMode>((ref) => GroupedMainViewMode.groupOverview);
final closetDrilledSeasonProvider = StateProvider<Season?>((ref) => null);

// lib/providers/composition_providers.dart
final compositionViewModeProvider = StateProvider<GroupedMainViewMode>((ref) => GroupedMainViewMode.groupOverview);
final compositionDrilledSeasonProvider = StateProvider<Season?>((ref) => null);
```

완전 중복(타입까지 두 번 정의)도 아니고, 별도 컨트롤러 클래스로 묶는 과한 제네릭 추상화도 아닌 중간 지점 — 타입(개념)만 공유하고 상태는 도메인별로 독립.

---

## 3. 개발 프로세스 변경 (8단계) — 원본 Task 8~15를 대체

사용자 지시(2026-07-12)로, 화면을 하나씩 순서대로 완성하던 기존 방식을 아래 8단계로 교체한다. **`2026-07-08-flutter-frontend-hifi-screens.md`의 Task 8~15는 이 프로세스로 재산정되며 더 이상 유효하지 않다** — 다음 `writing-plans` 단계에서 새 플랜 문서로 대체.

```
① 전체 화면 Skeleton
    ↓
② Component Library 구축 (후보 리스트업 → 사용자 검수 → 제작)
    ↓
③ Main 화면 3개 적용
    ↓
④ Detail 화면 적용
    ↓
⑤ Editor(Add/Create) 적용
    ↓
⑥ 나머지 화면 적용 (설정/휴지통/선택 모달 등)
    ↓
⑦ 기능 구현
    ↓
⑧ 디테일 튜닝
```

### Step① 범위 (지금 착수)

모든 화면(위 §1 표의 13행 전부 — 옷장 메인부터 선택 모달 2종까지)에 대해 **컴포넌트 없이** 다음만 정의:
- 페이지 타입(§1 표에 이미 확정됨)
- 레이아웃 리전(헤더 영역/토글바 영역/본문 영역/FAB 영역 등 — 실제 위젯 없이 자리만)
- 골격 코드: 현재 `app_router.dart`의 `_placeholder(String label)` 단순 텍스트 placeholder를, 위 리전 구조를 반영한 골격으로 승격(아직 공용 컴포넌트는 안 씀 — 컴포넌트는 Step②)

**stash 처리**: 세션 시작 시 stash한 `app_router.dart`(placeholder AppBar 수정)와 `integration_test/placeholder_back_button_test.dart`는 이 Step①로 흡수된다 — 개별 AppBar 땜질 대신 이 스켈레톤 작업이 대체하므로 stash는 복원하지 않고 버린다.

### Step② 범위 (Step① 완료 후 별도 착수)

여러 화면에서 공용으로 쓰일 요소 후보(헤더/툴바/갤러리/바텀시트/스크롤바 등)를 리스트업 → **사용자 검수** → 통과분만 제작. 이 문서는 후보 존재만 언급하고 확정 리스트는 만들지 않는다(Step① 결과를 보고 뽑는 게 더 정확함).

### Step③~⑥ 범위

Component Library를 화면 그룹별로 적용(Main 3개 → Detail → Editor → 나머지). §1 표의 플래그 매핑을 그대로 사용.

### Step⑦~⑧ 범위

정적 조립이 끝난 뒤 실제 상호작용/데이터 바인딩(⑦), 이후 시각 디테일 라운드(⑧, 옷장 메인이 이미 거친 것과 동일 성격의 패스).

---

## 4. 테스트 전략

- `AppMainScaffold` 자체 위젯 테스트: 플래그별 렌더링(뒤로가기 유무/토글 유무/groupingBar 유무) — Worker 작성.
- 기존 옷장 메인 통합테스트 22개는 `AppMainScaffold` 마이그레이션 후에도 동일 동작을 보장하는 회귀축.
- Step①(스켈레톤)은 실동작이 없는 순수 구조 코드라 Tester 불필요(Review만) — Step③ 이후 실제 상호작용이 생기면 그 시점부터 Tester 재개(CLAUDE.md 정책대로 매 사이클).

---

## 5. 스코프 밖

- 코디 에디터 제스처(드래그/회전/z-index), AI 처리 실사 연동 — 원본 플랜의 Global Constraints 그대로 유지.
- Step②의 공용 컴포넌트 확정 리스트 — 이 문서 범위 아님, Step① 완료 후 별도 리스트업+검수.
