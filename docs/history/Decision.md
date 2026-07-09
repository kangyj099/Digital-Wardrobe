<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[Decision] `documentation-conventions`/`uiux-design-conventions` 스킬 실채택 — 보류됐던 TechDebt 해소

결정:
- 파일럿(`Digital-Wardrobe-testbed/localTestbed`, 이후 삭제됨 — 내용은 이전 파일럿 세션에서 이미 검증·기록됨)에서 시험만 되고 채택 보류 상태였던 두 스킬을 실제 채택.
- `documentation-conventions`: `Workflow_Project.md` §1.4(Living Documents)/§1.5(Concise Writing)를 원문 그대로 이전. `workflow_project/01_Core Principles.md`의 해당 두 섹션 본문을 포인터로 교체(헤더 번호 유지).
- `uiux-design-conventions`: `Workflow_Design.md`의 Layer Boundary Rule(`workflow_design/01_core principles.md`)과 Design Review/Visual Review 체크리스트(`workflow_design/06_design review.md`) 본문을 이전, 각각 포인터로 교체. 브랜드 값/원칙 텍스트는 복사하지 않고 `01_BrandGuid.md` 참조만 남김(제2의 Source of Truth 방지 원칙 유지).
- `Workflow_Project.md` §12.1 표에 두 스킬 등재: `uiux-design-conventions`는 UI/Screen×Decision(Design) 행, `documentation-conventions`는 3개 Decision-stage 행(UI/Screen, Logic/Feature, Data/API/Architecture) 전부 — Decision-stage 작업이 Reference 문서 신규/갱신 내용을 만들어내는 지점이라는 근거.
- Version 범프: `Workflow_Project.md` 2.1 → 2.2, `Workflow_Design.md` 2.0 → 2.1 (둘 다 챕터 단위 수정, §1.6 기준 minor).

사유:
`engineering-principles`/`flutter-implementation-conventions` 채택 이후 dev에 반영된 앵커 구조 정리 작업이 안정화됐고, 이 TechDebt 항목이 "채택 여부/타이밍 재검토 필요"로 남아있어 재검토한 결과 채택하지 않을 이유가 없다고 판단.

Impact:
- `.claude/skills/documentation-conventions/SKILL.md`, `.claude/skills/uiux-design-conventions/SKILL.md` 신설
- `workflow_project/01_Core Principles.md`, `workflow_design/01_core principles.md`, `workflow_design/06_design review.md` 본문 축소, 포인터 추가
- `Workflow_Project.md` §12.1 갱신, Version 2.1→2.2
- `Workflow_Design.md` Version 2.0→2.1
- `TechnicalDebt.md` 해당 항목 해결 처리

---

[Decision] BACKLOG.md 커밋 승인을 포맷 수정 vs. 진행 기록 수정으로 차등화

결정:
- `CLAUDE.md` "진행 중 작업 상태" 항목에 추가: BACKLOG.md의 **포맷(섹션 구조·배치) 수정**은 기존과 동일하게 일반 Edit 승인 흐름을 거친다. 반면 Current/Last Completed 등에 방금 끝난 작업을 반영하는 **진행 기록용 내용 수정**은 별도 확인 없이, 함께 진행 중인 작업 변경사항의 커밋에 묶어 커밋한다.

사유:
Tester 하네스 확장 작업 커밋 전, PM이 결정문서류 전체(Decision.md/BACKLOG.md 포함)를 습관적으로 커밋 전 확인받으려 했는데, 사용자가 BACKLOG.md의 일상적 진행 기록 갱신까지 매번 확인받는 건 과하다고 판단 — "작업 자체의 일부"로 이미 승격된 BACKLOG.md 갱신(§3 "Skill-Internal Ledgers vs. Official Handoff", 위 관련 Decision 참고)의 취지를 커밋 단계까지 일관되게 적용한 것. 단, 섹션 구조를 바꾸는 포맷 수정은 문서의 향후 가독성/일관성에 영향을 주므로 계속 확인 대상으로 남김.

Impact:
- `CLAUDE.md` "진행 중 작업 상태" 항목 갱신
- 향후 BACKLOG.md 내용(진행 기록) 수정은 관련 작업 커밋에 자동 포함, 포맷 변경만 별도 확인

---

[Decision] 하네스에 Tester 역할 신설 — Worker→Review→Tester→Worker 사이클로 확장

결정:
- 기존 PM/Worker/Review 3역할 구조에 **Tester**를 추가. Review는 정적 코드 리뷰(품질/구조/테스트 코드 존재 여부)만 하고 앱을 실제로 구동하지 않는다는 공백이 있었음 — Tester가 그 공백(런타임 동작 검증)을 담당.
- **실행 메커니즘**: Flutter `integration_test` 패키지. 위젯 트리를 코드로 직접 구동(`tester.tap`/`pump`)해 실제 Riverpod 상태·네비게이션·데이터 흐름을 검증. 이 환경엔 브라우저/GUI 자동화 도구가 없어 이게 유일하게 현실적인 수단.
- **파이프라인 위치**: `Worker → Review → Tester → Worker(수정) → Complete` (M/L/XL). S(단일 수정)는 기본 생략하되, 런타임 동작을 바꾸면 예외적으로 포함.
- **트리거 기준**: Task 크기 무관, 런타임 동작이 있는 모든 작업(`/verify` 스킬의 기존 스킵 규칙과 동일 원칙).
- **테스트 스크립트 소유권**: Tester가 시나리오를 직접 설계하고 `integration_test/`에 작성·커밋(Worker가 자기 구현의 검증 시나리오까지 짜면 셀프리뷰 사각지대 발생). `lib/`는 절대 건드리지 않음 — Tester의 Write 권한은 `integration_test/`로만 제한.
- Tester의 Do: 동작 결과 검사, 비정형 흐름 포함, 연결 기능 회귀 확인, 정의된 모든 상태(성공/로딩/빈상태/오류/재시도/취소 — 실제 구현된 것만) 확인, 화면 간 데이터 일관성, 이탈 후 데이터 유지(현재는 mock 데이터 단계라 in-memory 상태 범위로 한정, 실제 백엔드 영속성/네트워크 중복은 Firebase 연동 후 재적용), Reference 문서/정책 준수. Don't: 구현·리팩토링 제안·코드 스타일 평가 안함, 실제 사용자 시나리오만, Pass/Fail 보고 + 재현 절차 필수.

