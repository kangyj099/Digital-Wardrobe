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
