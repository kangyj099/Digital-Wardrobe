> Version 1.1 — Defines an efficient workflow for reducing token usage while producing accurate results.
> This document applies across the entire project, including planning, design, development, and release.

# Project Workflow

Apply the following workflow based on the project size and the nature of the task.

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

## 1.4 Living Documents

Reference documents must always have only a single up-to-date version.

Do not create copies such as Version2, Final, or Final_Final.

---

## 1.5 Concise Writing

Reference documents are written as concisely as possible, without duplication, as long as doing so does not compromise exact meaning.

- This applies to newly authored or edited content. It does not retroactively shorten existing History document entries (`Decision.md` / `TechnicalDebt.md`) — those are append-only per §6.
- History document entries are held to a different standard: per §1.3 (Source of Truth), they must carry enough context to stand in for a lost conversation, so more detail is expected there than in Reference documents.
- When conciseness would conflict with the reachability requirement in §3 "Skill-Internal Ledgers vs. Official Handoff" (transcribing content directly so a fresh session can find it), reachability wins — do not replace necessary inline detail with a link just to shorten a document.

---

## 1.6 Version Numbering

Reference documents carrying a `> Version X.Y` header follow semantic-ish versioning.

- A chapter-level addition or modification bumps the number after the dot (minor): X.Y → X.(Y+1).
- A change to the document's usage pattern or overall framework/structure bumps the number before the dot (major): X.Y → (X+1).0.
- One revision pass gets one bump, even if it contains multiple chapter-level changes.
- Cosmetic edits that don't change meaning (renames, cross-reference updates, typo/wording fixes) do not count as a modification for this purpose — same exclusion as §1.5's Decision.md logging rule.

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

Review 실패 시엔 Worker가 고치고 Review로만 돌아간다(Tester는 아직 볼 필요 없는 코드니까). 하지만 **Tester가 실패하면 Worker가 수정한 뒤 처음 단계인 Review로 돌아가 Review→Tester 사이클을 처음부터 다시 밟는다** — 수정이 새 코드 결함을 만들지 않았는지, 그리고 실제로 동작이 고쳐졌는지 둘 다 다시 확인하기 위함. 이 재검증 루프는 Review와 Tester가 모두 통과할 때까지 반복된다.

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

---

# 8. Review Principles

A Review is not a brainstorming session for new ideas.

Its purpose is to identify issues that must be corrected.

Focus on finding problems, but do not propose unnecessary design changes.

**Principles**

* Maximum of five findings (no limit for critical issues)
* Assign priority (P0–P3)
* Provide rationale
* Minimize subjective preferences

---

# 9. Audit Principles

An Audit evaluates the entire project, not the current task.

It creates new tasks rather than making direct modifications.

---

# 10. Definition of Done

When a task step is completed, always verify the following — including for each individual step within a larger task, not only when the whole task finishes (see §3 "Skill-Internal Ledgers vs. Official Handoff"):

□ Changes have been committed to Git

□ Reference documents have been updated

□ Decisions have been documented

□ Technical debt has been recorded

□ Change Impact has been reviewed

□ `docs/work/BACKLOG.md`'s Current section reflects this step (not only "the next task has been added to the backlog" — the just-finished step's status too)

□ If the change has runtime-observable behavior, Tester has reported Pass (or the N/A reason is recorded)

---

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

---

# 12. Role Information Access

Defines what materials each role sees for a given task, based on the task's **Layer** and **Stage** — not on job title. This generalizes across any future pipeline (frontend, backend, infra, etc.) instead of hardcoding per-role exceptions.

## 12.1 Layer × Stage Determines Scope

Every task is tagged with the Layer(s) it touches and the Stage (Decision or Implementation) within that layer. This tagging happens during the existing Impact Scope evaluation (§7) — no separate step is added.

| Layer | Stage | Required Review | Required Materials |
| --- | --- | --- | --- |
| UI/Screen | Decision (Design) | Design Review | Raw references (`참고자료/`), Design reference docs, Plan reference docs (IA/UX spec), Brand docs, `Decision.md` |
| UI/Screen | Implementation (Frontend) | Development Review + spec-compliance check | Finalized design tokens/system doc, screen UX spec, existing widgets (`lib/`), Development workflow policy, Frontend workflow policy (`Workflow_Frontend.md` — stage-index anchor doc, lists the Frontend-specific skills to invoke) |
| Logic/Feature | Decision (Planning) | Usually none (PM scope) | Plan reference docs |
| Logic/Feature | Implementation | Development Review (functional) | Related code, Plan reference docs, **Skill: `engineering-principles`** (invoke first) |
| Data/API/Architecture | Decision | Development Review (architecture), pre-review | Development workflow policy |
| Data/API/Architecture | Implementation | Development Review (architecture) | Related modules/schema, **Skill: `engineering-principles`** (invoke first) |
| (any Layer with runtime behavior) | Implementation — Tester pass | Runs after Review passes | Same Reference docs as Review for that Layer/Stage, `Decision.md`/`TechnicalDebt.md`, Worker's handoff + modified files, and the runnable app itself (not the raw exploratory material behind a Decision-stage task) |

## 12.2 Worker vs. Review Materials

Worker and Review do not receive identical materials for the same task.

- **Shared**: judgment-criteria documents — the Reference documents for that Layer/Stage, **and** `Decision.md` / `TechnicalDebt.md`. History documents count as judgment criteria the same way Reference documents do, since Review checks policy compliance and consistency against past decisions.
- **Worker-only**: raw/exploratory material behind a Decision-stage task (e.g. raw design references, brand voice docs). Review does not need the exploration process, only the result and whether it complies.
- **Review-only**: the Worker's output (modified files, change summary, impact scope) — the artifact being judged, which the Worker produces rather than consumes.

## 12.3 Scope Escalation

If Review needs material outside its granted scope to reach a judgment, Review does not expand its own access. Review requests a scope expansion from PM, who re-evaluates Impact Scope (§7) and grants the minimum additional material needed. This preserves the Minimal Handoff Principle (§3) while allowing legitimate exceptions.

---

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