사유:
사용자가 "지금부터는 테스터가 있어야할 것 같다"며 구체적인 Do/Don't 스펙을 제시. 브레인스토밍으로 실행 메커니즘·파이프라인 위치·트리거 기준·스크립트 소유권 네 가지를 확정(각각 옵션 비교 후 사용자가 선택).

Impact:
- `.claude/agents/tester.md` 신설
- `Workflow_Development.md` §2.1/§2.2(handoff 표·템플릿), §4(Review의 Testing 항목 재정의 + Tester 역할 섹션) 갱신
- `Workflow_Project.md` §2(Roles), §5(Standard Pipeline), §10(Definition of Done), §12.1(Layer×Stage 자료 매핑) 갱신
- `CLAUDE.md` 하네스 운영 원칙 갱신(Tester 언급, Write 범위 제약, 사이클 명칭 변경)
- **환경 셋업 이슈 발견 → 해소**: `integration_test` 실행 검증이 처음엔 Windows desktop 빌드용 Visual Studio "Desktop development with C++" 워크로드 부재로 막혔음(웹 타깃은 `flutter test`가 integration test 미지원). 사용자가 VS C++ 워크로드 설치 완료 → `flutter test integration_test/app_smoke_test.dart -d windows` 실제 실행해 "All tests passed!" 확인, `39a2958` 커밋으로 확정. Android 툴체인은 별도로 계속 설치 진행 중(이 프로젝트가 `android/`/`ios/` 폴더를 가진 실제 모바일 타깃 프로젝트라 필요하지만, 이번 Tester 셋업 자체는 Windows desktop 경로만으로 완결됨 — Android는 향후 추가 디바이스 타깃 옵션).

---

[Decision] Task Manifest 신설 — Required Materials를 Read/Edit/Write 태깅된 구체 목록으로 변환

결정:
- `Workflow_Project.md` §11 Core Operating Principles 항목 11("PM must convert Required Materials into an explicit Task Manifest before spawning a Worker")이 그동안 근거 문서 없는 선언으로만 존재하던 것을, `workflow_project/12_Role Information Access.md`에 신설한 §12.4 "Task Manifest"로 실제 정의함.
- §12.1의 Required Materials는 추상적 카테고리("Plan reference docs" 등)일 뿐이고, PM이 Worker/Review를 스폰하기 직전에 이를 구체적 파일 경로 + 접근모드로 변환한 것이 Task Manifest. 접근모드 3종: **Read**(참고 자료, 수정 금지) / **Edit**(기존 파일 수정) / **Write**(신규 파일 생성). `Skill:` 항목은 항상 Read.
- `worker.md`/`review.md`에 이 태깅 규약을 지키라는 문장 추가(Worker: 도구 권한이 허용해도 Read 태그 파일은 건드리지 않음 / Review: 전부 Read, Edit/Write 계층 없음).
- `Workflow_Project.md` Version 2.0 → 2.1 (§12.4 신설은 chapter-level addition, §1.6 기준 minor bump).

사유:
"PM이 워커에게 일감·자료를 줄 때 Read/Edit/Write 권한이 따로 명시돼 있지 않다"는 지적에서 시작. 확인 결과 Task Manifest 항목 자체가 프로젝트 어디에도 실제로 연결/정의돼 있지 않은 선언뿐이었음 — 이번에 §12.4로 그 실체를 채움.

Impact:
- `workflow_project/12_Role Information Access.md` §12.4 신설
- `Workflow_Project.md` §11 항목 11에 "(see §12.4)" 참조 추가, Version 2.0 → 2.1
- `.claude/agents/worker.md`, `.claude/agents/review.md` 갱신

---

[Decision] `Workflow_Frontend.md`를 Frontend Implementation 단계의 §12.1 앵커(스킬 인덱스) 문서로 재정의 — 이전 minor bump 판단을 major로 정정

