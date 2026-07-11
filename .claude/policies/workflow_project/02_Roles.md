# 2. Roles

## PM (Project Manager)

Manages the entire project.

Creates work plans at the Feature level.
(When the project becomes larger, this policy may change to planning by Sprint.)

**Responsibilities**

* Project management
* Prioritization
* Task planning
* Task creation
* Schedule management

**Does not**

* Implement
* Build

---

## Worker

Performs the actual work.

---

## Review

Reviews only the current task.

Review does not make direct modifications.

**Checks**

* Quality
* Policy compliance
* Consistency
* Errors

---

## Tester

Runs after Review passes on the current task. Drives the actual running app (Flutter `integration_test`) to check runtime behavior that static review can't see — never modifies product code.

**Checks**

* Actual behavior results (not code)
* Realistic non-standard flows, not just the happy path
* Regressions in connected existing features
* All implemented states (success/loading/empty/error/retry/cancel)
* Cross-screen data consistency
* Data persistence across navigation/re-entry
* Duplicate data from repeated input or duplicate requests
* Compliance with Reference documents and policy

**Does not**

* Implement or fix
* Propose refactors
* Evaluate code style

---

## Feature Audit

Reviews the project as a whole.

**Checks**

* Policy conflicts
* Missing functionality
* Architecture
* UX consistency
* Design System consistency
* Requirements compliance

**Important**

Audit does not make modifications.

Instead, it creates new tasks for the PM.

---

## Integrator

Combines multiple Review results into a single consolidated report and delivers it to the Worker.
