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

**Task 7(옷장 메인 화면) 구현 — 완료.** 하네스 신설 후 첫 Worker→Review→Tester 실사용 사이클, 실제로 Review/Tester 각각 실동작 버그를 1건씩 잡아냄(둘 다 수정·재검증 완료):
- `lib/screens/closet_main_screen.dart` 신설(계절 필터는 `Season.values`/`.label` enum 순회로 구현, 플랜 원문의 하드코딩 문자열 예시를 의도적으로 벗어남), `lib/router/app_router.dart`의 `closetMain` 라우트를 실제 화면으로 교체 — 커밋 `58a22fe`.
- **Review가 P0 발견**: `app_router.dart`의 정적 라우트(`/closet/add` 등)가 동적 `:id` 라우트보다 뒤에 선언돼 있어 go_router가 선언 순서상 `:id`를 먼저 매칭 — FAB "옷 추가하기"가 실제로 망가져 있었음(go_router 소스코드로 직접 확인). 같은 패턴이던 `composition`/`style-log` 그룹도 예방적으로 함께 정리. 커밋 `8145d3f`.
- **Tester가 실동작 버그 발견**: 밀도 토글 아이콘 `onPressed`가 build 시점 지역 변수를 참조하는 stale-closure 버그 — 리빌드 전 빠른 연속 탭 시 순환이 멈춤. 커밋 `10d3643`으로 수정(`ref.read`로 콜백 시점 최신값 재조회). `integration_test/closet_main_screen_test.dart`(Tester 소유, 9개 시나리오)로 회귀 고정 — 커밋 `f8e4f61`/`bc5a2f3`.
- 최종 9/9 통합테스트 Pass, `flutter analyze` 클린. PR 오픈 예정(dev로).

**하네스 확장: Tester 역할 신설 — 완료.** Worker→Review 2단계 사이클에 Tester(런타임 동작 검증, Flutter `integration_test` 기반)를 추가. 상세는 `docs/history/Decision.md` 최신 항목 참고.
- `.claude/agents/tester.md` 신설, `Workflow_Development.md`/`Workflow_Project.md`/`CLAUDE.md` 3종 문서 갱신(역할 정의, 파이프라인 M/L/XL에 Tester 삽입, handoff 템플릿, Definition of Done, Layer×Stage 자료 매핑).
- `integration_test` 패키지 도입 + smoke test 작성, Windows desktop에서 실제 실행 검증 완료(`flutter test integration_test/app_smoke_test.dart -d windows` → "All tests passed!") — 커밋 `39a2958`, `feature/flutter-hifi-screens` 브랜치.
- Android 툴체인(Android Studio/SDK)은 사용자가 별도로 계속 설치 진행 중 — 이번 Tester 셋업 자체는 Windows desktop 경로만으로 완결됐고, Android는 향후 추가 디바이스 타깃 옵션(블로커 아님).
- 이어지는 **Task 7(옷장 메인 화면)** 구현이 새 Worker→Review→Tester 사이클을 처음 타는 실사용 케이스가 됨.