결정:
- `Workflow_Frontend.md`의 역할을 "프론트엔드 구현 원칙 문서"에서 "`Workflow_Project.md` §12.1의 UI/Screen×Implementation(Frontend) 행이 가리키는 단일 안정 앵커 문서 — 이 단계에 적용되는 Frontend 스킬 목록을 관리하는 인덱스"로 재정의. §1에 이 역할을 명시적으로 서술하는 문장 추가(기존 스킬 호출 pointer 문장은 그대로 유지).
- `Workflow_Project.md` §12.1 "UI/Screen | Implementation (Frontend)" 행에서 `**Skill: engineering-principles**`/`**Skill: flutter-implementation-conventions**` 개별 항목 제거 — `Workflow_Frontend.md`가 이미 그 두 스킬을 가리키므로 중복. 나머지 두 행(Logic/Feature Implementation, Data/API/Architecture Implementation)은 자기 몫의 앵커 문서가 아직 없어 `engineering-principles` 명시 참조를 그대로 유지.
- `Workflow_Frontend.md` Version 1.1 → 2.0 (MAJOR) — 문서의 근본 사용 패턴이 "재사용 가능한 원칙을 담는 문서"에서 "스킬 인덱스/라우팅 문서"로 바뀜, §1.6 기준 "usage pattern·framework/structure 변경"에 해당. 같은 브랜치 안에서 앞서 내려진 "Version 1.0 → 1.1 minor bump" 판단(아래 "Reference 문서 버전 넘버링 규칙 신설" 항목의 Impact)을 대체(supersede)함 — 그 판단 시점엔 §2~§6 원칙 본문을 스킬로 옮기고 pointer로 교체하는 것만 반영했고, 문서 자체의 역할이 "원칙 문서 → 인덱스 문서"로 바뀌는 것까지는 포함하지 않았음.

사유:
§12.1의 목적은 PM이 Layer×Stage별로 워커에게 필요한 최소 자료만 건네는 것. Frontend Implementation 행에 `Workflow_Frontend.md`와 그 문서가 이미 가리키는 두 스킬을 모두 나열하는 건 중복이었음 — `Workflow_Frontend.md` §1이 이미 "이 두 스킬을 호출하라"고 말하고 있으므로. 프로젝트 오너가 이 문서를 "Frontend 관련 스킬이 늘어나거나 더 세분화(예: 네비게이션/상태관리/테스트가 각각 별도 스킬로 쪼개짐)돼도 §12.1 표 셀은 절대 커지지 않고, 이 문서 하나만 계속 가리키면 되는" 안정적 앵커로 명시적으로 재정의하기로 함.

Impact:
- `Workflow_Frontend.md` §1 재작성(앵커/인덱스 역할 명시), Version 1.1 → 2.0
- `Workflow_Project.md` §12.1 UI/Screen·Implementation(Frontend) 행에서 스킬 2건 명시 참조 제거 (Version bump 없음 — 같은 리비전 패스 내 1.0→1.1 bump로 이미 커버됨, §1.6 "one revision pass = one bump")
- 아래 "Reference 문서 버전 넘버링 규칙 신설" Decision 항목의 `Workflow_Frontend.md` minor-bump 판단을 대체(supersede) — 그 항목 자체는 append-only 정책에 따라 소급 수정하지 않고 그대로 두되, 최신 판단은 이 항목을 따름.
- (감사 발견 반영) 같은 패스에서 `Workflow_Development.md`도 §4 Worker 섹션에 스킬 pointer 문장 추가로 Version 1.0 → 1.1(chapter-level modification) — 아래 "Reference 문서 버전 넘버링 규칙 신설" Decision의 Impact 목록에 최초 누락됐던 것을 여기 보완 기록.

---

[Decision] Reference 문서 버전 넘버링 규칙 신설 (§1.6)

결정:
- `Workflow_Project.md` §1.6 "Version Numbering" 신설: `> Version X.Y` 헤더를 가진 Reference 문서는 챕터 단위 추가/수정 시 점 뒤 숫자(minor)를, 문서의 사용 패턴·전체 프레임워크/구조 변경 시 점 앞 숫자(major)를 올린다. 한 리비전 패스는 그 안에 여러 챕터 단위 변경이 있어도 한 번만 bump한다.
- 이 패스에서 신설과 동시에 규칙을 자기 자신에게 적용 — `Workflow_Project.md`를 Version 1.0 → 1.1로 bump(신규 §1.6 추가 + §12.1 테이블 수정, 둘 다 챕터 단위 변경이지만 한 패스이므로 1회 bump).

사유:
Reference 문서 여러 개가 `> Version X.Y` 헤더를 갖고 있었으나 언제 major/minor를 올릴지 기준이 없어 매번 임의로 판단해야 했음. 프로젝트 오너가 시맨틱 버저닝과 유사한 규칙(챕터 단위 변경=minor, 프레임워크/사용 패턴 변경=major)을 명시적으로 제시해 성문화.

Impact:
- `Workflow_Project.md` §1.6 신설, Version 1.0 → 1.1
- 같은 패스에서 `Workflow_Frontend.md`도 이 규칙에 따라 Version 1.0 → 1.1 (챕터 단위 내용 교체는 수정이지 프레임워크 변경이 아니므로 minor bump)

---

[Decision] 재사용 가능한 원칙을 Workflow 문서에서 Claude Code Skill로 분리 채택 (engineering-principles, flutter-implementation-conventions)

결정:
- Workflow_*.md 정책 문서에 있던 재사용 가능한 원칙 콘텐츠를 `.claude/skills/<name>/SKILL.md` 형태의 Claude Code Skill로 분리하는 방식을 채택. Workflow 문서에는 흐름/역할/파이프라인만 남기고, 원칙 본문은 스킬이 갖고 스킬을 명시적 bare pointer 문장으로 호출하는 구조로 전환.
- 이번 패스에서 실제로 분리한 스킬 2개: `engineering-principles`(최초 신설명 `hardcoding-prevention`, 이후 리네임 — `Workflow_Development.md` §4 Worker 섹션에서 pointer), `flutter-implementation-conventions`(`Workflow_Frontend.md` §2~§6 원칙 본문을 추출).
- 같은 파일럿에서 함께 시험됐던 `documentation-conventions`, `uiux-design-conventions` 스킬은 이번 패스에서 채택하지 않음 — 아직 파일럿 초안 상태로 보류(`TechnicalDebt.md`에 후속 후보로 기록).

