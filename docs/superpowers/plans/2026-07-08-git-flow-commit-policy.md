# Git-Flow 기반 커밋/PR 정책 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## Execution Status (재개 시 여기부터 읽을 것)

- 실행 방식: subagent-driven-development 선택됨. 단, 서브에이전트는 이 프로젝트의 `.claude/agents/worker.md`/`review.md`를 그대로 사용 (스킬 기본 템플릿 아님).
- 스펙 문서 커밋 완료: `docs/superpowers/specs/2026-07-08-git-flow-commit-policy-design.md` (commit `da6df26`, dev 브랜치)
- **현재 브랜치: `dev`** (아직 feature 브랜치 생성 전, Task 1 미완료)
- Task 1(feature 브랜치 분기) 착수 전, dev에 남아있던 이번 작업과 무관한 기존 미커밋 변경을 먼저 정리하는 중이었음:
  - `git add` 완료(커밋 전, staged 상태): `CLAUDE.md`(진행 중 작업 상태 문단), `docs/work/BACKLOG.md`(신규), `docs/work/하네스_구축_체크리스트.md`(신규), `ios/.gitignore`(신규) — 사용자 승인받음, **아직 커밋 안 함**
  - `.claude/` 디렉토리 전체(`agents/worker.md`, `agents/review.md`, `hooks/block-git-commit.sh`, `settings.json`, `settings.local.json`)도 미커밋 상태로 확인됨 — 이것도 우리가 수정할 파일들의 베이스라인이라 feature 브랜치 분기 전에 dev에 먼저 커밋해야 diff가 깨끗해짐. **다음 세션에서 이어할 것**: `settings.local.json`을 커밋해도 되는지(보통 개인 로컬 전용 파일이라 `.gitignore` 대상인 경우가 많음) `.gitignore` 확인 후 결정 → `.claude/` 스테이징 → 위 4개 파일과 함께(또는 별도로) dev에 커밋 → 리포트 + 사용자 확인 → 그 다음에야 Task 1(feature 브랜치 생성) 진행

**다음 즉시 할 일**: `.gitignore` 확인 → `.claude/settings.local.json` 커밋 여부 결정 → dev에 정리 커밋 → Task 1(feature 브랜치 생성)부터 재개.

---

**Goal:** 매 커밋마다 리포트+확인을 요구하던 기존 정책을, main(릴리즈 전용)/dev(작업 브랜치, PR 병합만)/feature(자유 커밋) 3단계 git-flow 구조로 전환하고, 이를 로컬 훅으로 강제한다.

**Architecture:** `.claude/hooks/block-git-commit.sh`(정규식 기반, 실측으로 확인된 버그: 커맨드 안에 `git commit`보다 앞서 따옴표가 나오면 매칭이 끊겨 차단이 뚫림)를 `.claude/hooks/guard_git_actions.py`(JSON을 `json.loads`로 제대로 파싱하는 Python 스크립트)로 교체한다. 훅은 현재 git 브랜치와 시도된 명령을 보고 `dev`/`main` 직접 커밋, `gh pr create`, `main`으로의 `git push`만 차단한다. `feature/*` 브랜치 안의 커밋은 통과시킨다. 문서(worker.md, CLAUDE.md, Workflow_Project.md, Decision.md, BACKLOG.md)를 새 정책에 맞춰 갱신한다.

**Tech Stack:** Bash (Claude Code hook 실행 계층), Python 3.13 (JSON 파싱 및 로직), Git, GitHub CLI(`gh`)

## Global Constraints

- Windows 환경, Git Bash 사용 가능(`bash`, `python` PATH에 있음 — 이 세션에서 확인됨). `jq`는 없음 — JSON 파싱은 Python으로 한다.
- 훅 matcher는 `Bash` 도구 전체에 걸림 (settings.json에서 변경하지 않음) — 스크립트 내부에서 커맨드 내용으로 필터링한다.
- 기존 훅의 실측 버그(정규식이 인용부호를 만나면 매칭이 끊김)를 재현해 확인함: `git commit -m "test"`는 차단(exit 2)되지만 `git add "path" && git commit -m "test"`는 통과(exit 0)됨. 새 구현은 `json.loads()`로 `tool_input.command`를 통째로 꺼내 이 문제를 원천적으로 없앤다.
- `docs/knowledge/history/*`, `docs/knowledge/reference/**` 수정은 일반 Edit 승인 흐름을 거친다 (CLAUDE.md 체크포인트 2, 변경 없음).
- `dev`/`main` 직접 커밋, `gh pr create`, `main`으로의 `git push`는 항상 리포트 작성 + 사용자 확인 후에만 실행한다. 이 네 가지는 permissions allow-list에 절대 넣지 않는다.
- `feature/*` 브랜치 안에서는 Worker/PM 누구나 리포트/확인 없이 자유롭게 `git commit` 한다.
- 스펙 문서: `docs/superpowers/specs/2026-07-08-git-flow-commit-policy-design.md` (모든 정책 디테일의 근거).

