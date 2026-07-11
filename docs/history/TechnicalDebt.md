<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[TechDebt] 옷장 메인 재설계 중 추가된 시각적 매직넘버(스크롤마스크/틴트/디버그 상태바 치수) 토큰화 필요

상태: 미해결

내용:
`closet_main_screen.dart`에 추가한 세이지 틴트 컨테이너 크기(240x240)/alpha(0.15), `ShaderMask` stops([0.0, 0.06]), 디버그 상태바 높이(24)·아이콘 크기(14)·도트 크기(6)·폰트 크기(12) 등이 리터럴로 남아있음. 이번 스코프(코너 반경/duration 토큰화)와는 별개라 이번 라운드에서는 토큰화하지 않았으나, 추후 Design Tokens 확정 시 반영 검토 필요.

---

[TechDebt] `AppRadius`(`lib/theme/app_spacing.dart`) — Brand Guide/Design Tokens 문서에 정식 등재 필요

상태: 미해결

내용:
옷장 메인 재설계 시 `AppRadius.sm`(16, 드롭다운 패널)/`AppRadius.pill`(100, 필 버튼)을 코드에서 처음 정의했으나, Design Tokens에는 이 코너 반경 값에 대한 역할명 자체가 없었음. 추후 Brand Guide/Design Tokens 문서에 정식 등재 검토 필요.

---

[TechDebt] `documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류 — 파일럿 초안만 존재, 정식 검토 필요

상태: 해결됨 (2026-07-10) — 실채택 완료. 상세: `Decision.md` 최상단 항목 참고.

내용:
`Digital-Wardrobe-testbed/localTestbed`(브랜치 `feature/skill-extraction-testbed`) 파일럿에서 `hardcoding-prevention`(현 `engineering-principles`)/`flutter-implementation-conventions`와 함께 시험됐으나, 실제 채택 패스(`engineering-principles`/`flutter-implementation-conventions` 채택 Decision 참고)에서는 제외됨. `documentation-conventions`(`Workflow_Project.md` §1.4/§1.5 대상)와 `uiux-design-conventions`(`Workflow_Design.md`의 Layer Boundary Rule + Design/Visual Review 체크리스트 대상)는 아직 파일럿 초안 상태로만 존재. 채택 여부/타이밍 재검토 필요.

참고: 파일럿 원본(`Digital-Wardrobe-testbed/localTestbed/REPORT.md`)은 이후 해당 worktree 삭제로 더 이상 존재하지 않음 — 내용은 채택 Decision 항목에 요약됨.

---

[TechDebt] `.superpowers/sdd/`의 플랫(non-namespaced) 파일명이 서로 다른 plan 간 충돌

상태: 미해결

내용:
`task-N-brief.md`, `task-N-report.md` 같은 파일명이 plan별로 구분되지 않고 공유됨. 서로 다른 plan(예: git-flow-commit-policy plan과 flutter-frontend-hifi-screens plan)이 둘 다 Task 7을 가지면, 나중 plan의 Task 7 산출물이 앞선 plan의 Task 7 파일을 덮어씀.

발견 경위:
2026-07-09 세션 인계 실패 조사 중 발견.

영향:
같은 세션 내에서 여러 plan을 순차 실행할 때 이전 plan의 task 브리핑/리포트가 유실될 수 있음.

조치 방향(착수 조건):
`.superpowers/sdd/` 하위에 plan-slug 기반 서브디렉토리 또는 파일명 prefix 도입 검토. superpowers 스킬 자체(외부 플러그인)의 스크립트(`scripts/task-brief`, `scripts/sdd-workspace`)를 건드리는 문제라 이 프로젝트 단독으로 고치기 애매함 — 필요시 플러그인 쪽에 이슈 제기 검토.

---

[TechDebt] `guard_git_actions.py`의 세그먼트 분리 매칭 — heredoc 등 일부 셸 구문은 여전히 오탐/누락 가능

상태: 부분 해결 (원래 문제는 고쳐짐, 더 좁은 범위의 한계가 남음)

내용:
원래 문제("COMMIT_RE/PR_CREATE_RE/PUSH_RE가 원본 커맨드 문자열 전체에 `.search()`를 수행해서, 실제 git/gh 호출이 아니라 그 문자열을 텍스트로 담고 있는 커맨드도 차단됨")는 git-flow 정책 재설계 작업 Task 9 fix round에서 해결됨: 이제 커맨드를 셸 연산자(`&&`, `||`, `;`, `|`)로 분리하고, 각 세그먼트의 선두(`VAR=val` 및 `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 같은 흔한 래퍼 제거 후)가 실제로 `git`/`gh` 호출인지만 확인한다. 이 변경으로 fix round 1에서 `sudo git commit` 등 래퍼가 붙으면 게이트가 통째로 뚫리는 새 회귀가 잠깐 생겼으나, fix round 2에서 래퍼 스트리핑을 추가해 해결함.

남은 한계:
- 세그먼트 분리가 순수 텍스트 기반이라, 셸 연산자(`&&`/`;`/`|`)를 리터럴 텍스트로 포함하는 heredoc 본문(예: 이 문서 자체처럼 파이프나 세미콜론이 들어간 프로즈/코드를 heredoc으로 작성하는 커맨드)은 여전히 의도치 않게 여러 세그먼트로 쪼개질 수 있다.
- `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 외의 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)는 스트리핑 대상이 아니라 여전히 게이트를 우회할 수 있다.
- 근본 해결(진짜 셸 파서 사용)은 범위가 커서 여전히 보류.

발견 경위:
Task 2 리뷰(원래 문제 발견) → Task 9 fix round 1(세그먼트 매칭으로 해결 시도) → 리뷰에서 `sudo`/`env`/`exec`/`command`/`time` 래퍼 우회 회귀 발견 → fix round 2에서 래퍼 스트리핑 추가로 해결. 이 과정에서 리뷰어가 heredoc 기반 진단 커맨드가 여전히 오탐될 수 있음을 재확인함.

영향:
- 지정된 7개 래퍼(`sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup`)로 인한 우회는 fix round 2로 닫혔으나, 그 외 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)로 인한 우회는 여전히 가능함.
- 남은 오탐 한계는 이 하네스로 훅 자체를 다루는 문서/테스트 작성 시(특히 heredoc 사용 시) 여전히 마주칠 수 있음 — 불편함 수준.

조치 방향(착수 조건):
비슷한 문제가 반복되거나 작업 여유가 생기면, 정규식 기반 세그먼트 분리 대신 실제 셸 파서(예: `shlex`나 POSIX 셸 문법 파서)로 교체 검토.

---