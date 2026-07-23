# Step⑦ 그룹 B — 다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기

**작성일**: 2026-07-21
**대상 스펙**: `docs/reference/plan/03_화면별UX명세서.md` §0(Main형 정의), §5(삭제 & 휴지통)
**스코프**: 옷장/코디/스타일일지/휴지통 4개 Main형 화면의 다중선택 기능(신규) + 휴지통 화면의 복원/영구삭제/비우기 실제 실행(기존엔 전부 no-op 스텁) + 이를 뒷받침하는 아키텍처 제네릭화.
**스코프 밖(명시적 이관)**: 옷 삭제 시 코디 캐스케이드 UX(스냅샷 렌더링, 연결끊김 배지, 편집 진입 시 자동 정리) — "Editor Draft 구현" 후속 작업으로 이관됨(`docs/history/TechnicalDebt.md` 기존 항목 참고). 스타일일지 자체 필터 칩(UX명세서상 "플랫+필터형"이라는 이름은 있으나 구체적 필터 기준이 어디에도 정의돼 있지 않음 — 별도 스펙 필요, 이번 라운드 대상 아님).

---

## 1. 배경 및 동기

기존 `ClosetMainScreen`/`CompositionMainScreen`/`StyleLogMainScreen`/`TrashMainScreen`은 각자 독립된 화면 클래스 + 독립된 provider 파일로 구현돼 있었다. `AppMainScaffold`/`AppGalleryGrid`/`ClassificationDrilldownCapsule` 같은 하위 위젯은 이미 공유되지만, 화면 클래스 자체와 provider는 병렬 중복이었다(`docs/history/Decision.md` "Gallery 제네릭화는 이번 라운드에 전체로 하지 않음" 항목 — 전체 제네릭화를 한 번 검토했다가 의도적으로 미룬 전례가 있음).

이번 그룹 B의 핵심 신규 기능인 **다중 선택 모드**는 4개 화면(옷장/코디/스타일일지/휴지통) 전부에 완전히 동일한 형태([선택]버튼/롱프레스 진입, 체크박스, 하단 액션 버튼)로 필요하다. 프로젝트 자체 스펙 `03_화면별UX명세서.md` §0이 이미 이 4개 화면을 "Main형" 하나의 타입으로 묶고("두 가지 변형: 그룹형(옷장/코디) vs 플랫+필터형(스타일 일지, **휴지통**)"), 다중선택을 "Main형 공통 요소"로 정의하고 있다 — 이번 작업은 그 문서상 개념을 실제 코드 구조로 옮기는 것이다.

---

## 2. 아키텍처

### 2.1 `GalleryMainScreen<T>` 신설

`lib/widgets/gallery_main_screen.dart`에 제네릭 `ConsumerStatefulWidget`을 신설한다. 옷장/코디/스타일일지/휴지통 4개 화면(`ClosetMainScreen` 등)은 전부 이 위젯을 호출하는 얇은 wrapper로 축소된다 — 각자 자기 도메인 provider를 읽어 config를 조립해 넘기는 역할만 한다.

**이 위젯이 소유하는 것 (4개 화면 공통 — Main형 공통 요소)**
- `AppMainScaffold` 배선(뒤로가기/카테고리 토글/헤더 액션)
- 그리드 렌더링 — `gridBuilder` 콜백에 위임(§2.3)
- **다중선택(신규)**: `Set<String> _selectedIds` + `bool _multiSelectMode`를 이 위젯의 **로컬 State**로 관리(전역 provider 없음 — 위젯이 4번 독립적으로 인스턴스화되므로 로컬로 충분하고, 휴지통은 애초에 `AppCategory`에 속하지 않아 provider를 category로 키잉하는 방식과 상성이 안 좋았음).

**선택적으로 켜지는 것 (그룹형 2개, 옷장/코디만)**
- `classification: ClassificationConfig<T>?` — null이면 캡슐/밀도/그룹드릴다운이 렌더링되지 않고 그냥 플랫 그리드(스타일일지·휴지통). non-null이면 지금 `ClosetMainScreen`/`CompositionMainScreen`의 `build()`에 있는 캡슐+밀도+3상태(플랫/그룹개요/드릴인) 로직이 그대로 이 config로 옮겨간다.
- `classification == null`이면 밀도는 **항상 `AppDensity.mid` 고정**(기존 스타일일지 선례와 동일 — `docs/history/Decision.md` "그리드 밀도 토글은 그룹형 Main 화면 전용"에 근거가 명시돼 있는 결정이며, 이번에 재확인함).

