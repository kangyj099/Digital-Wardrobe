<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

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