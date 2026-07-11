---
name: documentation-conventions
description: How to write and update this project's Reference documents (docs/reference/**) — living-document discipline and concise-writing rules. Invoke before writing to or editing any file under docs/reference/**.
---

# Documentation Conventions

## 이 스킬을 언제 쓰나

`docs/reference/**` 아래 어떤 파일이든 쓰기/수정하기 전에 호출한다.

## 원문 (Workflow_Project.md §1.4, §1.5 — verbatim)

### 1.4 Living Documents

Reference documents must always have only a single up-to-date version.

Do not create copies such as Version2, Final, or Final_Final.

### 1.5 Concise Writing

Reference documents are written as concisely as possible, without duplication, as long as doing so does not compromise exact meaning.

- This applies to newly authored or edited content. It does not retroactively shorten existing History document entries (`Decision.md` / `TechnicalDebt.md`) — those are append-only per §6.
- History document entries are held to a different standard: per §1.3 (Source of Truth), they must carry enough context to stand in for a lost conversation, so more detail is expected there than in Reference documents.
- When conciseness would conflict with the reachability requirement in §3 "Skill-Internal Ledgers vs. Official Handoff" (transcribing content directly so a fresh session can find it), reachability wins — do not replace necessary inline detail with a link just to shorten a document.