**화면 전용 확장 (일반화 안 함, 스펙 §00 원칙 그대로)**
- 휴지통만: 탭 시 상세이동 대신 정보팝업, N일 배지, 유형 필터 칩(전체/옷/코디/스타일일지 — `AppMainScaffold.secondaryControlsLeft` 슬롯 재사용, 각각 독립 `GlassPill` 4개, 세그먼트 바 아님), 비우기 버튼.

**분류(criterion/drilldown) provider**: 지금처럼 옷장/코디 각자 파일 유지 — `ClosetSortCriterion`/`CompositionSortCriterion` 타입이 실제로 다르고 드릴인 값 타입도 다름(옷종류=`ClothingCategory`, 코디=`Weather` 등)이라 억지 통합 안 함.

### 2.2 헤더 상태 우선순위 (기존 "재호출 피커 모달"과의 충돌 해소)

기존 `selectionMode: bool`(재호출 피커 모달, `buildSelectionAwareHeaderActions`가 처리)과 신규 `_multiSelectMode`(다중선택, 이 위젯의 로컬 상태)는 서로 다른 개념이고 헤더의 같은 자리(X 버튼)를 두고 충돌할 수 있다. 우선순위를 명시적으로 정한다:

- `selectionMode == true`(피커 모달)면 "선택" 버튼/롱프레스 다중선택 진입 경로 자체를 렌더링하지 않는다 — 피커 모달 안에서 항목을 삭제한다는 개념이 성립하지 않기 때문. 헤더는 항상 피커 닫기 X만 보여준다.
- `selectionMode == false`일 때만 다중선택이 활성화된다. "선택" 버튼 탭 → 헤더가 다중선택 종료 X로 바뀐다.
- 두 X는 절대 동시에 존재하지 않는다(상호 배타).

### 2.3 그리드/타일 위임 방식 — `T` 타입 분기 없음

`GalleryMainScreen<T>`는 `T`의 런타임 타입을 분기하지 않는다. 대신 도메인 wrapper가 자기 **기존** 그리드 어댑터 위젯(`GroupedGalleryGrid`/`CompositionGalleryGrid`/`StyleLogGalleryGrid`, 휴지통은 자체 `AppGalleryGrid` 직접 사용)을 그대로 인스턴스화하는 `gridBuilder` 콜백을 제공한다:

```
gridBuilder: Widget Function({
  required int density,
  required ScrollController? controller,
  required double topSpacing,
  required bool multiSelectMode,
  required Set<String> selectedIds,
  required void Function(T item) onItemTap,
  required void Function(T item) onItemLongPress,
})
```

`GalleryMainScreen`은 현재 모드에 맞는 `onItemTap`(평소=상세이동, 다중선택 중=토글)을 계산해서 넘겨주기만 한다. 각 도메인의 기존 그리드 어댑터(`GroupedGalleryGrid` 등)는 죽지 않고 계속 쓰이며, 대신 `multiSelectMode`/`selectedIds`/`onItemLongPress` 3개 파라미터가 추가돼 자기 타일에 그대로 전달한다.

### 2.4 하단 플로팅 버튼 — Header/HUD Pinned Rule 준수

"하단 액션바"라는 표현 대신 **각각 독립된 `GlassPill`/`GlassCircleButton` 여러 개**로 명시한다(`lib/widgets/app_main_scaffold.dart`의 Pinned Rule — 조작 요소를 하나의 Bar/Container로 합치는 것은 프로젝트 전체 금지, 예외는 사용자 명시 승인 필요).

`AppMainScaffold`에 새 파라미터 `bottomFloatingActions: List<Widget>`(기본 빈 리스트)를 추가해서, 기존 `FrostedBackButton`과 같은 하단 밴드에 독립 pill들을 얹는다(기존 `_withGaps` 헬퍼로 간격 처리). 다중선택 모드 진입 시 `showBackButton`과 `floatingActionButton`을 둘 다 숨긴다(기존 피커모달의 `!selectionMode` 억제 패턴과 동일) — 뒤로가기/FAB와 하단 버튼이 겹치는 걸 막는다.

