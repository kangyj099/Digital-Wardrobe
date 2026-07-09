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
