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

```
Worker → Complete
```

Exception: if the single modification changes runtime-observable behavior (not just text/style/docs), Tester still runs — treat it as the M pipeline for that step.

---

## M (Medium)

```
Worker → Review → (Fail) Worker(fix) → Review          [Repeat until Review passes]
              → (Pass) Tester → (Pass) Complete
                             → (Fail) Worker(fix) → Review   [Return to the first stage and repeat the entire cycle]
```

If Review fails, Worker fixes the issue and returns only to Review (Tester does not need to inspect code that has not yet passed Review). However, **if Tester fails, Worker fixes the issue and returns to the first stage, repeating the Review → Tester cycle from the beginning** — this is to verify both that the fix did not introduce new code defects and that the actual runtime behavior has been fixed. This re-validation loop repeats until both Review and Tester pass. The cost of repeated execution follows the "Agent Reuse in Re-validation Loops" principle below.

---

## L (Large)

```
PM → Worker → Review → (Fail) Worker(fix) → Review
                   → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                  → (Fail) Worker(fix) → Review
```

The same branching rules as M apply: Review failure → Worker(fix) → Review; Tester failure → Worker(fix) → Review (restart from the beginning); Tester pass → proceed to Integrator.

---

## XL (Extra Large)

Split the review into two independent reviews.

```
PM → Worker → Review ×2 → (Fail) Worker(fix) → Review ×2
                       → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                      → (Fail) Worker(fix) → Review ×2
```

---

## Re-validation Scope in the Re-validation Loop (Common to M/L/XL)

"Returning to the first stage" means running the validation again; it does not mean reviewing the entire original Task from the beginning every time. Whether the re-validation round should spawn a new subagent or continue using the Review/Tester from the previous round follows the existing `CLAUDE.md` "Agent Instance Lifetime" principle (a round that re-examines the same Task falls under the "consecutive steps, same expertise" case described by that principle).

The scope of re-validation is narrowed to **the parts changed by the Worker's fix (diff) + the files touched by that fix** — portions that already passed in the previous round are not re-evaluated from scratch each time. If the fix touches files outside the original Task Manifest (§12.4), PM re-evaluates and adds only that expanded scope according to §12.3 (Scope Escalation).

This principle does not reduce the validation rigor of "repeat until both Review and Tester pass" — it only reduces the **cost** of repeated execution.

---

## Decision-Stage (Design & Plan) Pipeline

This pipeline covers all three Decision rows of §12.1: a design spec (UI/Screen × Decision), an implementation plan (Logic/Feature × Decision), or a data/architecture design (Data/API/Architecture × Decision). Regardless of Task size, the following applies:

```
Draft (small units: section/chapter level) → Review (that unit) → Repeat (until all units pass)
  → Assemble the full draft → Audit (holistic review of the completed draft in the context of the entire project)
      → (Pass) Finalize
      → (Fail) Revise the flagged units → Review → ... → Re-run Audit
```

The "small-unit Review" in the Design stage is already satisfied by the existing Design Review (`review` subagent, §12.1). In the Planning stage (writing implementation plans), the policy previously stated "Usually none (PM scope)", but the user-approval process is considered a substitute for this role **only when all of the following conditions are met** — if the conditions are not met, the `review` subagent must be called separately:

1. The three Self-Review items from the `writing-plans` skill (Spec coverage / Placeholder scan / Type consistency) must actually be performed, and the results must be recorded (not merely "the user said it looks good"; there must be a check against concrete evaluation criteria).
2. The approval must be given after actually cross-checking the relevant project policy/reference documents (`§12.1 Required Materials` for the applicable Layer × Stage) — PM must specify which documents were used as the basis for the approval request.

If these two conditions are met, the separate `review` subagent call may be skipped. The newly required step is **one Audit immediately before finalization**, and this always applies regardless of Task size (it always runs regardless of whether the above conditions are met).

