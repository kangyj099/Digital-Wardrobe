> Version 1.1
> Purpose: A development implementation policy for solo app development projects using Claude Projects that **minimizes token usage while maintaining project quality and consistency.**

---

# Development Workflow

# 1. Core Principles

## Source of Truth

The project's Source of Truth is the Git repository and the latest Reference documents.

Source code is based on Git, while planning, policies, and design are based on the latest Reference documents.

AI sessions are not the project's source of truth.

**Principles**

* Source code is based on Git.
* AI is not a code repository.
* Chat is a discussion space.

---

# 2. Information Handoff Between Sessions

## 2.1 Handoff Rules

| From       | To                    | Information to Transfer                      |
| ---------- | --------------------- | -------------------------------------------- |
| PM         | Worker                | Task objective, scope                        |
| Worker     | Review                | Modified files, change summary, impact scope |
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

Manages the entire project (not limited to development).

**Responsibilities**

* Project management
* Prioritization
* Scheduling
* Feature planning
* Selecting the next task

**Does not**

* Write code

---

## Worker

**Responsibilities**

* Implementation
* Modifications
* Refactoring

**Does not**

* Change product planning
* Manage the project

Before writing or reviewing implementation code, invoke the `engineering-principles` skill (`.claude/skills/engineering-principles/SKILL.md`).

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
* Testing
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

## Integrator

**Default policy:** Performed by a human. Use an AI session only when necessary.

**Responsibilities**

* Consolidate review results
* Remove duplicates
* Prioritize issues
* Produce the final revision list

---

## Feature Audit

**Responsibility**

Reviews the project as a whole.

**Checks**

* Missing functionality
* Policy conflicts
* UX consistency
* Architecture
* Requirements compliance

**Important**

Audit does not make direct modifications. It creates new tasks for the PM.

---

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
5. Review identifies problems.
6. Audit evaluates the project as a whole.
7. Decision Log and Technical Debt are maintained as cumulative documents.
8. Reference documents are always kept up to date.
9. Each session has only one purpose.

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
