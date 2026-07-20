# 코디 편집기 아트보드 — 격리 위젯(`InteractiveArtboard`) Design

**작성일**: 2026-07-19

**배경**: `docs/work/BACKLOG.md`의 "Step⑦ 나머지 스코프" 그룹 D(에디터급 이월 항목 — 아트보드 실제 렌더링 포함)와 "Editor Draft 구현" 후속 작업의 선행 조각. 그룹 A(분류 드릴다운)가 사용자 검토 대기 중인 유휴 시간에, 그룹 A/B/C와 파일이 전혀 겹치지 않는 독립 작업으로 병행 진행한다. `composition_editor_screen.dart`는 현재 완전 skeleton(`skeletonRegion`)이고, 아트보드를 실제로 그리는 코드는 프로젝트 어디에도 없다(`CompositionPreviewCard`는 커버 이미지 1장만 보여주는 카드일 뿐, 배치 렌더링이 아님) — 그린필드.

**개발 방식**: `Composition`/`ClothingItem` 모델이나 Riverpod provider에 의존하지 않는 완전 독립 위젯으로 개발한다. 별도 워크트리(`Digital-Wardrobe-composition-artboard`)·별도 브랜치(`feature/composition-artboard-widget`, `origin/dev` 기준)에서 진행하며, `integration_test/interactive_artboard_test.dart` 하나로 로컬 mock 데이터만 갖고 단독 검증한다. `composition_editor_screen.dart`에 실제로 연결하는 작업은 이번 스코프에 포함하지 않는다(§8/§9 참고).

**기술 근거**: `00_MVP.md` §6 "Composition canvas: Custom implementation using Flutter GestureDetector + Matrix4 — 적합한 기성 패키지 없음".

---

## 1. 스코프

`02_코디 (가상 조합).md`의 "코디 만들기(편집)" 절 중 **아트보드 자체의 코어 상호작용만** 이번 위젯이 책임진다:

- `ArtboardItem` 리스트 배치 렌더링(x/y/scale/rotation/zIndex)
- 이동(드래그), 크기조절(핸들), 회전(핸들)
- 겹친 영역 탭 → z-순서 팝업(재배열 + 선택)
- 화면 밖으로 드래그 → 삭제 콜백

**화면 레벨 책임(이번 스코프 밖, §8)**: 배경색 스와치, 옷 추가 바텀시트, 코디 이름 필드/저장 버튼, 하단 "사용된 옷 목록" 그리드, undo.

---

## 2. 데이터 계약 — `ArtboardItem`

`Composition`/`CompositionItemPlacement`을 재사용하지 않는다. `clothingItemId`(FK)를 포함하는 순간 위젯이 Composition 도메인에 결합되므로, 완전히 독립적인 좁은 타입을 새로 정의한다.

```dart
// lib/widgets/interactive_artboard/artboard_item.dart
class ArtboardItem {
  const ArtboardItem({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0, // radians
    this.zIndex = 0,
  });

  final String id;
  final String imagePath;

  /// 캔버스 박스에 대한 정규화 좌표(0.0~1.0), 아이템 중심 앵커 기준.
  /// 캔버스 크기(리사이즈/다른 화면 재사용)와 무관하게 배치가 깨지지 않도록 정규화한다.
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;

  ArtboardItem copyWith({double? x, double? y, double? scale, double? rotation, int? zIndex}) => ...;
}
```

나중에 `composition_editor_screen.dart`가 연결될 때 `CompositionItemPlacement` ↔ `ArtboardItem` 변환은 화면(또는 화면 전용 provider)의 책임이다(§9).

### 2.1 아이템 렌더 크기 (Base Size) — 리뷰 반영, 신설

