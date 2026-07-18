<!--> 프로젝트 현재 상태 스냅샷. 세션 시작 시 여기부터 확인. 항상 최신으로 유지 <-->

# Project

Digital Closet (working title, `digittal_wardrobe`)

Version: 1.0.0+1

Status: 🟡 기획/디자인 단계 (코드는 아직 스켈레톤뿐)

---

# Current Milestone

디자인 시스템 구축 — Brand Guide → Hi-Fi Sample → Visual Review → Design Tokens → Component Library (순서 근거: `.claude/policies/Workflow_Design.md` §2)

---

# Last Completed

**Step⑦ 1라운드(Task 1~9) 완료 (2026-07-16).** Detail 3화면(옷 상세/코디 상세/스타일일지 열람) 실데이터 바인딩 + 코디↔스타일일지 바인딩 + 상호참조 썸네일화(캐러셀/갤러리, 정사각형 통일)까지 전부 Worker→Review→Tester 통과, 2차례 Audit(Task 7 직후 1차: P1 2건 발견→즉시 Task 8/9로 흡수, Task 9 직후 2차 최종: P0/P1 없음) 통과. 상세 경위/커밋: `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`, `docs/history/Decision.md`. 2차 Audit이 남긴 P2/P3 후속 항목은 아래 Current 하위 목록에 등록.

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합, PR #10으로 dev 2차 병합 완료 2026-07-18 — Task 7~13/Step②~⑦ 1라운드 전체, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(화면 관통 공용 셸 스펙), `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너 정식 스펙 — 지금은 이 3개를 함께 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md`의 "화면 관통 공용 UI 셸 아키텍처로 전환" 항목)

**이번 세션에서 추가 완료 (2026-07-16→18, Step⑦ 1라운드 Plan에 Task 10~13으로 이어붙여 진행)**: 옷 상세/코디 상세 썸네일 UI 최종 확정.
- Task 11: 옷 상세 "연결된 코디" 섹션 — 사용자가 "코디 이미지를 그냥 이미지 넣지 말고 착용옷 캐러셀처럼"이라고 요청 → 여러 차례 오해(Task 10: 개별 옷으로 풀어헤침→되돌림, 이어서 "크기만 통일"로도 오해) 끝에 최종 확인: `CompositionPreviewCarousel`을 `PageView`+점 인디케이터 방식에서 "착용 옷"과 동일한 **연속 가로 스크롤**(고정 96x96 타일, 페이지 넘김/점 없음)로 교체(커밋 `5540dd4`+`fe31488`). Tester가 스크롤 물리 속성까지 정량 비교해 "착용 옷"과 동일 메커니즘임을 확인.
- Task 12: 코디 상세의 "연결된 스타일일지"도 정사각형(1:1)으로 통일 — `02_코디 (가상 조합).md`의 "1개면 2칸 확대" 스펙 규칙을 사용자 지시로 폐기, `StyleLogCrossReferenceGallery`의 `expandSingle` 파라미터 완전 삭제(옷 상세/코디 상세 둘 다 이제 항상 정사각형 — 아래 P3 "expandSingle 비대칭" 항목은 이걸로 해소됨). 커밋 `424e84f`+`badb675`.
- Task 13: 같은 갤러리를 "기본 2열, 1장이면 1열"로 재조정 — 사용자가 두 화면 모두에서 1장 연결 시 2열 그리드 절반이 비어 보이는 걸 지적, `crossAxisCount`를 `logs.length == 1 ? 1 : 2`로 동적화(Task 12가 폐기한 "2칸 확대"와는 다른 방식 — 스팬이 아니라 열 개수 자체를 줄임, 타일은 계속 정사각형). 커밋 `4a2dbdd`+테스트 커밋. Tester가 실측 픽셀(1장=컨테이너 전체폭 358px, 2장=175px씩 2열)로 검증.
- 넷 다 Worker→Review→Tester 통과(별도 Audit 불필요, S/M 사이즈). 상세 경위: `docs/history/Decision.md`의 대응 항목들, `docs/superpowers/plans/2026-07-15-step7-detail-binding.md` Task 10~13 섹션.
- **PR #10(Task 7~13 전체, 119개 파일) push 후 사용자가 직접 merge, dev 반영 완료(2026-07-18).** 병합 직전 제목/설명이 "Task 7"만 반영한 채 9일간 갱신 안 된 상태였던 걸 발견해 PM이 실제 누적 범위로 갱신 후 merge. `origin/dev`에는 이와 별개로 `feature/harness-agent-readonly-guard`(PR #14, review.md/worker.md 역할경계 수정)도 같은 날 직접 병합됐으나, 이 feature 브랜치엔 동등한 수정이 이미 더 이른 시점(`7079576`/`aaaad68` 커밋)에 반영돼 있어 `git diff HEAD origin/dev`가 완전히 비어있음(내용 차이 없음, 별도 조치 불필요) — 확인 완료.
- 로컬 feature 브랜치는 `origin/dev`보다 커밋 그래프상 2개(머지 커밋들) 뒤처져 있지만 트리 내용은 동일 — 다음 세션에서 `git fetch origin && git merge origin/dev` 한 번 돌려 그래프도 맞춰두면 좋음(§5 관례, 급하지 않음).
- 다음 세션은 아래 "다음 세션 작업" 1번부터 이어가면 됨.

