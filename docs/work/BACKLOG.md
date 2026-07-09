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
- **주의**: 하드코딩 원칙의 정책 문서화(`Workflow_Development.md` §1 "Hardcoding Policy" 하위 섹션, `Workflow_Frontend.md` cross-reference)는 커밋 후 사용자 지시로 revert됨(커밋 `9e8b66d`) — 원칙 자체는 유효하고 실제 코드에도 이미 적용됐지만, **정책 문서 상에는 더 이상 명문화되어 있지 않음**. 유일하게 남은 기록은 `Decision.md` 상단 항목들. 정책 문서 재반영 여부는 미결— 필요시 사용자에게 확인 후 진행.

(참고) 세션 인계 브릿지 규칙 신설 — PR #4 병합 완료(2026-07-09). Git-flow 커밋/PR 정책 도입 — PR #2 병합 완료(2026-07-08).

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-10) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev에 한 차례 병합 완료, **같은 브랜치에서 계속 작업 이어감** — 새 브랜치 불필요)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`
- 플랜(Task 1~15): `docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md`
- Design Workflow의 "Hi-Fi Sample" 단계를 실제 코드로 겸함 — 완료되면 아래 "Next"의 Hi-Fi Sample 항목도 함께 해소됨.

**다음 할 일: Task 7(옷장 메인 화면) 재개.** Task 1~6은 완료·병합됐고, git stash 등 별도 복구 절차 불필요(작업 트리 깨끗함). Tester 하네스가 갖춰졌으니 Task 7부터 Worker→Review→Tester 사이클 적용. 다만 **Task 7 플랜 원문(`docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md`)의 계절 드롭다운 예시 코드가 `'겨울'`/`'사계절'` 같은 하드코딩된 한글 문자열을 그대로 쓰고 있음 — 이제 `category`/`season`/`material`이 enum이므로, 실제 구현 시 그 리터럴을 그대로 베끼면 새 하드코딩 위반이 생긴다.** `Season.values`/`ClothingCategory.values`를 순회하며 각 `.label`로 드롭다운을 구성할 것. 또한 `selectedSeasonFilterProvider`가 이미 `Season?` 타입이라 플랜의 `DropdownButton<String?>` 예시 코드는 그대로 못 쓰고 `DropdownButton<Season?>`으로 바꿔야 함(2026-07-10 사전 점검에서 확인).

**(참고, 완료됨)** skill-extraction 파일럿(별도 worktree `Digital-Wardrobe-testbed`)은 채택 권고로 종료됐고, 그 결과가 아래 항목에 반영된 실제 채택 작업임 — 더 이상 진행 중인 별개 작업 아님.

**정책 채택**: Workflow 문서의 재사용 가능한 원칙(하드코딩 방지, Flutter 구현 규칙)을 `Workflow_*.md` 인라인 서술 대신 `.claude/skills/`(`engineering-principles`, `flutter-implementation-conventions`)로 분리하는 정책 채택 — `Workflow_Project.md` §1.6(Version Numbering 신설) §12.1(스킬 등재) 갱신 포함. Review×2 + Audit 완료, PR 오픈 후 병합 대기. 상세: `docs/history/Decision.md` 최상단 항목들.

**후속 (2026-07-10)**: 프로젝트 오너가 `docs/knowledge/` 하위를 `.claude/policies/`(정책)·`docs/reference/`·`docs/history/`로 재배치 + 6개 문서를 "앵커"(20줄 이상 항목을 별도 파일로 분리하고 `→ 경로` 포인터로 연결) 방식으로 재정리. 그 과정에서 생긴 회귀(계절 정렬값 오염, 깨진 앵커 경로, `Workflow_Project.md` §7~§11 헤딩/본문 밀림, 헤딩 중복, 고아 파일 등) 전수 점검 후 수정, Review 완료(P0 없음). §12.4 "Task Manifest" 신설로 PM→Worker 자료 전달 시 Read/Edit/Write 접근모드 명시 규약도 추가. 상세: `docs/history/Decision.md` 최상단.

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

- `.claude/worktrees/policy-doc-versioning-audit/` — 이 프로젝트 루트 밑에 untracked로 남아있는, 이 세션/브랜치와 무관한 별도 워크트리(다른 작업 "policy-doc-versioning-audit" 소유로 추정). 이번 세션들에서 조사만 하고 손대지 않음 — 정리 여부는 그 작업의 소유 세션이 판단할 것.

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