`ArtboardItem`엔 width/height가 없다 — 배경제거된 옷 이미지마다 원본 종횡비가 제각각이고, Flutter는 디코딩 전엔 이미지의 실제 픽셀 크기를 동기적으로 알 수 없다. 겹침 히트테스트(§3)·핸들 오프셋(§4.4)·크기조절 거리비율(§4.3) 전부 "아이템의 렌더 박스 크기"를 전제로 하므로, 이 기준을 명시적으로 정한다:

- `InteractiveArtboard`가 `baseItemSize`(정사각형 한 변, 논리픽셀) 파라미터를 받는다. 기본값은 캔버스 짧은 변 대비 자연스러운 비율로 Worker가 정함(참고치: 25~30%).
- 아이템의 실제 렌더 박스 = `baseItemSize * item.scale` (정사각형, 회전 전 기준).
- 이미지는 이 박스 안에 `BoxFit.contain`으로 그린다 — 디코딩 크기를 기다릴 필요 없이 원본 종횡비를 유지한 채 박스에 맞춰지고(레터박스 여백 발생 가능, 허용), 겹침 판정·핸들 오프셋·크기조절 계산은 전부 이 정사각형 렌더 박스 자체를 기준으로 한다(§3의 "바운딩박스 기준, 알파 비정밀" 방침과 일관).

---

## 3. 위젯 구성

`lib/widgets/interactive_artboard/` (신규 디렉토리, 4개 파일):

- **`artboard_item.dart`** — `ArtboardItem` 데이터 모델(§2)
- **`interactive_artboard.dart`** — 메인 `StatefulWidget`. `LayoutBuilder`로 부모가 준 크기를 그대로 캔버스로 사용(1:1 강제 안 함 — 화면이 `AspectRatio(1)`로 감싸는 건 호출부 책임, §4.3 각도 계산이 이 전제에 의존함). Stack 배치, 탭/겹침 판정 및 삭제 딤드·휴지통 아이콘 오버레이 관리(구체 아키텍처는 §4.1 신설 참고).
- **`artboard_item_view.dart`** — 개별 아이템 1개 렌더 + (선택 시) 바운딩 박스 아웃라인 + 핸들 3개.
- **`artboard_overlap_popup.dart`** — 겹침 팝업(§4.5).

**겹침 판정 기준**: 탭 좌표가 아이템의 **사각 바운딩박스**(§2.1의 렌더 박스, 회전 반영) 안에 2개 이상 걸치면 겹침으로 판정한다 — 배경제거된 옷 이미지의 알파 투명 영역까지 정밀 판정하지 않는다(단순함 우선). 이 방침의 트레이드오프: 투명한 모서리끼리만 걸치고 실제 눈에 보이는 픽셀은 안 닿은 경우도 "겹침"으로 오탐될 수 있음 — 리뷰에서 확인된 의도적 단순화, 문제 시 다음 라운드에서 알파 기반으로 정밀화 검토.

---

## 4. 상호작용 명세

### 4.1 히트테스트 · 제스처 아키텍처 (신설 — 리뷰 P0 반영)

**탭과 드래그를 서로 다른 인식기로 분리한다.** Flutter의 Tap/Pan 제스처 인식기는 이동 임계값(터치 슬롭)으로 자연히 분화되므로(움직임 없으면 Tap 승리, 움직이면 Pan 승리) 수동 중재 로직 없이 공존한다.