옷장/코디/스타일일지 = `[삭제]` 1개, 휴지통 = `[복원]` `[영구 삭제]` 2개. 선택 0개면 흐리게 비활성화(버튼이 나타났다 사라졌다 하지 않게).

---

## 3. 데이터 모델

### 3.1 모델 필드 추가 — `deletedAt`

`ClothingItem`/`Composition`/`StyleLog`에 `DateTime? deletedAt` 필드 추가(기본 null). Soft-delete 시 `DateTime.now()`로 세팅, 복원 시 다시 null.

### 3.2 `copyWith` sentinel 패턴 — 3개 모델 전체로 확장

`docs/history/TechnicalDebt.md`에 이미 기록된 버그: `ClothingItem`/`StyleLog`의 `copyWith`가 `field ?? this.field` 패턴이라 `copyWith(field: null)`을 호출해도 "안 건드림"과 구분이 안 돼 기존 값이 유지된다. 이번에 추가하는 `restoreMany`(`deletedAt`을 `null`로 되돌림)가 이 버그의 실제 소비자가 되므로, TechnicalDebt.md가 예고한 대로 지금 결정한다: **sentinel 패턴을 채택하고, 이번에 손대는 3개 모델의 모든 nullable 필드에 일괄 적용한다**(범위를 `deletedAt`에만 좁히지 않음 — 같은 파일을 여는 김에 하는 기계적 수정이고, 기존 문서화된 버그를 완전히 해소할 수 있어 절반만 고치는 것보다 낫다).

```dart
class ClothingItem {
  static const Object _unset = Object();

  ClothingItem copyWith({
    Object? category = _unset,   // ClothingCategory?
    Object? season = _unset,     // Season?
    Object? color = _unset,      // String?
    Object? material = _unset,   // String?
    Object? deletedAt = _unset,  // DateTime?
    bool? isDeleted,
    // ...non-nullable 필드는 기존처럼 T? 파라미터 + ?? 유지(sentinel 불필요)
  }) {
    return ClothingItem(
      category: identical(category, _unset) ? this.category : category as ClothingCategory?,
      // ...
    );
  }
}
```

적용 대상: `ClothingItem`(category/season/color/material/deletedAt, 5개), `StyleLog`(linkedCompositionId/deletedAt, 2개 — 기존 `copyWith` 있음, 수정), `Composition`(season/weather/coverImagePath/deletedAt, 4개 — **`copyWith` 자체가 지금 없어서 신규 작성**, 처음부터 sentinel로 작성하므로 마이그레이션 비용 없음).

검증: 필드마다 `copyWith(field: null)`이 실제로 지워지는지 확인하는 모델 유닛테스트 추가(화면 소비자 없이도 계약을 검증). 완료되면 `docs/history/TechnicalDebt.md`의 기존 항목을 해소 처리한다.

### 3.3 도메인 Notifier 메서드

`ClosetItemsNotifier`/`CompositionsNotifier`/`StyleLogsNotifier` 3개 클래스에 동일한 3종 메서드 추가:
- `softDeleteMany(Set<String> ids)` — 대상 id들에 `isDeleted:true, deletedAt:DateTime.now()`, 단일 `state=[...]` 리빌드 1번.
- `restoreMany(Set<String> ids)` — `isDeleted:false, deletedAt:null`.
- `purgeMany(Set<String> ids)` — 리스트에서 완전히 제거(하드 삭제).

기존 `ClosetItemsNotifier.softDelete(String id)`(단일)는 시그니처 유지, 내부적으로 `softDeleteMany({id})` 호출로 재구현(Detail 화면 단건삭제가 계속 이 이름을 씀).

3벌 병렬 추가는 메서드당 5~6줄 수준 중복이지만, 3개 모델이 공유 인터페이스가 없어 제네릭 베이스로 뽑으려면 새 인터페이스를 얹어야 하는 과설계라 채택 안 함(1차 리뷰 확인 완료).

### 3.4 휴지통 집계 — 파생 Provider로 전면 재작성

