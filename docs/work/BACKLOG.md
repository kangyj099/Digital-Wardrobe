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

**Step 2 완료 (2026-07-09)**: 파일럿(skill-extraction-testbed) 결과 확인 없이 원래 계획(인라인 추가)대로 진행하기로 사용자 지시(테스트베드는 별도 세션 범위, 이 세션에서 무시). Worker 1회 + Development Review 2회(review×2) 사이클로 완료.
- `Workflow_Development.md` §1 Core Principles에 `## Hardcoding Policy (No Magic Values)` 하위 섹션 신설(기존 번호 체계 유지, 새 top-level 섹션 없음).
- `Workflow_Frontend.md`에 그 섹션을 가리키는 cross-reference 한 줄 추가.
- `Decision.md`에 결정 기록 추가(위반/비위반 필드 리스트 포함).
- Review 1차 P2 3건 중 2건 반영(비위반 필드 리스트 누락 보완, Reference 문서에서 시점성 감사 상태 제거해 History로만 유지), 1건("등" 생략으로 인한 clause (c) open→closed list화)은 PM이 가장 사소하다고 판단해 명시적으로 skip. Review 2차 통과(P2 1건은 PM 프롬프트 오기로 인한 false positive로 판정, 실제 문서는 정확).

**⚠️ 커밋 `03a9da5`("docs(policy): add hardcoding principle to Workflow_Development.md §1")는 Step 3(enum화) 완료 시점에 반드시 revert할 것.** 사용자가 2026-07-09에 판단 미스로 이 커밋을 reset했다가 다시 체리픽으로 복구함 — 그 과정에서 이 파일(BACKLOG.md)의 Step 2 완료 기록이 유실됐던 적이 있어(현재 재작성분), git 이력이 다시 꼬일 수 있으니 주의. revert 사유/후속 조치는 아직 미정 — Step 3 완료 시점에 사용자에게 다시 확인할 것(자동으로 revert 실행하지 말 것, 항상 확인 후).

**Step 3 구현 완료 (2026-07-09, 커밋 `724c1cb`)**: `lib/models/enums.dart` 신설(`ClothingCategory`/`Season`/`ClothingMaterial`, 각각 `label` getter + JSON 외부화 예정 `// TODO:` 코멘트), `clothing_item.dart`(`kClothingMaterials` 제거, 3필드 enum화 + `copyWith` 갱신), `composition.dart`(`season`을 `Season?`로 nullable화), `mock_data.dart`/`closet_providers.dart`/테스트 2종(`closet_providers_test.dart`, `gallery_semantics_test.dart`) 갱신. PM이 `flutter analyze`/`flutter test` 재검증 완료(클린). **Development Review 진행 중 — 결과 반영 후 최종 완료 처리.**

**Category enum 값 확정 (사용자 확정, 2026-07-09)**: 8종 — 모자·상의·아우터·하의·원피스·양말·신발·가방/액세서리 (착용순서로 정렬, 03_화면별UX명세서.md §옷 종류 예시 순서 + 현재 mock 데이터의 원피스 포함).

**Season enum 값 확정 (사용자 확정, 2026-07-09)**: 4종 — 여름·겨울·간절기·사계절 (봄/가을 구분 없이 "간절기"로 통합). `03_화면별UX명세서.md`의 "봄→여름→가을→겨울" 정렬 기준과 다른 체계로, 이 결정이 그 문서 기준을 대체함(상세: `Decision.md` 최상단). **그 문서 자체의 갱신은 별도 미착수 — 필요 시 후속 작업.** 기존 mock 데이터의 '봄'/'가을' 값은 '간절기'로 재매핑.

**Step 3 완료 절차 — 사용자 지시(2026-07-09)**: enum화 구현이 끝나도 바로 다음 작업(Task 7 재개 등)으로 넘어가지 말 것. 반드시 Development Review를 거친 뒤 결과를 사용자에게 보고하고 나서 다음 단계로 이동.

**병행 중인 별도 작업 (참고, 이 스프린트 범위 밖)**: skill-extraction 파일럿은 별도 세션이 별도 worktree(`Digital-Wardrobe-testbed`)에서 진행 중 — 이 브랜치/세션에서 중복 착수하지 말 것.

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