**다음 세션 작업**:
1. **"Step⑦ 나머지 스코프" 진행 중 — 4개 그룹(A~D)으로 분해, 지금은 그룹 A 스펙 승인 대기.**
   - **그룹 A(그룹형 드릴다운 옷장·코디 2곳 + 설정 진입점 이동)**: 스펙 작성·자체검토·커밋 완료 — `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`. **사용자 최종 검토 대기 중** — 승인되면 `superpowers:writing-plans` 스킬로 구현 플랜 작성 후 Worker→Review→Tester(L 사이즈면 Audit까지) 사이클 착수. 승인 전이면 새 세션이 이 파일부터 다시 읽고 이어갈 것.
     - 스펙 작업 중 파생된 선행 작업 2건이 이미 별도로 완료됨(둘 다 이 스펙의 전제 조건이었음): (a) `ClothingItem`의 category/season/color/material 4개 필드 nullable화(`docs/history/Decision.md` 해당 항목, 커밋 `88cbea6`/`92d93ef`/`4c5c522`), (b) `ClothingCategory.dress`(원피스) → `onePiece`(한벌옷) 개명+착용순서 재정렬(`docs/history/Decision.md` 해당 항목, 커밋 `9dfd550`).
     - 스펙 핵심 내용: 옷장(중분류 4종: 날짜/옷종류/계절/착용빈도, 색상은 팔레트 미확정으로 보류)·코디(중분류 3종: 날짜/계절/날씨) 각각 `[중분류▾][소분류▾]` 캡슐 + 플랫/그룹개요(폴더카드)/드릴인 3상태 + 미분류 카드(nullable 필드 대상) + `04_설정.md`의 프로필 아이콘 진입점 조항을 "설정을 카테고리 드롭다운 최하단에" 방식으로 대체.
   - **그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기)**: 아직 스펙 착수 전. 브레인스토밍 중 확인된 것 — `05_삭제 & 휴지통 (Main형, 플랫+필터 변형).md`에 이미 상세 UX 정의 있음(진입점 2가지: [선택]버튼/롱프레스, 즉시휴지통이동+Toast실행취소, 15일 자동영구삭제, 옷 삭제 시 코디 캐스케이드는 스냅샷 아키텍처 전제라 "Editor Draft 구현" 후속으로 공식 이관됨). `ClosetItemsNotifier.softDelete`는 이미 있으나 Composition/StyleLog엔 없음(3-domain 계약 통일 필요). `TrashEntry`는 독립 mock이라 실제 3-domain `isDeleted` 집계로 전환 필요, `deletedAt` 필드 신설 필요(P2, 이미 기록됨). Detail 화면 "⋯더보기" 메뉴는 사실상 이 그룹 소속(유일한 항목이 [삭제]).
   - **그룹 C(설정 나머지 — 알림/다크모드/프로필편집/휴지통 진입)**: 아직 스펙 착수 전. **중요 발견**: `SettingsScreen` 실제 구현이 승인된 스펙(`04_설정.md`, 2026-07-09 확정)과 어긋난 상태(`TechnicalDebt.md`에 이미 P1로 기록됨) — 승인 스펙은 로우 2개(알림 토글, 로그아웃-Toast+Undo)만 규정하는데 실제론 다크모드/프로필편집 로우가 스펙外로 추가돼 있고 로그아웃 로우는 없음. "프로필 편집"은 이 앱에 프로필/로그인 개념 자체가 MVP 기획 어디에도 없어 실체가 불분명(사용자 확인 필요). 다크모드는 코드상 작음(`AppTheme.dark`/토큰 이미 존재, `main.dart`의 `themeMode: ThemeMode.light` 한 줄만 바꾸면 됨)이나 스펙엔 없어 승인 스펙 갱신 여부 결정 필요. 착수 전 사용자가 실제 설정 화면을 먼저 봐야 함(직접 미확인 상태였음).
   - **그룹 D(에디터급 이월 항목 — 겹친 아이템 팝업/아트보드 실제 렌더링/추가사진 드래그 순서변경/신규 생성 바인딩)**: 아직 스펙 착수 전. "Editor Draft 구현"(별도 후속 작업)과 인프라 상당 부분 겹칠 가능성 높음 — 아트보드 렌더링은 그룹 B의 코디 삭제 캐스케이드용 스냅샷 아키텍처와도 연결됨.
   - **"Editor Draft 구현"(Step⑦ 전체 완료 후 별도 후속 작업)**: 도메인별 `draftsProvider`(`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`) 신설, `EditorHeader.onCancel`/`AutoSaveIndicator` Draft 기준 배선, Editor 3화면 실제 Commit/Cancel 로직, `isIncomplete` 토글 로직. Recovery는 세션 내 복원만 범위(앱 강제종료 후 복원은 제외). 착수 전 `AutoSaveIndicator` 독스트링/Editor 3화면 skeleton 라벨의 구 정책("상시 저장" 서술) 정리도 함께(P2, Audit 2026-07-15 발견).