사유:
별도 worktree(`Digital-Wardrobe-testbed/localTestbed`, 브랜치 `feature/skill-extraction-testbed`)에서 PM/Worker/Review 팀으로 진행한 파일럿이 가설("원칙이 Workflow 문서에 인라인으로 쌓이면 텍스트량 때문에 오히려 안 지켜진다, 스킬로 분리하면 완화된다")을 검증함(`localTestbed/REPORT.md`). Verbatim 전사 요구사항(하드코딩 원칙 등)이 스킬 포맷 자체로 인한 드리프트 없이 지켜졌고, 유일한 리뷰 지적(P1: pointer 문장이 원칙을 재서술해 "제2의 Source of Truth" 실패 패턴을 재현)은 Worker 실행 실수였을 뿐 구조적 결함이 아니었으며 Review→Worker 1회전에서 자체 교정됨. `uiux-design-conventions` 스킬 초안은 verbatim 전사가 아닌 "방법론 추출"에도 이 포맷이 통한다는 것도 보였음(이번 패스에서는 미채택).

Impact:
- `.claude/skills/engineering-principles/SKILL.md` 신설(최초 신설명 `hardcoding-prevention`, 같은 패스 내에서 프로젝트 오너 요청으로 `engineering-principles`로 리네임 — 내용/스코프 변경 없음) — 원칙 원문은 파일럿 초안이 아니라 2026-07-09 최종 확정본("코드에 별도로 정의된 사전 합의된 const, enum, design token 등") 사용. 이 코드베이스에서 이미 확인된 위반 필드(`ClothingItem.category`/`season`/`material`, `Composition.season`) 참고용 메모 포함(조치는 별도 Step 3).
- `.claude/skills/flutter-implementation-conventions/SKILL.md` 신설 — `Workflow_Frontend.md` §2(네비게이션)~§6(Review 체크리스트) 원칙/AI Constraints 전량 이전.
- `Workflow_Development.md` §4 Worker 섹션에 engineering-principles bare pointer 추가.
- `Workflow_Frontend.md` §2~§6 본문을 스킬 pointer로 교체(헤더/번호는 유지). §1은 목적/스코프 내용은 그대로 유지하되 `engineering-principles`·`flutter-implementation-conventions` 두 스킬을 가리키는 pointer 문장이 새로 추가됨(§1 자체가 무수정으로 남은 것은 아님). §7은 무수정 유지. Version 1.0 → 1.1.
- `Workflow_Project.md` §12.1 Required Materials 컬럼에 두 스킬 등재(`engineering-principles`는 UI/Screen·Logic/Feature·Data/API/Architecture Implementation 행, `flutter-implementation-conventions`는 UI/Screen Implementation 행만), Version 1.0 → 1.1.
- `documentation-conventions`/`uiux-design-conventions` 채택은 보류 — `TechnicalDebt.md`에 후속 후보 task로 기록.

---

[Decision] ClothingItem.category / Season(ClothingItem·Composition) 폐쇄형 어휘 확정 — enum화 대상

결정:
- `ClothingItem.category` 8종(착용순서 정렬): 모자 / 상의 / 아우터 / 하의 / 원피스 / 양말 / 신발 / 가방·액세서리. `03_화면별UX명세서.md` §옷 종류의 예시 순서(모자→상의→아우터→하의→양말→신발→가방/액세서리 "등")를 근거로 하되, 그 목록이 "등"으로 비어있던 원피스를 현재 mock 데이터 실사용값 기준으로 추가해 확정.
- `ClothingItem.season` / `Composition.season` 4종: 여름 / 겨울 / 간절기 / 사계절. **`03_화면별UX명세서.md` §계절 정렬 기준("봄→여름→가을→겨울")과 다른 체계로, 이번 결정으로 대체함** — 봄/가을을 별도 계절로 구분하지 않고 "간절기"로 통합. 기존 mock 데이터의 '봄'/'가을' 값은 모두 '간절기'로 재매핑.
- 두 필드 모두 `docs/work/BACKLOG.md`에 기록된 하드코딩 원칙(위 항목 참고)에 따라 bare `String`이 아닌 실제 Dart `enum` 타입으로 구현(Step 3).

사유:
Step 2(하드코딩 원칙 문서화) 완료 후 Step 3(실제 enum화 구현) 착수 전, 폐쇄형 어휘 자체가 한 번도 명문화된 적이 없어(`category`는 예시 순서만, `season`은 이미 커밋된 테스트가 기획 문서와 다른 '사계절' 값을 사실상 확정값처럼 쓰고 있었음) PM이 사용자에게 직접 확인. 계절 체계는 사용자가 실제 옷장 태깅 관점에서 봄/가을 구분이 실익이 적다고 판단해 "간절기"로 통합하는 실용적 4종 체계를 선택.

