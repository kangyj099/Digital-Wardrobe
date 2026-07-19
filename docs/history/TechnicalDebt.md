<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[TechDebt] `composition_preview_carousel.dart`/`composition_detail_screen.dart`에 `AppSpacing` 미등재 매직넘버 — 로컬 named const로 유지 중

상태: 미해결

내용:
Task 6(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`) Review(2026-07-16)가 지적: `lib/widgets/composition_preview_carousel.dart`의 `height: 200`(카드 영역), `viewportFraction: 0.82`(PageView), 페이지 인디케이터 점 `width`/`height: 6`, `margin: 2`가 이름 없는 리터럴로 있었다. `CrossReferenceLinkBar.height`(아래 항목 참고) 전례를 따라 `_cardAreaHeight`/`_pageViewportFraction`/`_dotSize`/`_dotMargin` 이름의 로컬 `static const`로 승격하고 출처 주석을 달아 해소(같은 커밋에서 수정).

같은 Review가 `lib/screens/composition_detail_screen.dart`(Task 4, 커밋 `e015319`)의 "사용된 옷" 가로 스크롤 스트립에 있는 `height: 96`(스트립 전체 높이), 각 아이템 썸네일 `width: 72`(정사각 `SizedBox`라 `height`도 동일하게 72)도 동일하게 미등재 상태이나 이번엔 로그만 되고 아직 손대지 않았다고 함께 지적 — 두 파일 모두 확정된 디자인 값이라 급하지 않으나(막지 않음, not blocking), 다음에 이 두 파일 중 하나를 다시 열 때 `AppSpacing`으로 정식 토큰화 검토.

**추가(Task 7 Review, 2026-07-16)**: `lib/screens/style_log_viewer_screen.dart`(커밋 `7f6db21`)의 "추가 사진" 가로 스크롤 스트립에도 동일 패턴(`height: 96` ×2, `width: 96`)이 이름 없는 리터럴로 추가됐다 — 같은 종류의 값이라 이 항목에 함께 등재.

**정정(Task 8, 2026-07-16)**: 사용자가 스타일일지 열람 카드 구조를 스펙 원문(대표이미지→코디 슬롯 2페이지 캐러셀)대로 정정 지시 — `docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정..." 참고. 이 재구현 과정에서 `composition_preview_carousel.dart`의 `_cardAreaHeight`/`_pageViewportFraction`(고정 200/0.82) 상수 자체가 `AspectRatio(1)` 풀블리드 방식으로 교체되며 **사라진다** — 이 두 상수에 대한 이 항목의 미해결 상태는 Task 8/9 완료로 자연 해소. 나머지(`_dotSize`/`_dotMargin`, `composition_detail_screen.dart`/`style_log_viewer_screen.dart`의 `height: 96`/`width: 72`/`width: 96`)는 여전히 미등재 상태로 남음.

**추가(Task 8 Review, 2026-07-16)**: `lib/screens/style_log_viewer_screen.dart`(커밋 `37ef084`)의 2페이지 캐러셀 점 인디케이터도 `composition_preview_carousel.dart`의 `_dotSize`/`_dotMargin`과 동일한 값(6/2)을 이름 없는 리터럴로 반복했다 — 같은 패턴이 세 번째로 등장(코디 캐러셀→여기)한 것이라, 다음에 손댈 때는 이름 붙이는 것보다 공유 `_PageDotIndicator` 위젯 추출을 우선 검토.

**정정(Task 11, 2026-07-18)**: 사용자와의 여러 차례 정정 끝에 옷 상세의 코디 프리뷰가 `PageView`+점 인디케이터 방식이 아니라 "착용 옷"과 동일한 연속 스크롤 리스트여야 함이 확인됨(`docs/history/Decision.md` "옷 상세 코디 프리뷰를 `PageView` 캐러셀에서..." 참고). `composition_preview_carousel.dart`가 `ListView.separated`로 재작성되며 `_dotSize`/`_dotMargin`(및 점 인디케이터 자체)이 완전히 삭제됐다 — 이 항목의 "점 인디케이터 3번째 반복" 지적은 이제 `style_log_viewer_screen.dart` 단독 사례로 좁혀짐(공유 위젯 추출 필요성 자체가 낮아짐, 반복이 1곳뿐이라). 새로 도입된 `_tileSize`(96, 코디 카드 고정 크기)는 이름 있는 로컬 const로 이미 승격돼 있어 추가 조치 불필요.

조치 방향(착수 조건): `AppSpacing`이 다음에 Edit 대상에 포함되는 작업에서, 남은 항목들(`style_log_viewer_screen.dart`의 점 인디케이터 리터럴, `height: 96`/`width: 72`/`width: 96`, `composition_preview_carousel.dart`의 `_tileSize`)을 정식 토큰으로 승격 검토.

**추가(분류 기준 드릴다운 캡슐 기능 Audit, 2026-07-19)**: `lib/widgets/classification_group_card.dart`의 라벨 배지 `padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2)` — `vertical: 2`가 `AppSpacing` 어떤 토큰과도 안 맞는 미등재 리터럴(가장 가까운 게 `xxs`=4). 이 파일을 다음에 손댈 때 `AppSpacing.xxs`로 교체하거나 근거를 이름 붙여 로컬 const로 승격 검토 — 순수 패딩값이라 급하지 않음.

---

[TechDebt] 코디↔스타일일지 바인딩 액션(`_bindStyleLog`/`_bindComposition`)에 `context.mounted` 가드 부재 (P2)

상태: 미해결(리스크 낮음으로 판단, 착수 보류)

내용:
Step⑦ 1라운드(`docs/superpowers/plans/2026-07-15-step7-detail-binding.md`) Task 4 Review(2026-07-15)가 발견: `composition_detail_screen.dart`의 `_bindStyleLog`가 `await context.push<String>(...)` 이후 `context`를 직접 재사용하진 않지만, `ref.read(...)` 호출 전에 `context.mounted` 체크가 없다 — `.claude/skills/flutter-implementation-conventions/SKILL.md`가 요구하는 "async 작업 완료 후 context 사용 전 mounted 체크" 원칙의 문자 그대로의 위반. 이 async 갭 동안 화면이 실제로 dispose될 경로가 현재는 없어(같은 화면이 계속 떠 있는 상태에서 선택 모달만 push/pop) 런타임 크래시로 이어지지 않았고, Tester도 재현하지 못했다. Task 4 Worker의 결함이 아니라 Plan 코드 스니펫 자체에 있던 갭이라 그대로 구현됨.

**정정(Task 7 Review, 2026-07-16)**: 위에서 "Task 5의 `style_log_viewer_screen.dart`에도 그대로 반복될 예정"이라고 예측했으나, 실제 Task 7(`style_log_viewer_screen.dart`, 커밋 `7f6db21`)의 `_bindComposition`은 `ref.read(...)` 호출 직전에 `if (!context.mounted) return;` 가드를 이미 포함해서 구현됐다 — 이 항목의 범위를 `composition_detail_screen.dart`의 `_bindStyleLog` 단독으로 좁힌다.

조치 방향(착수 조건): `_bindStyleLog`의 `ref.read(...)` 호출 직전에 `if (!context.mounted) return;` 한 줄만 추가하면 해소됨 — 다음에 이 파일을 손댈 때(Editor Draft 구현 등) 함께 정리, 또는 별도로 픽업해도 비용이 매우 낮음.

---

[TechDebt] `SettingsScreen`이 이미 승인된 `04_설정.md` 스펙과 어긋남 — "전체 데이터 삭제"만 제거, 나머지는 보류 (P1)

상태: 부분 해결 — 사용자 확인 필요한 부분 보류 중

내용:
Step⑥(나머지 화면 적용) 완료 시점 Audit(2026-07-15)이 발견: `docs/reference/plan/03_화면별UX명세서/04_설정.md`는 2026-07-09 Design Review에서 승인 확정된 문서로, 로우 2개(알림 토글, 로그아웃/Toast+Undo — confirm 모달 명시적으로 미사용)만 규정하고, 프로필 아이콘 진입점은 옷장/코디/스타일일지 3개 Main 화면 헤더에 있어야 한다고 규정한다. 실제 Step⑥-A 구현(`lib/screens/settings_screen.dart`)은 이 스펙을 참고하지 않고 "다크 모드"/"프로필 편집"/"전체 데이터 삭제"(confirm 모달) 로우를 임의로 추가했다 — PM이 Worker 태스크 스코프 지정 시 이 화면 전용 스펙 문서를 놓치고 `00_페이지 타입 정의.md`의 일반 Utility형 규칙만 참조한 게 원인.

사용자 확인(2026-07-15): "전체 데이터 삭제" 로우(스펙에 아예 없는 데다 존재하지 않는 위험 기능을 노출)만 제거, "다크 모드"/"프로필 편집" 로우는 이번엔 그대로 두고 전체 스펙 재작성 여부는 보류.

남은 드리프트(미해결):
- 로그아웃 로우 자체가 없음(스펙 핵심 요구사항).
- "다크 모드"/"프로필 편집" 로우가 스펙에 없는데도 남아있음.
- 로그아웃 confirm 모달 대신 Toast+Undo 패턴 미구현(애초에 로그아웃 로우가 없어 해당 없음).
- 3개 Main 화면 헤더에 프로필 아이콘 진입점이 없어 `/settings`가 UI로는 도달 불가능한 라우트(직접 URL 진입만 가능).

조치 방향(착수 조건): 이 화면을 다음에 다시 손댈 때, 04_설정.md 원문대로 재구현할지 아니면 현재 확장을 정식 스펙 갱신 대상으로 삼을지부터 사용자 확인 후 진행.

---

[TechDebt] `Composition`/`StyleLog` 모델에 `isIncomplete` 등가 필드 부재 — `05_삭제 & 휴지통.md` 캐스케이드 요구사항 미충족 (P1, 필드 신설은 확정·값 로직은 후속 작업)

상태: 부분 해결 — 필드 신설 방식 확정(2026-07-15), 실제 값 설정/해제 로직은 "Editor Draft 구현" 후속 작업으로 이관

내용:
Step⑥ 완료 시점 Audit(2026-07-15)이 발견: `05_삭제 & 휴지통 (Main형, 플랫+필터 변형).md`가 "옷 삭제 시 코디 캐스케이드 처리"로 "정리 후 0개 남으면 기존 '미완성' 처리 재사용"을 명시하는데, 이는 `Composition` 모델이 이미 `isIncomplete`(또는 동등 개념) 필드를 가져야 함을 스펙이 요구하는 것. 현재 `lib/models/composition.dart`엔 그 필드가 없음(`isDeleted`만 있음). `StyleLog`도 구조적으로 같은 문제가 있을 개연성이 있어 함께 검토했음.

**Decision(2026-07-15, 사용자 확정)**: 두 모델 모두 `ClothingItem.isIncomplete`와 동일하게 **저장 필드**(`bool isIncomplete = false`)로 추가한다(파생 계산 방식 기각). 같은 날 이어진 "Editor 저장 모델 전환"(`Decision.md` 참고) 논의로 판정 기준 자체가 바뀜 — 값을 채우는 로직은 더 이상 "필드 미입력"이나 "캐스케이드로 0개 남음" 같은 데이터 완결성이 아니라 **해당 레코드에 연결된 미커밋 Editor Draft가 존재하는가**로 재정의됨. 이 토글 로직은 Editor 3화면(옷 추가/코디 만들기/스타일일지 추가) 저장 배선과 묶여 있어 Step⑦ 범위 밖, "Editor Draft 구현" 후속 작업에서 함께 처리.

Step⑥-B(선택 모달)에서 옷장(`ClothingItem.isIncomplete` 이미 존재)만 실제 "미완성 항목 탭 → 완성 화면 이동" 분기를 구현하고, 코디/스타일일지는 필드 부재로 TODO 주석만 남겨둔 상태(과설계 회피) — 이 TODO는 필드 신설 후에도 Editor Draft 구현 전까지는 유지.

조치 방향(착수 조건): Step⑦ 착수 시 Data/Architecture Implementation 태스크로 `Composition`/`StyleLog`에 `bool isIncomplete = false` 필드만 우선 추가(기본값 false, 토글 로직 없음) — 캐스케이드 삭제 로직의 "0개 남으면 미완성 재사용" 서술과 선택 모달 완성화면 분기는 Editor Draft 구현 후속 작업까지 계속 보류.

---

[TechDebt] `integration_test/` 파일 3개에 미사용 import 총 4건

상태: 미해결 (사소함)

내용:
Typography Pass 3 코드 반영 Review 중 `integration_test/typography_pass3_test.dart`의 unused_import 경고 2건(`closet_main_screen.dart`, `style_log_gallery_tile.dart`)을 먼저 발견. 이후 분류 기준 드릴다운 캡슐 기능(2026-07-19) Audit이 같은 성격의 경고 2건을 추가로 확인 — `integration_test/style_log_gallery_column_count_test.dart`의 `go_router`/`style_log_cross_reference_gallery` unused import(둘 다 2026-07-18 커밋 `6984001`부터 존재, 이번 기능과 무관한 기존 부채). 전부 `flutter analyze` 기준 unused_import 경고일 뿐, 테스트 통과에는 영향 없는 순수 lint 이슈.

해결 방향: 다음에 각 파일을 손댈 일이 생기면 그때 `import` 줄 제거로 함께 정리. 별도 태스크로 우선순위 부여할 정도는 아님.

---

[TechDebt] `DetailHeaderActions`가 Header/HUD Pinned Rule·Glass primitive보다 먼저 만들어져 금지된 패턴을 담고 있던 문제

상태: **해소됨 (2026-07-14)**

내용:
Header/HUD Stack 재설계(2026-07-13) 완료 후 Audit이 발견: `lib/widgets/detail_header_actions.dart`(Step②-A, `GlassPill`/`GlassCircleButton`/Pinned Rule보다 먼저 제작)가 `CategoryToggleDropdown`과 맨 아이콘버튼(⋯더보기)을 **하나의 스타일 없는 `Row`에 함께 담고 있었다** — Pinned Rule이 금지하는 패턴("하나의 Container/Row 안에 여러 요소를 함께 담아 렌더링 금지")에 정확히 해당.

해소: Step④(Detail 3화면 적용, 2026-07-14) Worker 태스크에서 `DetailHeaderActions` 위젯 자체를 삭제 — `AppMainScaffold`가 `showCategoryToggle`(기본 true)로 `CategoryToggleDropdown`을 이미 독립 `Positioned`로 자동 배치하므로, 남는 "⋯더보기"만 각 Detail 화면이 독립 `GlassCircleButton`으로 감싸 `headerActions`에 직접 넘기는 구조로 대체했다. Worker→Review(P0/P1 없음)→Tester(Pinned Rule 준수를 겹침 여부까지 실측하는 신규 통합테스트 16개 포함 전부 Pass)→Audit(코드 기준 완전 해소 확인) 완료, 커밋 `0f20a46`.

---

[TechDebt] `EditorHeader`가 Glass primitive(`GlassPill`/`GlassCircleButton`)를 쓰지 않는 원시 구현이며, Pinned Rule 적용 여부가 미확정인 Decision-stage 질문

상태: **해소됨 (2026-07-14) — Pinned Rule 예외로 확정, 원시 스타일 유지**

내용:
`lib/widgets/editor_header.dart`는 `GlassPill`/`GlassCircleButton`을 쓰지 않는 원시 `TextButton`/`IconButton` 구현이다. Decision.md대로 Editor는 애초에 `AppMainScaffold`를 안 쓰는 자체 헤더라 Pinned Rule이 그대로 적용되는지(면제되는 자체 헤더인지) 자체가 확인 필요. 취소/도움말 버튼이 Pinned Rule 예외로 면제되는지, 아니면 다른 화면과의 시각적 일관성을 위해 똑같이 Glass화해야 하는지는 Decision-stage 질문 — Worker가 임의로 정하지 말고 PM/사용자 확인 필요. (2026-07-14, Step④ 완료 시 이 항목이 원래 `DetailHeaderActions`와 묶여 있던 항목에서 분리됨 — `DetailHeaderActions` 쪽은 해소됨, 위 항목 참고.)

해소: PM이 `참고자료/목업/코디 제작/코디 제작 화면.txt`(핸드오프 문서)와 `코디 제작.png`를 사용자와 함께 재확인 — 목업이 Editor 상단바를 "상단 네비게이션 바(고정, 54px)"로 명시하고, 비주얼 스타일 섹션은 블러/프로스티드글래스를 바텀시트에만 언급(상단바는 언급 없음)한다는 근거로 "Editor 상단바는 스크롤 콘텐츠 위에 뜨는 글래스 오버레이가 아니라 고정 불투명 앱바"라고 판단, 사용자가 2026-07-14 확정. **`EditorHeader`는 Pinned Rule 적용 대상이 아니며, 현재의 원시 `TextButton`/`IconButton` 스타일이 의도된 예외** — Step⑤는 이 헤더를 Glass화하지 않고 3개 Add/Create 화면에 그대로 연결한다.

---

[TechDebt] `GlassPill`/`GlassCircleButton`이 프로스티드글래스 스타일 값(블러/보더/그림자/투명도) 5개를 서로 복붙 — 공유 소스 없음

상태: 미해결

내용:
Header/HUD Stack 재설계(2026-07-13) 후 Audit이 발견: `lib/widgets/glass_pill.dart`/`glass_circle_button.dart`가 `border: Colors.white.withValues(alpha: 0.2)`, `blurRadius: 8`, `shadow Offset(0,2)/alpha 0.05`, `ImageFilter.blur(sigmaX: 12, sigmaY: 12)`, `fill alpha: 0.38` 값을 각각 독립적으로 하드코딩하고 있다. `GlassCircleButton` 주석 자체가 "`GlassPill`과 동일한 톤을 재사용하기 위함"이라고 밝히면서도 실제로는 값을 복붙한 것 — Step④~⑥에서 floating control이 더 늘어나면 한쪽만 수정되고 다른 쪽이 안 바뀌는 드리프트 위험이 있다.

해결 방향: 두 위젯이 공유하는 decoration/상수 홀더(예: private `_glassDecoration()` 헬퍼, 또는 `AppRadius`/`AppMotion` 옆에 `AppGlassStyle` 같은 이름 있는 토큰 클래스)로 추출 — 이 블러/투명도 값들도 `AppRadius.pill`처럼 "코드에서 먼저 정의되고 나중에 Design Tokens에 등재된" 전례를 따를 후보.

---

[TechDebt] `FadingScrollEdge`가 정적 상단 마스크뿐 — 조건부(남은 콘텐츠 있을 때만)·하단 페이드 미구현

상태: **해소됨 (2026-07-13)**

내용:
사용자가 2026-07-13에 직접 지적한 뒤, 같은 날 정식 스펙(`docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`)을 제공 — Header/HUD Stack 재설계 Worker 태스크에서 `lib/widgets/fading_scroll_edge.dart`(ShaderMask 기반) 자체를 삭제하고 `TopGradientOverlay`/`BottomGradientOverlay`(스크롤 위치 기반 조건부 오버레이, `AppScrollContainer`가 조립)로 교체. Worker→Review(findings 없음)→Tester(스크롤 위치별 opacity 전이 실측 포함 전체 통과)→Audit(P0 없음) 전부 완료, 커밋 `76ead4d`.

---

[TechDebt] `CompositionGalleryTile`이 아직 텍스트만 표시 — 향후 `Composition.coverImagePath` 필드 신설로 해소 예정(사용자 확정)

상태: 미해결 (방향 확정, 미착수 — 단 착수 비용이 낮아짐, 2026-07-16)

내용:
Step③ Audit(2026-07-13)이 P1으로 지적: `CompositionGalleryTile`(`lib/widgets/composition_gallery_tile.dart`)이 코디 이름+계절 텍스트만 표시해 `02_코디 (가상 조합).md`의 "옷장과 동일한 레이아웃/버튼 패턴"(실제 사진 타일) 요구와 어긋난다. 대응 방식 3가지(대표 아이템 이미지 1장 재사용 / 미니 아트보드 합성 렌더 / `StyleLog`처럼 `coverImagePath` 필드 신설)를 검토한 결과 사용자가 **`coverImagePath` 필드 신설**로 확정(2026-07-13) — 단, 지금 당장 착수하지 않고 현행 텍스트 표시를 유지한 채 이후 라운드로 미룬다. 필드 신설 시 사용자가 대표 이미지를 지정/캡처하는 로직(신규 기능)이 선행돼야 하므로 순수 Frontend 표시 변경이 아니라 Data/Architecture 결정 + Editor(Step⑤) 연동이 함께 필요.

**갱신(2026-07-16)**: Step⑦ 상호참조 썸네일 작업(Task 6, `docs/history/Decision.md` "Detail 화면 상호참조를 텍스트 칩 → 썸네일 캐러셀/갤러리로 확장" 항목)에서 `Composition.coverImagePath` 필드 + "null이면 첫 옷 이미지로 폴백" 파생 provider가 이미 생긴다. `CompositionGalleryTile`을 이 provider로 갈아끼우기만 하면 되므로 착수 비용이 크게 낮아졌다 — 여전히 착수하지는 않음(이번 라운드 스코프 아님), 다음에 이 파일을 만질 때 저비용으로 처리 가능하다는 점만 기록.

---

[TechDebt] 코디 아이템 개수 상한(15개) 결정은 됐으나 코드에 미반영 — Editor(코디 만들기) 구현 시 적용 필요

상태: 미해결

내용:
`docs/history/Decision.md` "Detail 화면 상호참조를 텍스트 칩 → 썸네일 캐러셀/갤러리로 확장" 항목에서 코디 1개당 옷 개수 상한을 15개로 확정(2026-07-16, 사용자 확인). 코디 만들기(Editor) 화면이 아직 skeleton 상태라 지금 강제할 대상 자체가 없음 — "코디 만들기(편집)" 화면의 아트보드 아이템 추가 로직 구현 시(아이템 추가/드롭 처리 지점) 이 상한을 실제로 체크하는 로직을 넣을 것.

---

[TechDebt] Step③ Audit(2026-07-13)에서 발견된 소소한 주석/lint 이슈 2건 — 다음 해당 파일 터치 시 함께 정리

상태: **해소됨 (2026-07-13)** — 아래 2건 모두 Header/HUD Stack 재설계 작업 중 해소

내용:
1. ~~`lib/widgets/app_main_scaffold.dart:29`와 `lib/screens/closet_main_screen.dart:73`의 groupingBar 관련 주석 불일치~~ — Header/HUD Stack 재설계(2026-07-13, 커밋 `76ead4d`)로 `app_main_scaffold.dart`가 전면 재작성되며 groupingBar skeleton 주석이 3화면 전부 "Step⑦(기능 구현)에서 실제 그룹형 드릴다운으로 대체 예정"으로 일치(Audit 확인). **해소됨.**
2. ~~`integration_test/composition_style_log_main_screen_test.dart:8`에 미사용 import~~ — Header/HUD Stack 재설계 Worker 태스크(2026-07-13)가 같이 정리함. **해소됨.**

---

[TechDebt] `StyleLog` 모델에 정렬/필터 기준 필드(날씨/옷 종류/계절) 자체가 없어 스타일일지 메인 다중 필터 UI를 구현할 수 없음

상태: 미해결

내용:
`03_스타일 일지.md` UX명세서는 스타일일지 메인의 정렬/필터로 "날짜, 옷 종류, 날씨, 계절 기준 지원(역순 보기 옵션 포함)"을 요구하지만, `StyleLog`(`lib/models/style_log.dart`) 모델에 `season`/`weather`/착용 옷 종류에 대응하는 필드가 전혀 없다(날짜만 `wornDate`로 존재). Step③(코디/스타일일지 메인 적용, 2026-07-13)에서 `style_log_main_screen.dart`를 `AppMainScaffold`로 마이그레이션하며 Review가 이 사실을 지적 — 이전 Step①(전체 화면 Skeleton) 단계엔 "헤더 (스타일 일지 ▾ + 필터 칩)"이라는 placeholder 주석이라도 있었으나, 이번 마이그레이션에서 비기능 정렬 아이콘 하나만 남기고 그 흔적이 사라졌다. 실제 필터 구현은 `StyleLog` 모델 확장(Data/Architecture 레이어 결정) 없이는 불가능 — 모델 필드 추가가 선행돼야 함.

---

[TechDebt] 화면 간 반복 복제된 UI 블록 — Step④에서 4번째 사례가 실제로 발생, 추출 임계점 재검토 필요 (P2)

상태: **1~5번 사례 해소됨(2026-07-15)** — Step⑦ 착수 전 선행 작업(b)로 Worker→Review→Tester→Audit 전부 통과. 6번째 사례(Editor 3화면)는 신규 발견, 미해결(P3, 의도적 보류)

내용:
Step③(코디/스타일일지 메인 적용, 2026-07-13)에서 Review가 지적: (1) FAB 펼침 애니메이션 스캐폴딩(`_buildFabOption`/`_onFabOptionTap`/`AnimatedSize` 블록, 약 35줄)이 `closet_main_screen.dart`와 `style_log_main_screen.dart`에 텍스트만 바꿔 그대로 복제됨. (2) `_densityIcon(int density)` private 메서드가 `closet_main_screen.dart`와 `composition_main_screen.dart`에 코드 100% 동일하게 존재. (3) 갤러리 타일의 "좌하단 반투명 pill + `ConstrainedBox`+ellipsis" 라벨 블록이 `selectable_gallery_tile.dart`/`composition_gallery_tile.dart`/`style_log_gallery_tile.dart` 3곳에 동일 패턴으로 존재. 당시 Review 판정은 P2(논블로킹) — Step④~⑥에서 화면이 늘면 계속 늘어날 것이라 추출을 "다음 Step 진입 전 검토 권장"으로 남겼었음.

**Step④(Detail 3화면 적용, 2026-07-14) Audit이 4번째 사례 확인**: `closet_item_detail_screen.dart`/`composition_detail_screen.dart`/`style_log_viewer_screen.dart`가 `_placeholderContentHeight = 400` 로컬 상수, `GlassCircleButton(icon: Icons.more_horiz, tooltip: '더보기 메뉴', onTap: () {})` headerActions 블록, `AppScrollContainer`+`SingleChildScrollView`+`Column` 래퍼, 라벨 문자열만 다른 `CrossReferenceLinkBar` 단일 placeholder entry까지 거의 동일한 구조로 3번 복제됐다. Step⑤(Editor 3화면)·Step⑥(나머지 화면)이 아직 남아있어 이 패턴이 최소 한 번 더 반복될 가능성이 높음 — 추출 임계점을 넘었다고 판단되면 다음 Worker 태스크(Layer=UI/Screen, Stage=Implementation)로 `ExpandableAddFab`/`AppDensity.iconFor`/`GalleryMetaLabel`과 함께 Detail 3화면용 공용 컴포넌트(카테고리/id/placeholder 라벨/cross-reference entries를 파라미터로 받는)도 같이 검토.

**Step⑥-B(선택 모달, 2026-07-15) Audit이 5번째 사례 확인**: `if (selectionMode) FrostedCloseButton(...) else GlassPill(선택 TextButton)` 헤더 분기와 `floatingActionButton: selectionMode ? null : ...` 분기가 `closet_main_screen.dart`/`composition_main_screen.dart`/`style_log_main_screen.dart` 3곳에 거의 동일하게 반복됐다. 또한 갤러리 타일 좌하단 라벨 pill 패턴(위 항목 (3))도 `trash_gallery_tile.dart`까지 4곳으로 늘었다. Step⑦이 이 파일들을 다시 열어 실제 동작을 붙일 예정이라, 지금 추출하지 않으면 드리프트 위험(한 곳만 고치고 나머지를 놓침)이 Step⑦에서 최대화된다 — Step⑦ 착수 전 추출을 권장(Audit 제안).

**해소(2026-07-15)**: 1~5번 사례 전부 공용 위젯으로 추출 완료 — `ExpandableAddFab`(`lib/widgets/expandable_add_fab.dart`, FAB 펼침), `GalleryMetaLabel`(`lib/widgets/gallery_meta_label.dart`, 갤러리 타일 좌하단 라벨 pill, 4곳), `buildSelectionAwareHeaderActions`(`lib/widgets/selection_aware_header_actions.dart`, selectionMode 헤더 분기), `AppDensity.iconFor`(`lib/theme/app_spacing.dart`, 밀도 아이콘), `AppDetailScaffold`(`lib/screens/app_detail_scaffold.dart`, Detail 3화면 공용 셸 — 4번째 사례도 함께 해소). Worker→Review(P0 없음)→Tester(12개 통합테스트 파일, 130+ 케이스 전부 Pass, `TrashGalleryTile` 신규 폭 제약 버그 잡아냄)→Audit(P0 없음) 전부 완료.

**Audit(2026-07-15)이 새로 발견한 후속 항목**(별도 우선순위):
- (P1) `AppDetailScaffold`의 파라미터가 너무 좁다(`placeholderLabel`/`crossReferenceLabel` 단일 문자열뿐, `body` 슬롯도 실제 cross-reference entry 리스트도 없음) — `02_코디 (가상 조합).md`가 요구하는 실제 Detail 바디(사용된 옷 목록/연결된 스타일일지 목록 등)를 Step⑦에서 바인딩하려면 이 계약을 먼저 넓혀야 한다. Step⑦의 Detail 3화면 착수 시 가장 먼저 처리(호출부 3곳이 아직 적을 때 고치는 게 저렴).
- (P2) `AppDetailScaffold`가 `lib/widgets/`가 아니라 `lib/screens/`에 배치됨 — 같은 역할(Layout-tier 셸)인 `AppMainScaffold`는 `lib/widgets/`에 있어 관례가 어긋난다. 근거로 든 "widgets/ → screens/ 역의존 금지"는 `skeleton_region.dart`(Step②에 은퇴 예정이라고 스스로 명시한 임시 파일) 의존을 피하려던 것이라 오히려 근거가 약함. Editor Draft 구현 이전 아무 때나 낮은 비용으로 정리 가능.
- (P2) `AutoSaveIndicator`(`lib/widgets/auto_save_indicator.dart`) 독스트링과 Editor 3화면(`closet_add_screen.dart`/`composition_editor_screen.dart`/`style_log_add_screen.dart`)의 skeleton 라벨이 여전히 "상시 저장(드래프트 없음)" 구 정책을 서술 — "Editor 저장 모델 전환" Decision(같은 날) 이후로 내용이 안 맞음. 위젯 자체는 아직 어디서도 호출 안 됨(unwired)이라 지금 당장 화면에 영향은 없음 — "Editor Draft 구현" 착수 시 함께 정리.
- (P3, 의도적 보류) Editor 3화면(옷 추가/코디 만들기/스타일일지 추가)이 `EditorHeader`+`skeletonRegion` 2개로 구성된 동일 구조를 텍스트만 바꿔 반복하는 **6번째 사례**를 발견했으나, 이 3화면은 "Editor Draft 구현" 착수 시 통째로 실제 로직으로 재작성될 예정이라 지금 추출하면 이중작업 위험 — Audit 권고대로 지금은 추출하지 않고 기록만.

---

[TechDebt] `CrossReferenceLinkBar.height`(64)가 `AppSpacing`이 아니라 위젯 파일 로컬 const로 남아있음

상태: **해소됨(2026-07-16) — 위젯 자체가 삭제되어 대상 소멸**

내용:
Step②(Component Library) Task 2-A에서 `lib/widgets/cross_reference_link_bar.dart`를 신설하며 Detail 3화면(옷 상세/코디 상세/스타일일지 열람) skeleton의 `height: 64`(상호 참조 링크 바) 값을 그대로 가져왔으나, 이번 태스크의 Edit 대상에 `lib/theme/app_spacing.dart`가 포함되지 않아 `AppSpacing` 토큰으로 승격하지 못하고 위젯 파일 로컬 `static const`로 남겼다. Review(2026-07-13)에서 하드코딩 원칙 위반은 아니라고 판정(이름 있는 const + 출처 주석 확인)했으나, `app_spacing.dart`가 다음에 Edit 대상에 포함될 때 정식 토큰으로 승격 검토가 필요하다고 남겨뒀었다.

**추가 관찰(Step④ Audit, 2026-07-14, P3)**: Detail 3화면이 `CrossReferenceLinkBar`에 넣은 Step④ placeholder entry(`onTap: () {}`, "…Step⑦에서 연동 예정" 라벨)가 `_CrossReferenceLinkChip`(Material+InkWell+`gray100` pill 채움)을 그대로 통과해 렌더링된다 — Main 화면들의 `groupingBar` skeleton(`skeletonRegion()`, 외곽선 박스+텍스트로 명백히 "가짜"임을 표시)과 달리, 실제 완성된 인터랙션 컨트롤과 시각적으로 구분이 안 된다. 의도적 선택(완성된 Step②-A 컴포넌트를 그대로 재사용)이라 문제는 아니지만, Step⑦ 전에 Visual Review를 하는 사람이 "이미 연동된 컨트롤"로 착각할 위험이 있음.

**해소(Task 9, 2026-07-16)**: Step⑦ Task 8/9(`docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정..." 참고)에서 `CrossReferenceLinkBar`를 쓰던 마지막 화면(스타일일지 열람)이 2페이지 캐러셀 구조로 재구현되며 이 위젯을 쓰는 화면이 하나도 남지 않아, `AppDetailScaffold.crossReferenceEntries` 계약과 함께 `lib/widgets/cross_reference_link_bar.dart`/`test/widgets/cross_reference_link_bar_test.dart` 자체를 삭제했다(커밋 `732c57b`) — 위 두 관찰 모두 대상 위젯이 사라지며 자연 해소.

---

[TechDebt] 옷장 메인 재설계 중 추가된 시각적 매직넘버(스크롤마스크/틴트/디버그 상태바 치수) 토큰화 필요

상태: 미해결

내용:
`closet_main_screen.dart`에 추가한 세이지 틴트 컨테이너 크기(240x240)/alpha(0.15), ~~`ShaderMask` stops([0.0, 0.06])~~(Header/HUD Stack 재설계로 `FadingScrollEdge` 자체가 삭제돼 이 항목은 대상이 사라짐), 디버그 상태바 높이(24)·아이콘 크기(14)·도트 크기(6)·폰트 크기(12) 등이 리터럴로 남아있음. 이번 스코프(코너 반경/duration 토큰화)와는 별개라 이번 라운드에서는 토큰화하지 않았으나, 추후 Design Tokens 확정 시 반영 검토 필요.

---

[TechDebt] `AppRadius`(`lib/theme/app_spacing.dart`) — Brand Guide/Design Tokens 문서에 정식 등재 필요

상태: 미해결

내용:
옷장 메인 재설계 시 `AppRadius.sm`(16, 드롭다운 패널)/`AppRadius.pill`(100, 필 버튼)을 코드에서 처음 정의했으나, Design Tokens에는 이 코너 반경 값에 대한 역할명 자체가 없었음. 추후 Brand Guide/Design Tokens 문서에 정식 등재 검토 필요.

---

[TechDebt] `documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류 — 파일럿 초안만 존재, 정식 검토 필요

상태: 해결됨 (2026-07-10) — 실채택 완료. 상세: `Decision.md` 최상단 항목 참고.

내용:
`Digital-Wardrobe-testbed/localTestbed`(브랜치 `feature/skill-extraction-testbed`) 파일럿에서 `hardcoding-prevention`(현 `engineering-principles`)/`flutter-implementation-conventions`와 함께 시험됐으나, 실제 채택 패스(`engineering-principles`/`flutter-implementation-conventions` 채택 Decision 참고)에서는 제외됨. `documentation-conventions`(`Workflow_Project.md` §1.4/§1.5 대상)와 `uiux-design-conventions`(`Workflow_Design.md`의 Layer Boundary Rule + Design/Visual Review 체크리스트 대상)는 아직 파일럿 초안 상태로만 존재. 채택 여부/타이밍 재검토 필요.

참고: 파일럿 원본(`Digital-Wardrobe-testbed/localTestbed/REPORT.md`)은 이후 해당 worktree 삭제로 더 이상 존재하지 않음 — 내용은 채택 Decision 항목에 요약됨.

---

[TechDebt] `.superpowers/sdd/`의 플랫(non-namespaced) 파일명이 서로 다른 plan 간 충돌

상태: 미해결

내용:
`task-N-brief.md`, `task-N-report.md` 같은 파일명이 plan별로 구분되지 않고 공유됨. 서로 다른 plan(예: git-flow-commit-policy plan과 flutter-frontend-hifi-screens plan)이 둘 다 Task 7을 가지면, 나중 plan의 Task 7 산출물이 앞선 plan의 Task 7 파일을 덮어씀.

발견 경위:
2026-07-09 세션 인계 실패 조사 중 발견.

영향:
같은 세션 내에서 여러 plan을 순차 실행할 때 이전 plan의 task 브리핑/리포트가 유실될 수 있음.

조치 방향(착수 조건):
`.superpowers/sdd/` 하위에 plan-slug 기반 서브디렉토리 또는 파일명 prefix 도입 검토. superpowers 스킬 자체(외부 플러그인)의 스크립트(`scripts/task-brief`, `scripts/sdd-workspace`)를 건드리는 문제라 이 프로젝트 단독으로 고치기 애매함 — 필요시 플러그인 쪽에 이슈 제기 검토.

---

[TechDebt] `guard_git_actions.py`의 세그먼트 분리 매칭 — heredoc 등 일부 셸 구문은 여전히 오탐/누락 가능

상태: 부분 해결 (원래 문제는 고쳐짐, 더 좁은 범위의 한계가 남음)

내용:
원래 문제("COMMIT_RE/PR_CREATE_RE/PUSH_RE가 원본 커맨드 문자열 전체에 `.search()`를 수행해서, 실제 git/gh 호출이 아니라 그 문자열을 텍스트로 담고 있는 커맨드도 차단됨")는 git-flow 정책 재설계 작업 Task 9 fix round에서 해결됨: 이제 커맨드를 셸 연산자(`&&`, `||`, `;`, `|`)로 분리하고, 각 세그먼트의 선두(`VAR=val` 및 `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 같은 흔한 래퍼 제거 후)가 실제로 `git`/`gh` 호출인지만 확인한다. 이 변경으로 fix round 1에서 `sudo git commit` 등 래퍼가 붙으면 게이트가 통째로 뚫리는 새 회귀가 잠깐 생겼으나, fix round 2에서 래퍼 스트리핑을 추가해 해결함.

남은 한계:
- 세그먼트 분리가 순수 텍스트 기반이라, 셸 연산자(`&&`/`;`/`|`)를 리터럴 텍스트로 포함하는 heredoc 본문(예: 이 문서 자체처럼 파이프나 세미콜론이 들어간 프로즈/코드를 heredoc으로 작성하는 커맨드)은 여전히 의도치 않게 여러 세그먼트로 쪼개질 수 있다.
- `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 외의 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)는 스트리핑 대상이 아니라 여전히 게이트를 우회할 수 있다.
- 근본 해결(진짜 셸 파서 사용)은 범위가 커서 여전히 보류.

발견 경위:
Task 2 리뷰(원래 문제 발견) → Task 9 fix round 1(세그먼트 매칭으로 해결 시도) → 리뷰에서 `sudo`/`env`/`exec`/`command`/`time` 래퍼 우회 회귀 발견 → fix round 2에서 래퍼 스트리핑 추가로 해결. 이 과정에서 리뷰어가 heredoc 기반 진단 커맨드가 여전히 오탐될 수 있음을 재확인함.

영향:
- 지정된 7개 래퍼(`sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup`)로 인한 우회는 fix round 2로 닫혔으나, 그 외 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)로 인한 우회는 여전히 가능함.
- 남은 오탐 한계는 이 하네스로 훅 자체를 다루는 문서/테스트 작성 시(특히 heredoc 사용 시) 여전히 마주칠 수 있음 — 불편함 수준.

조치 방향(착수 조건):
비슷한 문제가 반복되거나 작업 여유가 생기면, 정규식 기반 세그먼트 분리 대신 실제 셸 파서(예: `shlex`나 POSIX 셸 문법 파서)로 교체 검토.

---

[TechDebt] `ClothingItem.copyWith`가 nullable 필드(category/season/color/material)를 명시적으로 null로 되돌릴 수 없음

상태: 미해결 (현재 호출부 없어 즉시 영향 없음)

내용:
`docs/history/Decision.md`의 "ClothingItem의 category/season/color/material 4개 필수 필드를 선택 필드로 전환(nullable화)" 결정을 구현하면서(리토핑 커밋), `copyWith`는 기존 관례(`lib/models/style_log.dart`의 `linkedCompositionId ?? this.linkedCompositionId` 패턴)를 그대로 따라 `category: category ?? this.category`식 단순 `??` fallback을 유지했다. Dart의 흔한 nullable-copyWith 함정 그대로 — `copyWith(category: null)`을 호출해도 "안 건드림"과 구분이 안 돼 기존 값이 그대로 유지된다. 즉 한 번 값이 채워진 필드를 나중에 "미분류로 되돌리기"는 지금 구조로 불가능하다. Review(nullable화 리토핑 태스크, 2026-07-19)가 P2로 발견.

영향:
- 지금은 이 필드들을 수정하는 호출부가 아예 없어(`closet_add_screen.dart`가 아직 스켈레톤) 실제로 발동하는 버그는 아니다.
- `closet_add_screen.dart`/편집 플로우 구현 시 "이미 채운 태그를 지운다" 인터랙션이 필요해지는 순간 이 한계에 부딪힌다.

조치 방향(착수 조건):
`closet_add_screen.dart` 실제 구현(편집/수정 폼) 착수 시, sentinel 객체 패턴(예: `Object _unset = Object(); copyWith({Object? category = _unset, ...})`) 또는 별도 `clearCategory()`류 메서드 도입 여부를 그 시점에 결정. 지금 미리 만들지 않는 이유: 실제 소비자가 없는 상태에서 패턴만 먼저 넣는 건 과설계(YAGNI) — 이 프로젝트가 `StyleLog.copyWith`에도 이미 같은 한계를 안고 있어 새로운 문제가 아니라 기존 패턴의 자연스러운 재현.

---