2. **2차(최종) Audit(2026-07-16, Task 9 직후) 발견 P2/P3 — 다음 Step⑦ 나머지 스코프 Plan 착수 전 픽업 검토**:
   - (P2) 옷 상세의 코디 캐러셀/스타일일지 갤러리 섹션에 제목(라벨) 누락 — 코디 상세는 "사용된 옷"/"연결된 스타일일지" 타이틀을 붙이는데 옷 상세는 안 붙임, 비대칭. `closet_item_detail_screen.dart`에 "연결된 코디"/"연결된 스타일일지" `Text(titleSmall)` 헤더 추가로 간단히 해소 가능.
   - (P2/P3) "착용 옷"(구 "추가 사진")이 스타일일지 열람의 스와이프 카드 슬롯 구조(대표이미지→코디 슬롯)에 포함돼야 하는지 미확정 — `03_스타일 일지.md` 23-24행 문언은 포함되는 것처럼 읽히나, 현재 구현(Task 8)은 별도 가로 스크롤 섹션으로 둠. 사용자 확인 필요(다음 세션 질문 후보).
   - (P3) `docs/history/Decision.md` "Detail 화면 상호참조를 텍스트 칩 → 썸네일 캐러셀/갤러리로 확장" 항목의 Impact 문단에 남은 초안 시절 Task 번호(정정 각주로 이미 보강함, `docs/history/Decision.md` 참고) — 추가 조치 불필요, 기록만.
   - ~~(P3) `expandSingle` 파라미터 비대칭~~ **해소(2026-07-18, Task 12)** — 파라미터 자체가 삭제되어 두 화면 모두 항상 정사각형으로 통일됨.
   - (P3) `flutter analyze` 미등재 lint 경고 2건(`integration_test/header_hud_stack_architecture_test.dart:200`, `integration_test/settings_trash_shell_test.dart:86`) — 기존 `typography_pass3_test.dart` 항목과 같은 성격, 다음에 해당 파일 손댈 때 정리.
