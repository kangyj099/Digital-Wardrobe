<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

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