Impact:
- `docs/work/BACKLOG.md` Step 3 항목에 확정값 기록
- `03_화면별UX명세서.md` §계절 정렬 기준 수정(사용지 직접)
- 실제 코드 구현(`lib/models/`, `lib/mock/mock_data.dart`, `lib/providers/`, 관련 테스트)은 이 결정 직후 별도 Worker 작업으로 진행

---

[Decision] BACKLOG.md 갱신을 "태스크 완료 시 후속조치"에서 "각 스텝 완료의 일부"로 승격

결정:
- `Workflow_Project.md` §3 "Skill-Internal Ledgers vs. Official Handoff": BACKLOG.md Current 갱신을 1차 방어선으로 승격 — 각 작업 스텝이 끝날 때마다(전체 태스크 완료 시가 아니라) 갱신하는 걸 그 스텝을 "완료"로 표시하는 행위 자체의 일부로 취급. 미완료 중단/세션 종료 시 옮겨 적는 기존 규칙과 Stop 훅(`check_backlog_freshness.py`)은 이 1차 방어선이 빠졌을 때의 백스톱으로 재배치.
- `Workflow_Project.md` §10 Definition of Done: 체크리스트가 "태스크 완료 시"뿐 아니라 태스크 내 개별 스텝마다 적용됨을 명시. "다음 태스크가 backlog에 추가됨" 항목을 "방금 끝난 스텝의 상태도 BACKLOG.md Current에 반영됨"으로 확장.
- `CLAUDE.md` "진행 중 작업 상태" 항목의 행동 지침을 "세션 종료 시"에서 "각 스텝 완료 시"로 앞당김.

사유:
Stop 훅(경고) vs block(강제) 두 방식을 검토하던 중, 사용자가 "기록은 다른 문서와 달리 작업 자체의 일부로 봐야 한다"는 대안을 제시함. 외부에서 사후 감지해 대응하는 hook 방식(경고=놓칠 수 있음, block=사용자 승인 없는 자동 행동 유발)보다, 애초에 기록을 스텝 완료 정의에 포함시켜 빠지면 "완료"로 안 치는 구조가 근본적으로 우월하다고 판단. SDD 스킬이 이미 "리뷰 통과 시 그 자리에서 장부에 한 줄 추가"하는 습관을 갖고 있었는데, 그 습관이 향한 대상(gitignore된 내부 장부)이 잘못됐던 것뿐이므로, 같은 습관을 BACKLOG.md로 재조준.

Impact:
- `Workflow_Project.md` §3, §10 갱신
- `CLAUDE.md` "진행 중 작업 상태" 항목 갱신
- Stop 훅(`check_backlog_freshness.py`)은 유지하되 역할이 "1차 방어선"에서 "백스톱"으로 재정의됨 (코드 변경 없음, 문서상 위상만 변경)

---

[Decision] Reference 문서 작성 원칙에 "간결성"(§1.5) 추가

결정:
- `Workflow_Project.md` §1.5 신설: Reference 문서는 정확한 의미를 해치지 않는 선에서 중복 없이 간결하게 작성.
- History 문서(`Decision.md`/`TechnicalDebt.md`)는 예외 — §1.3(대화 맥락을 대체해야 함)에 따라 Reference 문서보다 상세함이 허용되고, 이 원칙은 이미 기록된 History 항목에 소급 적용하지 않음(§6 append-only 원칙 유지).
- §3 "Skill-Internal Ledgers vs. Official Handoff"의 재현 가능성(self-containment) 요구와 충돌할 땐 재현 가능성이 우선 — 간결함을 이유로 필요한 내용을 링크로 대체하지 않음.

사유:
문서/지침 텍스트가 누적되면서 "지켜야 할 텍스트가 너무 많으면 오히려 안 지켜진다"는 우려가 제기됨. 다만 History 문서는 §1.3에 따라 의도적으로 상세해야 하는 반대 방향 원칙이 이미 있고, 오늘 신설한 §3 재현 가능성 요구와도 무차별 적용 시 충돌할 수 있어 예외/우선순위를 명시해 도입.

Impact:
- `Workflow_Project.md` §1.5 신설

---

[Decision] 세션 인계 브릿지 규칙 신설 — SDD 장부는 세션 내부용, BACKLOG.md가 공식 인계처

결정:
- 스킬이 쓰는 gitignore된 임시 작업 장부(예: `.superpowers/sdd/*`)는 세션 내부 복구용 캐시일 뿐, 세션 간 공식 인계 수단이 아님을 명문화. 그 안의 "완료 태스크→커밋" 매핑만 `git log`로 재구성 가능해 신뢰할 수 있고, 결정/사유/다음 계획 같은 프로즈는 별도로 tracked 문서에 옮겨적지 않으면 다음 세션에서 사라짐.
- 태스크가 완료되지 못한 채 일시중단되거나 세션이 끝날 때는, 그 시점까지의 핵심 결정과 다음 계획을 반드시 `docs/work/BACKLOG.md`(필요시 `Decision.md`)에 직접 옮겨 적어야 함. 기존 §10 Definition of Done의 "결정이 문서화되었는가" 체크는 태스크 완료 시점에만 발동하므로, 이 규칙은 그 체크가 커버 못 하는 "미완료 중단" 케이스를 메움.
- "기록해서 다음 세션이 이어갈 수 있게 했다"고 답하기 전에는, 실제로 새 세션이 `CLAUDE.md`→`BACKLOG.md` 경로만 따라가서 그 내용에 도달하는지 확인해야 함 — 내용 존재+정확성만으로는 부족.

