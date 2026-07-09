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

세션 인계(핸드오프) 브릿지 규칙 신설 — PR #4 병합 완료(2026-07-09, https://github.com/kangyj099/Digital-Wardrobe/pull/4). 3회 반복된 "세션 간 작업 맥락 인계 실패"의 구조적 수정: (1) `Workflow_Project.md` §3 "Skill-Internal Ledgers vs. Official Handoff" — gitignore된 스킬 내부 장부(`.superpowers/sdd/*`)는 세션 내부 캐시일 뿐 공식 인계 수단 아님, BACKLOG.md Current 갱신이 각 작업 스텝 완료의 일부(§10 Definition of Done 갱신도 동반)로 승격됨. (2) `Workflow_Project.md` §1.5 Concise Writing — Reference 문서는 간결하게, History 문서는 예외, §3 재현 가능성과 충돌 시 재현 가능성 우선. (3) Stop 훅(`.claude/hooks/check_backlog_freshness.py`) — BACKLOG.md가 HEAD보다 5커밋 이상 뒤처지면 비차단 경고(백스톱용, 1차 방어선 아님). 상세: `docs/knowledge/history/Decision.md` 상단 3개 항목.

(참고) Git-flow 커밋/PR 정책 도입 — PR #2도 병합 완료(2026-07-08).

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-10) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`
- 플랜(Task 1~15): `docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md`
- Design Workflow의 "Hi-Fi Sample" 단계를 실제 코드로 겸함 — 완료되면 아래 "Next"의 Hi-Fi Sample 항목도 함께 해소됨.

**진행 상태**: Task 1~6 완료 (커밋: 29609b3, e2f4e46, ef846b0, 5f5c924, b860811, 9e8e5e6, 34857cb, cef3242, fb786b7, material 추가 08750b0). **Task 7 진행 중 일시중단 (2026-07-09), 재개 예정 2026-07-10.** 현재 브랜치엔 `dev`가 두 차례 머지되어 위 "Last Completed" 항목(세션 인계 규칙 등)이 이미 반영돼 있음. 작업 재개 시 `git stash pop` 필요 (`stash@{0}`: "WIP: flutter-hifi Task7 pause (material hardcoding decision) + settings.json/platform boilerplate").

**일시중단 사유**: `ClothingItem.material/category/season`, `Composition.season`이 폐쇄형 어휘인데 bare `String`으로 타입돼 있어 컴파일타임 강제가 없는 하드코딩 갭을 사용자가 지적. 런타임 `assert`로 때우자는 제안은 근본 해결이 아니라며 사용자가 명시적으로 기각.

**하드코딩 원칙 최종 정의 (사용자 확정, 재논의 금지 — 2026-07-09 표현 보강판, 이전 초안 대체)**:

코드에서 사용되는 모든 값은 반드시 다음 중 하나를 Source of Truth로 가져야 한다.

(a) 런타임에 외부에서 공급되는 동적 데이터 (사용자 입력, API 응답, DB 조회 결과, 시스템 정보 등)
(b) JSON/XML/CSV 등 데이터 파일 또는 리소스
(c) 코드에 별도로 정의된 사전 합의된 const, enum, design token 등

코드 내에 근거 없는 리터럴 값(magic value)을 직접 사용하는 것은 허용하지 않는다.

예외는 다음 세 가지뿐이다: 삭제될 일회성 테스트 코드 / 명시적으로 표시된 임시 placeholder(데이터 파이프라인 미구축 시) / 긴급 디버그 로깅.

이 원칙은 다른 모든 프로젝트 원칙에 우선하며, 기존 코드를 포함한 전체 코드베이스에 적용한다.

이 원칙 위반으로 확인된 필드: `ClothingItem.category`, `ClothingItem.season`, `Composition.season`, `ClothingItem.material` (모두 enum화 필요). 위반 아닌 필드(자유 텍스트라 String이 맞음): `name`, `color`, `location`, `memo`, `imagePath`.

**다음 할 일 (Step 2) — 배치 방식 재검토 필요, 아래 "병행 실험" 결과 먼저 확인할 것**: 원래 계획은 `docs/knowledge/reference/policy/Workflow_Development.md` §1 Core Principles에 위 하드코딩 원칙을 하위 섹션으로 직접 추가하는 것이었음(기존 번호 체계 유지, 새 top-level 섹션 만들지 말 것). 그런데 2026-07-09에 "Workflow 문서엔 흐름/역할만 남기고 재사용 가능한 원칙은 Claude Code Skill로 분리하자"는 대안이 논의되어, 별도 worktree(`C:\Users\User\Documents\Projects\Digital-Wardrobe-testbed`, 브랜치 `feature/skill-extraction-testbed`, `localTestbed/` 안에서 PM/Worker/Review/Audit 팀으로 진행 중, 이 하드코딩 원칙이 첫 시험 대상)에서 파일럿이 진행 중임. **Step 2 착수 전, 그 파일럿 결과(`localTestbed/REPORT.md`, 별도 세션)가 나왔는지 먼저 확인 — 나왔으면 "인라인 추가" 대신 "스킬로 분리 + `Workflow_Project.md` §12.1에 등재" 방식을 검토.** 파일럿이 아직이거나 반려되면 원래 계획(인라인 추가)대로 진행: `Workflow_Frontend.md`에 그 섹션을 가리키는 한 줄 cross-reference만 추가. **`Workflow_Project.md` §4 Task Size 기준 XL로 취급**하고, 개발 리뷰 2회(review ×2) dispatch 후 가장 사소한 지적을 제외한 모든 피드백을 반영할 것.

**다음 할 일 (Step 3)**: Step 2 완료 후, Tasks 1-6 + material 추가 커밋(08750b0)에서 같은 bare-String 패턴 전수 감사. `category`/`season`/`material`(ClothingItem), `season`(Composition)을 enum화. 각 enum에 향후 JSON 외부화 예정이라는 `// TODO:` 코멘트 추가. `mock_data.dart`와 관련 테스트(`mock_data_test.dart`, `closet_providers_test.dart`, `gallery_semantics_test.dart`) 갱신. `flutter analyze` + `flutter test` 클린 확인 후 보고.

재개 지점: `git stash pop` 후 Step 2 배치 방식부터 확인 (사용자가 원칙 내용 자체는 이미 확정했으니 재질문 불필요, 배치 방식만 파일럿 결과에 따라 판단).

**병행 중인 별도 작업 (참고, 이 스프린트 범위 밖)**: 위 skill-extraction 파일럿은 별도 세션이 별도 worktree에서 진행 중 — 이 브랜치/세션에서 중복 착수하지 말 것.

---

# Next

- Brand Guide Pass 3 (Typography) 확정 — 위 Flutter 스프린트에서 임시 확정값(Material 3 기본 type scale)으로 우선 진행 중. 실제 화면을 눈으로 본 뒤 이 임시값을 정식 확정값으로 승격할지 재검토 필요 (`01_BrandGuid.md`의 "하이파이 샘플 제작 후 육안 확인" 조건과 부합).

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
