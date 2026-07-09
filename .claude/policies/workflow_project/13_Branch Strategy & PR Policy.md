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