사유:
2026-07-09, 동일 패턴의 세션 인계 실패가 3번째로 반복 확인됨. `.superpowers/sdd/progress-flutter-hifi-screens.md`에 정확한 일시중단 노트가 있었으나 gitignore돼 있고 BACKLOG.md에서 링크되지 않아 새 세션이 발견 불가능했음. 앞선 2회는 문제가 매번 그때그때의 특정 산출물만 패치되고 일반 규칙으로 기록되지 않아 재발함.

Impact:
- `Workflow_Project.md` §3 갱신 (신규 하위 섹션 "Skill-Internal Ledgers vs. Official Handoff")
- `CLAUDE.md` "진행 중 작업 상태" 항목에 행동 지침 + cross-reference 추가
- `TechnicalDebt.md`에 관련 항목 추가 (`.superpowers/sdd/` 플랫 파일명 충돌 건, 해당 파일 참고)
- Flutter Hi-Fi 스프린트 Task 7 일시중단 상세는 그 코드가 실제로 존재하는 `feature/flutter-hifi-screens` 브랜치의 `docs/work/BACKLOG.md`에 별도 커밋으로 반영 (dev 기반 브랜치에 넣으면 아직 dev에 없는 코드를 가리키는 참조가 생겨, 이번에 고치려는 것과 같은 종류의 실패를 재현할 위험이 있어 분리)

---

[Decision] ClothingItem에 재질(material) 태그 추가 — 18개 폐쇄형 어휘

결정:
- `ClothingItem`에 사용자 수정 가능한 `material` 필드 추가(단일 값, 필수).
- 값 범위는 섬유 성분(%) 기준이 아니라 **사람이 옷을 보고 부르는 방식** 기준의 폐쇄형 18개 어휘: 면 / 스판 / 데님 / 니트 / 플리스 / 리넨 / 모달·레이온 / 실크·새틴 / 시어서커 / 코듀로이 / 벨벳 / 패딩 / 나일론(바스락) / 가죽 / 퍼·무스탕 / 캔버스·패브릭 / 스웨이드 / 고무·러버.
- 카테고리(상하의/아우터/신발 등)를 가리지 않는 공용 필드로 둔다(예: 패딩 신발/패딩 바지도 허용). 카테고리별로 자주 쓰이는 값만 우선 정렬해 보여주는 건 UI 구현 시 처리(기존 "분류 기준별 정렬 기준표" 패턴과 동일).
- 옷장 메인 필터에는 추가하지 않는다 — 재질의 1차 목적이 사용자 탐색이 아니라 미래 추천 기능의 분석용 메타데이터라, 필터 추가는 추천 기능 설계 시점에 재검토.
- 니트/패딩처럼 "섬유 종류"가 아니라 "구성 방식(편물, 충전재+누빔)"을 가리키는 항목도 동일 리스트에 포함 — 이 리스트의 원칙 자체가 "질감/짜임으로 시각 구분 가능한가"이지 엄밀한 섬유과학 분류가 아님.

사유:
사용자가 미래에 "자주 입은 조합 분석 기반 옷 추천" 기능을 계획 중이며, 재질이 그 분석에 유의미한 메타데이터가 될 수 있다고 판단함. 다만 사진만으로 재질(특히 혼방 비율)을 정확히 파악하기는 사람도 AI도 어려움 — 실제로 이번 mock 이미지 매핑 중 3건(IMG_4261/4264/4276)에서 최초 추정과 실제 재질이 달라 사용자가 직접 정정함. 이는 기존 `mood_tags`가 "낮은 정확도, Phase 1.5 검증 필요"로 이미 플래그돼있는 것과 동일한 패턴이라, material도 같은 신뢰도 등급(AI 1차 추정 + 사용자 수정 가능)으로 취급하기로 함.

Impact:
- `docs/knowledge/reference/plan/00_MVP.md` §4.1(Auto-tagging fields), §5(Data Model) 갱신
- `lib/models/clothing_item.dart`에 `material` 필드 + `kClothingMaterials` 상수 추가
- `lib/mock/mock_data.dart` 12개 아이템에 재질 값 반영
- Task 10(옷 상세 화면) 스펙에 재질 표시 추가 예정 — 기존 "카테고리 · 색상 · 계절" 한 줄에 이어 붙이는 방식, 별도 섹션 신설 안 함. 반응이 별로면 나중에 뺄 수 있음(확정 아님).
- Follow-up: 재질 종류가 18개로 늘어나 Task 11(옷 추가하기) 드롭다운이 길어짐 — 구현 시 검색 가능한 드롭다운 등 UX 보완 검토 필요.

---

[Decision] PR-create 게이트를 main-base 전용으로 좁히고 gh pr merge 하드 블록 추가

결정:
- `gh pr create`는 base가 `main`일 때(또는 `--base` 미지정 시, 기본값이 `main`이므로)만 계속 게이트. feature→dev(`--base dev`) 등 non-main 대상은 자유롭게 허용.
- `gh pr merge`는 방향 무관 항상 하드 블록 — 확인 후 재시도 모델이 아니라 애초에 AI가 절대 실행하지 않는 액션.