- **탭 분류(선택/겹침 판정)**: `interactive_artboard.dart` 최상위에 캔버스 전체를 덮는 `GestureDetector.onTapUp` 1개만 둔다. 탭 좌표를 받아 `items`를 순회해 좌표가 각 아이템의 바운딩박스(§2.1) 안에 드는지 직접 계산한다 — 위젯 트리의 기본 히트테스트에 위임하지 않는다(그걸로는 "몇 개가 겹쳤는지" 자체를 알 수 없다). 0개=선택해제, 1개=그 아이템 선택, 2개 이상=§4.5 팝업 오픈.
- **드래그(몸체/핸들)**: 아이템 몸체 및 핸들 3개는 각자 독립적인 `GestureDetector.onPanStart/Update/End`를 가진다. Stack의 기본 히트테스트(나중에 그려진, 즉 zIndex가 큰 위젯이 우선)를 그대로 활용한다 — 겹친 영역을 몸체로 곧바로 드래그하면 **zIndex가 가장 큰(최상단) 아이템의 pan 감지기가 자동으로 이긴다** → `02_코디.md` "겹친 이미지 이동 시 기본은 최상단 옷" 요구사항이 별도 분기 코드 없이 자연히 충족된다(리뷰 P1 반영).
- **선택된 아이템의 상호작용 레이어는 paint 순서(zIndex)와 분리한다**: zIndex는 "그림이 그려지는 순서"만 결정하고, 선택된 아이템의 (투명) 몸체 히트테스트 영역 + 핸들 3개는 항상 Stack의 마지막 자식(paint 최상단)으로 별도 삽입해 포인터 우선권을 가진다. 이렇게 안 하면 팝업으로 선택한 아래쪽 아이템이 위쪽 아이템에 시각적으로 가려진 채 남아 몸체 드래그를 영원히 못 받는 문제가 생긴다(리뷰 P1 반영).

### 4.2 선택

- 캔버스 빈 영역 탭 → 선택 해제
- 겹치지 않은 단일 아이템 탭 → 그 아이템 선택
- 겹친 영역 탭 → §4.5 팝업으로 분기(직접 선택 안 됨, 팝업을 거쳐야 함) — 단 **탭이 아니라 곧바로 드래그**하면 팝업 없이 §4.1 아키텍처에 따라 최상단 아이템이 자동으로 움직인다
- 선택된 아이템: 외곽 사각형 안내선(바운딩 박스 아웃라인) + 핸들 3개 표시. 이 상호작용 레이어는 §4.1에 따라 항상 Stack 최상단에 위치하므로, 팝업으로 선택한 하위 아이템도 계속 드래그 가능

### 4.3 핸들 레이아웃 (선택된 아이템 기준, 3개 분리)

| 핸들 | 위치 | 역할 |
|---|---|---|
| 이동 | 바운딩 박스 좌하단 모서리 | 몸체 드래그와 동일 기능(중복, 아이템이 작아졌을 때 잡기 쉬운 여분 히트영역) |
| 크기조절 | 바운딩 박스 우하단 모서리 | 중심 기준 균등(uniform) 스케일만, 회전 없음 |
| 회전 | 바운딩 박스 상단 모서리 중앙에서 위로 뻗은 연결선 끝 | 중심 기준 회전만, 크기 없음 |

바운딩 박스 + 핸들 3개는 아이템과 함께 회전하는 동일 `Transform`(로컬 좌표)에 종속된다 — 회전된 아이템이면 핸들도 시각적으로 함께 기울어짐.

**크기조절 범위 제한** (리뷰 P2 반영): `scale`은 무한정 커지거나 0에 가깝게 작아지지 않도록 상하한을 둔다. 정확한 임계값은 Worker가 §2.1의 베이스 크기 대비 시각적으로 자연스러운 범위로 정하되, 반드시 이름 있는 상수로 선언하고 출처 주석을 남긴다(`engineering-principles` 하드코딩 금지 원칙).

**드래그 중 내부 계산은 위젯의 로컬 픽셀 좌표 기준으로 처리하고, 제스처 종료(커밋) 시점에만 정규화(0~1) 좌표로 변환한다** — `ArtboardItem.x/y`가 정규화 좌표(§2)이기 때문에, 로컬 픽셀 델타를 캔버스 크기로 나누지 않고 그대로 더하면 캔버스 크기에 따라 이동량이 달라지는 오차가 생긴다. 드래그 진행 중에는 로컬 픽셀 단위로 트랜지언트 상태를 유지하고, `onItemsChanged` 호출 직전에만 `dx / canvasWidth`, `dy / canvasHeight`로 정규화한다.

