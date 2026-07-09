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