사유:
PR #2(feature→dev) 오픈 후 검토하며, "PR 생성 시 확인받기"와 "merge 전 사람이 GitHub에서 다시 검토하기"가 같은 질문("이 내용을 반영해도 되는가")을 두 번 묻는 중복임을 발견. 실제 반영(dev/main 내용 변경)은 merge 시점에만 일어나므로, feature→dev처럼 merge 시 사람이 어차피 검토하는 경우는 생성 단계 게이트가 불필요. 반면 dev→main은 "지금 릴리즈할지"라는 타이밍 결정이 걸려있어 생성 단계에서도 확인이 의미 있음. 별개로, `gh pr merge`가 애초에 훅의 정규식 검사 대상이 아니어서 "사람만 merge한다"는 §13.3 원칙이 순수 서면 규칙에 불과했던 것도 이번에 기술적으로 막음.

Impact:
- `.claude/hooks/guard_git_actions.py` PR-create 로직 변경, `gh pr merge` 룰 추가
- `Workflow_Project.md` §13.2/13.3 갱신
- `CLAUDE.md` 체크포인트 3 갱신
- `worker.md` 문구 정확성 수정 (워커는 여전히 PR 생성/merge 안 함, 훅 스코프와 무관)

Follow-up (재검토 조건):
이 결정("feature→dev PR 생성은 자유")은 "PR 생성 자체는 아무 자동 동작도 촉발하지 않는다"는 전제에 의존한다. 나중에 PR이 열리기만 해도 자동으로 실행되는 CI/자동배포/자동병합 같은 자동화(예: `.github/workflows/`에 `on: pull_request`로 반응하는 워크플로 추가)를 도입할 때는, 그 작업이 이 전제를 깨는지 반드시 먼저 확인할 것. 깨진다면 feature→dev PR 생성도 다시 게이트가 필요한지 재검토해야 함.

---

[Decision] Git-flow 기반 브랜치/커밋/PR 정책 도입

결정:
- main(릴리즈 전용) ← dev(기본 작업 브랜치, PR 병합만) ← feature/<backlog-slug>(자유 커밋) 3단계 브랜치 구조 도입
- Worker도 feature 브랜치 안에서는 자유 커밋 가능 (기존 "Worker는 절대 커밋 안 함" 규칙 완화)
- dev/main 직접 커밋, gh pr create(feature→dev/dev→main 모두), main으로의 git push는 계속 리포트+사용자 확인 게이트
- `.claude/hooks/block-git-commit.sh`(정규식 기반 — 실측으로 확인된 버그: 커맨드 안에 `git commit`보다 앞서 따옴표가 나오면 매칭이 끊겨 차단이 뚫림)를 브랜치 인지형 Python 훅 `guard_git_actions.py`로 교체

사유:
매 커밋마다 리포트+확인을 받는 기존 방식은 작업량이 늘면서 확인 비용이 커짐. feature 브랜치 안에서의 저위험 커밋은 자유롭게 허용하고, 실제로 공유 상태(dev/main)에 반영되거나 외부에 보이는 행위(PR 생성, main push)에만 확인 게이트를 남기는 것으로 절충. 겸사겸사 기존 훅의 정규식 매칭 버그(따옴표 포함 커맨드에서 차단 실패)도 이번에 해소함.

Impact:
- Workflow_Project.md §13 신설
- CLAUDE.md 체크포인트 3 갱신
- worker.md 커밋 정책 갱신
- `.claude/hooks/block-git-commit.sh` → `guard_git_actions.py` 교체, settings.json 훅 커맨드 갱신
- GitHub Branch protection(main/dev)은 사용자가 별도로 웹 UI에서 설정 (이번 작업 범위 밖)

---

[Decision] 역할별 자료 접근권 원칙 추가 (Layer × Stage 기준)

결정:
- Workflow_Project.md §12 신설: 역할이 보는 자료는 직군이 아니라 "레이어(UI/기능/데이터·아키텍처) × 단계(결정/구현)"로 결정
- Worker/Review 자료는 동일하지 않음: 판단기준 문서(Reference + Decision.md/TechnicalDebt.md)는 공유, 원본 탐색 자료는 Worker 전용, 산출물(diff)은 Review 전용
- Review가 스코프 밖 자료가 필요하면 직접 접근하지 않고 PM에게 스코프 확장을 요청 → PM이 Impact Scope 재평가 후 승인

사유:
"프론트는 디자인 자료를 보고 백엔드는 안 본다"처럼 직군별로 규칙을 하드코딩하면 새 파이프라인마다 규칙을 새로 만들어야 함. 레이어×단계 매핑으로 일반화하면 어떤 파이프라인이 추가돼도 규칙 변경 없이 적용됨.

Impact:
- Workflow_Project.md §12 신설
- 하네스 에이전트 정의 작성 시 이 매핑을 그대로 반영 예정

---

[Decision] Claude Projects 사용 중단, Claude Code 단일 허브 전환 + 핸드오프 자동화

결정:
- 기획/논의를 별도 Claude.ai Project 채팅에서 하던 방식을 중단하고, Claude Code를 유일한 작업 허브로 사용
- Workflow_Project.md §3, §11 갱신: "모든 핸드오프는 사람이 수행" 원칙을
  "핸드오프는 PM 에이전트가 자동 중계하되, 필수 체크포인트는 여전히 사람 확인" 으로 변경
