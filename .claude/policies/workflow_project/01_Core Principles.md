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