`TrashEntriesNotifier`/`mockTrashEntries` 삭제. `trashEntriesProvider`를 **`Provider.autoDispose<List<TrashEntry>>`**로 재정의 — 3도메인 provider(`closetItemsProvider`/`compositionsProvider`/`styleLogsProvider`)를 각각 watch해서 `isDeleted`인 것만 걸러 `TrashEntry`(필드 구조 유지)로 매핑한다.

`TrashEntry.remainingDays` 필드명을 **`daysUntilPurge`로 변경**한다 — 기존 이름은 "유통기한" 뉘앙스가 있어 실제 의미(영구삭제까지 남은 일수, 도메인 동사 `purge`와 직결)와 어긋난다는 논의 끝에 확정.

```
daysUntilPurge = (15 - DateTime.now().difference(item.deletedAt!).inDays).clamp(0, 15)
```

**`autoDispose` 채택 이유**: 일반 `Provider`는 의존 provider가 실제로 바뀔 때만 재계산되고 시간 경과 자체로는 재계산되지 않는다 — 휴지통 화면에 오래 머물러도 "N일" 표시가 자정을 넘겨도 안 바뀔 수 있다는 문제(1차 리뷰 P2)가 있었다. `autoDispose`는 "휴지통을 보는 화면이 하나도 없어지는 순간 폐기 → 재진입 시 완전히 새로 계산"을 코드 없이 자동으로 제공하므로, 정확히 원하는 갱신 조건("휴지통 재진입 시" + "앱 재부팅 시"는 인메모리 mock이라 당연히 항상 재계산됨)을 만족한다. 지금은 휴지통 화면만 이 provider를 보므로 안전하다 — 나중에 다른 화면(예: 설정의 "휴지통(N)" 카운트 배지)이 동시에 watch하게 되면 `keepAlive` 재검토 필요.

### 3.5 15일 자동 영구삭제 — 앱 실행 시 1회

`purgeExpiredTrash(ProviderContainer container)` 함수를 `lib/providers/trash_providers.dart`에 신설. `lib/main.dart`의 `runApp()` 호출 **전**에 한 번 실행 — 3도메인 각각 `isDeleted && deletedAt이 15일 초과`인 id를 모아 `purgeMany` 호출. Provider 빌더 안에서 부수효과로 하지 않고 앱 시작 시점의 명시적 imperative 단계로 분리한다(Riverpod 관례).

```dart
// main.dart
void main() {
  final container = ProviderContainer();
  purgeExpiredTrash(container);
  runApp(UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()));
}
```

세션 내에서 실제로 15일이 지나가는 일은 없으므로(인메모리, 실시간 흐름), 이 체크는 "이전 세션에서 넘어온 오래된 mock 데이터 정리" 성격이다 — `mock_data.dart`에 `deletedAt`을 과거 날짜(15일 초과 포함)로 미리 심어 이 로직이 실제로 동작하는 걸 데모/테스트로 확인한다.

### 3.6 다중선택 실행 흐름

- **옷장/코디/스타일일지**: 하단 `[삭제]` 탭 → `softDeleteMany(selectedIds)` → 다중선택 모드 자동 종료 → `GlassToast` 노출("N개 항목이 휴지통으로 이동됨 · 실행취소"), Undo 탭 시 방금 지운 id들로 `restoreMany` 호출.
- **휴지통**: 하단 `[복원]`/`[영구 삭제]` 탭 → 선택된 `TrashEntry`들을 `category`별로 그룹핑 → 각 도메인 Notifier의 `restoreMany`/`purgeMany` 호출. `[영구 삭제]`는 스펙대로 확인 모달 먼저("영구 삭제하면 되돌릴 수 없어요, 계속할까요?").
- **휴지통 "비우기"**: 확인 모달("전체 {N}개 항목을 영구 삭제하시겠어요? 되돌릴 수 없어요") → 현재 `trashEntriesProvider` 전체를 category별로 그룹핑해서 3도메인 `purgeMany` 호출.
- **휴지통 개별 항목 정보 팝업**의 `[복원]`/`[영구 삭제]`도 동일 메서드를 단일 id 세트로 호출.
- **Detail 3화면 "더보기" 메뉴**: `PopupMenuButton`에 `[삭제]` 1항목 → 현재 레코드 `softDeleteMany({id})` → `context.pop()` → `GlassToast`.

### 3.7 안전 가드 — 영구삭제 시 참조 무결성

