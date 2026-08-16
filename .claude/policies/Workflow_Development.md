> Version 2.1
> Purpose: A development implementation policy for solo app development projects using Claude Code that **minimizes token usage while maintaining project quality and consistency.** Single consolidated document (former `workflow_development/04_Roles.md` merged back into this file on 2026-07-22 for reading convenience — see `docs/history/Decision.md`).

---

# Development Workflow

## 목차

- [1. Core Principles](#1-core-principles)
- [2. Information Handoff Between Sessions](#2-information-handoff-between-sessions)
- [3. Pipeline by Task Size](#3-pipeline-by-task-size)
- [4. Roles](#4-roles)
- [5. Document Policy](#5-document-policy)
- [6. Overall Workflow](#6-overall-workflow)
- [7. Core Operating Principles](#7-core-operating-principles)
- [8. Exception Handling Rules](#8-exception-handling-rules)

---

# 1. Core Principles

## Source of Truth
→ `Workflow_Project.md` §1.3 (per §1.7, no development-specific elaboration needed here).

## Scope of Design Deliverables

Design (Decision) deliverables must specify not only components and data models, but also the following for interaction procedures:

* The single file that owns the procedure. Listing the entry-point files is not sufficient.
* The boundary between aspects that may differ by screen and aspects that must remain consistent across all screens.

The scope includes user actions that are invoked under the same name across multiple screens.

---

# 2. Information Handoff Between Sessions

## 2.1 Handoff Rules

| From       | To                    | Information to Transfer                      |
| ---------- | --------------------- | -------------------------------------------- |
| PM         | Worker                | Task objective, scope                        |
| Worker     | Review                | Modified files, change summary, impact scope |
| Review     | Tester                | **Only when Review passes**: modified files, impact scope |
| Tester     | Worker                | **Only when Tester fails**: fail list + reproduction steps — Worker fixes, then goes back to Review, not straight back to Tester (full Review→Tester cycle repeats until both pass). If Tester passes: for M, no handoff — task completes; for L/XL, proceeds to Integrator (or Human) per §3's pipeline, not a direct handoff-free completion. |
| Review     | Integrator (or Human) | Revision list (P0–P3)                        |
| Integrator | Worker                | Final revision list                          |
| Worker     | PM                    | Completion summary                           |

---

## 2.2 Handoff Templates

### Worker → Review

```text
Task

Goal

Modified Files

Impact Scope

Review Request

Out of Scope
```

---

### Review → Worker

```text
P0

P1

P3

Rationale
```

---

### Worker → PM

```text
Completed Work

Modified Files

Remaining Issues

Next Candidate Task
```

---

### Tester → Worker (or PM)

```text
Task

Scenarios Tested (Pass/Fail each)

Repro Steps (required for each Fail)

Out of Scope / Skipped (what wasn't checked, and why)
```

---

# 3. Pipeline by Task Size

## Task size is determined by its impact scope.

The number of modified files is only a reference metric. **Impact scope always takes priority.**

| Size   | Criteria                                                                                                           |
| ------ | ------------------------------------------------------------------------------------------------------------------ |
| **S**  | Minor changes with little or no functional impact, such as a single component, text, or styling                    |
| **M**  | Changes within an existing feature. The impact is limited to a single feature.                                     |
| **L**  | Addition of a new feature, new screen, or new user flow                                                            |
| **XL** | Changes affecting the overall system, including multiple features, authentication, database, APIs, or architecture |

If the classification is ambiguous, prioritize the impact scope.

---

# 4. Roles

## PM (Project Manager)
→ `Workflow_Project.md` §2 PM 참고. Dev 도메인 비고: PM 역할은 development에 국한되지 않음(전사 총괄).

---

## Worker

**Responsibilities**

* Implementation
* Modifications
* Refactoring

**Does not**

* Change product planning
* Manage the project

Before writing or reviewing implementation code, invoke the `engineering-principles` skill (`.claude/skills/engineering-principles/SKILL.md`) — this applies to Review as well as Worker, per §12.1 Required Materials.

---

## Review

By default, a single Review session is used.

**Review Areas**

* Code quality
* Architecture
* Bugs
* Performance
* Exception handling
* Security
* Testing (static only — whether test code exists and is well-structured/covers the right cases; does not run the app. Actual runtime behavior is Tester's job, below)
* UX
* Alignment with product requirements

### Development Review (Optional)

Used only for large-scale tasks.

**Reviews**

* Code
* Architecture
* Performance
* Security

### Product / UX Review (Optional)

Used only for large-scale tasks.

**Reviews**

* UX
* Accessibility
* Usability
* Alignment with product requirements

---

## Tester
→ `Workflow_Project.md` §2 Tester 참고. Dev 도메인 추가사항(Project.md에 없는 것만):

* Design and commit its own `integration_test/` scripts (never touches `lib/`)
* Report Pass/Fail with mandatory reproduction steps for every Fail
* **Does not** (추가): Invent scenarios for features that aren't actually implemented yet

---

## Integrator

**Default policy:** Performed by a human. Use an AI session only when necessary.

**Responsibilities**

* Consolidate review results
* Remove duplicates
* Prioritize issues
* Produce the final revision list

---

## Feature Audit
→ `Workflow_Project.md` §2 Feature Audit (per §1.7, this role has no development-specific elaboration — defers to the project-wide definition).

# 5. Document Policy

## Reference Documents

### Reference Document Update Rules

Whenever an **L** or **XL** task is completed, always verify whether the Reference documents need to be updated.

Update the Reference documents whenever any of the following changes occur:

* Product planning changes
* API changes
* Database changes
* Design System changes
* Policy changes
* Ownership of a shared behavior changes (the owning file moves, or a behavior becomes or ceases to be cross-screen)

Implementation-only work that does not change the Reference content should **not** modify the Reference documents.

---

## History Documents

These are cumulative records.

Never delete them.

---

### Decision.md Policy

**Record**

* Important decisions
* Reasons for those decisions

Also record changes to the project's operational policies, including:

* Workflow changes
* Role changes
* Operational process changes
* Reference document policy changes

Do **not** record typo fixes or minor wording changes.

---

### TechnicalDebt.md

**Record**

* Refactoring tasks
* Improvement opportunities
* Deferred work

---

# 6. Overall Workflow

```text
Project Knowledge
↓
PM
↓
Worker
↓
Review
↓
(If needed)
Development Review
↓
Product / UX Review
↓
Integrator (or Human)
↓
Worker Revision
↓
Commit to Git
↓
Update Decision.md (if needed)
↓
Update TechnicalDebt.md (if needed)
↓
Feature Audit (large-scale tasks only)
↓
PM
↓
Next Task
```

---

# 7. Core Operating Principles

Always remember:

1. Git is the only Source of Truth.
2. Handoffs should contain only the minimum necessary information.
3. Use the pipeline appropriate for the task size (S/M/L/XL).
4. Small tasks should use a lightweight pipeline.
5. Review/Audit 범위 원칙 → `Workflow_Project.md` §11 참고.
6. Decision Log and Technical Debt are maintained as cumulative documents.
7. Reference documents are always kept up to date.
8. Each session has only one purpose.

---

# 8. Exception Handling Rules

In exceptional situations, the following rules take precedence over the standard workflow.

---

## Hotfix

Urgent bug fix.

```text
Worker → Review → Deploy
```

After completing a hotfix, document it in **Decision.md** only if the root cause is related to any of the following:

* Structural issues
* Recurring problems
* Operational policy changes

Do **not** record ordinary bug fixes.

---

## Product Planning Changes

If product planning changes are required:

```text
PM → Update Product Planning Documents → Worker
```

---

## Structural Issues Found During Audit

Audit does not make direct modifications.

```text
Audit → PM → Create New Task → Next Feature
```

---

## Urgent Priority Changes

If a new urgent task arises, the PM either pauses the current feature or reprioritizes the work.

The Worker follows the PM's priorities.
