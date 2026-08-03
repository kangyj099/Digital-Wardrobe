> Version 3.2 — Defines the project workflow. Single consolidated document (former per-section subfiles under `workflow_project/` merged back into this file on 2026-07-22 for reading convenience — see `docs/history/Decision.md`).
> This workflow applies across the entire project, including planning, design, development, and release.

# Project Workflow

Apply the following workflow based on the project size and the nature of the task.

## 목차

- [1. Core Principles](#1-core-principles)
- [2. Roles](#2-roles)
- [3. Information Handoff Between Sessions](#3-information-handoff-between-sessions)
- [4. Task Size](#4-task-size)
- [5. Standard Pipeline](#5-standard-pipeline)
- [6. Document Policy](#6-document-policy)
- [7. Change Impact](#7-change-impact)
- [8. Review Principles](#8-review-principles)
- [9. Audit Principles](#9-audit-principles)
- [10. Definition of Done](#10-definition-of-done)
- [11. Core Operating Principles](#11-core-operating-principles)
- [12. Role Information Access](#12-role-information-access)
- [13. Branch Strategy & PR Policy](#13-branch-strategy--pr-policy)
- [14. Token & Stats Logging](#14-token--stats-logging)
- [15. Worktree Placement](#15-worktree-placement)

---

# 1. Core Principles

## 1.1 Role Separation

AI produces higher-quality results when responsibilities are separated rather than having multiple roles handled within a single session.

Each session should perform only one role.

---

## 1.2 One Session = One Purpose

Each session should perform only one task.

---

## 1.3 Source of Truth

The project's only Source of Truth is the Git repository and the latest Reference documents.

Chat conversations are for discussion only. AI sessions are not the project's storage.

---

## 1.4 Living Documents / 1.5 Concise Writing
→ Skill: `documentation-conventions` (`.claude/skills/documentation-conventions/SKILL.md`) — invoke before writing to or editing any `docs/reference/**` file.

---

## 1.6 Version Numbering

Reference documents carrying a `> Version X.Y` header follow semantic-ish versioning.

- A chapter-level addition or modification bumps the number after the dot (minor): X.Y → X.(Y+1).
- A change to the document's usage pattern or overall framework/structure bumps the number before the dot (major): X.Y → (X+1).0.
- One revision pass gets one bump, even if it contains multiple chapter-level changes.
- Cosmetic edits that don't change meaning (renames, cross-reference updates, typo/wording fixes) do not count as a modification for this purpose — same exclusion as §1.5's Decision.md logging rule.

---

## 1.7 Document Hierarchy & Override

`Workflow_Project.md` defines project-wide default rules. Domain documents (`Workflow_Development.md`, `Workflow_Design.md`) may override or elaborate a Project rule for their domain — where they do, the domain document's version governs within that domain. Where a domain document is silent on a topic, Project's rule applies as the default.

`Workflow_Frontend.md` further specializes `Workflow_Development.md` and `Workflow_Design.md` for Flutter/Dart implementation-stage UI/Screen work specifically (per its own §1 scope note) — it is not a single-parent child of either alone.

A domain document that intentionally defers to Project on a topic (rather than genuinely having nothing to add) must say so with an explicit pointer, not silence. Silence is ambiguous: a task's Task Manifest (§12.4) may include only the domain document, not Project.md, so a reader/AI with no access to Project.md cannot distinguish "this topic doesn't apply here" from "this topic applies, go look at the parent."

---

# 2. Roles

## PM (Project Manager)

Manages the entire project.

Creates work plans at the Feature level.
(When the project becomes larger, this policy may change to planning by Sprint.)

**Responsibilities**

* Project management
* Prioritization
* Task planning
* Task creation
* Schedule management

**Does not**

* Implement
* Build

---

## Worker

Performs the actual work.

---

## Review

Reviews only the current task.

Review does not make direct modifications.

**Checks**

* Quality
* Policy compliance
* Consistency
* Errors

---

## Tester

Runs after Review passes on the current task. Drives the actual running app (Flutter `integration_test`) to check runtime behavior that static review can't see — never modifies product code.

**Checks**

* Actual behavior results (not code)
* Realistic non-standard flows, not just the happy path
* Regressions in connected existing features
* All implemented states (success/loading/empty/error/retry/cancel)
* Cross-screen data consistency
* Data persistence across navigation/re-entry
* Duplicate data from repeated input or duplicate requests
* Compliance with Reference documents and policy

**Does not**

* Implement or fix
* Propose refactors
* Evaluate code style

---

## Feature Audit

Reviews the project as a whole.

**Checks**

* Policy conflicts
* Missing functionality
* Architecture
* UX consistency
* Design System consistency
* Requirements compliance

**Important**

Audit does not make modifications.

Instead, it creates new tasks for the PM.

---

## Integrator

Combines multiple Review results into a single consolidated report and delivers it to the Worker.

---

# 3. Information Handoff Between Sessions

## Sessions are independent, handoff is orchestrated. (Important)

**Worker → (Orchestrator relays summary) → Review**

Claude Code (the PM/orchestrator agent) performs handoffs directly between sessions/subagents. Sessions still do not share information with one another except through this relayed summary; a worker never has direct visibility into another session's raw context.

Certain handoff points remain mandatory human checkpoints regardless of automation (e.g., PM task distribution visibility, decision-doc diffs, pre-commit confirmation) — see the harness checkpoint config for the current list.

---

## Minimal Handoff Principle

Request a **summary** from the current session, and provide only the **minimum necessary information** to the next session.

Never resend the entire project.

---

## Handoff Contents

* Task
* Goal
* Changes made
* Impact scope
* Review request
* Out of scope

---

## Skill-Internal Ledgers vs. Official Handoff

Some skills (e.g. superpowers subagent-driven-development) maintain gitignored progress ledgers (e.g. `.superpowers/sdd/*`) so a single session can recover its own context after compaction. These ledgers are **session-internal caches, not official cross-session handoff.**

- **Primary defense**: updating `docs/work/BACKLOG.md`'s Current section is part of completing a task step, not a separate follow-up action deferred to a pause or session end. Same discipline as marking a todo complete or appending to a progress ledger — a step is not done until this is done. §10's Definition of Done applies this per step, not only when the whole task finishes.
- **Backstop for when that slips**: if a task is paused incomplete, or a session ends, before a task finishes, the key decisions and next steps made so far must still be transcribed directly into `docs/work/BACKLOG.md` (and `Decision.md` where applicable). The `Stop`-event reminder hook (`.claude/hooks/check_backlog_freshness.py`) is a second, mechanical backstop for the same slip — advisory only, not a substitute for the primary defense above.
- Only the "completed task → commit" mapping in a skill-internal ledger is trustworthy from a fresh session — and only because it can be independently reconstructed from `git log`. Prose in the ledger (decisions, rationale, next steps) does not survive into a new session unless it is copied into a tracked document.
- Before reporting "recorded so a future session can continue," verify that a fresh session would actually reach the content by following the real `CLAUDE.md` → `BACKLOG.md` path. Existence and accuracy of the content alone is not sufficient.

---

## Post-Completion Continuity Simulation & `/clear` Recommendation

Task 단계가 Complete에 도달했고 PM이 "이 세션에서 더 이어갈 작업이 없다"고 판단하면, PM은 `docs/work/BACKLOG.md`(및 방금 추가된 Decision.md/TechnicalDebt.md 항목)를 완전히 새 세션 입장에서 다시 읽어, 그 문서만으로 새 세션이 정확히 이어받을 수 있는지 시뮬레이션한다. 이는 위 "Skill-Internal Ledgers vs. Official Handoff"의 "recorded so a future session can continue" 검증을 애드혹 체크가 아니라 명시적 필수 단계로 격상한 것이다.

- **문제 없으면**: 사용자에게 평문으로 `/clear`를 실행해도 안전하다고 권유한다. PM은 절대 직접 `/clear`를 실행하지 않는다 — 순수 정보 제공/권유이며, 실행은 항상 사람 몫이다.
- **문제 있으면**: 먼저 BACKLOG/Decision 기록을 보정한 뒤(위 "Backstop" 절차) 재시뮬레이션하고 나서 권유한다.
- **적용 범위**: Task 크기(S/M/L/XL) 무관하게 완료 시점마다 적용된다. 단, "PM이 세션 내 후속 작업이 이미 대기 중이 아니라고 판단한 Task 완료 시점"에 한해서만 이 시뮬레이션을 수행한다 — 다음 Task가 같은 세션에서 곧바로 이어질 예정이면 매 체크박스마다 반복하지 않는다.

---

# 4. Task Size

Task size is determined by its impact.

| Size | Description           |
| ---- | --------------------- |
| S    | Single modification   |
| M    | One feature           |
| L    | New feature or screen |
| XL   | System-wide           |

---

# 5. Standard Pipeline

Once work is completed, return it to the PM.

## S (Small)

```text
Worker → Complete
```

Exception: if the single modification changes runtime-observable behavior (not just text/style/docs), Tester still runs — treat it as the M pipeline for that step.

---

## M (Medium)

```text
Worker → Review → (Fail) Worker(fix) → Review          [반복: Review 통과할 때까지]
              → (Pass) Tester → (Pass) Complete
                             → (Fail) Worker(fix) → Review   [처음 단계로 회귀, 전체 사이클 재수행]
```

Review 실패 시엔 Worker가 고치고 Review로만 돌아간다(Tester는 아직 볼 필요 없는 코드니까). 하지만 **Tester가 실패하면 Worker가 수정한 뒤 처음 단계인 Review로 돌아가 Review→Tester 사이클을 처음부터 다시 밟는다** — 수정이 새 코드 결함을 만들지 않았는지, 그리고 실제로 동작이 고쳐졌는지 둘 다 다시 확인하기 위함. 이 재검증 루프는 Review와 Tester가 모두 통과할 때까지 반복된다. 반복 실행 비용은 아래 "재검증 루프의 에이전트 재사용" 원칙을 따른다.

---

## L (Large)

```text
PM → Worker → Review → (Fail) Worker(fix) → Review
                   → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                  → (Fail) Worker(fix) → Review
```

M과 동일한 분기 규칙: Review 실패 → Worker(fix) → Review; Tester 실패 → Worker(fix) → Review(처음부터 재수행); Tester 통과 → Integrator로 진행.

---

## XL (Extra Large)

Split the review into two independent reviews.

```text
PM → Worker → Review ×2 → (Fail) Worker(fix) → Review ×2
                       → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                      → (Fail) Worker(fix) → Review ×2
```

---

## 재검증 루프의 재검증 범위 (M/L/XL 공통)

"처음 단계로 회귀"는 검증을 다시 한다는 뜻이지, 매번 원본 Task 전체를 처음부터 다시 본다는 뜻은 아니다. 이 재검증 라운드를 새 서브에이전트로 스폰할지 직전 라운드의 Review/Tester를 이어 쓸지는 이미 있는 CLAUDE.md "에이전트 인스턴스 수명" 원칙을 그대로 따른다(같은 Task를 다시 보는 라운드는 그 원칙이 말하는 "연속된 스텝, 같은 전문성"에 해당).

재검증의 판정 대상은 **Worker의 fix로 바뀐 부분(diff) + 그 fix가 건드린 파일**로 좁힌다 — 직전 라운드에서 이미 통과한 부분을 매번 처음부터 다시 판정하지 않는다. fix가 원래 Task Manifest(§12.4) 밖의 파일까지 건드렸다면, 그 확장된 범위만 §12.3(Scope Escalation)에 따라 PM이 재평가해 추가한다.

이 원칙은 "Review와 Tester가 모두 통과할 때까지 반복"하는 검증 강도를 낮추지 않는다 — 반복 실행의 **비용**만 줄인다.

---

## Decision-Stage (Design & Plan) Pipeline

Design spec(UI/Screen × Decision)이든 구현 계획(Logic/Feature × Decision)이든, Task 크기와 무관하게 다음을 따른다:

```text
Draft (작은 단위: 섹션/챕터 단위) → Review (그 단위) → 반복(모든 단위 통과할 때까지)
  → 초안 전체 조립 → Audit (프로젝트 전체 맥락에서 완성된 초안을 홀리스틱하게 검토)
      → (Pass) 확정
      → (Fail) 지적된 단위 수정 → Review → ... → Audit 재수행
```

Design 단계의 "작은 단위 Review"는 기존 Design Review(`review` 서브에이전트, §12.1)로 이미 충족됨. Planning 단계(구현계획 작성)는 지금까지 "Usually none (PM scope)"였으나, 다음 조건을 모두 만족할 때만 사용자 승인 절차가 이 역할을 대체하는 것으로 인정한다 — 조건 미충족 시 `review` 서브에이전트를 별도로 호출해야 함:

1. `writing-plans` 스킬의 Self-Review 3항목(Spec coverage / Placeholder scan / Type consistency)이 실제로 수행되고 결과가 남아있을 것(단순히 "사용자가 좋다고 했다"가 아니라, 구체적 판정 기준에 대한 체크가 있어야 함),
2. 그 승인이 프로젝트의 관련 정책/레퍼런스 문서(해당 Layer×Stage의 §12.1 Required Materials)를 실제로 대조한 뒤 이뤄질 것 — PM이 승인 요청 시 어떤 문서를 기준으로 체크했는지 명시.

이 두 조건을 충족하면 별도 `review` 서브에이전트 호출은 생략 가능. 신규로 요구되는 것은 **확정 직전의 Audit 1회**이며, 이건 크기 무관 항상 적용된다(위 조건 충족 여부와 무관하게 항상 돎).

**알려진 트레이드오프(의도적으로 수용)**: 이 두 조건 통과는 결국 "작성자 본인의 Self-Review"이지 §1.1(Role Separation)이 요구하는 독립적 검증이 아니다. 그럼에도 예외를 허용하는 이유는 (a) Design 단계는 이미 독립 `review` 서브에이전트를 강제하고 있어 비대칭이 없고, (b) Planning 단계 아래에는 항상 걸리는 Audit이라는 두 번째 독립적 눈이 항상 있어 완전한 셀프체크로 끝나지 않으며, (c) 매 plan 섹션마다 `review` 서브에이전트를 부르면 계획 작성 자체의 오버헤드가 급증해 이 원칙이 실제로 안 지켜질 위험이 커진다는 실용적 판단. 상세 근거는 `docs/history/Decision.md` 참고.

---

# 6. Document Policy

Only two types of project documents exist.

## Reference Documents

Always keep them up to date.

---

## History Documents

Cumulative records.

Never delete them.

---

# 7. Change Impact

For every task of size **L or larger**, evaluate the Change Impact before starting the work.

# 8. Review Principles

A Review is not a brainstorming session for new ideas.

Its purpose is to identify issues that must be corrected.

Focus on finding problems, but do not propose unnecessary design changes.

**Principles**

* Maximum of five findings (no limit for critical issues)
* Assign priority (P0–P3)
* Provide rationale
* Minimize subjective preferences

# 9. Audit Principles

An Audit evaluates the entire project, not the current task.

It creates new tasks rather than making direct modifications.

# 10. Definition of Done

When a task step is completed, always verify the following — including for each individual step within a larger task, not only when the whole task finishes (see §3 "Skill-Internal Ledgers vs. Official Handoff"):

□ Changes have been committed to Git

□ Reference documents have been updated

□ Decisions have been documented

□ Technical debt has been recorded

□ Change Impact has been reviewed

□ `docs/work/BACKLOG.md`'s Current section reflects this step (not only "the next task has been added to the backlog" — the just-finished step's status too)

□ If the change has runtime-observable behavior, Tester has reported Pass (or the N/A reason is recorded)

□ If PM judged no continuation work is queued, the fresh-session continuity simulation (§3 "Post-Completion Continuity Simulation") was run and, if clean, `/clear` was recommended to the user

# 11. Core Operating Principles

Always remember:

1. The Source of Truth is the Git repository and the Reference documents.
2. Sessions do not share memory except through an orchestrated handoff summary.
3. Handoffs are orchestrated by the PM agent; mandatory checkpoints require human confirmation.
4. Each session has only one purpose.
5. Use the pipeline appropriate for the task size.
6. Review identifies problems.
7. Audit evaluates the project as a whole.
8. Reference documents are always kept up to date.
9. History documents are never deleted.
10. Always evaluate the Change Impact before making changes.
11. PM must convert Required Materials into an explicit Task Manifest — each item tagged Read/Edit/Write — before spawning a Worker (see §12.4).

# 12. Role Information Access

Defines what materials each role sees for a given task, based on the task's **Layer** and **Stage** — not on job title. This generalizes across any future pipeline (frontend, backend, infra, etc.) instead of hardcoding per-role exceptions.

## 12.1 Layer × Stage Determines Scope

Every task is tagged with the Layer(s) it touches and the Stage (Decision or Implementation) within that layer — regardless of task size. This tagging is a lightweight classification, distinct from §7's heavier formal Change Impact evaluation (which only applies to L/XL tasks): tagging always happens so material routing works even for S/M tasks; for L/XL tasks it naturally happens alongside the §7 evaluation, but it is not gated by §7 and needs no separate step even for smaller tasks.

| Layer | Stage | Required Review | Required Materials |
| --- | --- | --- | --- |
| UI/Screen | Decision (Design) | Design Review + mandatory Audit before confirmation (크기 무관) | Raw references (`참고자료/`), Design reference docs, Plan reference docs (IA/UX spec), Brand docs, `Decision.md`, **Skill: `uiux-design-conventions`** (invoke first), **Skill: `documentation-conventions`** (invoke first) |
| UI/Screen | Implementation (Frontend) | Development Review + spec-compliance check | Finalized design tokens/system doc, screen UX spec, existing widgets (`lib/`), Development workflow policy, Frontend workflow policy (`Workflow_Frontend.md` — stage-index anchor doc, lists the Frontend-specific skills to invoke) |
| Logic/Feature | Decision (Planning) | Small-unit review — `writing-plans` Self-Review(3항목) + 정책 대조 승인이 충족되면 대체 가능, 미충족 시 `review` 서브에이전트 — + mandatory Audit before confirmation (크기 무관) | Plan reference docs, **Skill: `documentation-conventions`** (invoke first) |
| Logic/Feature | Implementation | Development Review (functional) | Related code, Plan reference docs, **Skill: `engineering-principles`** (invoke first) |
| Data/API/Architecture | Decision | Development Review (architecture) + mandatory Audit before confirmation (크기 무관, §5 Decision-Stage Pipeline 적용) | Plan reference docs(MVP/Needs/IA&UserFlow/화면별UX명세서 — 화면에 노출되는 데이터 항목이 스키마 후보), `Decision.md`, **Skill: `documentation-conventions`** (invoke first) |
| Data/API/Architecture | Implementation | Development Review (architecture) | Related modules/schema, Finalized data model doc (`docs/reference/data/`), **Skill: `engineering-principles`** (invoke first) |
| (any Layer with runtime behavior) | Implementation — Tester pass | Runs after Review passes | Same Reference docs as Review for that Layer/Stage, `Decision.md`/`TechnicalDebt.md`, Worker's handoff + modified files, and the runnable app itself (not the raw exploratory material behind a Decision-stage task) |

(§5 "Decision-Stage (Design & Plan) Pipeline"의 확정-전-Audit 규칙이 위 Design/Planning/Data 세 행 모두에 반영되어 있음 — 본문 규칙과 이 표가 따로 갱신되며 어긋나는 걸 방지하기 위해 세 행을 함께 갱신함.)

## 12.2 Worker vs. Review Materials

Worker and Review do not receive identical materials for the same task.

- **Shared**: judgment-criteria documents — the Reference documents for that Layer/Stage, **and** `Decision.md` / `TechnicalDebt.md`. History documents count as judgment criteria the same way Reference documents do, since Review checks policy compliance and consistency against past decisions.
- **Worker-only**: raw/exploratory material behind a Decision-stage task (e.g. raw design references, brand voice docs). Review does not need the exploration process, only the result and whether it complies.
- **Review-only**: the Worker's output (modified files, change summary, impact scope) — the artifact being judged, which the Worker produces rather than consumes.

## 12.3 Scope Escalation

If Review needs material outside its granted scope to reach a judgment, Review does not expand its own access. Review requests a scope expansion from PM, who re-evaluates Impact Scope (§7) and grants the minimum additional material needed. This preserves the Minimal Handoff Principle (§3) while allowing legitimate exceptions.

## 12.4 Task Manifest

§12.1's Required Materials are abstract categories ("Plan reference docs", "existing widgets"). Before spawning a Worker or Review, PM converts them into an explicit **Task Manifest**: a concrete list of file paths and skills, each tagged with an access mode. This manifest — not a restatement of §12.1's categories — is what goes into the dispatch prompt.

**Access modes**

- **Read** — reference/judgment-criteria material. Must not be modified, even though the Worker's tool grant (`Read, Edit, Write, ...`) would technically allow it.
- **Edit** — an existing file the task expects the Worker to modify.
- **Write** — a new file the task expects the Worker to create.

A `Skill: <name>` entry is always Read — invoking a skill never grants edit access to the skill file itself.

**Example** (Worker dispatch for a UI/Screen × Implementation(Frontend) task):

```
Read: docs/reference/design/00_DesignPrinciples/03_Layout Principles.md, docs/reference/plan/03_화면별UX명세서/01_옷장.md
Edit: lib/screens/closet/closet_main_screen.dart
Write: lib/widgets/closet_item_tile.dart
Skill: flutter-implementation-conventions
```

For a Review dispatch, every item is Read by default (per §12.2, Review judges the Worker's output rather than producing it) — this includes the Worker's modified files themselves, which Review inspects but never edits.

# 13. Branch Strategy & PR Policy

## 13.1 Branch Structure

```text
main  ─ release only
 └─ dev  ─ default working branch. No direct commits (human-only exception), merges only via PR
     └─ feature/<backlog-item-slug>  ─ branched from dev when PM starts a BACKLOG.md item. Worker/PM commit freely here
```

## 13.2 Commit Gate

- `feature/*`: free commit and push, no report/confirmation gate.
- `dev` / `main`: direct commit blocked by hook; requires report + human confirmation (same procedure as Core Operating Principles checkpoint 3).
- `gh pr create` targeting `dev` (or any non-`main` base): free, no report/confirmation gate — the human reviews at merge time instead, so gating creation too would just ask the same question twice. ⚠️ This relies on PR creation itself triggering no automated action. Before adding any automation that runs just from a PR being opened (e.g. a `.github/workflows/` file with `on: pull_request`, auto-deploy, auto-merge), re-check whether it breaks this assumption — if it does, this free-gate needs to be reconsidered (see Decision.md's "Follow-up" note on this decision).
- `gh pr create` targeting `main` (or with no `--base`, which defaults to `main`): always blocked by hook; requires PR draft + report + human confirmation. This one stays gated because it signals a release decision (timing), not just code safety.
- `gh pr merge` (any direction): always blocked by hook, not a confirm-and-retry gate — the AI never merges, period. The human merges directly (GitHub UI or running the command themselves).
- `git push` targeting `main`: always blocked by hook; requires report + human confirmation.

## 13.3 PR Triggers

- **feature → dev**: triggered when a BACKLOG.md checklist item is complete (Worker→Review cycle done). PM drafts the PR title/description and opens it with `gh pr create --base dev` freely, no pre-creation confirmation needed. The human reviews and merges on GitHub — PM never merges, and never runs `gh pr merge`.
- **dev → main**: triggered when every item intended for the next patch/release has landed on dev. The human decides, or PM proposes and the human approves; PM drafts a report (doubling as release notes) and gets confirmation before running `gh pr create --base main`. The human merges on GitHub — PM never merges, and never runs `gh pr merge`.

GitHub Branch protection on `main`/`dev` (require PR before merge, disallow force-push/deletion) is configured by the human directly in the GitHub web UI — independent of the local hook, as a second safety net.

## 13.4 Sync Cadence (feature ← dev)

A long-lived `feature/*` branch can drift far from `dev` if nobody pulls — including structural changes (file moves/renames, policy doc reorganization) that turn into painful conflicts the longer they're deferred. This happened concretely on 2026-07-10: a parallel PR restructured the policy/reference doc layout on `dev`, and the Tester-harness feature branch hadn't synced in the meantime.

- **Pull `dev` into the feature branch at two checkpoints**: (a) whenever a Task completes (the Worker→Review→Tester cycle reaches Complete — the same moment BACKLOG.md's Current section gets updated), and (b) whenever an entire Plan (a multi-task effort, not a single step) finishes.
- Run `git fetch origin && git merge origin/dev` on the feature branch. This is a safe, feature-branch-local operation — no report/confirmation needed to run it (same basis as §13.2's free commit gate).
- If the merge is clean, continue. If it conflicts, PM resolves directly (the one with context on both sides' intent, same reasoning as why Tester — not the person waiting — should design its own scenarios) and then shows the resulting diff for human confirmation before finishing — especially when Decision documents or policy docs are among the conflicts (still governed by Core Operating Principles checkpoint 2).

# 14. Token & Stats Logging

Opt-in diagnostic tool, off by default — not a standing requirement on every task. The single switch is the `Status: ON`/`OFF` line at the top of `docs/work/TokenLog.md`. PM checks that line before spawning any Worker/Review/Tester. When it reads `OFF`, PM skips §14.1 entirely and Worker/Review/Tester omit the Stats line from their handoff. When it reads `ON`, both apply.

## 14.1 Token Usage (approximate)

PM checks the current conversation's total context token count (`/context`) immediately before spawning a Worker/Review/Tester, and again right after receiving that agent's handoff. The difference (Delta) is logged to `docs/work/TokenLog.md`.

This Delta approximates the growth of the PM session's own context (the dispatch prompt plus the returned handoff) — it is not the subagent's own internal token consumption, which PM cannot observe since the subagent runs in a separate context window.

## 14.2 Read/Edit Stats

Every Worker/Review/Tester handoff includes a Stats line: Read Count, Files Read, Search Count (Grep/Glob), and Edit/Write Files. PM appends each handoff's Stats to `docs/work/AgentStats.md`.

# 15. Worktree Placement

A worktree meant to run independent/parallel work (e.g. a separate session doing unrelated document restructuring while this session continues) must be created as a **sibling directory outside the repository root** (e.g. `../Digital-Wardrobe-<purpose>`, via `git worktree add ../Digital-Wardrobe-<purpose> <branch>`) — not under `.claude/worktrees/` (the `EnterWorktree` tool's default in-repo location).

**Why this is the only reliable fix, not just the preferred one**: confirmed 2026-07-13 — this project's Read/Grep/Glob tooling does not respect `.gitignore` (verified: `.dart_tool/`, which is gitignored, is still fully returned by Glob). So even though `.claude/worktrees/` is listed in `.gitignore`, any worktree placed there is still walked by every subsequent Grep/Glob call for as long as it exists, doubling search surface and token cost. No ignore-file-based workaround (`.gitignore`, `.ignore`, `.rgignore`) fixes this, since the tooling doesn't consult ignore files at all — only physical placement outside the repo's directory tree avoids the double-match.

**Precedent**: the skill-extraction pilot already used this pattern (`Digital-Wardrobe-testbed`, sibling to the main repo).

**Cleanup discipline**: remove a finished sibling worktree with `git worktree remove <path>`, not a raw `rm -rf` — the latter leaves a dangling `.git` worktree-metadata entry behind. Two such orphans (`.claude/worktrees/policy-audit-fix`, `.claude/worktrees/setting-ui-temp`) were found and cleaned up on 2026-07-13; one had a `.git` pointer to already-`git worktree prune`d metadata, meaning it had silently been causing duplicate search matches since well before it was noticed.