- ~~Detail 3화면 보일러플레이트 중복~~ **완료(2025-07-15)** — `AppDetailScaffold`로 해소. 이후 Task 9(2026-07-16)에서 `crossReferenceEntries` 계약 자체를 폐기(`CrossReferenceLinkBar`도 삭제) — TechDebt 항목 해소됨.
- (P2) `AppDetailScaffold`(`lib/screens/app_detail_scaffold.dart`)가 같은 역할의 `AppMainScaffold`(`lib/widgets/`)와 달리 `lib/widgets/`가 아닌 `lib/screens/`에 배치됨 — Audit(2026-07-15) 발견, 근거가 약한 배치. 호출부가 3곳뿐인 지금이 이동 비용이 가장 쌈, 급하지 않음.
- 6번째 UI 블록 중복 사례(Editor 3화면 `EditorHeader`+`skeletonRegion` 보일러플레이트, P3, Audit 2026-07-15 발견) — "Editor Draft 구현" 착수로 어차피 재작성될 예정이라 의도적으로 추출 보류(`docs/history/TechnicalDebt.md` 참고).
- 코디 타일 표시 방식(Audit P1, Step③ 때 발견)은 `coverImagePath` 필드 신설(Task 5, 2026-07-16 완료)로 착수 비용이 낮아짐 — `CompositionGalleryTile`(코디 메인 그리드) 이미지 업그레이드는 여전히 미착수(TechDebt 참고).
- 코디 아이템 개수 상한 15개(`Decision.md` 확정, 2026-07-16) — 실제 코드 반영은 Editor 구현 시점.
- Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지 — 이번 라운드엔 제작 안 함. 실제로 만들 때 지킬 계약(Overlay, 레이아웃 비침습)은 위 스펙 §3/§6에 이미 정의됨.
- (P2, 급하지 않음) 휴지통 mock provider에 삭제 시각(`deletedAt`) 필드가 없어 실제 3-domain 집계 전환 시 "N일 남음" 계산 불가 — 모델에 필드 추가 필요. `mockTrashEntries`의 `t3` 항목이 `remainingDays: 27`로 15일 상한을 넘는 값이라 다음에 손댈 때 0~15 범위로 조정.
- ~~`ClothingItem`의 category/season/color/material 4개 필수 필드를 선택 필드로 전환(nullable화)~~ **완료(2026-07-19)** — Worker→Review(1차 P0 발견·재작업)→Review(2차 통과)→Tester 전체 사이클 통과, 실제 영향 파일은 애초 집계(13개)보다 훨씬 좁은 4개였음. 상세는 `docs/history/Decision.md` 해당 항목의 "상태" 줄 참고. 후속: 옷장·코디 메인 헤더 스펙(`2026-07-19-main-header-classification-and-settings-entry-design.md`)의 "옷장은 미분류 없음" 전제를 이제 갱신해야 함(다음 세션 작업으로 진행 중).

---

# Next

- ~~`ui-ux-pro-max` 플러그인에서 Flutter 관련 내용만 추출해 프로젝트 로컬 스킬로 이식~~ **완료(2026-07-18)** — `feature/flutter-ui-reference-skill` 브랜치(저장소 바깥 sibling worktree)에 방치돼 있던 450줄 초안을 이어받아 검증 후 커밋. 검증 내용: (1) Flutter 52개 가이드라인·팔레트/폰트 표 샘플을 원본 플러그인 로컬 캐시(`~/.claude/plugins/marketplaces/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/data/*.csv`)와 대조해 추출 정확성 확인, (2) 라이선스 고지문이 원본 `LICENSE` 파일과 정확히 일치함을 재확인(MIT, Copyright Next Level Builder). 산출물: `.claude/skills/flutter-ui-reference/SKILL.md`. 후속 조치로 `.claude/settings.json`에 `"ui-ux-pro-max@ui-ux-pro-max-skill": false` 추가해 이 프로젝트에서만 원본 플러그인(7개 스킬: banner-design/brand/design/design-system/slides/ui-styling/ui-ux-pro-max) 비활성화 — 전역 설정은 그대로 둬서 다른 프로젝트는 영향 없음.