영구 삭제(`purgeMany`)는 다른 코디/스타일일지가 그 id를 여전히 참조하고 있어도 실제로 데이터에서 제거한다(캐스케이드 정리 UX 없이 안전하게만 처리 — 사용자 확정). 아래 3곳에 방어 코드 추가:

1. `composition_providers.dart`의 `compositionCoverImageProvider` — 코디의 첫 아이템이 purge됐으면 다음 아이템으로 폴백 시도, 전부 없으면 `null` 반환(기존에도 nullable이라 자연스러움).
2. `composition_detail_screen.dart` — 아트보드가 `placement.clothingItemId`로 옷을 조회하는 부분. purge된 아이템의 placement는 렌더링에서 건너뜀(캐스케이드 배지 UX 없이 그냥 안 그림 — Editor Draft 후속 작업 전까지는 이 정도로 충분).
3. `style_log_viewer_screen.dart` — `linkedCompositionId`가 purge된 코디를 가리키면 "연결 안 됨" 취급(연결된 코디 섹션 숨김). `StyleLog` 데이터 자체는 안 건드림(역방향 정리 안 함, 참조만 방어).

**알려진 미가드 지점(의도적, 낮은 우선순위)**: `closet_item_detail_screen.dart`/`composition_detail_screen.dart`/`style_log_viewer_screen.dart`가 **자기 자신의 id**를 조회하는 `firstWhere`(각각 `itemId`/`compositionId`/`styleLogId`)는 가드하지 않는다. 이 앱은 `go_router`의 단순 `GoRoute` push 스택(`StatefulShellRoute` 아님)이라, 상세화면이 스택에 남아있는 채로 그 대상이 다른 경로로 purge되는 시나리오는 실질적으로 도달 불가능하다(상세화면에서 휴지통으로 바로 못 감, 뒤로가기해야 함). `docs/history/TechnicalDebt.md`에 낮은 우선순위로 기록하고, 딥링크/탭 상태 유지 등 네비게이션 구조가 바뀌면 재검토한다.

### 3.8 설정 → 휴지통 진입

`settings_screen.dart`의 "일반" 섹션 아래 로우 하나 추가: "휴지통" + chevron → `context.push(AppRoute.trashMain)`(라우트는 `lib/router/app_router.dart:31,99`에 이미 등록돼 있음, 지금은 도달 경로만 없는 상태). 원래 BACKLOG상 "그룹 C(설정 나머지)" 몫으로 분류돼 있었으나, 그룹 C가 막힌 진짜 이유(다크모드/프로필편집 스펙 불일치, 사용자 확인 필요)와 이 로우 추가는 무관하다고 판단해 그룹 B로 앞당김 — 그렇지 않으면 이번 라운드가 끝나도 `/trash`가 여전히 정상 UI로 도달 불가능한 상태로 남는다.

---

## 4. 다중선택 UX 인터랙션

### 4.1 타일 확장 — 기존 `selected` 파라미터를 완성

`SelectableGalleryTile`(옷장 타일)에 이미 `selected: bool` 파라미터가 있으나 실제로 어디서도 넘겨지지 않는 미완성 기능이었다(`isIncomplete`/`deletedAt`과 같은 "필드만 먼저" 패턴 — 다중선택이 이 기능을 기다리던 소비자). 삭제하지 않고 **완성**한다:

- `selected`가 true면 기존 2px 프라이머리 보더에 더해 **우상단에 체크서클 오버레이**를 그린다(미선택=아웃라인 원, 선택=프라이머리 채움+체크 아이콘). 좌상단은 "미완성" 배지, 하단은 `GalleryMetaLabel`이 이미 쓰고 있어 우상단이 유일하게 비어있는 자리(4개 타일 전체 확인 완료, 충돌 없음).
- 체크서클 시각 부분은 도메인 정보가 전혀 없는 순수 UI 원자라 `lib/widgets/multi_select_checkmark.dart`(`MultiSelectCheckmark({required bool selected})`)로 추출해 4개 타일이 공유한다.
- `onLongPress: VoidCallback?` 파라미터 추가.
- `CompositionGalleryTile`/`StyleLogGalleryTile`/`TrashGalleryTile`에도 동일하게 `selected`+`onLongPress`+체크서클 추가(지금은 `selected` 파라미터 자체가 없음 — 신규 추가).

