<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[TechDebt] `pubspec.yaml`이 선언한 asset 경로(`assets/images/mock/`, `assets/fonts/...`)가 이 브랜치 계보엔 실제 파일로 존재하지 않음

상태: 미해결

내용:
`pubspec.yaml`에 asset 경로를 등록한 커밋(`29609b3`, "register fonts and mock image assets...")은 `.gitignore`/`pubspec.lock`/`pubspec.yaml`만 수정했고, 실제 이미지/폰트 파일은 커밋하지 않았다. 해당 mock 이미지 파일들은 이후 별도의 형제 브랜치(`feature/flutter-hifi-screens`, 커밋 `b38e162`)에만 추가돼 있고, 이 브랜치(및 `29609b3` 이후 `flutter-hifi-screens` 병합 전 상태로 갈라져 나온 다른 형제 브랜치들)의 조상 커밋에는 포함되어 있지 않다. `dev`/`main`의 `pubspec.yaml`은 애초에 asset/font 섹션 자체가 없는 템플릿 그대로라, "dev엔 있는데 이 브랜치엔 없다"가 아니라 "이 계보 자체가 asset을 실제로 커밋하기 전 단계에서 갈라졌다"가 정확한 원인이다. `assets/fonts/`는 모든 브랜치에서 `.gitignore`로 항상 제외됨(의도적, 라이선스 문제로 추정).

발견 경위:
2026-07-09, '설정' 화면 구현(Layer=UI/Screen, Implementation) 중 Worker가 `flutter test`/`flutter analyze` 실행 시 asset 번들링 실패를 겪고, 다른 체크아웃에서 `assets/`를 로컬로 복사해 우회(커밋하지 않음). Development Review가 `git log -p -- pubspec.yaml`로 근본 원인을 재확인.

영향:
`29609b3` 이후 `flutter-hifi-screens`의 asset 커밋을 아직 병합받지 않은 브랜치를 새로 체크아웃하면 동일하게 `flutter test`/빌드의 asset 번들링이 실패한다.

조치 방향(착수 조건):
`feature/flutter-hifi-screens`가 `dev`에 병합되어 asset 커밋이 공통 조상에 편입되면 자연히 해소됨. 그 전에 이 계보의 다른 브랜치에서 로컬 테스트/빌드가 필요하면 해당 브랜치에 asset을 임시로 복사(커밋 금지)하거나, `flutter-hifi-screens`에서 asset 커밋만 cherry-pick하는 방법을 검토.

---

[TechDebt] `documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류 — 파일럿 초안만 존재, 정식 검토 필요

상태: 미해결

내용:
`Digital-Wardrobe-testbed/localTestbed`(브랜치 `feature/skill-extraction-testbed`) 파일럿에서 `hardcoding-prevention`(현 `engineering-principles`)/`flutter-implementation-conventions`와 함께 시험됐으나, 실제 채택 패스(`engineering-principles`/`flutter-implementation-conventions` 채택 Decision 참고)에서는 제외됨. `documentation-conventions`(`Workflow_Project.md` §1.4/§1.5 대상)와 `uiux-design-conventions`(`Workflow_Design.md`의 Layer Boundary Rule + Design/Visual Review 체크리스트 대상)는 아직 파일럿 초안 상태로만 존재. 채택 여부/타이밍 재검토 필요.

참고: `Digital-Wardrobe-testbed/localTestbed/REPORT.md`

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