- 하네스 필수 체크포인트 확정 (설정 파일은 추후 별도 작성):
  1) PM의 작업 분배는 사람이 반드시 봄 (비차단 로그)
  2) 결정문서 수정은 diff를 사람이 반드시 확인
  3) git commit 전 리포트 작성 + 사람 확인 필수
  4) 작업↔리뷰 자동 순환, 완료 후 로그 열람 여부는 사람이 선택 (관례로 처리, 인프라 기능 아님)
  5) (드랍) 필수 확인 항목의 "다음부터 자동승인" 버튼 제거 — 권한 시스템 레벨에서 불가능 확인됨
- 작업 단위 = 스텝 (전체 산출물 단위 아님). 워커 인스턴스는 스텝 간 전문성이 같으면 유지, 다르면 새로 스폰 — PM이 그때그때 판단

사유:
Claude.ai Project와 Claude Code는 연동/동기화가 없음(Anthropic 자체 기능요청 #2511, #39051 모두 미구현 확인). 두 도구를 병행하면 Project 지식베이스가 항상 stale해지는 수동 동기화 부담이 발생해서, 논의+실행을 한 도구로 합침.

Impact:
- Workflow_Project.md §3, §11 갱신 완료
- CLAUDE.md에 폴더 안내 추가 완료
- 하네스 설정(.claude/agents/*.md, settings.json 훅)은 틀이 더 갖춰진 뒤 별도 작업 예정

---

[Decision] Design Workflow 순서 변경 — Hi-Fi Sample 선행 방식으로 전환 (기존 결정 대체)

결정:
- ref_정책_Workflow_Design.md §2 프로세스를 다음으로 변경:
  Brand Guide(방향) → Hi-Fi Sample(3~5화면, Wireframe 겸함) → Visual Review 
  → 사이즈/간격/컬러 조정 → Design Tokens 확정 → Component Library → 나머지 화면
- 기존 "PLACEHOLDER 병행 착수" 결정(Design System/Component Library를 Brand Guide와 
  병행 진행)은 본 결정으로 대체(superseded)

사유:
디자인 수치(사이즈/간격/컬러)는 실제 화면에서 육안 확인 후 픽스해야 한다는 판단.

Impact:
- ref_정책_Workflow_Design.md §2, §5 갱신 필요
- 기존 준비된 Task B(Design System/Component Library placeholder 착수) 보류

---

[Decision] Brand Guide Pass 2 확정 — Colors (T1~T3 실값)

결정:
- Pass 1 Visual Direction(아이보리~베이지 배경 + 블루뉴트럴 + 딥블루그레이) 기반
  Primary/Neutral/Accent 실값 확정
- On-Primary는 순수 흰색(#FFFFFF) 대신 오프화이트 적용 (T2의 흑백 회피 취지를
  Neutral 역할뿐 아니라 On-Primary에도 동일 적용)
- 다크모드 대비(WCAG 4.5:1/3:1) 1차 검증 완료

사유:
P6 "흑백 기피" 원칙을 텍스트/배경 역할 전반에 일관 적용. 별도 예외 규정 없음.

Impact:
Design System Stage 5 T1~T3 실값 확정. Task B(Design System 구축) 착수 조건 일부 충족.

Follow-up:
- T2 Gray 스케일 근사치 → 실제 색상 툴 재보간 필요 (Task B 착수 조건)
- Warning/Accent 등 미검증 대비 쌍 → Task B 진입 전 전수 재검증 필요
- 문서 파일명(Pass1+2 통합) 리네이밍 → Pass 3 완료 후 일괄 정리

---

[Decision] Brand Guide Pass 1 확정 — Essence/Personality/Visual Direction

결정:
- Brand Essence: E2 (자기 이해형 — "입어온 나를 돌아보는 기록")
- Brand Personality: 든든한 개인 기록자 (격식 있는 다정함, 반말/애칭/과한 감탄사 배제)
- Visual Direction: 아이보리~베이지 배경 + 블루뉴트럴, 딥블루그레이로 무게감,
  웜톤/핑크/그린 계열 액센트 배제

사유:
Needs 문서 ②(기억/취향 축)에 무게 실은 Essence 선택. Personality는 P1의
"경로별 표현 강도만 차등, 구조는 미분기" 원칙과 정합되도록 담백함 기반 단일 축 유지.

Impact:
Pass 2(컬러 실값), Pass 3(타이포)의 상위 제약. Design System Stage 5 실값 산정 시 참조.

Follow-up:
- Accent 색상 역할 미정 → Pass 2에서 결정
- 다크모드 대비(WCAG 4.5:1) 검증 → Pass 2 착수 조건
- 팔레트 5종 → 1종 압축 → Pass 2에서 확정

---

[Decision] Brand Guide 선행 없이 임시 토큰 값으로 Design System 착수

배경:
Brand Guide 확정 지연으로 Stage 5(Design Tokens) 실값 확보 시점 불투명.

결정:
- Design Tokens 역할 구조(Stage 5)는 유지, 실값 대신 PLACEHOLDER 값으로 Design System/Component Library 선행 진행.
- 모든 컴포넌트는 토큰 역할만 참조(하드코딩 금지). Brand Guide 확정 시 값만 일괄 교체.

사유:
Stage 5 문서에 이미 "역할만 정의, 값은 Brand Guide 대기"로 명시되어 있어 기존 설계 의도와 합치. 새 개념 도입 아님.

Impact:
Design System, Component Library. 화면/기획 문서 변경 없음.

Follow-up:
Brand Guide 확정 시 PLACEHOLDER 값 전수 교체 Task 필요 (TechnicalDebt.md 등록 대상 여부는 별도 확인).