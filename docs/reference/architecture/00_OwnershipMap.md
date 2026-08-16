# 소유권 맵

크로스커팅 동작과 공용 컴포넌트가 **어느 파일 한 곳에 사는지** 정하는 정본이다.

같은 동작이 화면마다 따로 구현되는 것을 설계 시점에 막는다.

## 표

| 항목 | 소유 파일 | 비고 |
| --- | --- | --- |
| 삭제 절차(확인→소프트삭제→피드백→되돌리기) | **미정** (6곳 복제) | 통합 Task가 소유 파일을 결정한다. `BACKLOG.md` P2.<br>미정 행에 구현을 하나 더 추가할 때의 처리는 `engineering-principles`를 따른다. |
| 소프트삭제/복원/영구삭제 상태변경 — 옷장 | `lib/providers/closet_providers.dart` | 3개 도메인 구현이 변수명만 다른 복붙이다. 제네릭화 후보로 `BACKLOG.md` P2에 올라 있다.<br>제네릭화하면 3행이 1행이 된다. |
| 소프트삭제/복원/영구삭제 상태변경 — 코디 | `lib/providers/composition_providers.dart` | |
| 소프트삭제/복원/영구삭제 상태변경 — 스타일일지 | `lib/providers/style_log_providers.dart` | |
| 삭제된 옷 포함 판정 | `lib/providers/composition_providers.dart` | `00_DataSchema.md` §13.4가 단일 정본을 명시한다. 두 정의로 갈라지면 안 된다. |
| 커버 이미지 렌더링(에셋/로컬파일 분기) | `lib/widgets/composition_cover_image.dart` | |
| 정적 아트보드 렌더링 | `lib/widgets/interactive_artboard/static_artboard.dart` | `BACKLOG.md` P1(코디 상세를 스냅샷 표시로 전환)이 착수되면 호출부가 1곳으로 줄어든다.<br>그 시점에 등재 기준에서 빠진다. 해당 Task가 이 행을 제거한다. |
| Glass 셸 화면의 Toast + 실행취소 | `lib/widgets/glass_toast.dart` | Utility 셸용 `undoable_action_toast.dart`는 설정 로그아웃 1곳에서만 쓰여 등재 기준에 미달한다.<br>**통합 대상이 아니다.** 의도적 공존이다.<br>근거는 `glass_toast.dart` 독스트링과 `2026-07-21-multi-select-and-trash-design.md` §5다. |
| 다중선택 모드 | `lib/widgets/gallery_main_screen.dart` | 휴지통은 이 셸을 쓰지 않고 로컬로 구현한다. 의도적이다.<br>근거는 `trash_main_screen.dart` 독스트링과 plan Task 10이다. |
| 메인 셸 | `lib/widgets/app_main_scaffold.dart` | |
| 상세 셸 | `lib/screens/app_detail_scaffold.dart` | 같은 역할의 메인 셸은 `lib/widgets/`에 있는데 이것만 `lib/screens/`에 있다.<br>이동 후보로 `BACKLOG.md` P2에 올라 있다. |
| 스크롤 컨테이너 | `lib/widgets/app_scroll_container.dart` | |
| 갤러리 그리드 | `lib/widgets/app_gallery_grid.dart` | |
| 에디터 헤더(크롬) | `lib/widgets/editor_header.dart` | 옷 추가, 코디 편집, 스타일일지 추가 3개 도메인이 쓴다.<br>Glass primitive를 쓰지 않고, Pinned Rule 적용도 미확정이다. `TechnicalDebt.md`에 등록돼 있다. |
| 분류 그룹 그리드 | `lib/widgets/classification_group_grid.dart` | |
| 스타일일지 크로스레퍼런스 갤러리 | `lib/widgets/style_log_cross_reference_gallery.dart` | |
| 메인 헤더 선택 액션(크롬) | `lib/widgets/selection_aware_header_actions.dart` | |
| 선택 진입 버튼 | `lib/widgets/selection_entry_button.dart` | 리프 프리미티브 위의 얇은 어댑터다.<br>메인 3화면과 휴지통이 손으로 반복하다 한쪽에서 `style:` 누락 드리프트가 실제로 발생했다. 그래서 등재한다.<br>근거는 해당 파일 독스트링이다. |
| 추가 FAB(크롬) | `lib/widgets/expandable_add_fab.dart` | 경계선 사례다. 화면이 로컬로 재구현할 수 있는 크롬이라 포함한다. |

