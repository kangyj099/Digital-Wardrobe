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

**전체 화면 Skeleton (8단계 프로세스 Step①) 완료 (2026-07-13).** 옷장 메인을 제외한 신규 화면 10개(코디/스타일일지/휴지통 메인, 상세 3종, Add/Create 3종, 설정) 골격 신설 + 옷장 메인 그룹형 드릴다운 리전 보강, `app_router.dart` 전체 placeholder 승격. Task A~F 전부 Worker→Review 사이클 통과(Tester는 Plan 전체 생략 — 실동작 없는 순수 구조 코드), 통합테스트 28개로 회귀 고정. 진행 중 발견한 하네스 결함 2건(Worker/Review 역할 경계 이탈)도 그 자리에서 수정 — `.claude/agents/worker.md`/`review.md`/`audit.md`. 세부 근거: `docs/history/Decision.md` 최상단, 세부 커밋 이력은 `git log feature/flutter-hifi-screens`.

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합 완료, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(아키텍처 전환 후 정식 스펙 — 지금은 이쪽을 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md` 최상단)

**다음 세션 작업**: 8단계 프로세스의 Step②(Component Library 구축) — 공용 컴포넌트 후보 리스트업(`AppMainScaffold`/`FrostedBackButton`/`CategoryToggleDropdown`/모달 래퍼 등) → 사용자 검수 → 제작. Step①은 완료됐고 dev-sync도 완료된 상태(§13.4). 하네스 결함 수정 + 문서 간결화 브랜치 2개(`feature/harness-agent-readonly-guard`, `feature/backlog-conciseness`)는 이 브랜치에 병합 완료.

---

# Next

- Brand Guide Pass 3 (Typography) 확정 — 위 Flutter 스프린트에서 임시 확정값(Material 3 기본 type scale)으로 우선 진행 중. 실제 화면을 눈으로 본 뒤 이 임시값을 정식 확정값으로 승격할지 재검토 필요 (`01_BrandGuid.md`의 "하이파이 샘플 제작 후 육안 확인" 조건과 부합).

- **`ui-ux-pro-max` 플러그인에서 Flutter 관련 내용만 추출해 프로젝트 로컬 스킬로 이식** (별도 세션에서 진행 예정, 2026-07-12 확정). 배경: 토큰 소모 진단 중 `ui-ux-pro-max`/`ui-styling` 플러그인 스킬 7종이 이 Flutter 전용 프로젝트와 무관한 내용을 매 턴 상시 로드하고 있는 걸 발견.
  - 이미 조사 완료: `ui-styling`(references 6개, 2,652줄)은 **전부 shadcn/Tailwind 전용, Flutter 내용 0줄** — 통째로 버려도 됨. `ui-ux-pro-max` 메인 `SKILL.md`(703줄)는 17개 스택(React/Vue/Flutter/SwiftUI 등) 포괄이라 그중 Flutter 전용 + 스택 무관 범용 부분(색상 팔레트/폰트 페어링/접근성 원칙 등)만 골라내는 편집 작업 필요.
  - 저작권 검토 완료: MIT License (Copyright Next Level Builder, 저장소 `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`), README에 추가 제약 없음 확인. 사용·수정·재배포 자유, 유일 조건은 **저작권 고지 + MIT 허가문구를 사본에 포함**하는 것 — 새 스킬 파일에 출처 URL과 MIT 고지문을 반드시 남길 것.
  - 원본 소스 경로(로컬 플러그인 캐시, 이 저장소 밖): `C:/Users/User/.claude/plugins/marketplaces/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/SKILL.md`.
  - 목표 산출물: 새 프로젝트 스킬(가칭 `.claude/skills/flutter-ui-reference/SKILL.md`).
  - 완료 후 후속 조치: 이 프로젝트의 `.claude/settings.json`에 `"ui-ux-pro-max@ui-ux-pro-max-skill": false`를 추가해 (기존 `figma@claude-plugins-official: false`와 동일한 방식으로) 이 프로젝트에서만 원본 플러그인 비활성화 검토 — 전역(`~/.claude/settings.json`)은 다른 프로젝트에서 계속 쓸 수 있으니 그대로 둠.

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

(2026-07-13 재발·재해소, 원인 정정) `.claude/worktrees/policy-doc-versioning-audit/` 등 stale worktree 4개(2026-07-12 정리) 이후에도 고아 디렉토리 2개(`policy-audit-fix`, `setting-ui-temp`)가 남아있었음 — `setting-ui-temp`는 이미 pruned된 `policy-doc-versioning-audit` 메타데이터를 가리키는 죽은 `.git` 포인터를 갖고 있어, 그 정리 이후로도 계속 검색을 중복시키고 있었던 것으로 추정(`rm -rf`로 지워 `git worktree remove`를 안 거친 게 원인으로 보임). 2026-07-13에 재발견·삭제 완료.
**원인 정정**: 2026-07-12 기록엔 "이 worktree들이 gitignore 안 돼 있어서"라고 돼 있었으나, 이후 `.claude/worktrees`는 실제로 `.gitignore`에 등록돼 있었음에도 Glob이 여전히 매칭하는 걸 확인 — 진짜 원인은 **이 환경의 Grep/Glob 도구가 `.gitignore`를 아예 참조하지 않는 것**(gitignore 대상인 `.dart_tool/`도 그대로 매칭됨으로 검증). 재발 방지로 `Workflow_Project.md` §15 신설 — 앞으로 병렬 세션용 worktree는 저장소 바깥 형제 디렉토리로만 생성(상세: `Decision.md` 최상단).

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