**드래그 계산은 회전에 무관하게 로컬 픽셀 좌표에서 직접 처리** (Worker 구현 메모, 복잡도 낮추는 핵심):

- 이동: 포인터의 로컬 픽셀 델타를 트랜지언트 오프셋에 그대로 누적(커밋 시에만 정규화 변환, 위 참고)
- 크기조절: `scale = scale_dragStart * (현재 포인터-중심 거리 / 드래그시작 시점 포인터-중심 거리)` — 순수 유클리드 거리 비율이라 아이템 회전각과 무관하게 성립(정규화 여부도 무관 — 비율이라 스케일 상쇄됨)
- 회전: `rotation = atan2(dy, dx) - dragStart시점_각도오프셋` — 로컬 픽셀 좌표의 각도만으로 계산, 로컬(아이템)좌표 역변환 불필요. 단, 캔버스가 1:1이 아니면 x/y 축척이 달라 각도가 왜곡될 수 있음 — 이번 위젯은 호출부가 `AspectRatio(1)`로 감싼다는 전제(§3)이므로 왜곡 없음, 캔버스가 정사각형이 아닌 채로 쓰일 경우는 이번 스코프 밖(§8에 추가)

핸들의 **정적 표시 위치**만 아이템의 현재 rotation을 반영한 Transform 안에 두면 되고, 드래그 중 값 계산 로직 자체는 회전 비의존적이다.

### 4.4 핸들 겹침 방지

핸들 위치는 아이템 크기에 비례해서 무한히 축소되지 않는다 — `핸들 오프셋 = max(아이템 실제 반경, 최소오프셋 상수)`. 아이템이 아무리 작아져도 좌하단/우하단/상단 3개 핸들이 서로 붙거나 겹치지 않는다. 최소오프셋 상수 값은 Worker가 터치 히트영역(최소 44x44 논리픽셀 권장, 접근성 일반 기준)을 고려해 결정.

### 4.5 겹침 처리 — 팝업 1개

`02_코디.md` 원문("겹친 영역 터치 → 컨텍스트 메뉴(팝업)로 겹친 이미지 리스트 → 드래그로 순서 재배열", "겹친 이미지 이동 시 기본은 최상단 옷, 아래쪽 옷은 컨텍스트 메뉴에서 선택 후 터치+드래그")을 그대로 따른다 — 탭=선택 팝업과 롱프레스=z-index 팝업으로 분리하지 않는다(브레인스토밍 중 정정, 최초 프레이밍 오류였음).

- 겹친 영역 탭 → `ArtboardOverlapPopup` 오픈: 겹친 아이템들을 z-순서(위→아래)로 나열
- **행 안에서 탭과 드래그의 히트영역을 분리한다**(리뷰 P1 반영 — 같은 영역에 탭·드래그를 겸하면 터치 오인식 위험): 행의 썸네일+라벨 영역을 탭하면 선택, 행 끝의 별도 드래그핸들 아이콘(예: `Icons.drag_handle`)을 잡고 끌어야 순서가 재배열된다.
- 드래그핸들로 재배열 → 즉시 `onItemsChanged`로 zIndex 갱신 커밋
- 썸네일/라벨 영역 탭 → 팝업 닫힘 + 그 아이템 선택(§4.2) — 이후 몸체 드래그/핸들 조작이 그 아이템에 적용됨

### 4.6 삭제 (드래그 아웃)

스펙 원문 동작(햅틱+딤드+휴지통 아이콘+드롭 시 삭제)은 유지하되, 리뷰에서 지적된 두 가지를 구체화한다:

- **경계 이탈 판정 기준**(리뷰 P1 반영): 아이템의 **중심점**이 캔버스 경계를 벗어나는 순간을 "경계 밖" 트리거로 삼는다(바운딩박스 전체가 아니라 중심 1점 기준 — 판정이 단순하고, 삭제되지 않고 되돌아온 아이템은 정의상 중심이 항상 경계 안이었으므로 커밋되는 `x`/`y`(§2, 정규화 좌표)가 항상 `[0.0, 1.0]` 범위 안에 있음이 자연히 보장되어 별도 clamping이 불필요해진다).
- **화면 밖 렌더링 방식**(리뷰 P0 반영): `interactive_artboard.dart`의 캔버스 박스는 호출부가 준 크기 그대로라 자체 Stack 안에 여백이 없다 — 딤드 오버레이·휴지통 아이콘·경계를 넘어간 아이템의 드래그 중 시각 피드백은 `Overlay.of(context)`에 `OverlayEntry`로 그린다(Flutter `Draggable`의 `feedback` 레이어와 동일한 방식). 위젯 자신의 `RenderBox` 경계에 갇히지 않아, 상위 위젯이 무엇으로 감싸든(클리핑 여부와 무관) 안전하게 동작한다.
- 아이템(몸체 또는 이동핸들)을 캔버스 경계 밖으로 드래그하면 햅틱 피드백(`HapticFeedback.mediumImpact()`) + 캔버스 바깥 영역 딤드 처리 + 휴지통 아이콘 노출. 그 상태에서 드롭하면 `onItemDeleted(id)` 콜백 발생. 경계 안으로 되돌아와서 드롭하면 일반 이동으로 커밋(삭제 취소).

---

## 5. 콜백 계약 (Controlled Widget)

```dart
InteractiveArtboard({
  required List<ArtboardItem> items,
  required ValueChanged<List<ArtboardItem>> onItemsChanged, // 제스처 종료(커밋) 시에만 호출, 매 프레임 아님
  required ValueChanged<String> onItemDeleted,
  ValueChanged<String?>? onSelectionChanged, // 하단 목록 동기화용 훅, 이번 라운드는 소비자 없음(§8)
})
```

위젯은 `items`를 진실 소스로 받아들이되, 드래그 중 트랜지언트 시각 피드백은 내부 State로만 유지하고 제스처 종료 시점에만 `onItemsChanged`로 확정값을 올려보낸다(Flutter `Slider`류의 controlled-widget 관례).

---

## 6. 영향 범위 (신규 파일만, 기존 파일 수정 없음)

- `lib/widgets/interactive_artboard/artboard_item.dart`
- `lib/widgets/interactive_artboard/interactive_artboard.dart`
- `lib/widgets/interactive_artboard/artboard_item_view.dart`
- `lib/widgets/interactive_artboard/artboard_overlap_popup.dart`
- `integration_test/interactive_artboard_test.dart`

`lib/models/composition.dart`, `lib/mock/mock_data.dart`, `composition_editor_screen.dart` 등 기존 파일은 이번 스코프에서 건드리지 않는다.

---

## 7. 테스트 전략

프로젝트 관례대로(제스처/UI 상호작용은 Tester 통합테스트, Provider 순수로직만 TDD — 이 위젯엔 순수로직 provider가 없으므로 전부 Tester 몫) `integration_test/interactive_artboard_test.dart` 하나만 신설한다. `MaterialApp(home: Scaffold(body: InteractiveArtboard(...)))`로 위젯만 단독 마운트하고, 로컬 mock `ArtboardItem` 리스트(테스트 파일 내부 상수, `lib/mock/mock_data.dart` 재사용 안 함 — 격리 유지)를 사용한다.