## 등재하지 않은 것

| 항목 | 이유 |
| --- | --- |
| 스냅샷 캡처·저장 | 코디 편집기 1개 화면 |
| `InteractiveArtboard` | 코디 편집기 1곳 |
| `UndoableActionToast` | 설정 1곳. Glass Toast 행 비고 참고 |
| 연결 바텀시트 | 미구현이라 소유 파일이 없다. "소유 예정 위치"는 추측이다 |
| `composition_preview_card.dart` | 커버 이미지 렌더링 행의 소비자. 소비자를 행으로 올리면 표가 호출부 목록으로 변질된다 |
| `artboard_item.dart` | 데이터 클래스 |

## 등재 규칙

### 등재 대상

둘 이상의 화면이나 호출부에서 쓰이는 것 중, 아래 두 가지 요건 중 하나 이상을 충족하는 것만 등재한다.

1. **동작** — 확인, 상태변경, 화면전환, 피드백, 되돌리기 중 둘 이상이 정해진 순서로 묶인 절차. 정의는 `flutter-implementation-conventions`를 따른다.
2. **공용 컴포넌트** — 화면이 로컬로 재구현할 수 있는 것. 공용 셸과 크롬, 여러 도메인이 공유하는 렌더링 경로가 해당한다.

단일 화면 전용 로직은 넣지 않는다.(넣으면 이 표가 코드 미러가 되어 즉시 노후화하기 때문)

### 제외 대상

* 모델과 데이터 클래스(`lib/widgets/` 아래에 있어도 마찬가지)
* 리프 프리미티브 (`glass_pill.dart`, `status_badge.dart`, `multi_select_checkmark.dart`, `gallery_meta_label.dart`처럼 화면이 자체 구현으로 대체할 성질이 아닌 말단 표현 위젯)  
    예외 : 리프 프리미티브라도 화면이 손으로 반복해 드리프트가 발생한 기록이 있으면 등재한다.

### 기재 요령
이 표가 답하는 질문은 "누가 소유하는가" 하나다.
* **소유 파일은 정확히 1개** 
    2개 이상이면 그 항목은 설계가 끝나지 않은 것으로 본다.
* 소유 파일이 아직 없으면 "미정"으로 적고 행은 남긴다.  
    (행을 지우면 "미해결"과 "그런 항목이 없음"이 구분되지 않는다.)
* 도메인별로 갈라지는 항목은 도메인당 1행으로 쪼갠다.  
    한 행에 파일 여러 개를 적고 "도메인당 하나라서 단일"이라고 쓰지 않는다.
* 문서화된 의도적 예외가 있으면 소유 파일은 1개로 유지한다.  
    예외 대상과 근거 문서를 비고에 밝힌다. 근거 없는 분기는 소유 파일을 2개로 적어 미해결임을 드러낸다.
* 비고 서술은 셀 안에 둔다. 한 문장마다 `<br>`로 줄을 나눈다.
* 호출부 목록, 개수는 기재하지 않는다.  
    호출부 전수 확인은 `flutter-implementation-conventions`가 grep을 기준선으로 규정한다.  
    저장된 숫자는 검증할 때 어차피 다시 세야 하므로 중복이다.

### 검증 요령

* 행을 추가하거나 수정할 때 소유 파일과 등재 자격은 grep으로만 확인
* 설계 문서나 명세의 열거를 근거로 삼지 않는다. 독스트링에 등장하는 심볼명을 호출부로 세지 않는다.
* 다른 Reference 문서의 소유권 서술과 어긋나면 소유 파일에 대해서는 **이 표가 정본**이다.  
    `00_DataSchema.md` §13.3과 §13.4가 그런 서술을 담고 있다.
* 이 표는 전수를 주장하지 않는다.
* 누락된 항목은 발견한 Task가 즉시 처리한다.  
    Edit 권한이 있으면 직접 추가, 없으면 PM에게 보고.