### 4.2 그리드 어댑터 확장

`GroupedGalleryGrid`/`CompositionGalleryGrid`/`StyleLogGalleryGrid`에 `multiSelectMode: bool`(기본 false), `selectedIds: Set<String>`(기본 빈 Set), `onItemLongPress: void Function(T)?` 파라미터 추가 — 각자 자기 타일에 `selected: multiSelectMode && selectedIds.contains(item.id)`, `onLongPress: () => onItemLongPress?.call(item)`로 그대로 전달.

### 4.3 진입

- 헤더 "선택" `GlassPill` 탭 → 다중선택 모드 진입(0개 선택 상태로 시작).
- 타일 롱프레스 → 다중선택 모드 진입 **+ 그 타일 즉시 1개 선택**.
- 롱프레스 핸들러는 하나로 통일: 이미 다중선택 모드면 롱프레스도 탭과 동일하게 토글 처리(진입 전용 분기 없음).
- 재호출 피커 모달(`selectionMode==true`) 중엔 롱프레스/선택버튼 자체가 렌더링되지 않음(§2.2).

### 4.4 모드 중 시각 상태

- 헤더 "선택" pill → **"N개 선택" 텍스트 pill + X(닫기) pill**, 둘 다 독립 `GlassPill`(Pinned Rule 준수).
- 탭 → 상세 이동 대신 그 타일 선택 토글로 전환(`GalleryMainScreen`이 `onItemTap`을 모드에 따라 다르게 계산해서 넘기므로 도메인 코드는 신경 안 써도 됨, §2.3).
- 하단 플로팅 버튼: 옷장·코디·스타일일지=`[삭제]` 1개, 휴지통=`[복원]``[영구 삭제]` 2개. 선택 0개면 흐리게 비활성화.

### 4.5 종료

- X 탭 → `_selectedIds` 비우고 모드 종료, 뒤로가기/FAB 원복(§2.4).
- 삭제/복원/영구삭제 실행 성공 시 자동으로 모드 종료.

### 4.6 접근성

타일의 기존 `Semantics(label: '...미완성')` 패턴처럼, 선택 모드 중엔 라벨 끝에 ", 선택됨"을 조건부로 덧붙인다.

---

## 5. Toast 위젯 (신규)

기존 코드에 Toast/SnackBar 패턴이 전혀 없어 이번에 처음 만든다. Flutter 기본 `SnackBar` 대신, 이 앱이 이미 쓰는 글래스 팔레트(`GlassPill`/`GlassCircleButton`)와 일관된 커스텀 위젯을 신설한다.

`lib/widgets/glass_toast.dart`:
```dart
class GlassToast {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) { ... } // Overlay.of(context).insert()로 삽입, 수 초 후 자동 dismiss
}
```

"휴지통으로 이동됨 · 실행취소"(다중선택 삭제, Detail 더보기 삭제 둘 다 동일 패턴)에 사용.

---

## 6. 파일 배치 / 작업 분해 개요

**신규 파일**
- `lib/widgets/gallery_main_screen.dart` — `GalleryMainScreen<T>` + `ClassificationConfig<T>`
- `lib/widgets/glass_toast.dart` — `GlassToast`
- `lib/widgets/multi_select_checkmark.dart` — `MultiSelectCheckmark`

**모델 변경**
- `lib/models/clothing_item.dart` / `composition.dart` / `style_log.dart` — `deletedAt` 필드 + `copyWith` 전체 sentinel화(§3.2)
- `lib/models/trash_entry.dart` — `remainingDays` 필드명을 `daysUntilPurge`로 변경(§3.4)

**Provider 변경**
- `lib/providers/closet_providers.dart` — `restoreMany`/`purgeMany` 추가, `softDelete` 재구현
- `lib/providers/composition_providers.dart` — `CompositionsNotifier`에 3종 메서드 신설(현재 메서드 0개) + `compositionCoverImageProvider` 안전가드
- `lib/providers/style_log_providers.dart` — `StyleLogsNotifier`에 3종 메서드 신설
- `lib/providers/trash_providers.dart` — `TrashEntriesNotifier` 삭제, `trashEntriesProvider`를 `Provider.autoDispose`로 재작성 + `purgeExpiredTrash` 함수
- `lib/mock/mock_data.dart` — `mockTrashEntries` 삭제, 기존 mock 중 일부에 `isDeleted`+`deletedAt` 미리 심음(정상범위 1개 이상 + 15일 초과 자동정리 시연용 1개 이상)
- `lib/main.dart` — `runApp()` 전 `purgeExpiredTrash(container)` 호출 + `ProviderContainer`/`UncontrolledProviderScope`로 전환

