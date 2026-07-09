# Design Workflow

> Version 2.0
>
> Purpose: A design workflow policy for efficiently collaborating with AI on Flutter-based mobile app design.

---

# 1. Core Principles
→ .claude\policies\workflow_design\01_core principles.md

# 2. Design Process

Design work follows the sequence below.

Design Pipeline

Brand Guide (   )
→ UX Principles
→ Interaction Principles
→ Layout Principles
→ HF Sample
→ Visual Review
→ Design Tokens
→ Design System
→ Components
→ HF Screens
→ Review
→ Dev Handoff

# 3. Unit of Work

Each session performs only one design task.

# 4. Page Type First

Before designing a new screen, first determine its Page Type.

Define shared rules in the Page Type specification, and document only screen-specific behavior in individual screen specifications.

Each screen should contain only its unique characteristics.

# 5. Design Freeze

The representative High-Fidelity Sample is the visual baseline of the project.

After the Design Tokens are finalized, changes to layout structure or visual language should be avoided.

If structural changes are required after Design Tokens are approved, the representative High-Fidelity Sample must be reviewed and updated first.

# 6. Design Review
→ .claude\policies\workflow_design\06_design review.md

# 7. Design Audit

Reviews the project's overall design.

Audit does not make direct modifications. It creates tasks for the PM.

**Review Areas**

* Cross-screen consistency
* Design System conflicts
* Duplicate components
* UX flow
* Accessibility

# 8. Design System Updates

The Design System is established after Design Tokens are finalized.

Whenever shared visual rules or Tokens change, update the Design System accordingly.

# 9. Component Library Updates

Whenever reusable shared components are added or modified, update the Component Library.

# 10. Change Impact

Evaluate the Change Impact before making any design changes.

# 11. Definition of Done

□ Review feedback has been incorporated

□ Design Freeze status has been verified

□ Design System update has been verified

□ Component Library update has been verified

□ Developer impact has been reviewed

□ Decision has been documented

□ Design Debt has been documented

# 12. Core Operating Principles

1. The Design System takes precedence over individual screens.
2. Shared rules are defined in the Page Type specification.
3. Individual screens contain only their unique characteristics.
4. Review identifies problems.
5. Audit evaluates the project as a whole.
6. The Design System is always kept up to date.
7. Prioritize component reusability.
8. Always consider Flutter implementation feasibility.
9. Always evaluate the Change Impact before making changes.
10. Design is inseparable from development.