---

### Task 1: 이 작업 자체를 위한 feature 브랜치 생성

**Files:** 없음 (git 브랜치 조작만)

**Interfaces:** 없음 — 순수 셋업 작업

- [ ] **Step 1: dev가 최신인지 확인하고 feature 브랜치 분기**

```bash
git status
git checkout dev
git pull
git checkout -b feature/git-flow-commit-policy
```

Expected: `Switched to a new branch 'feature/git-flow-commit-policy'`

- [ ] **Step 2: 현재 브랜치 확인**

```bash
git rev-parse --abbrev-ref HEAD
```

Expected: `feature/git-flow-commit-policy`

(이 브랜치 안에서는 이후 모든 커밋을 리포트/확인 없이 자유롭게 진행한다 — 이 작업 자체가 새 정책의 첫 적용 사례다.)

---

### Task 2: 브랜치 인지형 git-action guard 훅 작성

**Files:**
- Create: `.claude/hooks/guard_git_actions.py`
- Delete: `.claude/hooks/block-git-commit.sh`
- Modify: `.claude/settings.json:9` (hook command 라인)

**Interfaces:**
- Produces: `guard_git_actions.py`는 stdin으로 Claude Code PreToolUse hook payload(JSON, `tool_input.command` 필드 포함)를 받아 exit code 0(통과) 또는 2(차단 + stderr 메시지)를 반환하는 CLI. 이후 Task들은 이 스크립트의 동작에 의존하지 않음(독립적인 문서 작업).

- [ ] **Step 1: `guard_git_actions.py` 작성**