**Ownership Assessment (all three Decision rows — UI/Screen · Logic/Feature · Data/API/Architecture):** Small-unit Review at the Decision stage also assesses the following. The same requirement applies whether it is performed by the `review` subagent or replaced by the alternative conditions above; under the alternative path, it is performed as a fourth Self-Review item — none of the three Self-Review items (Spec coverage / Placeholder scan / Type consistency) checks ownership assignment, so without adding this assessment to the alternative path, the ownership check would be skipped entirely under the cheaper path recommended by the policy.

- If the specification lists multiple entry points for a single action but the design does not designate the file that owns that action, assign P1.
- If the Task meets the gate (Task size L/XL, or the specification explicitly identifies 2 or more screens/entry points for a single action) but the deliverable does not include an updated ownership map (`docs/reference/architecture/00_OwnershipMap.md`), assign P1.

**Known Trade-off (intentionally accepted):** Passing these two conditions ultimately constitutes the author's own Self-Review, rather than the independent verification required by §1.1 (Role Separation). The exception is nevertheless allowed for practical reasons: (a) the Design stage already mandates an independent `review` subagent, so there is no asymmetry; (b) the Planning stage always has a second independent set of eyes in the form of the mandatory Audit, so it does not end with a purely self-checking process; and (c) requiring a `review` subagent for every plan section would significantly increase the overhead of plan writing, increasing the risk that this principle would not actually be followed. See `docs/history/Decision.md` for the detailed rationale.

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

→ §2 Feature Audit ("Checks" / "Important") — already fully defined there, not restated here.

# 10. Definition of Done

When a task step is completed, always verify the following — including for each individual step within a larger task, not only when the whole task finishes (see §3 "Skill-Internal Ledgers vs. Official Handoff"):

□ Changes have been committed to Git

□ Reference documents have been updated

□ Decisions have been documented

□ Technical debt has been recorded

□ If the recorded technical debt describes a recurring pattern rather than a one-off defect, it has been promoted to a rule in the relevant domain conventions skill

□ If this step changed which file owns a shared behavior, the ownership map (`docs/reference/architecture/00_OwnershipMap.md`) has been updated

□ Change Impact has been reviewed

□ `docs/work/BACKLOG.md`'s Current section reflects this step (not only "the next task has been added to the backlog" — the just-finished step's status too)

□ If the change has runtime-observable behavior, Tester has reported Pass (or the N/A reason is recorded)

□ If PM judged no continuation work is queued, the fresh-session continuity simulation (§3 "Post-Completion Continuity Simulation") was run and, if clean, `/clear` was recommended to the user

# 11. Core Operating Principles

Index of rules already stated in full elsewhere in this document — not a second copy. Domain documents (Development/Design) point here rather than restating these lines themselves.

1. Source of Truth → §1.3
2. Sessions share no memory except via orchestrated handoff → §3
3. Handoffs are PM-orchestrated; mandatory checkpoints need human confirmation → §3
4. One Session = One Purpose → §1.2
5. Pipeline by task size → §4, §5
6. Review principles → §8
7. Audit principles → §9 (→ §2 Feature Audit)
8. Reference documents always current → §6
9. History documents never deleted → §6
10. Change Impact evaluated before changes → §7
11. Task Manifest required before spawning a Worker → §12.4

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

(§5's "Decision-Stage (Design & Plan) Pipeline" pre-finalization Audit rule is reflected in all three Design/Planning/Data rows above — the three rows are updated together to prevent the body rule and this table from becoming inconsistent when updated separately.)

(**Ownership Map**: All Implementation-stage Tasks, as well as Decision-stage Tasks that meet the gate (Task size L/XL, or the specification explicitly identifies 2 or more screens/entry points for a single action), must include `docs/reference/architecture/00_OwnershipMap.md` in their Required Materials regardless of Layer/Stage. Since it is a single-table document, the per-dispatch cost is small.)

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

PM includes `docs/reference/architecture/00_OwnershipMap.md` as **Read** in the Task Manifest for **all Implementation-stage Tasks**. For Tasks that require the map to be updated, it is included as **Edit**. For Decision-stage Tasks, it is included when the Task meets the gate (Task size L/XL, or the specification explicitly identifies 2 or more screens/entry points for a single action).

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
