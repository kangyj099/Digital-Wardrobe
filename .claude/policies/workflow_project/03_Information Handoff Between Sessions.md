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