**dev 병합 충돌 해소 + 동기화 프로세스 신설 — 완료 (2026-07-10).** `feature/flutter-hifi-screens`가 dev를 오래 안 당겨받은 사이, dev에 먼저 병합된 별도 PR(#6, 정책/레퍼런스 문서 폴더구조 개편 — `docs/knowledge/**` → `.claude/policies/`+`docs/history/`+`docs/reference/`)과 갈라져 `CLAUDE.md`/`Workflow_Project.md`/`Decision.md`/`BACKLOG.md` 4개 파일에서 충돌 발생. PM이 해결, `flutter analyze` 클린 확인, 남은 옛 경로 참조(`tester.md` 등)도 정리. 재발 방지로 `Workflow_Project.md` §13.4 "Sync Cadence" 신설 — Task 완료 시점/Plan 완료 시점마다 `git fetch && git merge origin/dev` 수행(상세: `Decision.md` 최상단).

Flutter Hi-Fi 스프린트 Task 1~6 + 하드코딩 원칙 정립(category/season/material enum화) — **PR #5 병합 완료 (dev, 2026-07-10, https://github.com/kangyj099/Digital-Wardrobe/pull/5)**.
- Task 1~6: 프로젝트 셋업, 디자인 토큰, mock 모델/데이터, Riverpod provider, go_router 셸, 공용 갤러리 컴포넌트.
- 하드코딩 원칙(모든 값은 (a)런타임 동적 데이터 (b)데이터 파일/리소스 (c)코드 내 const/enum/design token 중 하나를 Source of Truth로 가져야 함) 확정 — 전체 코드베이스에 적용, 예외는 일회성 테스트 코드/명시적 임시 placeholder/긴급 디버그 로깅 3가지뿐.
- `ClothingItem.category`/`season`/`material`, `Composition.season`을 bare `String`에서 `lib/models/enums.dart`의 실제 Dart `enum`(`ClothingCategory` 8종/`Season` 4종/`ClothingMaterial` 18종, 각각 `label` getter)으로 전환 — 위반 필드 4개 전부 해소.
- Season 값 체계를 봄/여름/가을/겨울(기존 `03_화면별UX명세서.md` 기준)에서 여름/겨울/간절기/사계절로 재정의(사용자 확정) — 그 문서도 함께 갱신됨.
- **(해결됨)** 하드코딩 원칙의 정책 문서화(`Workflow_Development.md` §1 "Hardcoding Policy" 하위 섹션, `Workflow_Frontend.md` cross-reference)는 커밋 후 사용자 지시로 한 차례 revert됐었으나(커밋 `9e8b66d`), 이후 `.claude/skills/engineering-principles/SKILL.md`로 정식 재문서화 완료(스킬 분리 정책 채택, 상세: `Decision.md`). 현재 정책 문서(스킬) 상에 명문화돼 있음 — 더 이상 미결 상태 아님.

(참고) 세션 인계 브릿지 규칙 신설 — PR #4 병합 완료(2026-07-09). Git-flow 커밋/PR 정책 도입 — PR #2 병합 완료(2026-07-08).

---

 **하네스 로깅 보강 — 완료 (2026-07-12).** 토큰 소모 진단 중 발견한 두 공백을 메움: (1) Workflow_Project.md §14.1 — 에이전트 스폰 전/handoff 직후 /context 근사 토큰 Delta를 docs/work/TokenLog.md에 기록. (2) §14.2 — Worker/Review/Tester handoff에 Read/Search/Edit 호출 통계(Stats) 기록, docs/work/AgentStats.md에 누적. opt-in, 기본 OFF — docs/work/TokenLog.md 헤더의 Status: ON/OFF 한 줄이 §14.1/§14.2 공통 스위치이며, 토큰 소모 문제가 의심될 때만 켬. worker.md/review.md/tester.md 3종 handoff 포맷도 이 스위치에 따라 Stats 줄을 조건부로 포함하도록 갱신. 부수: stale worktree 4개 정리(위 Known Issues 참고).

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (**마감 2026-07-24로 정정** — 기존 2026-07-10에서 연장, 2026-07-11 사용자 확정. 옷장 메인 재설계가 예상보다 커져 스코프 안정화 위해 조정) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev에 한 차례 병합 완료, **같은 브랜치에서 계속 작업 이어감** — 새 브랜치 불필요)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`
- 플랜(Task 1~15): `docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md`
- Design Workflow의 "Hi-Fi Sample" 단계를 실제 코드로 겸함 — 완료되면 아래 "Next"의 Hi-Fi Sample 항목도 함께 해소됨.

**옷장 메인 화면 재설계 진행 중 (2026-07-10~11, 일시 중단 상태)** — Task 7 완료 후 Visual Review가 아예 없었다는 게 드러나(사용자 질문 "리뷰 과정에 비주얼 리뷰 했어?"로 발견), 목업 스펙과 실제 구현을 정밀 대조해서 재작업 중. **상세 진행상황·설계 스케치·재개 순서는 `docs/work/옷장메인_재설계_체크리스트.md` 참고**(git 추적됨, 항상 최신 — 이전에 `~/.claude/plans/`의 세션 로컬 플랜 파일을 참고 문서로 남겼었는데 그건 이미 낡았고 비추적 파일이라 이 문서로 완전히 대체함).
- 요약: Season enum 개편/Design Tokens 확정/레이아웃 재구축/밀도값 변경/시각 디테일 라운드/컬러 팔레트 변수화까지 Worker 작업은 전부 완료(커밋 `fb15a84`~`399d3ef`), 그중 시각 디테일 라운드(`0da0cee`)와 팔레트(`399d3ef`)는 **Review/Tester 정식 사이클 미실시**(PM 직접 검증만 완료) 상태로 일시 중단.
- 뒤로가기 버튼(요청받음, 미착수), Task 4(검색필드+스크롤바, 미착수)는 체크리스트 문서에 상세 기록.

**다음 재개 시 할 일**: 사용자가 직접 화면을 보고 판단한 추가 디테일이 있으면 먼저 반영 → 시각 디테일 라운드(`0da0cee`) Review→Tester 마무리 → 뒤로가기 버튼 → 팔레트 작업(Task 6) Review→Tester → Task 4(검색필드+스크롤바) → Task 8(스타일일지 열람) 등 나머지 화면으로 이어감. `lib/router/app_router.dart`의 라우트 순서 원칙(정적 경로를 `:id` 동적 라우트보다 먼저 선언, Task 7에서 확립)은 계속 유의.

**(참고, 완료됨)** skill-extraction 파일럿(별도 worktree `Digital-Wardrobe-testbed`)은 채택 권고로 종료됐고, 그 결과가 아래 항목에 반영된 실제 채택 작업임 — 더 이상 진행 중인 별개 작업 아님.

**정책 채택 (완료, PR #6/#8 병합됨)**: Workflow 문서의 재사용 가능한 원칙(하드코딩 방지, Flutter 구현 규칙)을 `.claude/skills/`(`engineering-principles`, `flutter-implementation-conventions`)로 분리 + `docs/knowledge/` 재배치·앵커 구조 정리 + §12.4 Task Manifest 신설 — 전부 `dev`에 반영 완료. 상세: `docs/history/Decision.md` 참고.

**후속 (2026-07-10)**: 남아있던 TechDebt(`documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류) 재검토 후 실채택 — `Workflow_Project.md` §1.4/§1.5, `Workflow_Design.md` Layer Boundary Rule + Design/Visual Review 체크리스트를 두 스킬로 이전, §12.1 등재, Version 범프(Project 2.2/Design 2.1). `feature/skill-conventions-adoption` 브랜치, PR 오픈 예정. 상세: `docs/history/Decision.md` 최상단.

---

# Next

- Brand Guide Pass 3 (Typography) 확정 — 위 Flutter 스프린트에서 임시 확정값(Material 3 기본 type scale)으로 우선 진행 중. 실제 화면을 눈으로 본 뒤 이 임시값을 정식 확정값으로 승격할지 재검토 필요 (`01_BrandGuid.md`의 "하이파이 샘플 제작 후 육안 확인" 조건과 부합).

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

(2026-07-12 해소됨) `.claude/worktrees/policy-doc-versioning-audit/` 등 stale worktree 4개 — 사용자가 3개 정리, 나머지 1개(디렉토리는 이미 삭제된 상태였음)는 `git worktree prune`으로 메타데이터 정리 완료. 원인: 이 worktree들이 gitignore 안 돼 있어서 Grep/Glob 전체 검색 시 같은 파일이 중복 매칭되어 토큰 소모가 배가됐음.

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
