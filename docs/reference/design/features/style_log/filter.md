# Style Log Filter UI Revision

Style Log는 Category Toolbar를 사용하지 않습니다.

대신 Header 아래 Content 위에 떠 있는 Floating Filter Controls를 사용합니다.

Filter UI는 별도의 Layout 영역을 차지하지 않습니다.

화면 상단에 고정된 불투명 Bar 형태가 아니라,
Content 위에 Overlay 되는 Floating Control Layer 형태입니다.

---

# 1. Floating Filter Controls

## Layout

Filter Control은 한 줄 Row 구조를 사용합니다.

Example:

[필터(3)] [ 봄 × | 여름 × | 맑음 × ]

구성:

- Filter Button
- Selected Filter Group

Flutter 기준 구조:

Row
├── FilterButton
└── SelectedFilterGroup

---

## Floating Rule

Filter UI는 기존 Header Floating Design System과 동일한 시각 언어를 사용합니다.

사용:

- Frosted Glass Surface
- Translucent Background
- Blur Effect
- Rounded Corner
- Subtle Border
- Soft Shadow

금지:

- Full width Container
- Opaque Fixed Toolbar
- 일반 Material AppBar 스타일
- 별도의 고정 Filter 영역

Filter UI는 Content 위에 떠 있는 Control Layer입니다.

---

## Component Rule

기존 Header Floating Component와 동일한 디자인 토큰과 Component를 재사용합니다.

새로운 Filter 전용 Floating 스타일을 만들지 않습니다.

---

# 2. Filter Button State

Filter Button은 Filter 상태를 시각적으로 표현합니다.

---

## Default

조건:

- 적용된 Filter 없음

Visual:

[필터]

Style:

- Surface Background
- Neutral Border
- Neutral Text

---

## Active

조건:

- Filter가 하나 이상 적용됨

Visual:

[필터(3)]

Style:

- Primary Tint Background
- Primary Border
- Primary Text

Filter 개수는 현재 적용된 Filter 개수를 표시합니다.

---

## Expanded

조건:

- Filter Panel 열림

Visual:

- Active 상태 유지
- Arrow Rotation
- Pressed State
- Background 약간 강조
- Shadow 약간 감소

---

## Disabled

현재 사용하지 않습니다.

---

# 3. Selected Filter Group Interaction

선택된 Filter는 Selected Filter Group 내부에 표시합니다.

개별 Filter Chip을 각각 Floating 요소로 만들지 않습니다.

하나의 Floating Group 안에서 선택된 Filter를 표시합니다.

Example:

[ 봄 × | 여름 × | 맑음 × ]

---

## Selected Filter Group Rule

- Group 자체는 하나의 Floating Container
- 내부 Filter는 Horizontal Scroll
- 항상 한 줄 표시
- Filter 사이 Divider 사용
- Filter 종류별 색상 구분 없음
- 전체 Group 클릭은 동작하지 않음
- 우측 × 버튼만 삭제 기능 수행

삭제 시:

- 해당 Filter만 제거
- 리스트 즉시 갱신

---

# 4. Filter Panel

Filter Button을 누르면 Floating Panel을 표시합니다.

Visual은 기존 Dropdown 스타일과 동일하게 사용합니다.

사용:

- Rounded Corner
- 동일한 Surface
- 동일한 Border
- 동일한 Shadow
- 동일한 Blur

전체 화면 Modal이 아니라 Anchor Popup 형태를 사용합니다.

---

# 5. Filter Panel Header

Header는 Panel 내부 상단에 고정됩니다.

Example:

────────────────────────
초기화                 필터(제목)              완료
────────────────────────

규칙:

- Header는 스크롤되지 않음
- 왼쪽에 "초기화" 버튼 제공
- 오른쪽에 "완료" 버튼 제공
- 초기화는 선택된 Filter가 있을 때만 활성화
- 초기화 클릭 시 모든 선택 Filter 제거
- 완료 클릭 6.ApplyRule에 따라 판넬 닫고 필터 적

---

# 6. Apply Rule

Filter는 선택 즉시 리스트에 적용하지 않습니다.

사용자가 Panel을 닫는 순간 현재 선택 상태를 한 번에 적용합니다.

Apply Trigger:

- 바깥 영역 터치
- Filter Button 재클릭
- 완료 버튼
- 기타 정상 Close

위 모든 경우 동일하게 Apply 합니다.

별도의 "적용" 버튼은 사용하지 않습니다.

## Implementation Rule

모든 Panel Close Trigger는 동일한 Close Handler를 사용합니다.

Apply 로직을 각 이벤트에 개별 구현하지 않습니다.

모든 경우:

Close Handler 호출 → 현재 선택 상태 Apply → Panel Close

순서로 처리합니다.

Apply 로직은 단일 함수/단일 책임으로 관리합니다.

---

# 7. Filter Sections

Accordion을 사용하지 않습니다.

모든 Filter Section은 기본적으로 펼쳐진 상태로 표시합니다.

Example:

기간
────────────────────────

[ 시작일 ] ~ [ 종료일 ]

(달력)

계절
────────────────────────

□ 봄 ☑ 여름
□ 가을 □ 겨울

날씨
────────────────────────

☑ 맑음
□ 흐림
□ 비
□ 눈

---

# 8. Period Filter

기간 선택은:

- 시작일
- 종료일

두 값을 사용합니다.

Placeholder:

시작일
종료일

Placeholder 영역은:

0000.00.00

문자열 폭 기준으로 고정합니다.

실제 날짜가 입력되어도 Layout Shift가 발생하지 않아야 합니다.

하루만 선택하는 경우:

2026.07.30 ~ 2026.07.30

허용합니다.

---

# 9. Option Layout

Filter Option은 Horizontal Scroll을 사용하지 않습니다.

Wrap Layout을 사용하여 자동 줄바꿈합니다.

Example:

☐ 봄 ☑ 여름
☐ 가을 ☐ 겨울

모바일에서 한 손으로 선택하기 쉬운 터치 영역을 유지합니다.

---

# 10. Future Expansion

현재 구현 대상:

- 기간
- 계절
- 날씨

Phase 2:

- Tag Filter
- 기타 Filter

추가 예정입니다.

추가되는 Filter는 동일한 Section 구조를 사용해야 합니다.

현재는 Tag Filter UI를 구현하지 않습니다.

---

# 11. Motion & Interaction

Filter UI는 상태 변화를 자연스럽게 전달해야 합니다.

---

## Filter Panel

Open / Close Animation:

- Fade
- Scale
- 약 180~220ms

---

## Selected Filter Group Appearance

Panel이 닫히고 Apply될 때:

- Fade In
- Slide In

Animation으로 등장합니다.

---

## Filter Removal

× 버튼 클릭 시:

- Fade Out
- Remove Animation

이후 리스트를 갱신합니다.

---

## List Update

Filter 변경에 따른 리스트 갱신은:

- Chip 변경 이후 자연스럽게 진행
- Cross Fade 또는 부드러운 갱신 사용

---

# 12. UX Principle

Filter UI는 상태(State)를 시각적으로 표현해야 합니다.

사용자는 버튼과 Group의 외형만 보고도 아래 내용을 즉시 인지할 수 있어야 합니다.

- 현재 Filter 적용 여부
- 적용된 Filter 개수
- Filter Panel 열림 여부
- 현재 선택된 Filter 목록
- 어떤 Filter가 적용 중인지
- Filter를 개별 제거할 수 있는지

목표:

시각적 상태 표현만으로 현재 Filter 상태를 이해할 수 있는 UI를 제공합니다.