```python
#!/usr/bin/env python3
"""PreToolUse hook: gates git/gh actions per the project's branch policy.

See docs/knowledge/reference/policy/Workflow_Project.md §13.
- `git commit` on a `feature/*` branch: allowed, no gate.
- `git commit` directly on `dev` or `main`: blocked, needs report + human confirmation.
- `gh pr create` (any direction): blocked, needs PR draft + report + human confirmation.
- `git push` targeting `main`: blocked, needs report + human confirmation.
"""
import json
import re
import subprocess
import sys

COMMIT_RE = re.compile(r"\bgit\s+commit\b")
PR_CREATE_RE = re.compile(r"\bgh\s+pr\s+create\b")
PUSH_RE = re.compile(r"\bgit\s+push\b")
MAIN_TOKEN_RE = re.compile(r"\bmain\b")


def get_current_branch():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def main() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return 0

    command = payload.get("tool_input", {}).get("command", "")
    if not command:
        return 0

    if PR_CREATE_RE.search(command):
        print(
            "STOP: `gh pr create` is gated by this project's harness. "
            "Before creating the PR: (1) write a PR draft (title, description, "
            "summary of changes) and a report covering what was done, why, and "
            "the impact, (2) show it to the user and get explicit confirmation. "
            "Only after that, retry.",
            file=sys.stderr,
        )
        return 2

    if PUSH_RE.search(command) and MAIN_TOKEN_RE.search(command):
        print(
            "STOP: `git push` targeting `main` is gated by this project's "
            "harness (main is release-only). Before pushing: (1) write a "
            "report covering what is being released and why, (2) show it to "
            "the user and get explicit confirmation. Only after that, retry.",
            file=sys.stderr,
        )
        return 2

    if COMMIT_RE.search(command):
        branch = get_current_branch()
        if branch in ("dev", "main"):
            print(
                f"STOP: direct `git commit` on `{branch}` is gated by this "
                "project's harness (dev/main only take changes via PR). "
                "Before committing: (1) write a report covering what was "
                "done, what changed and why, and the impact, (2) show it to "
                "the user and get explicit confirmation. Only after that, "
                "retry the commit. If this work belongs in a feature branch "
                "instead, create one off dev and commit there freely.",
                file=sys.stderr,
            )
            return 2
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: 기존 훅 파일 삭제**

```bash
rm .claude/hooks/block-git-commit.sh
```

- [ ] **Step 3: `.claude/settings.json`의 훅 커맨드 갱신**

`.claude/settings.json:9`를 다음과 같이 바꾼다 (matcher는 그대로 `Bash` 유지):

```json
            "command": "python .claude/hooks/guard_git_actions.py"
```

- [ ] **Step 4: 수동 검증 — `dev` 브랜치에서 커밋 시도 시 차단되는지 확인**

```bash
git checkout dev
echo '{"tool_input":{"command":"git add \"docs/some file.md\" && git commit -m \"test\""}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: direct \`git commit\` on \`dev\`...` 메시지, `exit code: 2` (기존 훅이 놓쳤던 "따옴표 포함 커맨드" 케이스가 이제 잡히는지 확인하는 회귀 테스트)

- [ ] **Step 5: 수동 검증 — `gh pr create` 항상 차단되는지 확인**

```bash
echo '{"tool_input":{"command":"gh pr create --title \"x\" --body \"y\""}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: \`gh pr create\`...` 메시지, `exit code: 2`

- [ ] **Step 6: 수동 검증 — `main`으로의 push 차단되는지 확인**

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: \`git push\` targeting \`main\`...` 메시지, `exit code: 2`

- [ ] **Step 7: 수동 검증 — feature 브랜치에서는 통과하는지 확인**

```bash
git checkout feature/git-flow-commit-policy
echo '{"tool_input":{"command":"git add \"docs/some file.md\" && git commit -m \"test\""}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: 아무 stderr 출력 없음, `exit code: 0`

- [ ] **Step 8: 관계없는 명령은 통과하는지 확인**

```bash
echo '{"tool_input":{"command":"git status"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: `exit code: 0`

- [ ] **Step 9: Commit (feature 브랜치 안, 자유 커밋)**

```bash
git add .claude/hooks/guard_git_actions.py .claude/settings.json
git rm .claude/hooks/block-git-commit.sh
git commit -m "feat(hooks): replace regex commit-blocker with branch-aware guard_git_actions.py"
```

---

### Task 3: `worker.md` 커밋 정책 갱신

**Files:**
- Modify: `.claude/agents/worker.md:17-19`

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: "Never commit" 섹션을 "Commit policy" 섹션으로 교체**

`.claude/agents/worker.md`의 다음 블록을:

```markdown
## Never commit

You never run `git commit`. When your work is done, hand it back — PM and the human decide when and whether to commit, with a report. If you believe the work is commit-ready, say so in your handoff; do not commit it yourself.
```

다음으로 교체:

```markdown
## Commit policy

Commit freely inside the `feature/*` branch PM assigned you for this task — no report or confirmation needed per commit. Never run `git commit` directly on `dev` or `main`, and never run `gh pr create` — both are gated by the project's harness hook and require PM/human confirmation. If you find yourself on `dev` or `main` when you expected a feature branch, stop and tell PM instead of committing.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/agents/worker.md
git commit -m "doc(worker): allow free commits inside feature branches, keep dev/main/PR gated"
```

---

### Task 4: `CLAUDE.md` 체크포인트 3 갱신

**Files:**
- Modify: `CLAUDE.md:29`

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: 체크포인트 3 라인 교체**

`CLAUDE.md:29`의:

```markdown
3. **커밋 전 리포트 + 확인**: `git commit` 실행 전 반드시 "무엇을 했고 / 어디를 왜 고쳤고 / 어떤 영향이 있는지"를 텍스트로 먼저 작성하고 사용자 확인을 받는다. `git commit`을 permissions allow-list에 절대 넣지 않는다 (`.claude/settings.json`의 훅이 추가로 강제함).
```

다음으로 교체:

```markdown
3. **dev/main 커밋 및 PR 생성 전 리포트 + 확인**: `feature/*` 브랜치 안에서의 commit은 Worker/PM 누구나 리포트·확인 없이 자유롭게 한다. 하지만 `dev`/`main`에 직접 `git commit`하거나, `gh pr create`로 PR을 생성하거나(feature→dev, dev→main 모두), `main`으로 `git push`하기 전에는 반드시 "무엇을 했고 / 어디를 왜 고쳤고 / 어떤 영향이 있는지"를 텍스트로 먼저 작성하고 사용자 확인을 받는다. 이 네 가지 행위를 permissions allow-list에 절대 넣지 않는다 (`.claude/settings.json`의 훅이 추가로 강제함).
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "doc(claude): scope commit-confirmation checkpoint to dev/main and PR creation"
```

---

### Task 5: `Workflow_Project.md`에 브랜치 전략/PR 정책 §13 신설

**Files:**
- Modify: `docs/knowledge/reference/policy/Workflow_Project.md` (파일 끝, §12.3 뒤에 추가)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: 파일 끝에 새 섹션 추가**

`docs/knowledge/reference/policy/Workflow_Project.md`의 마지막 줄(§12.3 끝) 뒤에 다음을 추가:

```markdown

---

# 13. Branch Strategy & PR Policy

## 13.1 Branch Structure

```text
main  ─ release only
 └─ dev  ─ default working branch. No direct commits (human-only exception), merges only via PR
     └─ feature/<backlog-item-slug>  ─ branched from dev when PM starts a BACKLOG.md item. Worker/PM commit freely here
```

## 13.2 Commit Gate

- `feature/*`: free commit, no report/confirmation gate.
- `dev` / `main`: direct commit blocked by hook; requires report + human confirmation (same procedure as Core Operating Principles checkpoint 3).
- `gh pr create` (either direction): always blocked by hook; requires PR draft + report + human confirmation.
- `git push` targeting `main`: always blocked by hook; requires report + human confirmation.

## 13.3 PR Triggers

- **feature → dev**: triggered when a BACKLOG.md checklist item is complete (Worker→Review cycle done). PM drafts the PR title/description plus a completion report, gets human confirmation, then runs `gh pr create`. The human merges on GitHub — PM never merges.
- **dev → main**: triggered when every item intended for the next patch/release has landed on dev. The human decides, or PM proposes and the human approves; same draft + confirm + `gh pr create` flow. The report doubles as release notes.

GitHub Branch protection on `main`/`dev` (require PR before merge, disallow force-push/deletion) is configured by the human directly in the GitHub web UI — independent of the local hook, as a second safety net.
```

- [ ] **Step 2: Commit**

```bash
git add docs/knowledge/reference/policy/Workflow_Project.md
git commit -m "doc(policy): add §13 branch strategy and PR policy"
```

---

### Task 6: `Decision.md`에 결정사항 기록

**Files:**
- Modify: `docs/knowledge/history/Decision.md:1` (파일 맨 위, 기존 첫 항목 앞에 삽입 — 최신이 위)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: 파일 맨 위(1번째 줄 주석 바로 아래)에 새 Decision 항목 삽입**

`docs/knowledge/history/Decision.md:1`의 주석 줄 바로 다음에 다음 블록을 삽입 (기존 첫 `[Decision]` 항목보다 위):

```markdown

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
```

- [ ] **Step 2: Commit**

```bash
git add docs/knowledge/history/Decision.md
git commit -m "doc(decision): git-flow 브랜치/커밋/PR 정책 도입 기록"
```

---

### Task 7: `BACKLOG.md` 갱신

**Files:**
- Modify: `docs/work/BACKLOG.md:25-28` (Current 섹션)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: Current 섹션을 갱신**

`docs/work/BACKLOG.md:25-28`의:

```markdown
# Current

하네스(PM/Worker/Review 서브에이전트 + 훅) 구축 — 진행 상황은 `docs/work/하네스_구축_체크리스트.md`에서 별도 추적
```

다음으로 교체:

```markdown
# Current

Git-flow 커밋/PR 정책 도입 (main/dev/feature 3단계 브랜치, hook 교체) — 진행 상황은 `docs/superpowers/plans/2026-07-08-git-flow-commit-policy.md`에서 별도 추적
```

- [ ] **Step 2: Commit**

```bash
git add docs/work/BACKLOG.md
git commit -m "doc(backlog): git-flow 정책 작업을 Current로 갱신"
```

---

### Task 8: 최종 검증 + feature → dev PR

**Files:** 없음 (검증 + PR 생성)

**Interfaces:** Task 2에서 만든 `guard_git_actions.py`의 최종 동작을 재확인한다.

- [ ] **Step 1: 훅 전체 시나리오 재검증 (Task 2 Step 4~8 재실행)**

```bash
git checkout dev
echo '{"tool_input":{"command":"git add \"x y\" && git commit -m test"}}' | python .claude/hooks/guard_git_actions.py; echo "dev commit: $?"
echo '{"tool_input":{"command":"gh pr create --title t --body b"}}' | python .claude/hooks/guard_git_actions.py; echo "pr create: $?"
echo '{"tool_input":{"command":"git push origin main"}}' | python .claude/hooks/guard_git_actions.py; echo "push main: $?"
git checkout feature/git-flow-commit-policy
echo '{"tool_input":{"command":"git add \"x y\" && git commit -m test"}}' | python .claude/hooks/guard_git_actions.py; echo "feature commit: $?"
```

Expected: `dev commit: 2`, `pr create: 2`, `push main: 2`, `feature commit: 0`

- [ ] **Step 2: 커밋 로그 확인**

```bash
git log --oneline dev..feature/git-flow-commit-policy
```

Expected: Task 2~7에서 만든 커밋들이 순서대로 보임

- [ ] **Step 3: PR 초안 + 완료 리포트 작성 후 사용자에게 제시**

무엇을 했고(브랜치 인지형 훅 교체 + 정책 문서 5종 갱신), 어디를 왜 고쳤고(§13 신설 배경, 기존 훅의 정규식 매칭 버그 발견), 어떤 영향이 있는지(기존 "매 커밋 확인" 부담이 feature 브랜치 안에서는 사라짐, dev/main/PR/main-push 행위만 계속 게이트)를 정리해 사용자에게 보여주고 확인을 받는다.

- [ ] **Step 4: 확인 후 PR 생성**

```bash
git push -u origin feature/git-flow-commit-policy
gh pr create --base dev --head feature/git-flow-commit-policy --title "Git-flow 기반 커밋/PR 정책 도입" --body "$(cat <<'EOF'
## Summary
- main(릴리즈 전용) / dev(작업 브랜치, PR 병합만) / feature(자유 커밋) 3단계 브랜치 구조 도입
- .claude/hooks/block-git-commit.sh(정규식 매칭 버그 실측 확인됨)를 브랜치 인지형 guard_git_actions.py로 교체
- worker.md, CLAUDE.md, Workflow_Project.md §13, Decision.md, BACKLOG.md 갱신

## Test plan
- [x] dev/main에서 git commit 시도 시 훅이 차단(exit 2)하는지 확인 (따옴표 포함 커맨드 포함)
- [x] gh pr create 시도 시 훅이 항상 차단하는지 확인
- [x] main으로의 git push 시도 시 훅이 차단하는지 확인
- [x] feature 브랜치에서 git commit이 통과(exit 0)하는지 확인
EOF
)"
```

Expected: PR URL 출력. 사용자가 GitHub에서 리뷰 후 직접 머지.

---

## Self-Review Notes

- **Spec coverage**: 브랜치 구조(§1), commit 훅 로직(§2), PR 정책(§3), 수정 대상 파일 5종(§4) 모두 Task 1~7에 매핑됨. `review.md`는 스펙대로 변경 없음.
- **Placeholder scan**: 없음 — 모든 스텝에 실행 가능한 코드/커맨드 포함.
- **Type/signature consistency**: `guard_git_actions.py`는 다른 Task가 임포트하는 라이브러리가 아니라 독립 실행 스크립트이므로 시그니처 일관성 이슈 없음. `settings.json`의 커맨드 문자열과 실제 파일 경로(`.claude/hooks/guard_git_actions.py`)가 Task 2 Step 3/4에서 정확히 일치함을 확인함.
- **회귀 테스트 반영**: 실측으로 발견한 "따옴표 포함 커맨드" 버그를 Task 2 Step 4, Task 8 Step 1의 검증 커맨드에 명시적으로 포함시켜, 새 구현이 이 케이스를 확실히 잡는지 확인하도록 함.

---

## Addendum: PR-create/merge 게이트 재설계 (Task 8에서 PR #2 오픈 후 추가 결정)

**배경**: Task 8 완료 후 PR #2(dev←feature/git-flow-commit-policy)를 열고 나서, 사용자와 논의 중 두 가지가 드러남 —
1. `gh pr create`를 매번 리포트+확인으로 게이트하는 것과, 사용자가 어차피 GitHub에서 merge 전에 PR을 다시 검토하는 것이 "이 내용을 dev/main에 반영해도 되는가"라는 같은 질문을 두 번 묻는 중복이었음.
2. `gh pr merge`는 애초에 훅이 정규식 검사 대상에 넣지 않아서, "사람만 merge한다"는 §13.3 원칙이 순수 서면 규칙일 뿐 기술적으로 전혀 강제되지 않았음.

**새 정책**: PR 생성 게이트를 대상 브랜치(base)로 구분한다 — feature→dev는 자유(실제 반영 시점인 merge에서 사람이 어차피 검토하므로), dev→main만 계속 게이트(코드 안전성 문제가 아니라 "지금 릴리즈할지"의 타이밍 결정이므로). `gh pr merge`는 방향 무관 항상 하드 블록 — "확인 후 재시도" 모델이 아니라 애초에 AI가 절대 실행하지 않는 액션이라는 걸 훅으로도 강제.

### Task 9: `guard_git_actions.py` — PR-create 게이트를 main-base 전용으로 좁히고 `gh pr merge` 하드 블록 추가

**Files:**
- Modify: `.claude/hooks/guard_git_actions.py`

**Interfaces:** 없음 (독립 실행 스크립트, 다른 Task가 임포트하지 않음)

- [ ] **Step 1: 모듈 docstring 갱신**

파일 상단(2~9번 줄)의 docstring을:

```python
"""PreToolUse hook: gates git/gh actions per the project's branch policy.

See docs/knowledge/reference/policy/Workflow_Project.md §13.
- `git commit` on a `feature/*` branch: allowed, no gate.
- `git commit` directly on `dev` or `main`: blocked, needs report + human confirmation.
- `gh pr create` (any direction): blocked, needs PR draft + report + human confirmation.
- `git push` targeting `main`: blocked, needs report + human confirmation.
"""
```

다음으로 교체:

```python
"""PreToolUse hook: gates git/gh actions per the project's branch policy.

See docs/knowledge/reference/policy/Workflow_Project.md §13.
- `git commit` on a `feature/*` branch: allowed, no gate.
- `git commit` directly on `dev` or `main`: blocked, needs report + human confirmation.
- `gh pr create` targeting `dev` (or any non-`main` base): allowed, no gate.
- `gh pr create` targeting `main` (or with no `--base`, which defaults to the
  repo's default branch `main`): blocked, needs PR draft + report + human confirmation.
- `gh pr merge` (any direction): always blocked. Not a confirm-and-retry gate —
  the human merges directly, the AI never runs this command.
- `git push` targeting `main`: blocked, needs report + human confirmation.
"""
```

- [ ] **Step 2: regex 정의 갱신**

`COMMIT_RE`/`PR_CREATE_RE`/`PUSH_RE`/`MAIN_TOKEN_RE` 정의 블록을:

```python
COMMIT_RE = re.compile(r"\bgit\s+commit\b")
PR_CREATE_RE = re.compile(r"\bgh\s+pr\s+create\b")
PUSH_RE = re.compile(r"\bgit\s+push\b")
MAIN_TOKEN_RE = re.compile(r"(?<![\w-])main(?![\w-])")
```

다음으로 교체 (두 줄 추가):

```python
COMMIT_RE = re.compile(r"\bgit\s+commit\b")
PR_CREATE_RE = re.compile(r"\bgh\s+pr\s+create\b")
PR_MERGE_RE = re.compile(r"\bgh\s+pr\s+merge\b")
PR_BASE_RE = re.compile(r"--base[=\s]+(\S+)")
PUSH_RE = re.compile(r"\bgit\s+push\b")
MAIN_TOKEN_RE = re.compile(r"(?<![\w-])main(?![\w-])")
```

- [ ] **Step 3: `main()`의 `gh pr create` 처리 블록 교체**

현재:

```python
    if PR_CREATE_RE.search(command):
        print(
            "STOP: `gh pr create` is gated by this project's harness. "
            "Before creating the PR: (1) write a PR draft (title, description, "
            "summary of changes) and a report covering what was done, why, and "
            "the impact, (2) show it to the user and get explicit confirmation. "
            "Only after that, retry.",
            file=sys.stderr,
        )
        return 2
```

다음으로 교체 (앞에 `gh pr merge` 체크를 새로 추가하고, `gh pr create`는 base 브랜치를 보고 판단):

```python
    if PR_MERGE_RE.search(command):
        print(
            "STOP: `gh pr merge` is never run by AI agents in this project's "
            "harness (Workflow_Project.md §13.3: the human always merges, "
            "directly on GitHub or by running this command themselves). This "
            "is not a confirm-and-retry gate — do not retry this command.",
            file=sys.stderr,
        )
        return 2

    if PR_CREATE_RE.search(command):
        base_match = PR_BASE_RE.search(command)
        base = base_match.group(1).strip("'\"") if base_match else None
        if base is None or MAIN_TOKEN_RE.search(base):
            print(
                "STOP: `gh pr create` targeting `main` (or with no `--base` "
                "given, which defaults to this repo's default branch, `main`) "
                "is gated by this project's harness (main is release-only). "
                "Before creating the PR: (1) write a PR draft (title, "
                "description, summary of changes) and a report covering what "
                "is being released and why, (2) show it to the user and get "
                "explicit confirmation. Only after that, retry.",
                file=sys.stderr,
            )
            return 2
        return 0
```

- [ ] **Step 4: 수동 검증 — feature→dev PR 생성은 자유롭게 통과**

```bash
echo '{"tool_input":{"command":"gh pr create --base dev --head feature/x --title t --body b"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: 아무 stderr 출력 없음, `exit code: 0`

- [ ] **Step 5: 수동 검증 — dev→main PR 생성(명시적 base)은 계속 차단**

```bash
echo '{"tool_input":{"command":"gh pr create --base main --head dev --title t --body b"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: \`gh pr create\` targeting \`main\`...` 메시지, `exit code: 2`

- [ ] **Step 6: 수동 검증 — `--base` 없는 `gh pr create`도 차단 (기본값이 main이므로)**

```bash
echo '{"tool_input":{"command":"gh pr create --head dev --title t --body b"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: \`gh pr create\` targeting \`main\`...` 메시지, `exit code: 2`

- [ ] **Step 7: 수동 검증 — `gh pr merge`는 방향 무관 항상 차단**

```bash
echo '{"tool_input":{"command":"gh pr merge 2 --merge"}}' | python .claude/hooks/guard_git_actions.py
echo "exit code: $?"
```

Expected: stderr에 `STOP: \`gh pr merge\`...` 메시지, `exit code: 2`

- [ ] **Step 8: 기존 회귀(Task 2/Task 8에서 검증한 시나리오) 재확인** — dev/main 직접 커밋 차단, main push 차단, feature 커밋 통과, 관계없는 커맨드 통과 4개 그대로 재실행해 회귀 없는지 확인.

- [ ] **Step 9: Commit (feature 브랜치 안, 자유 커밋)**

```bash
git add .claude/hooks/guard_git_actions.py
git commit -m "feat(hooks): scope PR-create gate to main-base only, hard-block gh pr merge"
```

---

### Task 10: `Workflow_Project.md` §13.2/§13.3 갱신 — PR 생성 자유화 반영

**Files:**
- Modify: `docs/knowledge/reference/policy/Workflow_Project.md` (§13.2, §13.3)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: §13.2 Commit Gate 교체**

현재:

```markdown
## 13.2 Commit Gate

- `feature/*`: free commit, no report/confirmation gate.
- `dev` / `main`: direct commit blocked by hook; requires report + human confirmation (same procedure as Core Operating Principles checkpoint 3).
- `gh pr create` (either direction): always blocked by hook; requires PR draft + report + human confirmation.
- `git push` targeting `main`: always blocked by hook; requires report + human confirmation.
```

다음으로 교체:

```markdown
## 13.2 Commit Gate

- `feature/*`: free commit, no report/confirmation gate.
- `dev` / `main`: direct commit blocked by hook; requires report + human confirmation (same procedure as Core Operating Principles checkpoint 3).
- `gh pr create` targeting `dev` (or any non-`main` base): free, no report/confirmation gate — the human reviews at merge time instead, so gating creation too would just ask the same question twice.
- `gh pr create` targeting `main` (or with no `--base`, which defaults to `main`): always blocked by hook; requires PR draft + report + human confirmation. This one stays gated because it signals a release decision (timing), not just code safety.
- `gh pr merge` (any direction): always blocked by hook, not a confirm-and-retry gate — the AI never merges, period. The human merges directly (GitHub UI or running the command themselves).
- `git push` targeting `main`: always blocked by hook; requires report + human confirmation.
```

- [ ] **Step 2: §13.3 PR Triggers 교체**

현재:

```markdown
## 13.3 PR Triggers

- **feature → dev**: triggered when a BACKLOG.md checklist item is complete (Worker→Review cycle done). PM drafts the PR title/description plus a completion report, gets human confirmation, then runs `gh pr create`. The human merges on GitHub — PM never merges.
- **dev → main**: triggered when every item intended for the next patch/release has landed on dev. The human decides, or PM proposes and the human approves; same draft + confirm + `gh pr create` flow. The report doubles as release notes.

GitHub Branch protection on `main`/`dev` (require PR before merge, disallow force-push/deletion) is configured by the human directly in the GitHub web UI — independent of the local hook, as a second safety net.
```

다음으로 교체:

```markdown
## 13.3 PR Triggers

- **feature → dev**: triggered when a BACKLOG.md checklist item is complete (Worker→Review cycle done). PM drafts the PR title/description and opens it with `gh pr create --base dev` freely, no pre-creation confirmation needed. The human reviews and merges on GitHub — PM never merges, and never runs `gh pr merge`.
- **dev → main**: triggered when every item intended for the next patch/release has landed on dev. The human decides, or PM proposes and the human approves; PM drafts a report (doubling as release notes) and gets confirmation before running `gh pr create --base main`. The human merges on GitHub — PM never merges, and never runs `gh pr merge`.

GitHub Branch protection on `main`/`dev` (require PR before merge, disallow force-push/deletion) is configured by the human directly in the GitHub web UI — independent of the local hook, as a second safety net.
```

- [ ] **Step 3: Commit**

```bash
git add docs/knowledge/reference/policy/Workflow_Project.md
git commit -m "doc(policy): scope §13 PR-create gate to main-base, note gh pr merge hard-block"
```

---

### Task 11: `CLAUDE.md` 체크포인트 3 재조정

**Files:**
- Modify: `CLAUDE.md` (체크포인트 3)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: 체크포인트 3 라인 교체**

현재:

```markdown
3. **dev/main 커밋 및 PR 생성 전 리포트 + 확인**: `feature/*` 브랜치 안에서의 commit은 Worker/PM 누구나 리포트·확인 없이 자유롭게 한다. 하지만 `dev`/`main`에 직접 `git commit`하거나, `gh pr create`로 PR을 생성하거나(feature→dev, dev→main 모두), `main`으로 `git push`하기 전에는 반드시 "무엇을 했고 / 어디를 왜 고쳤고 / 어떤 영향이 있는지"를 텍스트로 먼저 작성하고 사용자 확인을 받는다. 이 네 가지 행위를 permissions allow-list에 절대 넣지 않는다 (`.claude/settings.json`의 훅이 추가로 강제함).
```

다음으로 교체:

```markdown
3. **dev/main 커밋, dev→main PR 생성 전 리포트 + 확인 / PR merge는 항상 사람 몫**: `feature/*` 브랜치 안에서의 commit과 `gh pr create --base dev`는 Worker/PM 누구나 리포트·확인 없이 자유롭게 한다(merge 시점에 사람이 어차피 검토하므로). 하지만 `dev`/`main`에 직접 `git commit`하거나, `gh pr create --base main`으로 PR을 생성하거나, `main`으로 `git push`하기 전에는 반드시 "무엇을 했고 / 어디를 왜 고쳤고 / 어떤 영향이 있는지"를 텍스트로 먼저 작성하고 사용자 확인을 받는다. `gh pr merge`는 확인을 받아도 실행하지 않는다 — PR 병합은 항상 사람이 직접 한다. 이 행위들을 permissions allow-list에 절대 넣지 않는다 (`.claude/settings.json`의 훅이 추가로 강제함).
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "doc(claude): scope checkpoint 3 to dev/main commit + main-base PR create, note merge is human-only"
```

---

### Task 12: `worker.md` 커밋 정책 문구 정확성 수정

**Files:**
- Modify: `.claude/agents/worker.md`

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: Commit policy 섹션 교체**

현재:

```markdown
## Commit policy

Commit freely inside the `feature/*` branch PM assigned you for this task — no report or confirmation needed per commit. Never run `git commit` directly on `dev` or `main`, and never run `gh pr create` — both are gated by the project's harness hook and require PM/human confirmation. If you find yourself on `dev` or `main` when you expected a feature branch, stop and tell PM instead of committing.
```

다음으로 교체:

```markdown
## Commit policy

Commit freely inside the `feature/*` branch PM assigned you for this task — no report or confirmation needed per commit. Never run `git commit` directly on `dev` or `main` — that's gated by the project's harness hook and requires PM/human confirmation. Never run `gh pr create` or `gh pr merge` yourself regardless of what the hook allows — deciding when a task's work is ready to propose merging (and merging itself) is PM/human's call, not yours. If you find yourself on `dev` or `main` when you expected a feature branch, stop and tell PM instead of committing.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/agents/worker.md
git commit -m "doc(worker): clarify PR create/merge stay PM/human-only regardless of hook scope"
```

---

### Task 13: `Decision.md` 기록 — PR-생성/merge 게이트 재설계

**Files:**
- Modify: `docs/knowledge/history/Decision.md` (파일 맨 위, 기존 첫 항목 앞에 삽입)

**Interfaces:** 없음 (문서 변경만)

- [ ] **Step 1: 파일 맨 위에 새 Decision 항목 삽입**

`docs/knowledge/history/Decision.md`의 맨 위(주석 줄 바로 다음)에 다음 블록을 삽입:

```markdown

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

---
```

- [ ] **Step 2: Commit**

```bash
git add docs/knowledge/history/Decision.md
git commit -m "doc(decision): PR-create 게이트 main-base 전용화 + gh pr merge 하드 블록 기록"
```

---

### Task 14: 최종 검증 + PR #2 갱신

**Files:** 없음 (검증 + push)

- [ ] **Step 1: 훅 전체 시나리오 재검증** — Task 9 Step 4~7 + 기존 회귀(dev/main commit 차단, main push 차단, feature commit 통과)까지 전부 재실행.
- [ ] **Step 2: 커밋 로그 확인** — `git log --oneline dev..feature/git-flow-commit-policy`로 Task 9~13 커밋이 기존 8개 뒤에 순서대로 붙었는지 확인.
- [ ] **Step 3: 갱신 리포트 작성 후 사용자에게 제시** — 무엇을 바꿨고(PR-create 게이트 범위 축소 + gh pr merge 하드 블록), 왜 바꿨고(중복 확인 제거, 실제 구멍 메움), 어떤 영향이 있는지(feature→dev PR은 이제 자유, dev→main은 계속 게이트, merge는 항상 사람) 정리해 확인받는다.
- [ ] **Step 4: 확인 후 push (PR #2에 자동 반영)**

```bash
git push origin feature/git-flow-commit-policy
```

Expected: PR #2가 새 커밋 5개를 자동으로 반영. 새 PR 생성 불필요.
