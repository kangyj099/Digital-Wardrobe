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
1. **Step⑦(기능 구현) 1라운드(Task 1~13) 전체 완료, PR #10으로 dev 병합 완료(2026-07-18) — 다음은 "Step⑦ 나머지 스코프"를 별도 Plan으로 착수.** 그룹형 드릴다운 실배선(옷장/코디 메인 2곳), 선택 버튼 진입/다중선택 자체, 휴지통 복원·영구삭제·비우기 실행, 설정 알림/다크모드/프로필 진입 연결. 착수 전 이번 라운드가 스코프 밖으로 미룬 항목(겹친 아이템 팝업/아트보드 실제 렌더링/추가사진 드래그 순서변경/신규 생성 바인딩/Detail "⋯더보기" 메뉴)도 함께 Plan에 반영할 것.
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
