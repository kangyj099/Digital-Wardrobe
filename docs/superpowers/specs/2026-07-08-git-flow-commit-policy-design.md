# Git-Flow 기반 커밋/PR 정책 설계

Date: 2026-07-08
Status: Approved (design), pending implementation

## 배경

기존 정책: `.claude/hooks/block-git-commit.sh`가 브랜치와 무관하게 모든 `git commit`을 차단하고,
매 커밋마다 "리포트 작성 → 사용자 확인" 체크포인트(`CLAUDE.md` 체크포인트 3)를 강제했다.
작업이 늘어나면서 매 커밋마다 확인받는 비용이 커져, git-flow 스타일 브랜치 전략으로 전환한다.

## 브랜치 구조

```
main  ─ 릴리즈 전용. 실제 배포 시에만 사용
 └─ dev  ─ 기본 작업 브랜치. 직접 commit 금지(사람 손 예외), PR 병합만 허용
     └─ feature/<backlog-항목-slug>  ─ PM이 BACKLOG 항목 시작 시 dev에서 분기. Worker/PM 누구나 자유 commit
```

- Feature 브랜치 이름: `feature/<backlog-항목-slug>` (예: `feature/harness-git-policy`)
- Feature 브랜치는 PM이 BACKLOG.md의 새 항목 작업을 시작할 때 dev에서 분기해 생성한다. 브랜치 생성 자체는 확인 불필요(로컬, 가역적).
- GitHub 저장소의 Branch protection(“PR 없이 병합 금지”, force-push/삭제 금지 등)은 **사용자가 GitHub 웹 UI에서 직접 설정** — 로컬 훅과는 독립적인 이중 안전망. 이 스펙의 구현 범위에는 포함하지 않는다.

## Commit 정책 (로컬 훅)

`.claude/hooks/block-git-commit.sh`를 브랜치 인지형으로 재작성한다.

| 상황 | 동작 |
|---|---|
| 현재 브랜치가 `feature/*` 에서 `git commit` | 통과 — 리포트/확인 불필요, Worker/PM 누구나 자유 커밋 |
| 현재 브랜치가 `dev` 또는 `main` 에서 `git commit` | 차단 — "리포트 작성 → 사용자 확인 → 재시도" 요구 (기존 체크포인트 3와 동일 절차, 대상만 축소) |
| `gh pr create` 호출 (브랜치 무관, feature→dev / dev→main 모두) | 차단 — PR 초안(제목/설명/변경 요약) + 리포트 작성 → 사용자 확인 → 재시도 |
| `git push` 로 `main`을 대상 지정 (`git push … main`, `git push origin HEAD:main` 등) | 차단 — 동일하게 리포트+확인 요구. GitHub Branch protection이 아직 설정 전이거나 우회되는 경우에도 안전망 유지 |

훅은 현재 브랜치를 `git rev-parse --abbrev-ref HEAD`로 확인해 분기 판단한다.

## PR 정책

**feature → dev**
- 트리거: `docs/work/BACKLOG.md`의 체크리스트 항목 하나가 완료됐을 때 (Worker→Review 사이클 종료 시점)
- PM이 PR 제목/설명 + 완료 리포트(무엇을/왜 고쳤고/영향 범위)를 작성해 사용자에게 제시
- 사용자 확인 후에만 `gh pr create` 실행
- 병합(merge)은 사용자가 GitHub에서 직접 승인/머지 — PM이 자동 머지하지 않는다

**dev → main**
- 트리거: 다음 패치에 포함될 항목들이 모두 dev에 반영 완료된 시점 (사용자 판단, 또는 PM이 제안하고 사용자가 승인)
- 동일하게 PM이 PR 초안 + 리포트 작성 → 확인 → `gh pr create`
- main은 릴리즈 전용이므로 이 PR의 리포트는 릴리즈 노트 성격을 겸한다

## 수정 대상 파일

1. `.claude/hooks/block-git-commit.sh` — 위 표의 브랜치 인지형 로직으로 재작성
2. `.claude/agents/worker.md` — "Worker는 절대 커밋하지 않는다" 규칙을 "feature 브랜치 안에서는 자유 커밋 가능, dev/main에는 직접 커밋 금지"로 수정
3. `CLAUDE.md` "하네스 운영 원칙" 체크포인트 3 — "커밋 전 항상 리포트+확인"에서 "dev/main 커밋 및 PR 생성(gh pr create) 시에만 리포트+확인"으로 범위 축소
4. `docs/knowledge/reference/policy/Workflow_Project.md` — 브랜치 전략 섹션 신설 (본 문서의 브랜치 구조/PR 정책 요약을 반영)
5. `docs/knowledge/history/Decision.md` — 이번 정책 변경을 결정사항으로 기록

`review.md`는 변경 없음 (여전히 read-only, 특정 task 리뷰만 수행).

## 영향받지 않는 부분

- Review 서브에이전트의 역할/권한
- Worker/Review Layer×Stage 자료 접근 정책 (§12)
- Decision/TechnicalDebt 문서 수정 시 일반 Edit 승인 흐름 (변경 없음)
- Worker→Review→Worker 사이클 자체의 흐름 (여전히 사람 개입 없이 자동 순환, 사이클 종료 시 "로그 보시겠어요?" 확인)

## Out of Scope

- GitHub Branch protection 실제 설정 (사용자가 직접 진행)
- CI/CD, 자동 배포 파이프라인
- main 버전 태깅 규칙 세부사항