**화면 변경**
- `closet_main_screen.dart`/`composition_main_screen.dart`/`style_log_main_screen.dart`/`trash_main_screen.dart` — `GalleryMainScreen<T>` wrapper로 재작성(내부적으로 기존 그리드 어댑터 재사용, §2.3)
- `closet_item_detail_screen.dart`/`composition_detail_screen.dart`/`style_log_viewer_screen.dart`/`app_detail_scaffold.dart` — "더보기" 메뉴에 실제 `[삭제]` 연결(§3.6) + composition/style_log 상세는 안전가드(§3.7)
- `settings_screen.dart` — "휴지통" 로우 추가(§3.8)

**위젯 변경**
- `app_main_scaffold.dart` — `bottomFloatingActions` 파라미터 신설(§2.4)
- `selectable_gallery_tile.dart`/`composition_gallery_tile.dart`/`style_log_gallery_tile.dart`/`trash_gallery_tile.dart` — `selected`+`onLongPress`+체크서클(§4.1)
- `grouped_gallery_grid.dart`/`composition_gallery_grid.dart`/`style_log_gallery_grid.dart` — `multiSelectMode`/`selectedIds`/`onItemLongPress` 전달(§4.2)

**테스트**
- 신규 모델 유닛테스트: 3개 모델 × 각 nullable 필드의 `copyWith(field: null)` 검증
- 영향받는 기존 통합테스트(위젯 트리 타입이 유지되면 대부분 통과 예상, 화면 클래스 재작성 규모라 전수 재검증 필요): `closet_main_screen_test.dart`, `composition_style_log_main_screen_test.dart`, `classification_drilldown_test.dart`, `closet_main_shell_widgets_regression_test.dart`, `header_hud_stack_architecture_test.dart`, `app_main_scaffold_shell_migration_test.dart`, `settings_trash_shell_test.dart`
- 신규 통합테스트: 다중선택 진입/토글/종료(4화면), 삭제 실행+Toast+Undo, 휴지통 복원/영구삭제/비우기, 설정→휴지통 네비게이션, 안전가드 3곳, 앱 실행 시 자동 영구삭제

**문서 갱신**
- `docs/history/TechnicalDebt.md` — `copyWith` nullable 필드 항목 해소 처리 + 신규 저-우선순위 항목(자기 자신 id 조회 미가드) 추가
- `docs/history/Decision.md` — 이번 세션에서 확정된 아키텍처/명명 결정 기록(`GalleryMainScreen<T>` 제네릭화, "Main형 우산에 휴지통 포함", `daysUntilPurge` 명명, `deletedAt` sentinel 확장)
- `docs/work/BACKLOG.md` — 그룹 B 완료 처리 시 갱신

**규모**: 4개 메인 화면 전체 재작성 + provider 4개 + model 3개 + detail 3개 + settings + 신규 위젯 3개 — 이 프로젝트 태깅 기준 L/XL. Review·Tester 통과 후 완료 처리 전 Audit 1회(`Workflow_Project.md` §5).

---

## 7. 리뷰 이력

1차 리뷰(아키텍처 섹션 단독, `review` 서브에이전트): P0 없음, P1 2건(피커모달/다중선택 헤더 충돌, Pinned Rule 준수), P2 2건(뒤로가기 겹침, 밀도 fallback), P3 1건(필터칩 스타일) — 전부 반영 완료.

2차 리뷰(전체 4섹션, `review` 서브에이전트): P0 1건(`copyWith` null-clear 버그, §3.2에서 해소), P1 2건(`main.dart` 파일목록 누락 → §6 반영, 액션 디스패치/그리드 위임 방식 미정 → §2.3 확정), P2 2건(안전가드 "정확히 3곳" 표현 부정확 → §3.7에 명시적 예외 근거 추가, `remainingDays` 갱신 방식 → §3.4 `autoDispose` 채택) — 전부 반영 완료.
