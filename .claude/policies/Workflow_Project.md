> Version 2.6 — Defines the project workflow and links to detailed workflow documents.
> This workflow applies across the entire project, including planning, design, development, and release.

# Project Workflow

Apply the following workflow based on the project size and the nature of the task.

# 1. Core Principles
  →  .claude\policies\workflow_project\01_Core Principles.md

# 2. Roles
  →  .claude\policies\workflow_project\02_Roles.md

# 3. Information Handoff Between Sessions
  →  .claude\policies\workflow_project\03_Information Handoff Between Sessions.md

# 4. Task Size
  →  .claude\policies\workflow_project\04_Task Size.md

# 5. Standard Pipeline
  →  .claude\policies\workflow_project\05_Standard Pipeline.md

# 6. Document Policy
  →  .claude\policies\workflow_project\06_Document Policy.md

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
  →  .claude\policies\workflow_project\12_Role Information Access.md

# 13. Branch Strategy & PR Policy
  →  .claude\policies\workflow_project\13_Branch Strategy & PR Policy.md

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