검증 항목:
- 탭 선택 시 핸들 3개 + 바운딩 박스 표시
- 몸체/이동핸들 드래그 → 위치 갱신 확인
- 크기조절 핸들 드래그 → scale만 변경, rotation 불변 확인
- 회전 핸들 드래그 → rotation만 변경, scale 불변 확인
- 겹친 영역 탭 → 팝업 노출, 팝업 내 드래그핸들로 재배열 → zIndex 순서 반영
- 팝업 내 썸네일/라벨 탭 → 선택 전환 확인
- 경계 밖 드래그+드롭 → `onItemDeleted` 발생 + 아이템 제거 확인
- 경계 밖 드래그 후 안쪽으로 복귀+드롭 → 삭제 안 됨(정상 이동 커밋) 확인
- **(리뷰 반영, 신규)** 겹친 영역을 팝업 없이 곧바로 드래그 → zIndex 최댓값(최상단) 아이템이 움직이는지 확인(§4.1/§4.2)
- **(리뷰 반영, 신규)** 팝업에서 하위(비-최상단) 아이템 선택 → 그 아이템이 시각적으로 가려져 있어도 몸체 드래그로 계속 이동 가능한지 확인(§4.1)
- **(리뷰 반영, 신규)** 팝업 행에서 썸네일/라벨 탭과 드래그핸들 드래그가 서로 다른 결과(선택 vs 재배열)를 내는지 확인(§4.5)
- **(리뷰 반영, 신규)** 아이템 중심이 경계에 걸치지만 넘지 않은 상태로 드롭 → 삭제 안 됨, 커밋된 x/y가 `[0.0, 1.0]` 범위 안인지 확인(§4.6)

---

## 8. 스코프 경계 (이번 라운드에 포함하지 않음)

- 배경색 스와치 컨트롤
- 옷 추가 바텀시트(옷장 갤러리 모달)
- 코디 이름 입력 필드 / 저장(V) 버튼
- 하단 "사용된 옷 목록" 그리드 및 아트보드 선택과의 동기화(`onSelectionChanged` 훅만 노출, 소비자 미구현)
- Undo(되돌리기)
- `composition_editor_screen.dart`와의 실제 연결(§9의 후속 메모만 남김)
- 정사각형이 아닌 캔버스에서의 회전 각도 보정(§4.3) — 호출부가 항상 1:1로 감싼다는 전제로 이번 라운드는 다루지 않음

---

## 9. 후속 통합 메모 (composition_editor_screen.dart 연결 시 참고용, 이번 스코프 아님)

- `CompositionItemPlacement` ↔ `ArtboardItem` 변환 계층 필요(화면 또는 화면 전용 provider가 담당). 리뷰에서 지적된 **좌표 변환은 정규화 스케일 문제만이 아니다** — `ArtboardItem.x/y`는 명시적으로 아이템 **중심 앵커**(§2)인데, `CompositionItemPlacement`(`lib/models/composition.dart`)는 앵커 기준 문서화가 아예 없고 `mock_data.dart`의 실제 값들(예: `x: 40, y: 40`류의 작은 절대값)은 중심 앵커보다 모서리 앵커에 더 가까워 보인다 — 캔버스 크기로 단순 나누기만 하면 앵커 불일치로 모든 아이템 위치가 눈에 띄게 어긋날 수 있다. 연결 작업 착수 시 `CompositionItemPlacement`의 실제 앵커 규약부터 먼저 확인/확정 필요.
- `onSelectionChanged`를 하단 "사용된 옷 목록" 그리드와 연결(§4.2의 훅 재사용).
- Undo는 화면 레벨에서 `onItemsChanged`가 올려주는 스냅샷 히스토리 스택으로 구현 검토(위젯 자체엔 히스토리 개념 없음).

---

## 10. 구현 메모 (리뷰 반영, Worker 참고)

- **접근성 최소선**: 핸들 3개(이동/크기조절/회전) 각각에 `Semantics(label: ...)`을 붙인다(예: "이동 핸들", "크기조절 핸들", "회전 핸들"). 스크린리더로 실제 드래그까지 조작 가능하게 하는 전체 접근성 지원은 이번 스코프 밖 — 라벨만 최소로 붙여 완전 무대응은 피한다.
- **성능**: 드래그 중 프레임마다 `setState`가 발생하므로, 아이템 전체를 매 프레임 다시 그리지 않도록 `artboard_item_view.dart` 각 인스턴스를 `RepaintBoundary`로 감싸는 것을 권장한다.
