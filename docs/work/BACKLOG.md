<!--> 프로젝트 현재 상태 스냅샷. 세션 시작 시 여기부터 확인. 항상 최신으로 유지 <-->

# Project

Digital Closet (working title, `digittal_wardrobe`)

Version: 1.0.0+1

Status: 🟡 기획/디자인 단계 (코드는 아직 스켈레톤뿐)

---

# Current Milestone

디자인 시스템 구축 — Brand Guide → Hi-Fi Sample → Visual Review → Design Tokens → Component Library (순서 근거: `docs/knowledge/reference/policy/Workflow_Design.md` §2)

---

# Last Completed

Git-flow 커밋/PR 정책 도입 + PR-create/merge 게이트 재설계 (main/dev/feature 3단계 브랜치, `guard_git_actions.py` 훅, feature→dev PR 자유/dev→main PR만 게이트, `gh pr merge` 하드 블록) — 구현/리뷰 완료, PR #2 오픈 후 병합 대기 (https://github.com/kangyj099/Digital-Wardrobe/pull/2). 상세 기록은 `docs/superpowers/plans/2026-07-08-git-flow-commit-policy.md`, `docs/knowledge/history/Decision.md` 참고.

---

# Current

(없음 — 위 작업은 PM/AI 쪽에서 할 일 끝났고 사용자 merge만 남음)

- Workflow 문서의 재사용 가능한 원칙(하드코딩 방지, Flutter 구현 규칙)을 `Workflow_*.md` 인라인 서술 대신 `.claude/skills/`(`engineering-principles`, `flutter-implementation-conventions`)로 분리하는 정책 채택 — `Workflow_Project.md` §1.6(Version Numbering 신설) §12.1(스킬 등재) 갱신 포함. Review×2 + Audit 완료, PR 오픈 후 병합 대기. 상세: `docs/knowledge/history/Decision.md` 최상단 항목들.

---

# Next

- Brand Guide Pass 3 (Typography) 확정 — **순서 미정**: Type Scale(사이즈/굵기) 실값은 `01_BrandGuid.md`에 "하이파이 샘플 제작 후 육안 확인하여 확정"이라 명시돼 있어, Hi-Fi Sample을 먼저 만들지 Pass 3를 어떻게 쪼갤지 결정 필요 (세션 중 논의하다 다른 작업으로 넘어가 미결정 상태로 남음)
- Hi-Fi Sample (대표 화면 3~5개) 제작

---

# MVP Progress

`docs/knowledge/reference/plan/00_MVP.md` §2 스코프 기준, 코드 구현 여부 (전부 미착수):

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

(없음)

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
