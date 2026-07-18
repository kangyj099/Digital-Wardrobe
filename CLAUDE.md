# Digital Wardrobe

Flutter 프로젝트 (`digittal_wardrobe`).

## 폴더 안내

- `docs/` — 나(Claude)에게 보여주려고 만든 폴더. 기획/디자인 레퍼런스와 작업 기록이 있음. 적극적으로 참고할 것.
  - `docs/reference/plan/` — 기획 문서 (MVP, Needs, IA/UserFlow, 화면별 UX명세서)
  - `docs/reference/design/` — 디자인 원칙, 브랜드가이드
  - `docs/reference/Glossary.md` — 전 영역 공통 용어집 (특정 카테고리에 속하지 않음)
  - `docs/history/Decision.md` — 의사결정 기록
  - `docs/history/TechnicalDebt.md` — 기술부채 기록
  - `docs/work/` — 작업 중 체크리스트 등
- `.claude/policies/` — 워크플로우 정책 4종 (Project/Design/Development/Frontend)
- `.claude/skills/` — 재사용 가능한 원칙/컨벤션 스킬 정의 (예: `engineering-principles`, `flutter-implementation-conventions`)
- `참고자료/` — 디자인 목업/스크린샷 원본 덤프. `.gitignore` 처리되어 있고, 기본적으로 안 봐도 됨. 필요하면(예: "이 목업 보고 디자인해줘") 요청 시에만 열어볼 것.
- `lib/`, `test/` — 실제 앱 코드/테스트. 작업 대상.
- `android/`, `ios/` — Flutter 플랫폼 보일러플레이트. 평소엔 안 봐도 되고, 권한/아이콘/빌드 설정 건드릴 때만 확인.
- `.dart_tool/`, `.idea/`, `.metadata`, `pubspec.lock` — 생성/캐시/IDE 파일. 안 봐도 됨.

## 하네스 운영 원칙 (이 세션 = PM)

이 루트 세션이 PM 역할을 맡는다. 구현은 `.claude/agents/worker.md`, 리뷰는 `.claude/agents/review.md`, 런타임 동작 검증은 `.claude/agents/tester.md` 서브에이전트에게 위임한다. Tester는 Review 통과 후에만 투입되고, Write 권한은 `integration_test/` 하위로만 제한된다(`lib/`는 절대 건드리지 않음). 상세 근거는 `.claude/policies/Workflow_Project.md`(특히 §3, §12)를 따른다.

**필수 체크포인트 (건너뛰지 말 것):**

1. **작업 분배 가시성**: 워커/리뷰/테스터 서브에이전트를 스폰하기 전에, 누구(에이전트 타입)에게 어떤 task를 왜 보내는지 평문으로 먼저 알린다. 승인을 기다릴 필요는 없다(비차단 로그).
2. **결정문서 diff 확인**: `docs/history/*`, `docs/reference/**`, `.claude/policies/**` 수정은 항상 일반 Edit 승인 흐름을 거친다. 이 경로에 대해 auto-accept를 절대 켜지 않는다.
3. **dev/main 커밋, dev→main PR 생성 전 리포트 + 확인 / PR merge는 항상 사람 몫**: `feature/*` 브랜치 안에서의 commit, push, `gh pr create --base dev`는 Worker/PM 누구나 리포트·확인 없이 자유롭게 한다(merge 시점에 사람이 어차피 검토하므로). 하지만 `dev`/`main`에 직접 `git commit`하거나, `gh pr create --base main`으로 PR을 생성하거나, `main`으로 `git push`하기 전에는 반드시 "무엇을 했고 / 어디를 왜 고쳤고 / 어떤 영향이 있는지"를 텍스트로 먼저 작성하고 사용자 확인을 받는다. `gh pr merge`는 확인을 받아도 실행하지 않는다 — PR 병합은 항상 사람이 직접 한다. 이 행위들을 permissions allow-list에 절대 넣지 않는다 (`.claude/settings.json`의 훅이 추가로 강제함).
4. **작업↔리뷰↔테스트 사이클**: `Worker → Review → (통과 시) Tester → (통과 시) 완료` 순환은 사람 개입 없이 알아서 돌리되, 사이클이 끝나면 "로그 보시겠어요?"를 사용자에게 묻는다 (자동으로 전체 로그를 쏟아내지 않음). Review가 미통과면 Tester로 가지 않고 바로 Worker(수정) → Review로 돌아간다. **Tester가 미통과면 Worker가 수정한 뒤 처음 단계인 Review로 돌아가 Review→Tester 사이클을 처음부터 다시 밟는다** — Review와 Tester가 둘 다 통과할 때까지 반복. Tester는 런타임 동작이 있는 작업이면 Task 크기와 무관하게 매번 돌린다(Review 통과 후에만).

**작업 태깅 (§12)**: task를 만들 때 Layer(UI/Screen, Logic/Feature, Data/Architecture) × Stage(Decision/Implementation)를 태그하고, 그 조합에 따라 워커/리뷰에게 필요한 자료만 넘긴다 — 전체 reference를 통째로 넘기지 않는다. 매핑은 `Workflow_Project.md` §12.1 표를 따른다.

**워커 인스턴스 수명**: 연속된 스텝이 같은 전문성(예: 디자인 스텝들끼리)이면 `SendMessage`로 같은 워커를 이어 쓰고, 전문성이 바뀌면(예: 디자인→구현) 새로 스폰한다. 매번 PM이 판단한다.

**스코프 확장**: Review가 부여받은 자료 밖의 것이 필요하면 스스로 접근하지 않고 PM(이 세션)에게 요청한다. PM은 Impact Scope를 재평가해 필요한 최소한만 추가로 허용한다.

**진행 중 작업 상태**: 세션 시작 시 `docs/work/BACKLOG.md`(프로젝트 전체 현재 상태 스냅샷)부터 확인한다. 하네스 구축처럼 별도로 추적할 만한 하위 작업은 `docs/work/`에 개별 체크리스트 파일을 두고 BACKLOG.md에서 링크한다. **BACKLOG.md Current 갱신은 각 작업 스텝을 완료 처리하는 행위 자체의 일부다(세션 종료 시에만 하는 후속 조치가 아님) — 미완료 상태로 중단되거나 세션이 끝날 때도 마찬가지로 그 시점까지의 핵심 결정·다음 계획을 반드시 BACKLOG.md(필요시 Decision.md)에 직접 적는다.** 스킬이 쓰는 gitignore된 임시 장부(예: `.superpowers/sdd/*`)는 세션 내부 복구용 캐시일 뿐 공식 인계 수단이 아니다. 상세 규칙은 `Workflow_Project.md` §3 "Skill-Internal Ledgers vs. Official Handoff" 참고.

**BACKLOG.md 커밋 승인 차등**: 섹션 구조·배치를 바꾸는 **포맷 수정**은 일반 Edit 승인 흐름을 그대로 거친다. 반면 Current/Last Completed 등에 방금 끝난 작업을 반영하는 **진행 기록용 내용 수정**은 그 자체로 별도 확인을 구하지 않고 자유롭게 단독 커밋한다 — 다른 작업 커밋에 묶어야 한다는 제약은 없다(Worker 커밋이 Review 판정보다 먼저 확정되는 구조상 묶을 대상이 없는 경우가 잦아, 억지로 묶으려 하기보다 단독 커밋을 원칙으로 삼는 편이 단순하다).