---

# MVP Progress

`docs/reference/plan/00_MVP.md` §2 스코프 기준, 코드 구현 여부 (전부 미착수):

- [ ] Clothing archiving (AI 배경제거 + 자동태깅)
- [ ] View/filter by tags
- [ ] Composition (가상 코디, 편집 가능)
- [ ] Style Log
- [ ] Clothing-based history
- [ ] Automatic wear count

---

# Current Folder

`lib/` (현재 `main.dart` 스켈레톤만 존재)

---

# Known Issues

(2026-07-13 발견) **Windows에서 `flutter test integration_test/<file> -d windows` 연속 실행 시 파일 잠금으로 빌드 실패.** 이전 실행의 `digittal_wardrobe.exe` 프로세스가 종료되지 않고 남아있으면(`tasklist`로 확인 가능) 다음 빌드가 그 exe를 "쓰기용으로 열 수 없다"(`LINK : fatal error LNK1168`)며 실패한다. **예방**: 통합테스트 파일을 여러 개 순차 실행할 때마다 사이사이 `taskkill //F //IM digittal_wardrobe.exe`(PowerShell/Git Bash 기준, 이미 실행 중인 게 없으면 에러 무시하고 넘어가도 됨)로 강제 종료할 것. Windows가 이 프로젝트에서 `integration_test`를 돌릴 수 있는 사실상 유일한 non-web 디바이스라(Chrome/Edge는 "Web devices are not supported for integration tests yet") 이 문제를 피할 방법이 없음 — 항상 위 예방 조치를 습관화할 것.

(2026-07-13 발견) **`windows/runner/*.cpp`(네이티브 Windows 러너 보일러플레이트)에 non-ASCII(한글 등) 주석을 넣으면 MSVC 빌드가 깨짐.** 이 파일들이 BOM 없는 UTF-8이라 MSVC가 시스템 코드페이지로 해석을 시도하며 non-ASCII 문자에 C4819 경고를 내고, `windows/CMakeLists.txt`의 `/W4 /WX`가 이를 에러로 승격시켜 빌드 자체가 실패한다(실측: `main.cpp`에 넣은 한글 주석 하나가 원인, 커밋 `fab826a`에서 영어로 교체해 해결). `lib/`(Dart)는 이 프로젝트 관례대로 한글 주석을 계속 써도 무방 — 이 문제는 `windows/` 네이티브 C++ 파일에만 해당. **예방**: `windows/runner/` 아래 파일을 건드릴 땐 주석을 영어로 쓸 것.

---

(2026-07-13 재발·재해소, 원인 정정) `.claude/worktrees/policy-doc-versioning-audit/` 등 stale worktree 4개(2026-07-12 정리) 이후에도 고아 디렉토리 2개(`policy-audit-fix`, `setting-ui-temp`)가 남아있었음 — `setting-ui-temp`는 이미 pruned된 `policy-doc-versioning-audit` 메타데이터를 가리키는 죽은 `.git` 포인터를 갖고 있어, 그 정리 이후로도 계속 검색을 중복시키고 있었던 것으로 추정(`rm -rf`로 지워 `git worktree remove`를 안 거친 게 원인으로 보임). 2026-07-13에 재발견·삭제 완료.
**원인 정정**: 2026-07-12 기록엔 "이 worktree들이 gitignore 안 돼 있어서"라고 돼 있었으나, 이후 `.claude/worktrees`는 실제로 `.gitignore`에 등록돼 있었음에도 Glob이 여전히 매칭하는 걸 확인 — 진짜 원인은 **이 환경의 Grep/Glob 도구가 `.gitignore`를 아예 참조하지 않는 것**(gitignore 대상인 `.dart_tool/`도 그대로 매칭됨으로 검증). 재발 방지로 `Workflow_Project.md` §15 신설 — 앞으로 병렬 세션용 worktree는 저장소 바깥 형제 디렉토리로만 생성(상세: `Decision.md` 최상단).

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
