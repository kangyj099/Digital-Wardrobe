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

Runs after Review passes. Exercises the actual running app (Flutter `integration_test`) to check what static review can't see — runtime behavior, not code.

**Responsibilities**

* Check behavior results, not code
* Cover realistic non-standard flows, not just the happy path
* Check regressions in existing features connected to the change
* Check every defined state (success, loading, empty, error, retry, cancel) that's actually implemented
* Check that the same data displays consistently across screens
* Check that saved data survives navigation/re-entry
* Check that repeated input or duplicate requests don't create duplicate data
* Check behavior against Reference documents and project policy
* Design and commit its own `integration_test/` scripts (never touches `lib/`)
* Report Pass/Fail with mandatory reproduction steps for every Fail

**Does not**

* Implement or fix anything
* Propose refactors
* Evaluate code style (that's Review's job)
* Invent scenarios for features that aren't actually implemented yet

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
